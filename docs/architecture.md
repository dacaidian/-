# War Card 架构说明

> Encoding guard: this document must stay valid UTF-8. If Chinese text becomes unreadable or `apply_patch` cannot edit this file, first repair/normalize the file as UTF-8. Do not append around broken bytes.
>
> 中文说明：本文档必须保持 UTF-8。若出现乱码，应先修复编码。

## 项目形态

这是一个 Godot 桌面卡牌战棋游戏。正常流程是：主菜单 -> 种族/英雄选择 -> 棋盘对局 -> 对局结算 -> 主菜单。卡牌规则主要由 `data/cards.json` 驱动，运行时行为由通用行动、效果、状态、触发器和 UI 控制器组合实现。

主要目录：

- `data/`：种族、英雄、卡牌和衍生牌定义。
- `scenes/`：Godot 场景，包括应用外壳、主菜单、种族选择、棋盘、卡牌和 debug UI。
- `scripts/application/`：跨页面应用数据契约，目前包含统一对局结果 `MatchResult`。
- `scripts/data/`：静态数据和运行时数据模型。
- `scripts/actions/`：玩家可见的行动，如移动、攻击、施法、注入毒液、毒爆、骑乘攻击、方向移动、种族技能等。
- `scripts/effects/`：由 JSON 配置调用的通用效果。
- `scripts/game/`：对局编排、目标选择、触发、死亡、手牌使用、被动、棋盘层、AI 和比赛配置。
- `scripts/ui/`：应用导航、菜单页面、结算画面、动画、状态显示、手牌抽屉、装备面板和种族面板等。
- `scripts/ai/`：AI 候选行为生成、评估和执行。
- `scripts/audio/`：背景音乐、音效池和音频配置解析。
- `assets/`：卡面、UI、音乐和未来 VFX 贴图资源。

## 应用外壳与页面流程

`project.godot` 的唯一正常入口是 `scenes/app/game_shell.tscn`。`GameShell` 在整个应用生命周期内常驻，并通过 `ScreenHost` 挂载当前页面。当前页面状态包括主菜单、种族选择、牌局历史骨架、卡牌图鉴和战斗。页面不能直接创建另一个页面，也不能修改 `SceneTree.current_scene`；它们只发出用户意图，由 `GameShell` 负责实例化、卸载和淡入。

主菜单位于 `scenes/main_menu/main_menu.tscn`，提供开始游戏、牌局历史、卡牌图鉴和退出游戏。牌局历史当前使用独立功能页骨架；卡牌图鉴使用 `scenes/ui/card_collection_screen.tscn`。两者都只向 `GameShell` 发出返回意图，不直接加载主菜单。

原 `StartMenu` 现在是纯种族/英雄选择页。它维护 `MatchSetup`，开始时发出 `match_start_requested`，返回时发出 `back_requested`。`MatchSetup.duplicate_configuration()` 生成与页面生命周期解耦的配置快照；`GameShell` 在战斗节点进入场景树、触发 `_ready()` 之前调用 `GameManager.configure_match()`。选择页不得直接加载 `main.tscn`。

`GameManager` 只管理一局对战。资源分胜利和投降都进入 `_finish_match()`，停止 AI 调度、取消交互并生成 `MatchResult`。`MatchResult` 保存结束原因、胜负方、回合、目标分和玩家摘要，是未来牌局历史持久化的稳定输入；历史模块不得持有 `PlayerState` 或已销毁战斗节点。`MatchResultScreenController` 根据结束原因展示资源胜利或投降结算，玩家确认返回后，`GameManager` 只发出 `match_finished`，由 `GameShell` 卸载战斗并回到主菜单。

### 卡牌图鉴

图鉴的数据入口仍是 `CardDatabase`，UI 不重新解析 `cards.json`。`CardDatabase` 分别维护 `cards_by_faction_id` 与 `token_cards_by_faction_id`：前者用于常规牌池，后者用于衍生牌归档；两类卡牌都进入全局 `cards_by_id`。`get_faction_token_cards()` 只暴露衍生牌查询，不改变其“不进入牌池”的规则。即使未来某个种族只有 `tokens[]` 而没有 `cards[]`，两个索引也必须独立完成加载。

`CardCollectionCatalog` 是图鉴只读查询模型。它把普通牌和衍生牌转换为 `CardCatalogEntry`，解析种族显示名、英雄专属关系、中文类型/关键字和来源分类，并提供种族、类型、阶级、来源、全文搜索与排序组合。来源分类不是简单读取 `count`：

- 常规牌池：普通 `cards[]` 中会进入牌池的卡牌。
- 默认入手：`start_in_hand: true`，开局进入手牌但不进入牌池。
- 衍生牌：定义在对应种族 `tokens[]`，只能由效果、技能或形态变化生成。
- 状态展示：时间、RC 浓度等规则状态牌，保留图鉴可见性但不进入牌池。

`CardCollectionScreen` 只维护筛选状态、种族导航、分页、悬浮预览、点击选择和详情面板，不决定卡牌来源。搜索同时覆盖名称、描述、id、种族、英雄归属、原始关键字与中文关键字。英雄是独立图鉴类型；“随从牌”筛选不重复包含英雄。卡墙每页最多实例化 12 张卡图，筛选作用于完整目录；换页和离开图鉴时释放 `CardData` 的正面纹理强引用，避免浏览图鉴后长期保留整套高分辨率卡面。卡牌正面使用 `front_texture`，不得使用仅供棋盘展示的 `table_texture`。

投降按钮及确认窗口由 `MatchExitController` 管理，并挂在 `GameManager` 持有的独立 `MatchExitLayer` 上，避免战斗根节点 `_ready()` 装配期间的兄弟节点插入竞争。它只负责展示、确认和发出意图；投降方识别、忙碌状态校验、胜者判定和结算仍属于 `GameManager`。单人对 AI 时，唯一的非 AI 玩家是投降方；本地双人时，当前行动玩家是投降方。未来增加暂停、设置或返回桌面时，应扩展独立的对局菜单控制器，不把场景导航塞回回合 HUD。

## 依赖方向与编排边界

项目按“数据模型 -> 规则能力 -> 对局编排 -> 表现适配”的方向组织。下层不反向持有上层 UI 节点：

- 数据模型：`CardData`、`CardState`、`PlayerState`、`BoardCell` 只表达静态定义和运行时状态。
- 规则能力：action、effect、status、target/death/board resolver 负责合法性与状态变化；同一规则只保留一个权威入口。
- 对局编排：`GameManager` 持有本局对象并暴露稳定门面，负责把回合、交互、触发、死亡和表现请求串起来，不应继续吸收具体卡牌算法或 panel 细节。
- 表现适配：`GameAnimationResolver` 把规则对象解析成 UI 锚点，`GameHudCoordinator` 编排 HUD 生命周期，各 UI controller 维护自己的节点，layout controller 只负责几何排列。

跨层调用优先使用明确类型和稳定门面。`has_method()` 仅用于真正可选的宿主能力或兼容边界；核心对局服务不应靠字符串探测来形成隐式接口。新增机制时先确定权威 owner，再决定 facade，避免在 `GameManager`、action、effect 和 UI 中各写一份判断。

## 核心数据模型

`CardData` 是不可变的卡牌定义，来自 `cards.json`。它包含 id、类型、角色、等级、数量、关键词、基础属性、基础移动力、混沌腐蚀、效果、施法动作、配置行动、骑乘攻击、装备类型和英雄附属信息。卡牌正面图来自 `url`；如果同目录存在同名 `-table.png`，例如 `牧师.png` 对应 `牧师-table.png`，则记录为 `table_texture_path`，用于棋盘正面展示和种族选择界面的英雄预览。`CardDatabase` 初始化只解析纹理路径；`front_texture`、`table_texture` 和 `back_texture` 是带缓存的惰性属性，首次被具体 UI 使用时才通过 `ResourceLoader` 加载，禁止在 `from_dictionary()` 中重新全量解码卡图。图鉴分页可以通过 `release_front_texture_cache()` 放弃自己的缓存引用，但不能修改卡牌路径或规则数据。

`CardState` 是棋盘上的卡牌实例，保存拥有者、位置、层级、翻开状态、当前攻击、当前生命、生命上限、护盾、护甲、状态、行动次数、原始快照和棋盘展示图。

跨回合效果必须区分激活、存续、刷新和失效四个阶段。通用时点模式、快照/实时策略、多入口复用与测试矩阵见 `docs/runtime-effect-lifecycle.md`；新增“持续一回合”能力时必须先明确来源玩家、持续归属和准确失效 trigger。

`HandCardState` 是手牌条目的运行时包装。英雄复活牌、带冷却的手牌、未来带状态的手牌都应使用它。读取手牌时不要直接 `as CardData`，应使用 `HandCardState.get_card_data(entry)`。

`PlayerState` 保存玩家身份、种族、手牌、装备、法力、资源分、坟场、种族资源、透视能力和当前回合计数。

`BoardCell` 保存棋盘格子的身份和能力。7x7 棋盘中，内圈 5x5 是常规战场格，外圈通常不补牌、不允许地面单位放置，但飞行单位可以进入空中层。格子的能力会随着“交换单元格”移动，不能用当前位置推断能否补牌或放置。兽径这类地形/单元格效果也存放在 `BoardCell`，并随单元格交换移动；`CardState.has_beast_path` 只是给卡牌节点绘制单元格效果的镜像，不属于卡牌内容，不能随 `clear_card()` 或 `set_card_data(null)` 清空。移动合法性使用当前兽径连通图判断，不能只看固定坐标或原始路径 id。

## 卡牌数据规则

`cards.json` 以种族为单位组织。一个种族可以有：

- `heroes`：英雄及其附属牌。
- `cards`：会进入牌池的常规卡牌。
- `tokens`：衍生牌，不进入牌池，但可以被效果获取到手牌或召唤。
- 种族运行时配置，如默认入手升级、种族资源、种族技能等。

当前卡牌类型包括：随从、法术、建筑、升级、装备。

卡牌等级决定补牌顺序：先用 1 阶牌池，耗尽后进入 2 阶，再进入 3 阶。

英雄附属牌只有在对应英雄被选择时才会进入牌池。英雄附属手牌默认要求该英雄在场才能使用，除非未来卡牌明确声明例外。

默认入手升级牌会在开局直接进入对应玩家手牌并生效，不进入棋盘牌池。

## 棋盘与层级

棋盘是 7x7。内圈 5x5 是正常战场；外圈是边缘区域，通常不补牌、不允许地面单位放置，但允许飞行单位使用空中层。

一个单元格可以同时有地面层和空中层。地面和空中占用相互独立。飞行单位不能阻挡玩家点击同格空闲的地面层。

补牌、手牌放置和移动合法性必须读取 `BoardCell` 的能力，而不是格子的当前坐标。

`BoardLayerResolver` 是棋盘层级和格子能力入口，负责地面/空中状态查询、土地格判断、地面补牌/放置/空中放置合法性，以及同步 `BoardCell` 与 `CardState` 的交互标记。`GameManager` 只保留兼容门面，不应重新写一套格子能力判断。

`BoardSlotResolver` 是牌池到棋盘格的入口，负责抽牌进格子、清空格子、空格补牌，以及按下一张可抽等级选择卡背。`GameManager` 只调用门面方法；死亡、手牌放置、AI 翻牌、替换未翻开卡牌等流程都应走这里，避免绕过 7x7 格子能力和等级牌池顺序。

## 交互状态

`InteractionManager` 管理空闲、棋盘卡牌焦点、棋盘目标选择、手牌焦点、手牌目标选择、多阶段选择等状态。右键和 Escape 应在焦点/目标选择状态下保持一致的退回逻辑。

`ActionMenuController` 只负责展示行动菜单，不负责判断行动是否可用。行动可用性应放在行动类或 resolver 中。

`GameHudCoordinator` 负责对局 HUD 的生命周期编排：统一创建和刷新回合状态、种族技能、种族时间、手牌抽屉、装备区、牌池视图和投降入口，并在内容变化后请求右侧布局。各 panel controller 仍只维护自身节点；`GameHudCoordinator` 不修改规则状态，`GameManager.update_*_view()` 只保留稳定的兼容门面。新增 HUD 面板时，应把创建/刷新顺序接入协调器，把几何排列接入 `RightSideHudLayoutController`，不要再把面板细节写回 `GameManager`。右侧面板按“回合概览 → 种族运行时状态 → 种族能力 → 装备”排序；控制器不得保留自己的绝对坐标或视口定位方法。HUD 中需要展示卡牌缩略图时，统一通过 `CardTexturePreviewController` 绑定悬浮大图；该控制器只管理预览节点、视口内定位和显示生命周期，不读取规则状态。目前种族运行时状态牌与装备牌均使用此入口。

## 行动系统

所有棋盘行动继承 `CardAction`。主行动组包括移动、攻击、施法。行动锁决定一个单位本回合能否同时进行多个主行动组。骑兵、移动攻击、施法移动、施法攻击等关键词会改变这些锁。

`ActionResourceResolver` 集中处理主行动资源和行动组兼容性。`CardState` 保留 `can_take_action_group()`、`register_action_group()` 等外部 API，但不再直接承载兼容规则细节。新增主动作组合、关键词授予行动兼容、状态授予行动兼容时，应优先修改这个 resolver。

配置动作可用 `once_per_lifetime: true` 声明“当前单位实例仅可使用一次”。`CardAction` 统一校验该限制，`CardState.consumed_action_ids` 保存已消耗动作；它不会在回合开始清空，并会随形态切换的行动经济快照传递，因此覆盖变身死亡恢复原形后也不能重复使用。新鲜创建的单位实例会重置该集合。不要用永久状态或卡牌 id 分支模拟一次性动作。

重要行动：

- `MoveAction`：默认相邻移动；拥有瞬移能力时可选择全场合法空格。地面单位选地面层，飞行单位选空中层。野兽人地面随从在连通兽径上移动时可穿越中间单位和建筑，且不消耗主行动力和移动力，但仍受定身/冻结等行动禁止状态限制。
- `DirectionalMoveAction`：无目标方向移动，用于通风猕猴“西行”等固定方向副动作。
- `AttackAction`：普通攻击，包含远程规则、正面宽度攻击、固定溅射、占领提示、护甲减伤、隐身目标过滤、攻击后破隐。
- `AttackAction` 同时处理普通攻击关键字。嘲讽 `taunt`：当防守方存在正面、可见的嘲讽随从时，攻击者普通攻击敌方单位只能选择嘲讽单位；攻击中立单位和攻击友方单位不受影响。吸血 `lifesteal`：普通攻击对中心目标造成的实际生命伤害会治疗攻击者等量生命，护甲、圣盾、护盾和过量伤害不计入；吸血治疗会走 `on_effective_heal` 触发链路。`frontal_width_N` 表示以攻击方向为中心，同时伤害面前奇数宽度 N 个格子的地面与飞行单位；`giant` 统一映射为 `frontal_width_3`。`ranged_attack_immune` 只禁止非贴身的远程普通攻击选中和伤害，贴身攻击仍按近战结算，法术与其他效果不受它影响。嘲讽只限制普通攻击的目标选择，不限制法术、副动作伤害或正面宽度攻击的额外受伤单位；吸血目前也只统计中心目标的普通攻击生命伤害。扇形与固定溅射命中的额外目标统一由 `GameAnimationResolver` 映射到卡面，并在死亡结算前通过 `CardAnimationController.play_secondary_attack_impacts()` 播放并行冲击反馈；`CombatImpactAnimationProvider` 只消费攻击者、主目标和实际受伤目标的视觉快照，提供正面宽度、固定溅射及专属变体，不重新计算跨层、阵营或免疫规则。规则层不得直接操作视觉节点。
- 固定溅射使用数值关键字 `splash_N`。普通攻击命中主目标后，对主目标所在格周围八个相邻格中的敌方和中立单位造成固定 N 点普通攻击伤害；每个相邻格同时检查地面层与飞行层，因此溅射可以跨层，但主目标同格的另一层不属于相邻格，不受该次固定溅射。友方单位不会被波及。溅射伤害经过护甲、圣盾和统一伤害加深入口，不触发吸血或占领；导致的死亡仍以原攻击者为来源，正常结算亡语、资源分、复生与补牌。
- 嘲讽表现分两层：常态由 `CardStatusOverlay` 绘制克制的盾墙标识，避免遮挡卡面；普通攻击进入目标选择时，`InteractionManager` 给敌方合法嘲讽目标设置 `is_taunt_target_hint`，由 `Card` 绘制动态橙金光晕承担强提示。嘲讽规则不要直接创建 UI 节点。
- `SpellAction`：棋盘单位的施法动作。目标由 `SpellTargetResolver` 解析；施法后默认破除隐身，除非配置 `breaks_stealth: false`。
- `EffectAction`：通用“选目标并执行效果”的配置行动。
- `MountedAttackAction`：骑乘单位的独立攻击，如角鹰骑士上的弓箭手。
- `FixedMeleeDamageAction`：固定伤害近战副动作，如月刃豹爪击。

## 效果系统

效果由 JSON 配置驱动，在 `EffectRegistry` 中注册。新增效果 id 和配置键应先放入 `EffectData`，避免字符串散落。

已实现的通用效果包括：治疗、伤害、直接摧毁单位、护盾、资源分、法力、翻牌、施加/净化状态、授予行动/施法/关键词/复生、获取或选择卡牌入手、复活、进化、顺序献祭、棋盘陷阱、单元格交换、单元格地形/兽径、子母蛊链接、种族状态、透视、月刃、多目标法术、入场同步属性、友方攻击协同等。

规则应优先使用通用效果。只有无法通过数据组合表达的机制，才考虑新增较专用的效果。

`on_enter_board` 是单位进入棋盘的统一触发点，适用于翻开进入棋盘和从手牌放置进入棋盘。不要同时写一套 `on_reveal` 和一套放置逻辑。

`after_friendly_attack` 会在友方单位完成普通攻击后广播给其他友方单位。效果可以用 `source_card_ids` 过滤原始攻击者。当前例子是猴妖仙“毫毛”在孙悟空攻击后尝试协同攻击同一目标。

## 目标选择

`SpellTargetResolver` 负责法术目标规则。已有规则包含所有随从、所有单位、非英雄随从、非建筑、指定区域、2x2 区域、相邻目标、指定卡牌 id、隐身过滤、魔法免疫过滤等。

魔法免疫是底层能力：魔法免疫单位不能被法术直接选中，法术效果结算时也会被 `CardEffect.filter_spell_immune_targets()` 跳过。方向射线仍可碰撞并停在魔免单位上，但伤害、状态等法术效果无效。

隐身使敌方行动无法直接选中该单位。友方行动仍可选择己方隐身单位；范围与方向射线等不直接点选单位的效果仍可命中隐身单位。

选择系统分为五层：

- `BoardQuery`：纯棋盘几何，例如相邻格、区域格、固定长度直线、方向射线。它不读取卡牌效果，也不修改棋盘。
- `SpellTargetResolver`：目标合法性过滤，例如是否可选英雄、建筑、隐身、魔免、友方或敌方。它不负责多段点击流程。
- `SelectionRequest` / `SelectionResult`：效果或行动与选择 UI 之间的数据契约。请求描述“要选择什么”，结果只返回被选中的格子、路径、方向、射线命中等数据。
- `DirectionRayTargetResolver`：把方向几何解析成实际碰撞目标，统一处理 `first_unit` / `first_matching` 停止方式、地面/飞行双层和命中目标规则。玩家 UI 与 AI 必须复用同一份结果。
- `BoardSelectionController`：棋盘多阶段选择入口，根据 request 分派具体选择策略。当前支持 `line_vector` 和 `direction_ray`。

矢量/直线选择使用 `SelectionRequest.KIND_LINE_VECTOR`：先选起点，再选终点；终点必须与起点形成横、竖或 45 度斜线，并满足固定长度。当前用于野兽人“兽径”的 5 格直线选择。

方向射线选择使用 `SelectionRequest.KIND_DIRECTION_RAY`：以一个来源格为中心选择 4 向或 8 向方向，结果返回方向、射线格子和命中单位。卡牌通过 `CardData.selection` 配置来源、方向数、最大距离、停止方式、命中目标规则和是否必须命中。`first_unit` 在首个正面单位处停止，不合法则无命中；`first_matching` 忽略不符合命中规则的单位，直到找到首个匹配目标。命中规则只判断射线碰撞语义，不应用隐身/魔免的直接点选限制；效果结算仍统一应用魔法免疫。当前吉安娜“冰锥术”使用 8 向 `first_matching`，命中首个敌方随从并造成伤害与冻结。未来英雄朝向技能、直线弹道、射线扫描、传送门喷发等都应复用它；效果层决定命中后造成什么，不要把伤害或状态逻辑写进选择器。

## 状态系统

`CardStatus` 记录临时或持续状态。状态可以有 id、标签、持续时间、持续范围、叠加规则、属性修正、触发效果、回合效果和死亡后是否保留。

状态派生数值统一由 `CardState.recalculate_status_modifiers()` 重算。当前除攻击和生命上限外，`payload.armor_bonus` 与 `payload.movement_bonus` 也属于通用状态修正；`CardState` 分别保存被动基础值和状态增量，移除状态时按差值恢复，不能在单张卡牌里手动减回。需要在持续期间固定最终攻击力时使用状态 payload `attack_override`；覆盖期间底层攻击、永久成长、被动和其他状态变化仍被记录，覆盖结束后统一恢复，多个覆盖按施加顺序由最新状态生效。状态 `payload.keywords` 可临时授予规则关键字，例如 `reflect`；普通攻击反伤由 `AttackAction.resolve_attack_reflection()` 统一处理，有限层数状态可消费，临时关键字则在状态有效期间持续生效。

没有回合持续时间的状态，不一定等于“死亡后也保留”。大多数增益、圣盾、魅惑、链接、法术授予状态都应在死亡后消失，除非明确配置 `persists_after_death`。

状态也可以通过 `payload.spell_modifiers` 临时改写场上单位的施法动作。这里复用 `modify_spell_ability` / `modify_hand_spell_effects` 的配置语言，由 `HandSpellModifierResolver` 在构建随从 `spell_actions` 时读取；适合“疯狂后强化某个已有法术”这类效果，不应为每张卡写专用动作分支。

重要状态标签：

- `damage_prevention`：类似圣盾，抵挡伤害。
- `action_prevention`：禁止行动，用于定身、冻结等控制。
- `stealth`：隐身，影响敌方选取。
- `breaks_on_attack_or_spell`：攻击或施法后移除。

重要状态族：

- `rooted`：受到真实护盾/生命伤害前无法行动，表现为金色遮罩和“定”字。
- `stealth`：敌方无法选中；孙悟空“聚散成气”会授予隐身、瞬移和暴击。
- `poison`：按总伤害唯一化，高总伤害毒覆盖低总伤害毒；回合结束时毒先于治疗结算。持续阶段只使用总剩余伤害数字图标，不用大片毒雾遮挡棋盘。具体毒种可在 payload 中配置 `tick_animation`；“毒性爆发”压缩持续时间时由通用状态修改器写入 `status_compressed`，结算层据此切换催熟爆发反馈，但总伤害计算不变。
- `fire`：火焰伤害状态，结构与毒相同，按总剩余伤害唯一化；回合结束时造成 `payload.fire_damage` 伤害，当前不受机械免疫影响。持续数值图标使用 `assets/img/火焰数字`，展示总剩余火焰伤害。
- `snake_venom`：与毒持续时间绑定的临时攻击降低，恢复时必须按实际修正量恢复。
- `life_link_larva`：子母蛊幼虫。施放时附着在两个随从身上，但不带 `death_link` 标签，也不触发死亡连带；施术者下个回合开始前置状态结算时，若双方幼虫仍存在且双方仍在场，则成熟为 `life_link`。若其中一方幼虫已被净化或目标离场，另一方幼虫在成熟时机自然失效。
- `life_link`：成熟同命蛊，带 `death_link` 标签和 `on_destroyed` 触发效果；其中一个链接随从死亡时，另一方通过死亡链路直接死亡。
- `charm`：改变控制权，可被净化。
- `death_immunity`：生命可固定到 0，状态结束后再检查死亡。
- `reborn`：死亡触发仍会正常发生，然后原地复生，跳过坟场、补牌和占领。卡牌文案可使用 `复生[层数,生命值]` 的易读缩写，例如巨水元素的 `复生[1,1]`；静态数据不要保存这组冗余二元值，而统一配置为顶层 `reborn_health_values: Array[int]`。数组顺序就是复生消耗顺序：`0` 表示该次满血复生，正整数表示该次以指定生命值复生；因此 `复生[1,1]` 的配置是 `[1]`，`[0, 0, 2, 3]` 则是依次满血、满血、2血、3血的四次复生。层数由数组长度唯一决定，不额外保存容易失配的 count。运行时由 `CardState.reborn_health_values` 保存剩余队列，并写入实例快照与 `origin`；`grant_reborn` 继续向同一队列追加。旧 `reborn` / `reborn_N` 关键字只做兼容，新卡不得与显式数组混用。
- `health_modifier`：可叠加生命上限修正，如真言术·盾。净化时会降低生命上限和当前生命，并可能触发死亡。
- `transform`：变身状态。变身形态不继承原状态；原形完整快照会被保存，持续结束时恢复原形和原状态。变身是形态规则，不可被净化/驱散。变身不刷新行动经济，进入变身和恢复原形时都会保留本回合已消耗的移动、攻击、主行动组、行动 id 和副动作使用量；当前可用行动按“当前形态上限 - 已消耗量”重新计算，只有正常回合开始流程会恢复行动力。同一单位任一时刻只允许存在一层变身，`TransformUnitEffect` 在目标已经变身时判定不可执行，禁止嵌套原形快照。

变身分为两类：

- 进化变身：持续结束恢复原形；持续期间死亡则按当前形态正常死亡。英雄进化变身死亡时，按原英雄进入复活冷却。当前例子：孙悟空“法天象地”变为法象一回合。
- 覆盖变身：持续结束恢复原形；持续期间死亡时先解除变身并恢复原形，不进入真正死亡。变身可用 `preserve_original_identity` 控制是否继续代表原卡牌，默认 `true` 以兼容已有英雄变身；设为 `false` 时，`represents_card_id()`、英雄在场检查和按原卡牌 id 授予的能力都只识别当前形态。东京喰种“蜈蚣形态”“龙形态”和“圣剑形态”均为永久覆盖变身，分别生成 3/6、攻速 3、移动力 3、移动攻击的蜈蚣形态，6/8、巨兽的龙形态，以及 8/14、远程、溅射 4 的圣剑形态；三者不再代表金木研，因此不能继续施放金木研所属法术，也不能在形态之间嵌套覆盖；被击败时恢复变身前的金木研快照。覆盖形态也可以通过通用 `restore_transform` 效果主动结束；该效果只接受有效覆盖变身，并统一调用 `CardState.restore_from_transform_status()`，与到期和死亡恢复共享原形快照及行动经济规则。

派生属性应由 `CardState.recalculate_status_modifiers()` 统一计算。状态失效时不要手动写死加回固定数值。

状态生命周期的表现元数据同样属于通用配置。`tick_animation` 描述周期结算，`expire_animation` 描述正常到期，`death_on_expire_animation` 描述到期后进入死亡分支；规则 resolver 只按生命周期读取 key，不识别“毒”“薄葬”等具体卡牌 id。子母蛊成熟后把死亡传导动画保存在 `on_destroyed` 触发效果中，使 AB、BC 链接沿同一死亡链逐段播放，同时保持“直接死亡而非伤害”的规则语义。

## 伤害、死亡与补牌

伤害应尽量走 `CardState.take_damage()`，除非机制明确是直接杀死。这样才能保持护盾、定身破除、毒免疫、死亡免疫和死亡检查一致。

护甲只减少普通攻击伤害，不属于通用 `take_damage()`，因为法术、毒、固定伤害和反弹伤害不应默认被护甲减少。

死亡由 `DeathResolver` 统一处理。它负责坟场快照、亡语、英雄复活、复生、子母蛊链接、资源分、补牌和占领副作用。复生会先正常记录死亡并结算亡语，再消费队首生命值原地初始化新鲜状态；剩余复生队列继续保留，不进坟场、不补牌、不占领。指定复生生命值不得超过该实例复生后的生命上限。

死亡单位原格可能同时被复生、亡语召唤、击杀来源召唤和公共牌池补位争用。`DeathResolver` 负责阶段编排，独立的 `DeathSlotClaimResolver` 负责占位请求的登记、排序、合法放置与回退。当前优先级为：复生保留原实例 > 亡语 `claim_death_slot`（默认 200）> 击杀效果携带的 `death_slot_replacement`（默认 100）> 常规补牌。高优先级请求若因层级、卡牌类型或格子能力不合法，会继续尝试下一请求，最后才补牌。效果不得在死亡入口返回后自行延迟写入格子。

`death_slot_replacement` 是伤害效果的通用配置，必须声明 `card_id`、`victim_layer`、`destination_layer`、`slot_owner` 和 `priority`。死亡格请求在全部 `on_destroyed` 触发结算完成后、清空死亡实例之后、常规补牌之前执行；成功放置的新单位仍会经过格子进入效果、`on_enter_board` 和死亡检查。未来“亡语：在原地召唤”应使用 `claim_death_slot`，不要直接 `set_card_data()`。

所有可能导致死亡的入口都必须 `await GameManager.resolve_dead_states()`、`check_and_destroy_if_dead()` 或 `destroy_card_with_refill()`。不要在效果或行动里直接 `clear_card()`，也不要调用死亡入口后立即假设补牌、亡语或资源分已经完成，除非已经 `await`。巨兽溅射、月刃、毒爆、混沌腐蚀、反弹伤害、陷阱、献祭、吞噬和链接死亡都走同一条链路。

击杀来源由 `source_state` 传入死亡链路，并在死亡请求创建时保存 `source_snapshot`。这是为了处理亡语或嵌套触发：如果来源单位在后续批次结算前已经被清空，`on_destroyed` 仍然能通过快照拿到 `destroyer` 玩家，从而让矿脉等 `gain_resource_score` 效果正确归属。无场上来源的手牌法术必须把运行时 `effect_owner_id` 作为显式 `source_owner_id` 传入；毒和火焰死亡可从对应状态的 `source_owner_id` 回溯。需要依赖“击杀者仍在场”的种族成长可以继续检查 live `source_state`，例如野兽人进化和卡扎克杀戮成长。

`TurnEventLedger` 只记录当前行动玩家回合内已经通过死亡链路确认的事件，供 RC 浓度等跨行动规则查询，不反向修改死亡流程。当前“合格杀戮”定义为：来源归属于当前行动玩家，目标是有玩家归属的非英雄随从；可包含敌方或友方，不包含英雄、中立单位和建筑。死亡后复生仍算一次实际死亡。账本返回标准化死亡记录并提供“敌方随从击杀”查询；种族规则通过 `FactionRuntimeStateResolver` 消费记录，不把阵营分支写入 `DeathResolver`。没有归属来源的低浓度强制分食不会反过来计为杀戮。

普通攻击击杀中心目标时，如果允许近战占领，走 `resolve_attack_kill()` 和占领选择；巨兽溅射造成的额外死亡只走 `resolve_dead_states()`，不会触发占领，但会正常触发亡语、资源分、复生和补牌。范围伤害的 source 必须传造成伤害的单位或法术来源，不能传被伤害目标。

英雄死亡不进坟场，而是进入手牌并带复活冷却。装备可以修改复活冷却。

通用 `resurrect` 效果支持按 `filter_type`、`filter_owner` 和 `card_ids` 过滤坟场候选。需要“复活指定卡牌”时应优先配置 `card_ids`，不要新增专用效果。

补牌必须使用格子能力，并遵守等级牌池顺序。

卡背显示也跟随等级牌池顺序。需要展示牌池顶部、补牌飞行动画或指定等级卡背时，统一通过 `GameManager.get_card_pool_next_back_texture()` / `get_card_back_texture_for_level()`，实际解析逻辑由 `BoardSlotResolver` 负责。

## 手牌、装备与被动

手牌抽屉分为法术、随从、升级、装备区域。手牌可以进入焦点状态并展示行动列表。

手牌行动包括：施放法术、放置随从、装备装备、升级牌被动。

装备按类型唯一。装备同类型新装备时，旧装备返回手牌。

装备被动使用 `trigger: "while_equipped"`。属性型装备被动由 `HandPassiveResolver` 刷新；施法能力改写型装备也使用 `modify_spell_ability` / `modify_hand_spell_effects`，由 `HandSpellModifierResolver` 从已装备区读取。`HandPassiveResolver` 的刷新流程分成两步：先从手牌与装备区收集一次 active passive effect snapshot，再把同一批配置应用到翻牌上限、种族技能、单位移动力、关键字、攻击、护甲、攻速、骑乘攻击和周期光环。场上应用范围统一走 owner 的 face-up minion 集合，覆盖地面层和飞行层，避免每个刷新器重复判断。不要把装备属性逻辑写进 UI 或 `PlayerState.equip_card()`，除非只是区域 bookkeeping。

随从库牌是 `upgrade` 的语义子类，使用 `upgrade_type: "minion_library"` 标识，不新增第五种手牌区域。`CardReserveResolver` 解释 `maintain_card_reserve`：配置用 `reserve_id`、`capacity`、`cooldown_turns`、`count_zones`、`draw_mode`、`restock_mode` 和 `pool` 描述一份玩家独立的有限库存；运行时只把剩余库存、上次有效容量和冷却保存在 `PlayerState.effect_runtime_values["card_reserve:<reserve_id>"]`。同一玩家可以同时持有多张随从库牌，每张牌必须使用稳定且不同的 `reserve_id`，库存和冷却互不覆盖。来源升级牌入手时立即按缺口补到容量，库存采用不放回抽取；在役数量只统计己方手牌和己方正面战场随从，战场单位使用 `CardState.represents_card_id()` 兼容临时变身，坟场、牌库和被敌方控制的单位不计。低于容量时开始冷却，冷却只在来源拥有者自己的回合开始推进；冷却期间继续损失单位不会重置计时，完成时一次补足当前缺口。重新达到容量会取消计时；来源离开手牌时暂停但保留库存与冷却，再次入手继续。容量增加通过通用 `modify_card_reserve_capacity` 即时提供新增容量对应的牌，既有冷却不重置；容量降低不移除现有随从。有限库存耗尽后不再启动空冷却。

随从库不是固定相位效果，不能塞入 `PeriodicCycleResolver`：固定周期关心“第几个自己的回合”，随从库关心“当前是否存在容量缺口”。`GameManager` 只在持续被动刷新和玩家回合开始调用随从库门面；死亡、控制、放置等系统不直接修改库存。`HandDrawerController` 只消费 `CardReserveResolver.get_hand_view_data()` 返回的只读视图，在来源升级牌上显示在役、库存和冷却，不参与规则计算。

随从库来源可在 `maintain_card_reserve.animation` 配置补充表现。`CardReserveResolver` 仍保持同步缺口状态机：仅当一次批次实际获得至少一张牌时，才经 `GameManager.play_board_effect_animation()` 延迟请求一次表现，不按获得张数重复播放，也不让库存计算等待 UI。当前 S 阶与 SSS 阶喰种情报分别使用独立档案调度演出。

## 种族运行时系统

种族资源和种族技能属于玩家状态，不属于 UI 状态。

种族运行时状态分为两类：固定循环由 `PlayerState.advance_faction_runtime_state()` 处理；依赖本回合事件的条件状态由 `FactionRuntimeStateResolver` 分派给专用策略。面板继续读取统一的 `runtime_state` 配置与状态卡图，`panel_hint` 可覆盖默认的“回合结束后推进”提示。运行时状态面板只接收并展示当前行动玩家；非当前玩家的状态仍保存在规则层，但不跨回合显示。UI 不计算状态迁移。

种族技能面板只负责展示资源和按钮，并发出 `skill_requested`。`FactionSkillResolver` 负责把已解锁的 skill config 转成具体 `CardAction`、判断可用目标、定位授权技能的手牌来源，并启动目标选择。`GameManager` 只连接 UI 信号和刷新面板，不直接维护每个种族技能的 action 构造细节。

已实现例子：

- 暗夜精灵：日出、正午、黄昏、月升、满月、月落的时间循环。泰兰德英雄法术“精准射击”使用一回合 `attack_override: 4` 状态，将本回合最终攻击力固定为 4；它不再储存或在下次普通攻击时追加独立伤害。
- 苗疆族：毒、毒虫、剧毒之泉、注入毒液、毒爆、毒相关升级。
- 狐妖仙：尾数、献祭种族技能、默认入手升级、魅惑和复生体系。
- 猴妖仙：施法/移动/攻击互斥关系扩展、透视、定身、隐身/暴击、护甲装备、瞬移、分身协攻、固定方向副动作和阵营型净化。孙悟空的火眼金睛、筋斗云、铜头铁臂、身外身法各有一张 1 阶默认入手说明升级牌；这些牌 `count: 0`、`start_in_hand: true`、`effects: []`，只负责展示神通文本，不提供额外规则效果。
- 野兽人：同系斩杀进化。种族块通过 `evolution_rules` 描述进化链；卡牌通过 `evolution_line` 声明所属血脉。当前链条包括劣角兽 -> 角兽 -> 大角兽、剃刀兽 -> 剃刀兽战车、人马兽 -> 飞斧人马兽、鹰身女妖 -> 疯语兽、牛头怪 -> 重武牛头怪。规则牌“适者生存”默认入手，仅用于玩家理解种族规则，真实触发由死亡结算后的种族 resolver 统一处理。卡扎克·独眼通过普通攻击击败友方非英雄随从后，会获得目标卡牌原始攻击/生命上限，并使自身运行时混沌腐蚀 +1；这不是新动作。该成长写入 `CardState.permanent_stat_overrides`，优先级高于 `origin`，不会污染原始快照，也不能被净化/驱散；英雄死亡进入复活手牌后再放置，会以这些永久覆盖值作为新鲜状态初始化。部分野兽人卡牌带有 `chaos_corruption` 静态数值，运行时当前值保存在 `CardState.chaos_corruption`，由 `CardStatusOverlay` 直接绘制腐蚀圆环和中央数值；它不是 `CardStatus`，不要用驱散/净化状态的路径修改。默认入手升级牌“混沌腐蚀”在己方回合结束时触发 `chaos_corruption_burst`：统计场上己方正面随从的混沌腐蚀总数，每 10 点对全部敌方正面随从造成 1 点伤害，建筑不计入也不受伤害。1 阶法术“兽径”使用 `set_beast_path` 打开五格直线矢量选择，并把兽径写入 `BoardCell`；野兽人地面随从可在当前连通兽径网络内移动到合法空位，穿越中间单位和建筑，不消耗主行动力和移动力。2 阶升级牌“野蛮咆哮”通过手牌区 `grant_spell_actions` 授予鹰身女妖和疯语兽无目标施法动作；释放后使用 `apply_status` 给 `friendly_minions` 目标集合附加本回合 `attack_bonus +1` 状态。2 阶随从“嘶叫萨满”自带野性呼唤施法动作，使用 `add_card_to_hand` 的 `card_ids` 候选池随机获得一个初级野兽。3 阶建筑“万魔岩”监听成功的野兽人友军杀戮进化和卡扎克杀戮成长，给同 owner 的万魔岩附加不可净化的 `wanmo_charge` 储存资源状态；废灭仪式读取该状态层数，消耗充能并获得等量古尔兽。
- 东京喰种：`runtime_state.transition_policy: "rc_concentration"` 使用 `RcConcentrationResolver` 消费 `TurnEventLedger` 的标准化死亡记录。初始为高浓度；当前行动玩家每击杀一个敌方非英雄随从便立即提升一级，同一回合的多次独立击杀可从低连续升至高；高浓度不再继续增长。回合结束时若整回合没有合格杀戮则降低一级；友方非英雄随从的杀戮可以阻止衰减，但不会提升浓度。低浓度无杀戮时无法继续降低，改为保持低浓度并随机分食一个友方非英雄东京喰种随从。英雄、中立单位和建筑不参与该规则。RC 面板复用通用种族运行时状态面板，并显示低/中/高状态卡图；卡图悬浮预览复用 `CardTexturePreviewController`。该种族的施法回合在 UI 中命名为“赫子解放”；`KagunePowerResolver` 在赫子解放时按当时的 RC 浓度生成不可净化的能力快照，持续经过敌方回合，并在该玩家下一个回合开始时移除。这样甲赫的护甲与反伤、鳞赫的吸血等防御性能力拥有完整响应窗口，回合结束时的 RC 变化也不会重写已释放能力。尾赫在普通与高浓度下均为攻速 +1；鳞赫在普通和高浓度均获得移动攻击，攻击 +1，高浓度改为 +2 并获得吸血；甲赫护甲 +1，高浓度改为 +2 并获得通用 `reflect`；羽赫获得每回合一次、不消耗主行动力的状态授予 `EffectAction`“羽针”，普通浓度造成 1 点伤害，高浓度造成 3 点。当前普通牌池随从覆盖四类赫子：黑山羊特工（甲赫、原生护甲 1）、安定区流浪者（4/4、鳞赫）、青铜树成员（3/4、羽赫、远程、飞行）、小丑临时工（5/12、尾赫）。2 阶英雄法术“蜈蚣形态”使用永久覆盖变身生成英雄衍生形态；该形态主动切断金木研卡牌身份，从而禁止继续使用金木研所属法术，死亡时恢复原形。2 阶升级牌“S阶喰种情报”是首张随从库牌，容量 1、冷却 2，从有限池不放回提供壁虎（8/8 鳞赫）、瓶兄弟（3/10 尾赫、攻速 2）、雾岛董香（6/6 羽赫、远程）和月山习（3/8 甲赫、护甲 2、嘲讽）；四者定义在本族 `tokens[]`，可被全局查卡但不进入公共牌池。2 阶建筑“13区咖啡店”为 0/12，主动作“特调”通过通用 `add_card_to_hand` 获取衍生法术“方糖咖啡”，后者对一个随从恢复 3 点生命；咖啡店的 `while_on_board` 被动使金木研复活冷却 -1。死亡结算会统一汇总装备修正和存活正面棋盘来源的 `modify_hero_revive_cooldown`，并按 `card_ids` 过滤英雄，不得在咖啡店或金木研分支中写死。卡牌静态字段 `armor` 表示单位原生护甲，进入 `CardState` 后作为非状态护甲基值；装备/手牌被动与状态护甲在其上叠加，净化仅移除状态部分，复生和新鲜状态初始化会恢复原生护甲。状态授予动作必须继续经过 `GrantedActionResolver` / `ActionRegistry`，从而让玩家、提示和 AI 共用合法性。规则说明升级牌“赫子之力”默认入手但无效果，只展示规则。RC 升降、低浓度分食和随从库补充都发布稳定 animation key；浓度改变发生在规则更新之后，演出完成后才继续死亡/回合流程，避免状态面板与画面反馈不同步。开启赫子解放的 `kagune_release` 仍在扣费成功、能力快照刷新后播放；演出期间锁定交互，AI 同样等待结束。
- 东京喰种英雄法术“尾赫齐发”只使用通用 `apply_kagune_power` 效果，从 `KagunePowerResolver.create_kagune_payload()` 动态取得尾赫能力，不再附加独立攻击力状态。尾赫能力状态采用替换策略并复用通用赫子生命周期，持续至下个己方回合开始，避免多次施放重复叠加攻速。赫子持续表现按 `kagune_power` 状态标签识别，不依赖固定状态 id。英雄所属法术仍由 `HandPlayResolver.is_required_hero_on_board()` 与 `CardState.represents_card_id()` 统一校验；三种 `preserve_original_identity: false` 的金木研覆盖形态均不能施放该牌。
- SSS 阶随从“芳村功善”为 6/12：主动作“免单”使用通用 `friendly_minions_by_faction` 目标集合恢复全部己方东京喰种，并通过 `set_faction_runtime_state` 把 RC 浓度置为高；副动作“赫者化”每个单位实例仅可使用一次，永久覆盖变身为 4/10、巨兽、攻城 4 的“不杀之枭”。“高槻泉”为 8/8、瞬移、移动攻击，也可一次性覆盖变身为 12/12 巨兽“独眼之枭”。金木研三种覆盖形态、不杀之枭和独眼之枭均提供零主行动力副动作“恢复原形”，通过 `restore_transform` 主动还原；恢复后该动作随形态消失，原单位的赫者化一生一次消耗仍然保留。两种枭形态被击败时也会按覆盖变身规则恢复各自原形。“旧多二福”为 8/8，使用 `frontal_width_5` 同时攻击面前五格，并具有 `magic_immune` 与 `ranged_attack_immune`。“死堪”为 6/14，同时拥有尾赫、鳞赫、甲赫与羽赫；`KagunePowerResolver` 会收集并合并多个赫子 payload，因此赫子解放期间四种能力同时生效，不需要死堪专用分支。`TokyoGhoulAnimationProvider` 负责免单、赫者化与恢复原形演出。

东京喰种表现层采用“规则快照 -> 语义键 -> 路由门面 -> 专用自绘画布/持续覆盖”边界。`KagunePowerResolver` 在 payload 中固化 `kagune_types`、`is_high_concentration` 以及吸血/反伤的表现 key，规则数值不依赖动画实现。`TokyoGhoulAnimationProvider` 只注册路由、换算坐标、统一时长与回收临时节点；`TokyoGhoulCombatVisual` 负责四赫子、复合赫子、蜈蚣、龙、圣剑、枭和旧多的普通攻击轮廓，并由 `GameAnimationResolver.resolve_attack_animation_key()` 根据当前卡牌数据选择主题。远程赫子攻击替代通用弹道，近战赫子攻击保留通用卡牌撞击并只在命中点叠加局部生物武器反馈，避免贴身攻击误读为远程法术。`CombatImpactAnimationProvider` 与 `CombatAreaAttackVisual` 是普通攻击次级伤害的公共表现层：消费攻击者、主目标和实际受伤目标的矩形快照，分别表现 `frontal_width_N`/巨兽正面冲击、`splash_N` 固定溅射和圣剑形态专属 RC 剑弧；它们不重新扫描棋盘，也不参与伤害、跨层、死亡或占领结算。`TokyoGhoulRitualVisual` 负责变身、赫者化、恢复原形、尾赫齐发、分食、免单、特调和方糖咖啡；`TokyoGhoulEventVisual` 负责 RC 升降与 S/SSS 随从库补充；`TokyoGhoulKaguneVisual` 与 `TokyoGhoulFeatherVisual` 分别负责全战场赫子解放和羽针。无目标法术若通过 `target: "owner_card_by_id"` 明确作用于唯一场上单位，并显式配置 `presentation_target: "effect_target"`，`HandPlayResolver.resolve_implicit_animation_target()` 才把该规则目标解析为表现落点，使手牌到单位播放一次完整施法；未声明的既有法术仍保留原来的手牌位置演出。该元数据不改变选中、合法性或效果目标。持续赫子覆盖必须消费真实状态快照，以羽片、层叠甲壳、动态分节触肢和摆动尾鞭区分四类赫子；高浓度只增强密度与节奏。覆盖形态另有低干扰动态轮廓，状态或形态移除后立即停止刷新。统一色彩是深血红、酒红、紫黑与冷白边缘，都市蓝紫反光和雨线只作辅助，禁止退回通用红色光圈、文字印章、魔法阵或无类型差异的直线触手。修改后必须运行 `tools/test_tokyo_ghoul_animation_provider.gd`、`tools/test_tokyo_ghoul.gd`、`tools/test_rc_concentration.gd`、`tools/test_card_reserve.gd` 和路由测试。
- 影月议会：已接入英雄古尔丹、默认入手升级牌“邪能狂乱”、基础随从“混乱兽人”、2 阶随从“地狱犬”和“术士”、3 阶随从“混乱狼骑兵”“末日守卫”和“地狱火”、3 阶建筑“黑暗之门”、2 阶升级牌“基尔加丹的低语”、古尔丹英雄法术“灵魂虹吸”“恶魔召唤”和 2 阶武器“古尔丹之杖”。邪能体系使用法术/施法动作的 `spell_tags` 标记，例如 `spell_tags: ["fel"]`；手牌区升级牌通过 `trigger: "after_spell_cast"`、`active_zone: "hand"` 和 `required_spell_tags` 监听成功施法。古尔丹的“邪能灌注”目标规则为 `friendly_non_hero_minions`，对古尔丹自身造成固定 2 点自伤，并给选中的友方非英雄随从附加本回合 `fel_infusion` 攻击状态，同时触发邪能。“灵魂虹吸”使用通用 `life_drain` 效果：对敌方单位造成最多 3 点实际生命损失，并把实际吸取量作为古尔丹的临时当前生命；该生命可超过上限，但不提高 `max_health`，普通治疗也无法恢复到这个临时超上限值。“古尔丹之杖”是装备区 `while_equipped` 施法改写器，使用 `modify_spell_ability` 把 `fel_infusion` 改成 `fel_overload`：自伤 4、目标攻击 +6，并在施法者回合结束时通过状态 `turn_effects` 对相邻随从造成 2 点伤害，然后用通用 `destroy_units` 直接摧毁自身。混乱兽人的疯狂增益由“邪能狂乱”给 `friendly_minions_by_card_ids` 附加临时攻击状态实现；地狱犬和混乱狼骑兵的疯狂状态使用 `CardStatus.payload.actions` 临时授予副动作，分别是“法力燃烧”和“撕咬”，由 `GrantedActionResolver` 统一读取；魅魔和末日守卫的疯狂状态使用 `CardStatus.payload.keywords` 临时授予关键字，分别是 `lifesteal` 和 `giant`；术士疯狂状态使用 `CardStatus.payload.spell_modifiers` 临时改写已有“诅咒”，让它先施加 `damage_amplify` 和攻击降低，再追加 1 点伤害。地狱火“献祭”是无目标施法动作，使用通用 `apply_status` 对 `adjacent_enemy_non_hero_minions` 施加 `fire`，回合结束由 `StatusResolver` 结算。术士“诅咒”使用通用负面状态 `damage_amplify`：`payload.damage_amplify` 会在 `CardState.take_damage()` 中并入同一次伤害事件，因此可被圣盾一次性格挡，并会影响普通攻击、法术、毒、火焰、溅射等所有统一伤害入口。“基尔加丹的低语”使用通用 `periodic_status_aura` 同步周期光环；“黑暗之门”使用通用 `periodic_trigger` 执行周期子效果。二者的相位都由 `PeriodicCycleResolver` 维护，并保存在 `PlayerState.effect_runtime_values`。黑暗之门翻出时 `advance_phase: false` 且 `reset_phase: true`，立即触发一次并建立新的周期；之后只在建筑拥有者自己的 `before_turn_start` 推进相位，每两个自己的回合随机获得一张地狱火、末日守卫、混乱狼骑兵或魅魔。狼骑兵“撕咬”使用通用 `EffectAction`、目标规则 `adjacent_minions` 和 `damage + heal` 效果组合，不新增专用动作类。“恶魔召唤”使用通用 `add_card_to_hand` 生成同族 `tokens[]` 衍生牌“魅魔”；魅魔常驻 `taunt` 关键字，普通攻击目标过滤由 `AttackAction` 统一处理。后续恶魔召唤、黑暗之门和更多疯狂分支应继续沿用 spell tag + hand/equipment modifier + 状态配置，而不是在 `SpellAction` 或 `GameManager` 中按卡牌 id 分支。

状态净化支持正负面筛选。`CardStatus` 保存 `status_valence`，可取 `positive`、`negative`、`neutral`；未显式配置时按状态 id、标签和属性修正数值推断。`CleanseEffect` 通过 `cleanse_mode` 控制净化范围：`all` 保持旧逻辑，`positive` 只移除正面状态，`negative` 只移除负面状态。全场阵营型净化使用效果目标 `friendly_units` / `enemy_units`，只影响随从时使用 `friendly_minions`，不要在单张卡牌里手写遍历逻辑。当前例子是猴妖仙“驱神大圣禺狨王”：驱散敌方单位正面状态，并解除己方单位负面状态。

移动攻击、施法移动、施法攻击这类主动作兼容关系由当前实际关键词动态决定。即使关键词来自装备、状态或变身，`CardState.can_take_action_group()` 也必须能直接识别，避免只依赖某次被动刷新写入的缓存。

## AI

AI 分为候选行为生成、棋盘评估、手牌评估和行为执行。AI 应尽量调用玩家同一套行动和目标 API。合法性放在行动/resolver，评分放在 evaluator。

## UI 与动画

UI 控制器只负责表现，不应直接修改规则数据，除非通过明确回调进入 game/action/effect 层。

统一界面皮肤分为三层。`GameUiSkin` 是纯资源层，只预载 `assets/img/ui_skin/` 中的位图，创建带固定纹理边距和安全内容区的 `StyleBoxTexture`，并提供框体、输入框以及按钮普通/悬浮/按下/禁用状态；它不识别具体页面、玩法状态或按钮文案。`PANEL_TEXTURE_MARGINS` 只保护九宫格不被拉坏，`PANEL_SAFE_INSETS` 才定义内容不得侵入的木框、金属角和内斜面范围，两者不能互相替代；调用方传入的 padding 只能追加，不能清空基础安全区。`ApplicationUiStyle` 是应用页面语义层，负责主菜单、种族选择、图鉴、结算页和全局操作面板的样式选择。`RightSideHudStyle` 是战斗 HUD 语义层，负责紧凑尺寸、强调色、指标块和资源刻度，外层框体仍复用统一位图。各页面 controller 只能请求这些稳定变体，不得各自复制大型 `StyleBoxFlat` 木框、金属框或按钮状态。

框体按实际承载密度和主要拉伸方向分为六档，并在全局使用同一语义，而不是只服务手牌区：

| 类型 | 用途 | 视觉约束 |
|---|---|---|
| `MAIN` | 主菜单、图鉴等顶级页面 | 保留完整复杂装饰与最大安全区 |
| `DRAWER` | 手牌抽屉、多选面板、结算横幅等大型浮层 | 保留层次，但压窄边框以换取内容宽度 |
| `SIDEBAR` | 图鉴种族导航、卡牌详情等高而窄的侧栏 | 使用纵向专用压边纹理，避免横框被拉高失真 |
| `INSET` | 筛选区、统计区、确认框等中型容器 | 中等安全区和低干扰边缘 |
| `SECTION` | 手牌分区、动作菜单、棋盘选择提示等小型容器 | 超薄边框，优先保证按钮和文本空间 |
| `HUD` | 回合、装备、种族状态等右侧紧凑面板 | 独立窄框和统一列宽 |

重复卡片、装备条目、状态徽记、资源刻度和 VFX 图元不是结构性容器，应保留轻量平面样式。禁止为这些高密度重复元素套 `MAIN` / `DRAWER` 装饰框，也禁止在同等级装饰框中继续嵌套同等级框体。

皮肤母版通过 `tools/build_ui_skin_assets.py` 构建为运行时资源。生成母版可以保留宽阔装饰边缘，但运行时应通过九宫格预处理压缩装饰边带，并从同一视觉母版派生 `DRAWER`、`SIDEBAR`、`INSET`、`SECTION` 和 `HUD` 纹理；不能把横向框用于高窄侧栏，也不能把大型概念框整体缩放后塞进紧凑控件，否则边框会失真或侵占中心内容。横向按钮的四态必须来自同一轮廓，避免悬浮时布局跳动；按下态只通过图像反馈和内容轻微下移表达；手牌抽屉侧边按钮使用独立纵向 tab 资源，不能旋转横向按钮或强行拉伸文字。`PanelContainer` 由 StyleBox 自动落实安全区；普通 `Panel` 不会据此布局子节点，因此手牌抽屉等普通 Panel 必须在 controller 中显式维护与框体匹配的内容矩形。透明标题、徽记等独立装饰图使用保持比例的 `TextureRect`，不得作为九宫格背景拉伸。图鉴固定采用“侧栏 / 横向筛选 / 大型卡墙 / 侧栏详情”的 `SIDEBAR`、`INSET`、`DRAWER`、`SIDEBAR` 组合，筛选选项使用可换行容器。新增或重建 PNG 后，先运行 `tools/run_godot_validation.ps1 -ImportAssets`，再运行 `tools/test_ui_skin.gd` 验证纹理尺寸、状态差异、安全内容区、场景接入和九宫格契约。

`RightSideHudLayoutController` 只负责排列已经创建好的右侧 HUD 面板，例如回合状态、种族技能、种族时间和装备展示。它统一右侧列宽、屏幕边距和面板间距，并按实际内容高度顺序排布；高度不足时只压缩间距，禁止把后续面板向上回夹到前一个面板上。它不决定面板是否可见，也不读取或修改玩法状态；`GameManager` 只把需要参与布局的 panel 列表交给它。

`RightSideHudStyle` 提供右侧面板共享的背景、边框、标题、按钮、指标块和资源刻度样式；`HudSymbolIcon` 提供不依赖种族素材的轻量矢量图标。面板标题和“法力、翻牌、资源分、装备类型、种族状态、种族技能”等稳定语义优先使用图标与 tooltip，精确玩法数值仍保留短格式。最大值不超过 12 的种族资源优先用离散刻度表示，较大资源使用进度条。各 controller 可以选择自己的强调色，但不得复制一套新的面板外壳、宽度或定位常量。

一次性特效统一从 `CardAnimationController` 进入；通用移动、攻击和少量跨种族表现留在控制器，种族主题节点、Tween 与样式由独立 animation provider 持有。需要从棋盘状态、手牌锚点或牌池面板找到实际 UI 节点并发起动画时，走 `GameAnimationResolver`；`GameManager.play_*` 只保留兼容门面。局限在单张卡牌内的持续状态标识放在 `CardStatusOverlay`；会覆盖多个单元格并跟随来源移动的持续效果由 `BoardPersistentVisualController` 管理。数值图标放在 `Card` 的状态/数值堆叠区域。战场翻开的随从和建筑左上角显示种族 logo，资源从卡牌 `url` 所在目录的 `logo.png` 自动推导；没有 logo 时隐藏，不影响手牌和悬浮预览。

`BoardPersistentVisualController` 挂在全屏表现根节点下，扫描棋盘状态 payload 中的 `persistent_visuals` 描述，并通过 `visual_key` 注册表创建独立 renderer。`PersistentBoardAreaVisual` 负责来源状态生命周期、真实棋盘区域矩形计算、源单位移动跟随和逐帧刷新；具体主题 renderer 只负责绘制。区域大小复用 `area_rows` / `area_cols`，规则层不创建视觉节点。状态被移除、来源死亡或离场后，控制器自动回收表现。当前首个实现是 `ExtremeColdStormAreaVisual`，以后新增毒雾、火焰领域、空间扭曲或建筑光环时，应新增 renderer 并注册 key，而不是让卡牌节点越界绘制或在 `GameManager` 中写特效分支。

`CardAnimationController` 是稳定动画门面，通用法术和种族主题特效通过 `SpellAnimationRouter` 注册 provider。路由按“卡牌到卡牌、直接矩形、来源矩形到卡牌、全战场、多格路径、范围区域、多目标矩形组”七种表现上下文分别保存 animation key，不创建节点也不读取规则状态；provider 只接收表现上下文并拥有该主题的节点、Tween 和 StyleBox 实现。同一上下文中的同一 key 只能有一个权威处理器：重复注册不同 Callable 时保留首个注册并告警，禁止依靠 provider 加载顺序静默覆盖。`multi_rect` 用于同一时点同步作用于多张可见卡牌的军阵治疗、群体祝福等表现：`GameAnimationResolver` 负责把状态集合解析为矩形集合，provider 负责同步节奏；若 key 未注册该上下文，效果层必须回退到原有逐目标反馈。普通种族成功开启施法回合后使用 `spell_turn_activation`，由 `GenericSpellAnimationProvider` 播放蓝金法阵、法力脉冲和粒子演出；东京喰种改走专属 `kagune_release`，不会重复播放通用效果。白银之手、猴妖仙、野兽人、苗疆族、狐妖仙、影月议会、东京喰种和达拉然主题均已迁移到独立 provider；兽径使用 path 路由，狐火使用 area 路由。达拉然“冰锥术”在 `DalaranAnimationProvider` 内按凝聚、定向飞行、命中碎裂、冻结反馈四阶段播放；魔免目标仍显示碰撞碎裂，但不显示冻结结晶。原有 key、默认回退和 `GameAnimationResolver` 门面保持兼容，新主题不得再追加回中央 `match`，已由 provider 接管的 key 也不得在中央控制器保留第二套不可达实现。

猴妖仙表现由 `MonkeyAnimationProvider` 与程序化 `MonkeySpellVisual` 分层实现。Provider 只负责 animation key 路由、全战场/单卡/来源到目标坐标布局、时长和临时节点回收；Visual 只绘制赤金毛笔气流、玉白卷云、火眼扫描、猴毛剪影、铜甲、蟠桃、驱神笔风、定字封印、龙宫神器和法象巨影，不读取规则状态。火眼金睛和全场驱神允许扩展到表现根矩形；筋斗云与西行通过移动 animation key 在通用卡牌位移动画上叠加路径，不复制移动规则；毫毛入场由同步属性效果的配置 key 请求表现，协攻由攻击动画解析器选择专属 key；铜头铁臂反弹使用防守者到攻击者的来源/目标矩形表达反向伤害；龙宫珍宝仍走通用装备流程，只在装备落定前请求英雄目标演出。

猴妖仙持续状态继续由 `CardStatusOverlay` 读取真实 `CardStatus`：铜头铁臂用分段铜金护体环与铆钉数量表示可见层数，蟠桃用桃核与环纹表示叠加，定身用低遮挡“定”字和四角封印表示行动锁定，聚散成气用金边、玉白云丝表示隐身而不隐藏棋盘占位；火眼金睛额外附加不可净化、无规则数值的回合视觉标记，并与玩家透视资源在同一己方回合结束时过期；筋斗云显示卷云靴。法天象地只在变身瞬间播放法象巨影，持续期间由替换后的卡面、属性与巨兽标识表达形态，不再叠加遮挡卡面的持续状态特效。定身解除由 Overlay 观察真实状态从有到无后播放短暂碎裂，不由施法动画提前伪造。一次性演出不得承担状态生命周期，状态叠层也不得重新执行规则结算。新增猴妖仙表现后至少运行 `tools/test_monkey_animation_provider.gd`、`tools/test_animation_routing.gd` 与卡牌数据校验。

白银之手一次性法术由 `SilverHandAnimationProvider` 与程序化 `HolySpellVisual` 负责。统一视觉语言是有重量和军事秩序的白金圣光：温暖白色核心、象牙金中层、珍珠银防御面、金属金边缘、垂直降光、盾形结构、战锤印记、誓约圣印和受控光尘；禁止绿色治疗、普通红焰、廉价金色爆闪、羽翼装饰和无结构光圈。动画统一按“祈祷蓄势 → 圣光降临 → 庇护/治愈/裁决结算 → 祝福余辉”组织。

专属 key 为 `divine_shield`、`baptism`、`holy_heal`、`power_word_shield`、`inner_fire`、`faith_light`、`healing_to_resolve`、`resurrection`。圣盾是珍珠银盾面与厚重金边；洗礼明确区分向内治疗和向外裁决；治疗术使用温暖白金生命流；真言术·盾用誓约印记和分层生命护甲表达可叠加生命上限；心灵之火把生命光带压缩为白金神圣火焰；信仰圣光通过 `multi_rect` 让军阵目标同步响应；战斗牧师的有效治疗先正常结算，再用 `healing_to_resolve` 把残余圣光导向武器；复活术以纳鲁、最多六个有序剪影和飞向手牌的圣光印记表达重新归队。专属 key 只服务白银之手，通用 `heal` / `shield` 仍保留给其他种族，避免主题串色。

圣盾施放瞬间属于 provider，低亮度持续盾面属于 `CardStatusOverlay`。`CardState.take_damage()` 完整格挡后发出通用 `damage_prevented` 事件，卡牌表现层据此播放命中裂纹、冲击环和整齐碎片；规则层不创建视觉节点。真言术·盾的持续表现也由 `CardStatusOverlay` 读取实际状态层数，状态被净化或死亡清除后自动消失。所有动态覆盖仅在对应状态或短暂破碎反馈存在时启用 30 FPS 刷新。一次性动画必须在 Tween 结束后释放全部临时节点，新增或调整时运行 `tools/test_silver_hand_animation_provider.gd`。

苗疆族一次性蛊术由 `MiaoAnimationProvider` 编排，程序化 `MiaoSpellVisual` 提供共享的有机形状语言。统一节奏是“引蛊聚集 → 注蛊侵入 → 低亮度潜伏 → 成熟/结算 → 药烟或毒液余韵”；基础材质使用暗翡翠、毒液黄绿、深青、氧化铜和黑紫，生死链接加入朱砂与暗红，草药治疗使用琥珀、草木青和乳白药烟。蛊纹采用不闭合手绘环、蛇形分节、虫卵和菌丝分叉，不得退化成普通绿色光圈或持续全卡毒雾。蝎毒、蛇毒、王毒分别通过黄绿尾刺、深青蛇纹和黑紫毒核区分；毒性爆发表达为既有毒量被压缩催熟，而不是新增伤害。

苗疆表现按归属分层：励蛊、蛇毒减攻、子母蛊幼虫/成虫、薄葬和吞噬成长等单位局部持续反馈由 `CardStatusOverlay` 根据实时状态绘制，状态消失即停止刷新；毒本体继续只显示总剩余伤害数字。诱蛊的潜伏标记属于 `BoardSlotEffect.persistent_animation`，由 `CardBoard.set_slot_effect_visual()` 创建单元格绑定节点，绝不能挂在当前格子的卡牌节点上；陷阱被消费时先移除潜伏标记，再播放触发捕获。隐藏陷阱目前只向非 AI 的本地施术方显示。毒的同步回合结算、毒爆随机分配、薄葬释放/断裂和同命死亡传导使用 `multi_rect` 或链接专用上下文先完成视觉编排，再进入伤害/死亡流程；表现层不改变目标集合、随机结果或死亡顺序。调整后运行 `tools/test_animation_routing.gd`、`tools/test_miao_animation_provider.gd` 和相关棋盘持久表现测试。

达拉然法术表现由 `DalaranAnimationProvider` 统一编排，以程序化 `DalaranSpellVisual` 复用“规则几何、学派配色、透明能量层、起手聚能、释放冲击、余韵消散”的学院派语言。奥术使用蓝紫符文环、同心法阵、网格折叠和定向法力流；冰霜使用冰蓝晶体、六边形屏障、霜纹与清晰范围边界；火焰使用符文蓄力、白热核心、燃烧尾迹和集中冲击；水元素使用奥术召唤阵约束半透明流体、水纹、雾气和法力核心。`DalaranFireAnimationPlayer` 专门负责火球术/炎爆术的蓄力、投射物飞行和命中恢复，炎爆术通过更长蓄力、更大白热核心和更强冲击与火球术分级；`DalaranSpaceSwapPlayer` 负责奥术空间的双锚点法阵、稳定连接和格子内容交换，规则层只传 `arcane_space_swap`，不创建表现节点。召唤水元素、巨水元素、学院召唤、冰霜护盾、奥术智慧、暴风雪分别使用专属 key，不再复用通用 `summon` / `shield` / `arcane`。

达拉然持续表现按范围分层：辉煌光环是单位局部、可叠加状态，由 `CardStatusOverlay` 绘制反向旋转符文轨道、法力流和层数轨道，仅在状态存在时刷新；其回合产蓝效果通过 `gain_mana.source_animation` 配置 `arcane_aura_pulse`，公共 `GainManaEffect` 只负责按配置请求来源动画，不识别卡牌 id。产蓝脉冲的能量应在光环内部沿曲线回卷、汇入施法者并形成短促上升光点，不绘制缺乏真实 HUD 锚点的屏幕边缘硬直线。极寒风暴覆盖 3x3，继续由 `BoardPersistentVisualController` 和 `ExtremeColdStormAreaVisual` 管理边界、冰纹、旋转风场和来源跟随；回合结算的坠冰冲击仍是一段一次性 provider 动画。调整达拉然表现后至少运行 `tools/test_animation_routing.gd`、`tools/test_dalaran_animation_provider.gd`、`tools/test_dalaran_council.gd` 和 `tools/test_board_persistent_visuals.gd`。

暗夜精灵哨兵的一次性表现采用四层结构。`NightElfAnimationProvider` 是稳定路由门面，只校验表现上下文并把语义 key 分派给协作模块；`NightElfKineticVfx` 负责月刃与爪击，`NightElfSupportVfx` 负责静谧泉水、精准射击与艾露恩之优雅，`NightElfCelestialVfx` 负责满月之蔽、流星光环与流星坠落，`NightElfTimeVfx` 只负责六阶段全战场时间演出；`NightElfVfxRuntime` 统一时长缩放、根节点淡出回收、坐标换算与二次贝塞尔采样；`NightElfVfxFactory` 只创建 SDF 图元、轨迹和受控粒子。语义模块是 provider 私有实现，使用显式 preload 和依赖注入，不注册全局 `class_name`，规则层与中央动画控制器都不得直接调用。

月体、新月和月束分别使用 `night_elf_moon_disc.gdshader`、`night_elf_crescent.gdshader`、`night_elf_moonbeam.gdshader` 的 SDF/半透明材质；轨迹、弓弦、水带和风压使用 `Line2D`，星屑、水滴与叶影使用有数量上限的 `CPUParticles2D`。语义模块只组合图层与 Tween，图元工厂不决定技能节奏，运行时不识别 animation key。统一色彩为月光银白、冰蓝、夜空靛蓝和低饱和森林青，不复用达拉然的复杂奥术法阵，也不复用白银之手的暖金圣光。

技能语义保持独立：`moonblade` 是带双层银蓝尾迹的实体新月刃，按二次贝塞尔弧线飞行，在首次命中后短促转刃再反向弹射；命中使用新月切痕和银屑，不使用爆炸。`claw_strike` 使用三道带暗色切口、银蓝边缘和收窄末端的物理爪痕，并辅以低矮风压与少量叶片，不表现成远程月光波。`tranquil_spring` 先在月亮井聚水，再由双层弧形水带输送至目标，目标阶段分别播放冷白月束、水纹治疗和污浊碎片净化。`precision_shot` 使用绷紧弓弦、单一冷白瞄准线、箭头月光核心和小型艾露恩月痕，不使用通用增益圆环。

`full_moon_cover` 使用 `at_rect` 路由让中间月相沿高空弧线连续掠过，最终闭合为完整月轮并降下克制的冷白月束。`meteor_strike` 同时支持单目标矩形和 `multi_rect`：落点月纹出现时流星已经从高空沿明确曲线下坠，冷白星核、银蓝外焰与淡紫长尾连续运动，命中通过月纹冲击和碎光完成，不在预警与下坠之间停顿或重启；群体流星共享一个根节点并轻量错峰，避免逐目标串行和全屏白闪。`meteor_aura` 的施加动画和持续状态分离，持续层只保留低亮残月、单条星轨和少量星体。

时间变化使用状态专属 board key：`night_elf_time_transition_sunrise`、`_noon`、`_dusk`、`_moonrise`、`_full_moon`、`_moonset`，通用 `night_elf_time_transition` 仅作兼容回退。自动回合推进和法术直接跳转都在状态更新后发送当前状态对应的 key，因此日出、正午、黄昏、月升、满月和月落拥有不同的大型月相符号、环境滤镜与叶片/星尘运动。切换动画必须保留清晰的进入、停留和淡出阶段；六种滤镜分别使用晨曦暖玫、正午自然青、黄昏紫琥珀、月升靛蓝、满月冷蓝和月落灰紫，但透明度仍须保证棋盘与数值可读。规则层只决定状态，Provider 只解释表现。`precision_shot` 与 `meteor_aura` 的持续反馈仍由 `CardStatusOverlay` 读取真实状态并低频刷新；状态移除后必须停止处理。

新增暗夜精灵技能时，先判断它属于目标局部、来源到目标、全战场、多目标或持续区域，再由 Provider 声明语义 key，并把编排放进职责最接近的语义模块。只有形成新的独立变化轴时才新增模块，不按单张卡牌拆文件。新月、月体、月束、星点、轨道、箭体、爪痕和粒子优先复用 `NightElfVfxFactory`；弧线投射和流体传输复用 `NightElfVfxRuntime` 的二次贝塞尔采样；一次性根节点统一通过 Runtime 回收；持续跨格领域迁移到 `BoardPersistentVisualController`。调整后运行 `tools/test_night_elf_vfx_modules.gd`、`tools/test_animation_routing.gd`、`tools/test_night_elf_animation_provider.gd` 和 `tools/test_board_persistent_visuals.gd`。

手牌抽屉仍按法术、随从、升级、装备四个语义分区，并保留各自独立的纵向滚动，但不再固定四等分。所有分区禁止横向滚动；卡牌流宽度必须从受视口约束的目标抽屉宽度扣除各层安全区和内容间距后计算，不得复用抽屉旧固定宽度或尚未完成重排的节点宽度。生产节点树位于独立场景 `scenes/ui/hand_drawer_panel.tscn`，主场景和 UI 集成测试共用同一组件。`HandSectionLayoutPolicy` 是不依赖节点的纯布局策略：空分区收缩为仅标题的窄条；非空分区先取得一致的可操作最低高度，再按实际卡牌行数的平方根分配剩余空间，使拥挤区明确获得更多高度，同时避免卡牌数量极端悬殊时独占抽屉；某分区达到完整内容高度后停止增长，空间继续分给仍需滚动的分区。`HandDrawerController` 只统计卡牌数、计算每行容量并应用高度；焦点变化不参与高度计算，因此点击卡牌不会引发布局跳动。完整重建前捕获四区纵向滚动偏移；旧滚动节点会先脱离父节点再延迟释放，避免与新节点同名；随后在新高度应用并完成容器重排后统一恢复偏移。窗口尺寸变化只重新运行布局策略，不重新构造卡牌节点。

抽屉外框的宽高必须先约束到当前可见视口。四区的纵向分配预算由目标抽屉高度依次扣除 `DRAWER` 皮肤安全区、内部 `MarginContainer` 留白、标题高度及 `VBoxContainer` 间距得到；卡牌流宽度同理由目标抽屉宽度扣除外框、内部留白、`SECTION` 安全区和发光留白得到。禁止在刚修改抽屉尺寸后直接读取 `Sections.size` 作为下一轮预算，因为 Godot 容器重排前该值仍可能属于上一帧，把它回写到分区或卡牌流最小尺寸会形成反馈并把内容推到屏幕外。抽屉、主体和分区容器启用内容裁剪作为重排期间的显示保护，但裁剪不能替代正确的预算计算。

视口尺寸变化属于一次完整的响应式重排：先捕获各分区纵向滚动偏移并停止尚未完成的抽屉 Tween，再依据 `is_open` 和新目标宽度重新计算打开或收起位置，更新所有现有 `CardFlow` 宽度，最后重新分配分区高度并恢复滚动位置。收起位置不能读取旧 `ToggleButton.offset_left`，否则缩窄窗口后开关会随旧抽屉宽度移出屏幕。窄视口回归测试必须同时填满四个分区，并验证抽屉边界、收起开关、卡牌换列、滚动偏移及末尾装备区都保持可访问。

当前结构优化优先级：新增 HUD 接入 `GameHudCoordinator`；新增种族主题特效先实现稳定 provider 并声明所需路由上下文，单个 provider 同时承担路由、多个独立技能族、路径数学和生命周期时，再按“路由门面 → 语义编排 → 图元/运行时”拆分；`CardState` 后续按“快照/变身、状态容器、行动资源、战斗数值”拆出协作 resolver，但在每个调用方迁移完成前保留现有公开 API。禁止仅为了缩短文件而拆出仍然共同修改同一状态的薄包装类。

野兽人的表现使用专属 animation key：`beastmen_evolution` 表示同系斩杀后的野性进化，`beastmen_slaughter` 表示卡扎克·独眼普通攻击击败友方非英雄随从后的杀戮成长，`savage_roar` 表示野蛮咆哮的红橙冲击波，`wild_call` 表示萨满召集兽群的荒野召唤，`wanmo_ritual` 表示万魔岩废灭仪式的深红裂隙，`beast_path` 表示兽径地道贯通。`chaos_corruption_burst` 属于全战场触发型特效，应通过 `GameManager.play_board_effect_animation()` / `GameAnimationResolver.play_board_effect_animation()` 进入 board 路由；多格路径特效通过 `play_path_effect_animation()` 进入 path 路由，不要挂到某一张目标卡上。规则层只触发 key，血色爪印、吞噬核心、腐蚀波、兽径土石和仪式碎片等视觉统一由 `BeastmenAnimationProvider` 生成。

影月议会的表现使用 `fel_infusion`、`fel_overload`、`fel_burst`、`fel_madness`、`mana_burn`、`fel_bite`、`life_drain`、`curse`、`kiljaeden_whisper`、`dark_portal` 和 `immolation` 等 animation key。`fel_infusion` 用于古尔丹释放基础邪能灌注以及其持续状态覆盖；`life_drain` 用于灵魂虹吸，从目标身上抽取绿色邪能束流；`fel_overload` 用于古尔丹之杖升级后的邪能过载释放和持续裂纹状态；`fel_burst` 用于过载目标回合结束爆裂；`fel_madness` 用于邪能触发后混乱兽人、地狱犬、混乱狼骑兵、末日守卫等随从进入疯狂状态，视觉应以暗紫、黑绿和血红爪痕为主体，绿色只作为邪能边缘和少量火花，避免整张卡被纯绿覆盖；`mana_burn` 用于地狱犬从目标抽取邪能并造成伤害；`fel_bite` 用于狼骑兵座狼撕咬时的邪能汲取表现；`curse` 用于术士诅咒和 `damage_amplify` 持续覆盖；`kiljaeden_whisper` 用于基尔加丹的低语周期光环；`dark_portal` 用于黑暗之门翻出和周期召唤触发；`immolation` 用于地狱火献祭和火焰状态施加。持续状态视觉放在 `CardStatusOverlay` 或 `Card` 的数值图标堆叠区，释放瞬间表现放在 `CardAnimationController`，不要让规则层直接创建视觉节点。

音频表现由 `AudioManager` 统一管理，配置在 `data/audio.json`。`GameManager` 只暴露 `play_sfx()`、`play_spell_sfx()` 和 `start_battle_music()` 门面；规则层不直接持有 `AudioStreamPlayer`，视觉动画层也不直接加载音频资源。进入棋盘后默认播放 `battle_default` 背景音乐；没有外部音频文件时可使用程序化 BGM 兜底。攻击音效使用 `attack_melee` / `attack_ranged`，法术优先读取卡牌或 spell action 的 `audio` key，否则可按 `spell_<animation>` 约定扩展。

### 特效资源与未来 VFX 管线

当前代码型特效由 `CardAnimationController` 门面、`SpellAnimationRouter` 和主题 provider 协作，适合快速实现和中小型表现。未来若要制作更复杂的粒子、shader、序列帧、投射物、持续状态和手牌释放特效，应逐步引入独立 VFX 管线：

- `VfxManager`：表现层入口，负责播放一次性、投射物、区域、持续状态和 UI 锚点特效。
- `VfxRegistry` / `data/vfx.json`：把规则侧的 `animation` 或未来 `vfx` key 映射到具体 PackedScene、贴图、音效、持续时间和挂载层。
- `scenes/vfx/`：存放可复用 VFX 场景，例如火球、治疗、净化、毒、变身、法天象地、月相、魅惑等。
- `assets/vfx/source/`：外部购买或下载的原始素材。
- `assets/vfx/textures/`：项目内实际使用的清理后贴图、sprite sheet、flipbook。
- `assets/audio/sfx/`：法术、攻击、UI 和环境音效。

功能边界：

- 规则层只发出“发生了什么”，例如伤害、治疗、状态施加、变身、攻击命中。
- `GameAnimationResolver` 把规则事件转换为表现事件，并查找棋盘、手牌、牌池或 UI 锚点。
- `VfxManager` 负责实例化特效和生命周期，不读取或修改规则数据。
- `AudioManager` 负责音频播放，VFX 场景不直接 new 音频播放器，最多声明音效 key。
- `CardStatusOverlay` 仍负责卡面局部状态图标、数字和可读性强的战场状态；`BoardPersistentVisualController` 只承接确实覆盖多个格子的持续动态区域。不要用持续粒子替代所有状态信息。

素材来源建议：

- Godot Asset Library：Godot 原生 shader、粒子、插件和示例。
- itch.io / GameDev Market：2D 法术、投射物、impact、sprite sheet 和音效包。
- Kenney：授权友好的 UI、图标、占位素材和基础音效。
- OpenGameArt / Freesound：免费素材来源，但必须逐项确认许可证。
- Unity Asset Store / Fab / ArtStation / Gumroad：适合买通用 PNG 序列、flipbook、贴图、模型和音效；慎用强依赖 Unity ParticleSystem、URP、Niagara 或 Unreal 蓝图的成品特效。

引入外部素材时必须记录来源和授权。优先选择 CC0、明确可商用或项目购买授权；避免把授权不清的素材直接提交进仓库。

## 文档与编码

所有文档必须是 UTF-8。若出现不可读乱码，应先修复编码或重写文档，不要继续在坏文件上追加。

`docs/codex-working-map.md` 是任务入口索引；本文档负责概念边界、系统设计和长期规则。

## 未来设计笔记

本节不是当前实现要求，而是记录长期设计方向，避免未来每张卡各自为政。

### 节奏与种族卡牌数量

单个种族不宜过大。建议每个种族约 13-17 种主牌设计、30-35 张主牌复制数，不包含衍生牌和英雄生成牌。

推荐结构：

- 英雄：1 张。
- 1 阶：两个基础随从，加两到三个低阶法术/升级。此阶段应快速展示种族核心身份。
- 2 阶：两到三个核心随从，加关键升级/法术。此阶段应形成主要策略分支。
- 3 阶：一到两个终结随从，加少量高影响法术、装备、建筑或升级。每张 3 阶牌都应推动对局走向结尾。

每个种族通常保留两条主路线和一条副路线。路线过多会让回合很忙，但决策不聚焦。

### 中立牌与地图机制

中立牌不应像第二个通用种族。它们主要负责创造棋盘目标、少量资源波动和地图质感，不应替代种族终结手段。

当前中立牌池可以视为未来地图系统的原型：

- 地图定义自己的中立牌包。
- 地图可以把部分默认中立牌替换为主题版本。
- 地图可以定义环境规则、棋盘修正和可选事件时机。

示例结构：

```json
{
  "id": "deadwind_pass",
  "display_name": "逆风小径",
  "neutral_cards": [
    { "card_id": "arcane_mine", "count": 4 },
    { "card_id": "small_mine", "count": 4 },
    { "card_id": "unstable_rift", "count": 2 }
  ],
  "rules": [
    { "id": "swap_random_cells", "trigger": "round_end", "amount": 1 }
  ]
}
```

设计原则：种族决定玩家是谁，地图决定玩家在哪里战斗。

地图方向示例：

- 逆风小径：奥术矿脉、不稳定裂隙、单元格错位、法力奖励。
- 祖安：毒气、微光强化、炼金池、污染建筑、短期爆发和副作用。
- 圣光修道院：治疗点、净化泉、防御建筑、对毒和诅咒的压制。
- 影月谷：邪能裂隙、献祭祭坛、恶魔召唤、反治疗压力。
- 艾露恩林地：月井、月相、隐匿、远程压制和站位奖励。
- 机械城：零件、维修、装备、机械复活和能量核心。
- 天灾冰原：尸堆、冰冻区域、治疗削弱和亡灵复生。

### 中立牌平衡原则

中立牌应该制造互动，而不是直接赢下游戏。

建议方向：

- 公共伤害牌通常不应能打英雄，除非它是稀有、高阶、明确设计为终结牌。
- 类似暗箭的牌更适合做“非英雄随从去除”，让英雄死亡更多来自种族特色。
- 永久翻牌加成等长期资源中立牌需要叠加上限或较低数量。
- 矿脉建筑是健康的中立牌，因为它们制造空间争夺和资源分竞争。
- 偏向某个种族的中立牌更适合放入地图，或由种族规则替换进入公共牌池。

### 未来种族主题库

以下是设计储备，不代表已经进入实现范围。

- 卡拉赞：麦迪文、传送门、混乱元素、奥术傀儡、可攻击和升级的卡拉赞之塔。高阶裂隙可召唤 Boss 级威胁。
- 霍格沃兹：没有施法回合，法术直接消耗法力。哈利可以用法力学习不可饶恕咒、防御咒、攻击咒、基础咒等。伙伴和神奇动物是重要支援。
- 黄金学院：黄金是种族资源，来自斩杀、法术和建筑。黄金可购买随从和装备。金属法术、炼金术和黄金溶流提供破坏力。
- 影月氏族：古尔丹用邪能强化兽人和恶魔，黑暗之门提供持续兵源。
- 东京喰种：RC 浓度、四类赫子解放、金木研三种覆盖变身、S 阶与 SSS 阶有限随从库已接入；芳村功善、高槻泉、旧多二福、死堪及两种赫者形态已经完成。
- 共生体：毒液剥离组织，组织在子代池中进化，附着到人类随从后入场。纳尔是后期全局强化点。
- 破坏者联盟：微光提供本回合攻击爆发。金克斯/爆爆人格切换形成不同模式，武器、偷窃、罪犯和通缉令构成玩法。
- 光荣进化：机械随从通过升级后可消耗法力复活、交换意识，并解锁维克托的多条时间线。
- 蜘蛛侠：发明、蛛丝、蜘蛛感应反应法术、反派集结和平行宇宙援军。核心机制应是“反应”。
- 野兽人：基础种族已接入，当前拥有英雄卡扎克·独眼。后续核心方向是杀死同类后进化、混沌腐蚀积累到阈值后爆发，以及卡扎克牺牲友方野兽成长。
- 天灾军团：友方死亡留下尸体，尸体可缝合巨人或强化憎恶。骷髅兵和阿尔萨斯强调复生，霜之哀伤压制治疗。
- 九重天：杨戬、敕令、天兵、黄巾力士、雷部元帅、丹药、蟠桃、哮天犬和四大天王。应体现天庭秩序，与猴妖仙的个人神通形成对照。

### 现有种族方向

- 白银之手：信仰、祝福、阵线、治疗、保护、牺牲和反推。不要变成同时拥有硬控和高爆发的泛用种族。
- 达拉然议会：灵活法术工具箱。当前可选英雄包括安东尼达斯与吉安娜；吉安娜的 1 阶法术“冰锥术”是首个方向射线手牌法术，2 阶法术“巨水元素”通过通用 `add_card_to_hand` 获取 8/8 衍生随从，其原生复生队列为 `[1]`。3 阶“极寒风暴”在吉安娜身上附加永久光环：每个己方回合结束时，对本格及相邻八格、地面与空中层的敌方随从造成固定 4 点法术伤害，首次结算额外冻结一回合；被其击败的地面随从通过 `death_slot_replacement` 在原格召来巨水元素。其持续 3x3 蓝色冰风暴由 `persistent_visuals` 声明并交给 `BoardPersistentVisualController` 跟随吉安娜，回合结算时的坠落冰暴仍由 `DalaranAnimationProvider` 播放。英雄专属牌继续通过 `heroes[].attached_cards` 隔离，共享法术能量升级则通过效果 `card_ids` 显式覆盖适用英雄与法师单位。需要持续关注法术强度、重复施法和高影响法术解锁的膨胀。
- 苗疆族：毒和蛊生态。毒爆、陷阱和吞噬可以强，但要留下净化、站位和目标限制等反制。
- 暗夜精灵哨兵：时间、月相、远程、站位、坐骑和夜晚奖励。
- 狐妖仙：尾数、魅惑、献祭、控制和复生操纵。魅惑阈值和永久控制要保守。
- 猴妖仙：孙悟空神通和猴群协同。英雄灵活性很强，应通过分身、隐身、护甲、瞬移等组件的铺垫来平衡。
