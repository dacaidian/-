# War Card 架构说明

快速定位开发文件时，先阅读 `docs/codex-working-map.md`；本文件保留完整架构和规则约定。

## 分层

### 数据层

位置：`scripts/data`

- `CardData`：静态卡牌数据，来自 `data/cards.json`；卡牌所属的数据包通过 `faction_id` 记录，玩家种族包和中立牌库包都走同一读取结构。
- `BoardCell`：当前占据某个棋盘坐标的单元格属性，记录坐标、是否为普通地面格、地面层 `ground_state` 和飞行层 `aerial_states`。当前棋盘为 7x7，初始外圈是战场边缘，不补牌、不允许普通地面随从放置；初始中间 5x5 是现有地面牌池区域。奥术空间这类“交换单元格”效果会让 `is_land` 等单元格性质随单元格移动，而不是固定在屏幕坐标上。
- `CardState`：运行时卡牌状态，例如归属、正反面、攻击、生命上限、已受伤害、主行动次数、移动力、攻速/剩余攻击次数、当前状态、交互提示标记；同时保存 `origin`，表示这张具体卡牌进入游戏时的初始属性快照。它可以作为 `BoardCell.ground_state` 的地面层状态，也可以作为 `BoardCell.aerial_states` 中的飞行层状态；判断飞行能力统一走 `CardState.is_flying()` / `CardData.KEYWORD_FLYING`。`has_status_with_tag(tag)` 提供 tag 驱动的通用状态门控，不绑定特定 status_id；`is_area_preview` / `set_area_preview()` 用于 AOE 范围预览标记。
- `CardStatus`：附着在棋盘单位上的运行时状态，例如中毒、圣盾、冻结、临时增益等。它记录状态 id、名称、tag、层数、来源、持续时间和到期时点，不直接执行具体规则。
- `PlayerState`：玩家运行时状态，例如所属种族、资源分、翻牌次数、法力、手牌/牌库预留区、独立坟场。
- `CardDatabase`：读取并缓存 JSON 静态数据。支持测试模式：通过 `data/test_config.json` 配置白名单卡牌、数量覆盖和游戏参数（`game_params` 节），提供 `get_test_game_param()` 通用参数查询；游戏参数由 `GameManager._apply_test_game_params()` 在初始化时读取并覆盖 `@export` 默认值。
- `CardPool`：公共牌池，负责按 `count` 展开、洗牌、无放回抽取。`count <= 0` 的卡不会被展开进牌池，便于未来保留“可被查表但不自然出现”的卡。种族可以通过 `pool_modifiers.exclude_neutral_card_ids` 修改公共牌池，当前苗疆族用它移除中立 `生命之泉`。
- `tools/validate_cards.py`：卡牌数据校验器。它从 `EffectData`、`EffectRegistry`、`SpellTargetResolver`、`CardData`、`CardStatus` 等运行时代码中读取合法配置词汇，再校验 `data/cards.json` 的资源路径、卡牌引用、目标规则、效果 id、状态字段和英雄配套牌引用。新增或修改卡牌后应优先运行它。
- 衍生牌（Token）：不进入牌池、仅由卡牌效果生成的卡牌。在 `cards.json` 中定义在对应种族的 `tokens[]` 字段下，结构和普通卡牌一致。`CardDatabase.load_faction()` 会把 token 注册到 `cards_by_id`（全局可查），但不加入 `cards_by_faction_id`，因此牌池构造链路天然跳过。
- 入口选择会从 `CardDatabase.get_playable_faction_ids()` 读取可选种族，排除 `kind: "neutral_pool"` 的中立牌库；该列表保持 `cards.json` 中的加载顺序，避免默认种族选择被字典排序打乱。英雄列表优先读取种族层级 `heroes` 字段。

原则：数据层只保存和转换数据，不处理玩家点击和 UI。

## 规则层

位置：`scripts/game`、`scripts/actions`、`scripts/effects`

- `GameManager`：战局编排者，管理回合、玩家、棋盘、行动执行入口等核心流程；复杂规则和表现编排通过协作者拆分，避免继续膨胀。
- `BoardLayerResolver`：棋盘地面层/飞行层查询与落位判断协作者。`GameManager` 保留 `get_all_board_states()`、`get_board_states_at_slot()`、`can_place_*()` 等兼容入口，但内部委托给它，避免 7x7 外圈、地面层和飞行层语义继续散落在主编排类里。
- `MatchSetup`：战局配置数据对象，保存玩家名称、双方选择的种族和英雄，并负责“双方种族不可重复”和开始游戏合法性校验。入口 UI 修改它，战斗场景只读取最终结果。
- `BoardSlotResolver`：棋盘格填充与补位规则协作者，负责从公共牌池抽牌放入空格、清空格子、批量补空格；未来分级牌池或翻开进手牌后的补位策略优先在这里扩展。
- `BoardSlotEffect` / `BoardSlotEffectResolver`：固定棋盘格上的临时效果，不随卡牌内容移动。当前用于“诱蛊”这类陷阱：法术把效果写到空格或背面格，之后随从通过移动、手牌放置或翻开进入该格时触发。未来地形、陷阱、格子光环优先扩展这里，不要把格子状态塞进 `CardState`。
- `RevealResolver`：翻牌成功后的归属与区域路由协作者，负责判断当前玩家能否获得这张牌，并决定卡牌留在棋盘、进入手牌还是扣回背面。
- `DeathResolver`：死亡、入坟、销毁和攻击击杀后占领结算协作者。`GameManager` 保留 `check_and_destroy_if_dead()` 等对外入口，具体死亡流程放在这里。拥有 `death_prevention` 状态 tag 的单位不会进入死亡事件；状态到期后由 `StatusResolver` 再检查是否应死亡。
- `TriggerResolver`：触发队列协作者。当前负责排队并结算 `on_reveal`、`on_destroyed`、`on_effective_heal`；后续亡语、受伤、召唤、施法等触发都应优先接入这里。
- `StatusResolver`：状态规则和生命周期协作者。当前负责在普通回合时点前结算毒伤害，并在普通时点触发后推进临时状态的剩余回合；状态本身保存在 `CardState.statuses`。
- `EventContext`：触发名和运行时上下文 key 的常量集合，例如 `TRIGGER_ON_DESTROYED`、`DESTROYER_PLAYER_ID`。规则层和效果层跨模块传上下文时优先使用这里的常量，避免字符串散落。
- `EffectData`：卡牌效果 JSON 的字段名和基础读取工具，例如 `id`、`trigger`、`active_zone`、`card_ids`、`spell_actions`、`target`、`target_card_id`、`death_reason`、`filter_type`、`filter_owner`、`target_zone`、`amount_source`、`card_id`、`trigger_player`。它只定义配置语言，不执行效果；解析升级牌、时点触发、目标过滤、复活坟场筛选、状态内回合效果、上下文数值来源和运行时目标注入时优先使用这里，避免字符串散落。
- `BoardQuery`：棋盘几何和常用目标过滤工具，例如八方向相邻、正面单位、正面随从集合、指定玩家英雄是否正面在场。`get_area_slots()` 以指定格子为中心、按 `area_rows × area_cols` 展开矩形区域，自动处理棋盘边缘裁剪。攻击范围、法术目标、英雄配套牌使用限制、时点光环、AOE 范围展开等规则需要扫描棋盘时优先复用这里，避免每个规则自己计算格子坐标。
- `HandInteractionController`：手牌 UI 与手牌规则之间的交互编排层，负责手牌焦点、可用提示、动作菜单锚点和手牌点击后的动作流转。
- `HandCardState`：手牌运行时状态。旧手牌仍可直接保存 `CardData`，但需要冷却、来源、标签等运行时字段的手牌应保存为 `HandCardState`。当前英雄死亡复活会生成带 `cooldown_turns` 的英雄手牌。
- `HandPlayResolver`：手牌使用规则协作者。当前负责手牌法术的可用性、目标规则、效果结算和消耗手牌，也负责手牌随从放置到棋盘的通用流程；后续装备、升级牌主动使用也优先在这里扩展。
- `HandPassiveResolver`：手牌持续被动规则协作者，统一解析 `while_in_hand` 这类手牌中持续生效的数值修正。当前用于升级牌“金手指”的每回合翻牌上限加成、骑术的移动力覆盖、达拉然法术能量的攻击力光环，以及暗夜精灵按种族时间生效的攻速光环。
- `HandSpellModifierResolver`：手牌法术运行时修正规则协作者。它读取手牌中 `modify_hand_spell_effects` 这类升级牌效果，根据目标关系、被影响的 `card_ids` 等条件，在手牌法术结算前替换或追加运行时效果与动画；静态法术牌本身不被改写。
- `StatusModifierResolver`：状态施加前的运行时修正规则协作者。它读取施加者手牌中的 `modify_applied_status` 升级效果，在 `CardStatus.from_effect_data()` 前改写状态数据；当前用于“毒性爆发”把己方施加的毒压缩到 1 回合爆发。
- `SpellTargetResolver`：法术目标规则解释器。随从施法和手牌法术都通过它解释 `target_rule`，避免未来扩展目标限制时出现两套规则。
- `TargetStateResolver`：目标点击解析协作者。它把玩家视觉上点击到的 `CardState` 映射为当前行动真正需要的规则目标；例如飞行单位覆盖同一格时，地面移动/手牌放置可以解析到同格地面层，飞行目标或法术目标仍解析到飞行层。`GameManager` 只负责接收点击和执行动作，不直接处理同格多层目标选择。
- `BoardPairSelectionController`：效果内部的多段棋盘格选择协作者。它用于“选择第一个格子，再选择第二个格子”的重复流程，例如 `swap_board_slots`。这类流程发生在法术已经成功施放之后，不属于 `SpellTargetResolver` 的单次目标规则；因此它临时监听棋盘卡牌点击并在完成后清理目标提示和连接。
- `BoardUnitPairSelectionController`：效果内部的双单位选择协作者。它用于“已成功施放后，再从当前合法单位中选择两个单位”的流程，例如苗疆族“子母蛊”。它接收一组 `CardState` 候选，不重新解释法术目标规则；AI 玩家不打开该 UI，由对应效果自行选择单位，避免 AI 回合等待人工点击。
- `BoardUnitBounceSelectionController`：效果内部的二段单位选择协作者。它用于“第一目标已经通过普通法术目标流程选定，再从第一目标相邻单位中选择第二目标”的流程，例如女猎手“月刃”。它只负责第二段 UI、提示和临时目标高亮；第一目标是否合法仍由 `SpellAction` + `CardEffect.can_execute()` 过滤。
- `VictoryResolver`：胜负检查协作者。当前检查玩家资源分是否达到胜利目标，后续其他胜利条件也应在这里扩展。
- `ActionHintResolver`：计算空闲状态下哪些己方卡牌应显示绿色可行动提示；后续冻结、沉默、建筑操作等可行动性提示规则优先在这里扩展。
- `InteractionManager`：只管理当前交互状态，例如当前焦点牌、当前选择的行动、合法目标格子。
- `CardAction`：行动基类。
- `MoveAction`：移动行动，检查移动力，计算移动目标，消耗移动力并执行格子交换。
- `AttackAction`：普通攻击行动，登记一次攻击类别并消耗一次攻击次数；通过 attack profile 统一给出目标是否合法、是否近战、是否允许占领，再造成攻击力伤害。
- `SpellAction`：配置化施法行动，从 `CardData.spell_actions`、手牌升级牌授予的固定 `spell_actions` 和动态授予法术创建；负责法术目标规则、登记 `spell` 行动类别、播放施法动画，并把选中目标交给效果系统。需要按特定卡牌 id 限制目标时，`SpellAction` 会读取 `spell_data.card_ids` 并交给 `SpellTargetResolver`，不要在具体效果里再扫棋盘重做目标白名单。`SpellAction` 会把候选目标注入运行时效果并调用 `CardEffect.can_execute()`，因此月刃这类“第一目标还必须存在第二段弹射目标”的法术可以过滤掉无效第一目标。施法成功后会把本次 `spell_data` 记录到所属玩家的施法历史，供“学习上一个法术”等动态升级读取。
- `ActionRegistry`：行动注册表，决定一张牌当前拥有哪些行动；它只把静态或授予的 spell data 转成 `SpellAction`，不直接解释升级牌 JSON。动态非施法行动由 `GrantedActionResolver` 拼接，当前用于剧毒之泉体系的 `注入毒液` 和 `毒爆`。
- `GrantedActionResolver`：动态非施法行动解析器。它读取当前战场状态和当前玩家手牌升级牌，把符合条件的非施法行动拼接到行动列表；配置型授予使用 `grant_actions` + `active_zone: "hand"` + `card_ids` + `actions`。当前暗夜精灵哨兵“精英月刃豹”通过这套机制让女猎手获得副动作“爪击”。
- `PoisonAttackResolver`：统一判断一个单位当前是否拥有“普攻附带毒性”的能力，来源可以是静态 `after_attack`、手牌升级授予触发或状态 payload 触发。剧毒之泉、AI 评估等不要用卡牌 id 直接猜测毒虫能力。
- `RandomAllocationResolver`：通用整数随机分配工具。当前用于剧毒之泉“毒爆”把储存毒量逐点随机分配给相邻敌方随从；未来随机治疗、随机伤害也应优先复用。
- `GrantedSpellResolver`：授予法术解析器，负责从当前玩家手牌升级牌中读取 `grant_spell_actions` 和 `grant_last_spell_action`，并根据 `card_ids` 判断哪些随从获得这些法术。`grant_last_spell_action` 通过 `source_card_ids` 限定可学习的施法来源，当前用于“好好学习”。
- `GrantedUnitTriggerResolver`：授予单位触发效果解析器，负责从当前玩家手牌升级牌中读取 `grant_unit_trigger_effects`，并根据 `card_ids` 和 `granted_trigger` 判断哪些战场单位在某个触发时点获得额外效果。当前用于苗疆族“蛇毒”给蛊毒蛇追加攻击后附毒和减攻。
- `AddCardToHandEffect`：通用效果，通过 `card_id` 从 CardDatabase 查卡并置入效果归属玩家手牌；可选 `amount` 表示加入多张，省略时默认为 1。用于衍生牌、奖励牌等不进入牌池的卡牌获取。
- `ChooseCardToHandEffect`：通用选择获取效果，通过 `card_ids` 生成候选列表，使用 `CardMultiSelectController` 让玩家选择，再把选中卡与 `bonus_cards` 中的固定奖励一起置入手牌。当前用于安东尼达斯的“学院召唤”。
- `EffectRegistry`：效果注册表，负责触发 JSON 中配置的卡牌效果，并统一转发效果的施放前可用性判断。已注册效果包括 `heal`、`damage`、`shield`、`increase_max_health`、`set_attack_to_current_health`、`gain_flips`、`gain_resource_score`、`gain_mana`、`gain_attack`、`play_spell_action`、`apply_status`、`resurrect`、`add_card_to_hand`、`choose_card_to_hand`、`set_slot_trap`、`swap_board_slots`、`devour`、`link_units`、`destroy_linked_units`、`set_faction_runtime_state`、`moonblade`。玩家级效果统一通过 `CardEffect.get_target_player_id()` / `get_target_player()` 解析目标玩家，避免资源、法力、未来金币等效果各自维护一套 target 规则。触发上下文合并统一使用 `EffectData.duplicate_with_context()`，运行时法术目标注入统一使用 `EffectData.mark_selected_target()`；手牌法术会额外注入效果拥有者，供“目标周围敌方单位”这类规则判断敌我。单位自身状态也可以在 `payload.trigger_effects` 中提供触发效果，由 `EffectRegistry.execute_status_triggers()` 在同一触发入口结算；触发来源状态会以 `_trigger_status` 注入运行时效果，供“链接死亡”这类状态自身效果读取 link id。
- 死亡解析：外部仍调用 `GameManager.check_and_destroy_if_dead()` / `destroy_card()`，内部委托 `DeathResolver` 统一处理死亡或销毁；死亡不作为玩家动作显示在动作菜单中。

原则：新增攻击、施法、技能时，优先新增一个 `CardAction` 子类，再注册到 `ActionRegistry`。行动自己决定 `can_start()`、`get_valid_targets()` 和 `execute()`，不要把行动规则写进 UI。需要目标的行动只有在存在合法目标时才会显示在动作菜单中。行动基类提供通用判断，例如 `is_controlled_face_up_minion()`，避免每个行动重复写当前玩家归属和随从检查。

## 表现层

位置：`scenes`、`scripts/ui`

- `Card`：只负责卡牌显示、翻牌动画、背光提示、点击信号和棋盘数值图标。血量显示在右下角，攻击显示在左下角；护盾、毒性等“有数值的状态”统一放在血量图标上方的纵向状态数字栈中。攻击数字从卡牌正面图所属种族目录下的 `攻击数字/{attack}.png` 加载；毒性数字按剩余总毒伤害读取 `毒性数字/{poison_damage * remaining_turns}.png`。数值图标节点的创建和资源设置集中在 `create_value_texture()` / `set_value_texture()`，避免每新增一个图标都复制一套 TextureRect 初始化。`mouse_entered_card` / `mouse_exited_card` 信号携带 Card 引用，供 GameManager 连接 hover 驱动的 area 预览等行为；`draw_area_preview()` 绘制 AOE 范围蓝色预览。
- `CardStatusOverlay`：负责棋盘卡牌上的持续状态覆盖表现。当前读取 `CardState.statuses` 绘制圣盾金色圣光盾、辉煌光环奥术法阵、励蛊绿色蛊虫强化背光、同命蛊链接绿纹、薄葬死亡庇护和冻结冰蓝色边框+冰晶雪花；毒性这类数值状态不再在这里绘制整卡遮罩，避免和数值图标重复表达。
- `StartMenu`：游戏入口选择页。它只负责双方玩家选择种族和英雄，保证两名玩家不能选择相同种族；点击开始后实例化战斗场景并把 `player_faction_ids`、`selected_hero_card_ids` 传给 `GameManager`。
- `CardBoard`：只负责 7x7 棋盘布局、动态补齐 CardSlot/Card/AerialCard 节点、按当前 `BoardCell.is_land` 绘制地面格/边缘格样式，并响应窗口尺寸变化。地面层卡牌保持原尺寸；飞行层与地面层共格时由 `GameManager.sync_slot_card_layout()` 缩小并置于右上角显示。
- `DebugPanel`：只负责展示运行时状态；面板可一键收起为右上角小按钮，避免遮挡棋盘和右侧展示区。
- `ActionMenuController`：负责动作菜单 UI 的创建、显示、定位和按钮事件。
- `CardPoolViewController`：负责公共牌池的表现，例如固定牌堆节点绑定、剩余数量显示、补位飞牌动画。
- `TurnStatusController`：负责右上角当前回合铭牌，显示当前玩家、种族和回合数；它是正式 HUD，不依赖 DebugPanel。
- `HandDrawerController`：负责左侧手牌抽屉表现，按当前回合玩家展示其手牌池，并预留法术牌、随从牌、升级牌、装备牌四个区域；抽屉高度会随视窗刷新，每个区域内部用滚动容器承载手牌，避免手牌数量增长时溢出边框；同时负责翻牌入手牌的飞行动画、手牌卡悬浮预览和手牌点击信号，不处理手牌使用规则。
- `EquipmentDisplayController`：负责右侧当前玩家装备展示区，读取 `PlayerState.get_equipped_cards()` 展示当前生效装备、装备类型和悬浮大图预览；只做展示，不参与装备规则。
- `CardAnimationController`：负责卡牌交换、攻击、远程投射物、施法特效、占领移动等卡牌表现动画；规则层只通过 `GameManager` 的动画入口间接调用它。
- `AttackOccupyChoiceController`：负责攻击击杀后”是否占领”的选择弹窗，`GameManager` 只关心选择结果和后续规则结算。
- `CardMultiSelectController`：通用卡牌多选面板。不绑定任何特定区域或卡牌语义；调用方传入标题、待选卡牌列表和最大可选数量，面板展示卡牌缩略图、名称和数值，用户通过复选框多选后点击确认。当前用于坟场复活选择和学院召唤的三选一，未来可复用于牌库发现、手牌弃置、坟场放逐等场景。AI 玩家不会打开这个 UI，而是通过 `GameManager.choose_card_indices_for_ai()` 对同一批候选数据自动选择，避免规则效果依赖人工点击。

原则：表现层不直接修改游戏规则状态，所有点击都交给 `GameManager`。

## 当前核心流程

1. 游戏启动进入 `StartMenu`。
2. `StartMenu` 读取 `cards.json` 中的可玩种族，左右两栏分别选择玩家 1 和玩家 2 的种族；选择状态保存在 `MatchSetup` 中，两个玩家不能选择相同种族。
3. 选择种族后，英雄下拉框展示该种族 `heroes` 中配置的英雄，默认选择第一个英雄。点击“开始游戏”后实例化 `main.tscn` 战斗场景。
4. `StartMenu` 在把战斗场景加入树之前，把 `player_faction_ids` 和 `selected_hero_card_ids` 写入 `GameManager`，确保战斗初始化使用选择页结果。
5. `GameManager` 读取 `cards.json`。
6. 根据玩家种族、选中英雄和中立牌库构建公共 `CardPool`。
7. 从牌池抽牌填入 5x5 棋盘。
8. 玩家翻牌时：
   - 翻到自己种族：成功翻开并归属当前玩家。
   - 翻到中立牌库：任意玩家都可以成功翻开并获得归属。
   - 翻到对方种族：先翻开，再扣回去。
9. 翻牌成功后交给 `RevealResolver` 进入区域路由：
   - 随从、建筑等棋盘单位继续留在棋盘上，并在需要时触发 `on_reveal`。
   - 中立棋盘单位不会归属当前玩家；例如中立建筑“小型矿脉”翻开后保持无 owner、不可操纵。玩家自己种族的建筑翻开后才会归属该玩家。
   - 法术牌、升级牌、装备牌进入当前玩家手牌，原棋盘格清空并调用统一补位入口。
   - 区域路由只处理已经成功归属的卡牌；敌方种族的手牌类卡牌仍会在归属校验阶段扣回去，不会进入当前玩家手牌。
10. 玩家点击己方正面随从：
   - `InteractionManager` 设置焦点牌。
   - `ActionMenuController` 显示动作菜单。
11. 玩家选择移动：
   - `MoveAction` 计算合法目标。
   - `InteractionManager` 把合法目标标记到 `CardState.is_valid_target`。
   - `Card` 根据 `is_valid_target` 显示白色目标背光。
   - 点击目标后 `MoveAction.execute()` 登记 `move` 行动类别，消耗移动力，并执行交换动画。
12. 玩家选择攻击：
   - `AttackAction` 计算 attack profile。普通攻击使用相邻正面单位作为合法目标；单位包括随从和建筑，因此中立建筑也可以被攻击。
   - 点击目标后 `AttackAction.execute()` 登记 `attack` 行动类别，并消耗一次攻击次数。
   - `GameManager.play_card_attack_animation()` 是攻击动画入口，具体表现委托给 `CardAnimationController`：近战攻击是攻击者短冲和目标受击抖动；远程攻击是光弹飞向目标并触发命中闪烁。
   - 动画结束后对目标造成自身攻击力的伤害。
   - 若目标生命小于等于 0，进入 `GameManager.resolve_attack_kill()` 击杀后结算。
   - 如果 attack profile 允许占领，`AttackOccupyChoiceController` 展示选择弹窗：不占领时目标入坟并补目标格；占领时目标入坟但不补目标格，攻击者移动到目标格，攻击者旧格走统一补位。当前近战击杀随从或摧毁建筑都允许占领；远程击杀仍不触发占领。
13. 玩家选择施法：
   - 当前玩家先在右上角 HUD 点击“开启施法”并消耗法力。标准规则费用为 3；测试模式可以通过 `data/test_config.json` 的 `game_params.spell_turn_mana_cost` 临时覆盖。
   - 施法回合开启后，`ActionRegistry` 才会从当前随从的 `CardData.spell_actions` 和当前玩家手牌升级牌授予的 `spell_actions` 动态创建 `SpellAction`。
   - `SpellAction` 根据 `target_rule` 计算合法目标，当前 `all_minions` 表示所有正面随从。
   - 点击目标后登记 `spell` 行动类别，通过 `GameManager.play_spell_cast_animation()` 委托 `CardAnimationController` 播放表现，再执行配置中的效果。
   - 当前已配置的随从法术包括：牧师的治疗术，目标规则为 `all_minions`，治疗目标 7 点生命；火焰女巫的火球术，目标规则为 `non_hero_minions`，对目标造成 6 点伤害；冰霜女巫的冰霜护盾，目标规则为 `all_minions`，使目标获得 6 点护盾；奥术法师的奥术智慧，目标规则为 `none`，使当前玩家本回合额外获得 3 次翻牌；女猎手的月刃，目标规则为 `all_minions`，第一目标必须存在相邻弹射随从，随后由 `BoardUnitBounceSelectionController` 选择第二目标。
14. 玩家使用手牌法术：
	- `HandDrawerController` 只发出手牌点击信号，`HandInteractionController` 记录焦点与菜单锚点，并把当前玩家和卡牌数据交给 `HandPlayResolver`。
	- 点击可用手牌先进入和棋盘卡一致的焦点态；手牌卡显示金色焦点柔光，动作菜单显示“施放”。
	- 点击“施放”后，`HandPlayResolver` 根据手牌牌自己的 `target_rule` 计算目标，并通过 `InteractionManager.start_hand_card_target_selection()` 进入和棋盘行动相同的目标选择模式。
	- 手牌随从会显示“放置”动作。放置目标为棋盘空格或未翻开的背面牌；若放到背面牌上，该背面牌先返回公共牌池，再将手牌随从正面放入目标格并归属当前玩家。
	- 合法目标仍写入 `CardState.is_valid_target`，所以白色背光、右键/Esc 取消、点击目标结算都和移动/攻击/随从施法共用一套交互。
	- 目标选择阶段右键或 Esc 会退回这张手牌的焦点态和动作菜单；再次点击已选中的手牌或动作菜单取消按钮会回到空闲状态。
	- 手牌动作菜单定位使用点击瞬间记录的手牌卡全局矩形，而不是刷新后的 UI 节点；这样同名手牌、手牌重排和抽屉重绘不会让菜单错位到第一张牌。
	- 中立法术牌“草药”：目标规则为 `all_minions`，默认恢复目标 5 点生命，并从当前玩家手牌中消耗。苗疆族升级牌“草药符咒”使用 `modify_hand_spell_effects` 在运行时修正草药：对友方目标保持原治疗效果，对敌方目标替换为造成 5 点伤害。
15. 玩家获得手牌升级牌：
	- 升级牌、法术牌、装备牌都通过 `RevealResolver` 在翻开成功后进入当前玩家手牌，并腾空原棋盘格补牌。
	- 手牌持续被动由 `HandPassiveResolver` 统一刷新，不放在 `PlayerState` 中硬编码具体卡牌 id。
	- 当前中立升级牌“金手指”：`type: "upgrade"`，`trigger: "while_in_hand"`，`effect id: "modify_flip_capacity"`，每张使玩家每回合可翻牌上限 +1。
	- 手牌持续单位光环也由 `HandPassiveResolver` 统一刷新。当前白银之手“骑术”使用 `set_unit_movement` + `card_ids: ["knight"]`，使己方战场骑士移动力变为 5；达拉然议会“初级/中级/终极法术能量”使用 `modify_unit_attack` + `card_ids`，使指定法系单位攻击力 +1；暗夜精灵哨兵“迅捷之弓”使用 `modify_unit_attack_speed` + `required_runtime_state_id: "full_moon"`，只在满月时让弓箭手攻速 +1。新单位翻开归属后会重新刷新该玩家手牌光环。
	- 升级牌也可以配置为手牌中的时点光环：效果写 `active_zone: "hand"`，再配置 `trigger`、`target` 和通用效果 id。当前白银之手“信仰圣光”就是这类升级牌：己方回合结束后，治疗战场上所有己方 `受祝福的步兵` 和 `战斗牧师` 3 点生命。
	- 升级牌可以配置为手牌中的动作授予器：效果写 `id: "grant_spell_actions"`、`active_zone: "hand"`、`card_ids` 和 `spell_actions`。`GrantedSpellResolver` 负责解释这些配置，`ActionRegistry` 会在施法回合中为当前玩家对应随从合并这些授予法术。当前白银之手“真言术·盾”使用这套机制，让所有己方牧师获得法术“真言术·盾”；“心灵之火”使用同一机制，让所有己方牧师和战斗牧师获得法术“心灵之火”；达拉然“炎爆术”使用同一机制，让火焰女巫获得对随从造成 10 点伤害的炎爆术。
	- 金手指进入当前玩家手牌时会立即刷新手牌被动；如果是在自己的回合内翻开，会立刻增加当前回合剩余翻牌次数。之后每个自己的回合开始前也会重新计算当前手牌中的持续加成。

## 坟场与死亡约定

- 每个 `PlayerState` 拥有自己的 `graveyard`。
- 坟场保存的是 Dictionary 快照，不直接保存棋盘上的 `CardState` 对象。
- 坟场快照分为三块：
  - `origin`：卡牌实例进入游戏时的初始属性，例如原始攻击、原始生命、原始移动力、原始攻速、关键词、效果和 `CardData` 引用。
  - `last_state`：死亡前最后状态，例如当前攻击、当前生命上限、已受伤害、所属玩家和原格子。
  - `death`：死亡元数据，例如死亡原因、回合、原格子、来源卡牌。
- 复活、召回、复制等规则应优先使用坟场快照或 `CardState.origin`，不要重新回 JSON 推断这张具体牌的原始状态。当前已实现 `ResurrectEffect`（通用坟场复活效果），它从 `PlayerState.graveyard` 中按 `filter_type` / `filter_owner` 过滤候选卡牌，通过 `CardMultiSelectController` 让玩家多选，再按 `target_zone` 移动到目标区域；当前落地区域支持 `hand`，执行时调用 `PlayerState.add_to_hand()` 并从坟场通过 `PlayerState.remove_from_graveyard_at()` 移除。手牌法术入口会先检查复活候选，避免没有合法目标时仍然消耗复活术；复活到手牌后的随从可通过通用手牌“放置”动作重新进入棋盘。
- 英雄死亡是特殊离场规则：英雄仍会触发 `on_destroyed` 等死亡相关结算，但不会进入普通 `graveyard`，而是进入所属玩家手牌并生成 `HandCardState`，当前冷却为 3 个自己的回合开始。
- 直接死亡法术、攻击致死、效果伤害致死都应调用 `GameManager.check_and_destroy_if_dead()`、`resolve_dead_states()`、`resolve_dead_units()` 或 `destroy_card()`，这些入口内部委托 `DeathResolver`，避免各行动重复实现清场和入坟逻辑。具体效果如果可能导致死亡，应在效果内部完成死亡检查，例如 `DamageEffect`。
- 行动执行中的死亡由外层行动流程统一收尾；`GameManager.is_executing_action` 用于避免死亡结算和点击流程重复取消交互。
- 死亡批处理：`DamageEffect` 先对全部目标造成伤害，再把受伤目标列表交给 `GameManager.resolve_dead_states()`。`DeathResolver` 会收集同一批死亡单位，设置 `CardState.is_pending_death` 防止重复入队，然后按稳定顺序触发 `on_destroyed`。亡语造成的新死亡会排入后续死亡批次，而不是插队打断当前批次。
- 直接销毁类流程继续使用 `GameManager.destroy_card()` / `destroy_card_with_refill()`；它们内部会走强制死亡事件，即使目标当前生命大于 0 也会进入同一套死亡触发和清场流程。
- 当前死亡触发顺序是：当前行动玩家拥有的死亡单位、其他玩家拥有的死亡单位、中立死亡单位；同组内按棋盘 `slot_index` 从小到大。
- `on_destroyed` 的运行时上下文由死亡事件注入，包含 `EventContext.DEAD_STATE`、`EventContext.DEATH`、`EventContext.DESTROYER_PLAYER_ID` 和可选 `EventContext.SOURCE_STATE`。后续亡语效果应读取这些上下文，而不是回头猜测是谁造成了死亡。

## 攻击副作用约定

- 普通攻击本体只负责校验、消耗行动资源、播放攻击动画和造成伤害。
- `AttackAction.get_attack_profile()` 是攻击规则的汇总点，目前包含 `can_attack`、`is_melee`、`can_occupy`。动画表现和击杀后副作用都读取这份 profile，避免各自重复推断攻击类型。
- 攻击后的单位自身触发效果统一走 `TriggerResolver` 的 `after_attack`，上下文包含 `EventContext.ATTACK_TARGET_STATE`。需要作用于被攻击敌方单位时，效果目标使用 `target: "attack_target_enemy_unit"`；只作用于被攻击敌方随从时使用 `target: "attack_target_enemy_minion"`。当前毒蝎的“蝎毒”、蛊毒蛇受升级牌“蛇毒”授予的攻击附毒、生蛊王蛇的“王毒”都走 `after_attack + apply_status`，不要在 `AttackAction` 中写死卡牌名。
- `can_attack_with_zero_attack` 关键词允许 0 攻单位发起攻击，用于毒蝎这类“攻击不造成战斗伤害，但攻击后触发效果”的单位。普通 0 攻单位仍不能攻击。
- 攻击造成击杀后，统一进入 `GameManager.resolve_attack_kill()`，内部委托 `DeathResolver.resolve_attack_kill()` 处理攻击击杀后的副作用结算。攻击击杀仍保留占领选择；效果伤害走批量死亡结算，不触发占领。
- 当前内置副作用是“可选占领”：攻击者可以移动到被击杀目标的格子。
- 占领不是普通移动，不额外消耗移动力或主行动；它是攻击击杀的后续结算。
- 占领选择的 UI 由 `AttackOccupyChoiceController` 管理，攻击击杀规则不直接创建弹窗节点。
- 后续如果增加掠夺、连击、击杀触发、阵营特性等效果，应优先挂在击杀后结算流程，而不是把逻辑塞进 `AttackAction` 或 UI。

## 棋盘补位约定

- 补牌不是死亡专属规则，而是“棋盘格被腾空后”的公共规则。
- `GameManager.refill_board_slot_from_pool()` 是规则层保留的统一补位入口，内部委托 `BoardSlotResolver` 从公共牌池抽牌并安排补位动画。
- 顶部牌堆是 `main.tscn` 中固定的 `CardPoolView` 节点，便于在编辑器里直接查看和调整；`BoardSlotResolver` 只决定是否抽牌和补哪个格子，剩余数量与飞牌表现仍由 `CardPoolViewController` 处理。
- 死亡入坟、法术牌翻开后进入手牌、召回、移出棋盘等流程，只负责完成自己的区域变化，然后调用统一补位入口。
- 具体流程不要直接把“死亡”和“补牌”耦合在一起；未来如果某些效果禁止补位，应该在腾空流程上加策略参数，而不是改死亡规则本身。

## 卡牌等级与公共牌池

- `data/cards.json` 中每张卡牌可以配置 `level`，默认值为 1。`CardData.level` 只描述静态卡牌等级，不参与棋盘运行时状态变化。
- 卡背资源与等级一一对应，统一使用 `res://assets/img/卡背/{level}.png`。`CardData` 加载时会根据 `level` 缓存对应卡背，`CardState` 绑定卡牌数据时复制该卡背作为当前实例背面。
- 游戏开始时仍然把双方种族牌库和中立牌库合并成一个公共牌池；不同等级不会拆成多个外部牌池，避免补位入口变复杂。
- `CardPool.draw_random()` 是等级抽取规则的唯一入口：先查找当前牌池里仍存在的最低等级，再通过 `get_indices_for_level()` 只在该等级的剩余卡牌中随机抽取。当前等级耗尽后，下一次抽牌自然进入更高等级。
- 公共牌堆 UI 通过 `CardPool.get_lowest_available_level()` 展示当前最低可抽等级的卡背；补牌飞行动画则使用已抽出卡牌自己的卡背，避免等级切换瞬间动画卡面错误。
- `BoardSlotResolver`、开局铺牌、死亡/入手牌后的补位都继续调用 `draw_random()`，因此所有补牌场景共享同一套等级推进规则。
- 当前等级定义：1 级为乌瑟尔、受祝福的步兵、信仰圣光、安东尼达斯、法师学徒、初级法术能量、召唤水元素、陈朵、励蛊、诱蛊、蛊童、草药符咒、剧毒之泉、金手指、小型矿脉、生命之泉、无中生有、草药；2 级为牧师、骑士、真言术·盾、骑术、火焰女巫、冰霜女巫、奥术法师、中级法术能量、好好学习、辉煌光环、女猎手、精英月刃豹、迅捷之弓、蛊毒蛇、巫医、子母蛊、蛇毒、中型矿脉、奥术矿脉、暗箭、无中生有生有；3 级为奥术傀儡、战斗牧师、心灵之火、终极法术能量、炎爆术、复活术、学院召唤、奥术空间、角鹰骑士、光明使者之锤、安东尼达斯的圣杖、生蛊王蛇、蛊巨蜥、薄葬、毒性爆发、大型矿脉、超大型矿脉。
- `CardPool.from_match_selection()` 是战斗牌池构建入口：玩家种族牌通过 `CardDatabase.build_weighted_pool_for_selection()` 加入，中立牌库仍通过普通 `build_weighted_pool()` 加入。
- 玩家种族牌池构建会根据 `selected_hero_card_ids` 过滤英雄：只加入选中的英雄，不加入同种族未选英雄。`heroes[].attached_cards` 中列出的子卡牌只会在对应英雄被选中时加入，避免未来多个英雄包互相污染。

## 棋盘单元格

- 物理棋盘尺寸为 `board_columns x board_rows`，当前默认 `7x7`。`GameManager.board_cells` 是当前占据各坐标的单元格属性模型，`board_states` 继续作为地面层兼容视图存在，二者索引一致。
- `BoardCell.is_land` 表示普通地面格。初始状态只有内圈 5x5 为地面格，外圈是战场边缘；但奥术空间可以交换两个单元格，使地面格移动到外圈坐标，或使边缘格移动到内圈坐标。补牌和普通随从放置永远读取当前位置上的 `BoardCell.is_land`。
- 补牌入口统一使用 `GameManager.can_refill_ground_slot()`；普通地面放置入口统一使用 `GameManager.can_place_ground_card_on_slot()`。新增规则不要直接判断 `state.is_empty()` 就认为可放置，否则会绕过外圈/飞行层限制。
- 飞行单位进入 `BoardCell.aerial_states`，不占用 `ground_state`。飞行单位可以放置或移动到外圈边缘格，也可以和地面单位、建筑共存于同一 `BoardCell`；涉及“所有单位”的规则应使用 `GameManager.get_all_board_states()`，涉及“某格内所有单位”的规则应使用 `GameManager.get_board_states_at_slot()`。补牌、未翻开牌、地面放置和奥术空间的单元格性质仍只读写地面层，保持 `board_states` 的兼容语义。

## 回合时点触发

- 回合时点触发统一由 `TurnTriggerResolver` 收集，再交给 `TriggerResolver` 和 `EffectRegistry` 执行；不要把具体卡牌效果写进 `GameManager.end_turn()`。
- 当前支持两个公共时点：`before_turn_start` 和 `after_turn_end`。`after_turn_end` 在刚结束回合玩家执行 `PlayerState.end_turn()` 后触发；`before_turn_start` 在下一名玩家执行 `PlayerState.start_turn()` 前触发。
- 时点触发上下文会注入 `EventContext.TURN_PLAYER_ID`，表示该时点对应的玩家。效果需要判断“当前回合玩家”时应读取这个上下文，而不是猜测来源牌归属。
- 回合时点触发源来自战场上所有正面牌，按 `slot_index` 从小到大稳定入队。每张牌是否触发由自身 `effects[].trigger` 决定。
- 战场单位上附着的状态也可以成为回合时点效果来源，通过 `payload.turn_effects` 配置效果列表。`TurnTriggerResolver` 会在战场时点触发后，扫描棋盘正面单位的状态并结算满足时点的状态内效果；状态层数（`stacks`）会乘到效果 `amount` 上。当前辉煌光环的 `arcane_aura` 状态使用这套机制在 `before_turn_start` 时点产生额外法力。
- 手牌中的升级牌也可以成为回合时点效果来源，但必须显式配置 `active_zone: "hand"`。`TurnTriggerResolver` 会在战场时点触发和状态效果后，结算当前回合玩家手牌中满足该时点的升级牌效果；具体效果仍交给 `EffectRegistry`。
- 生命之泉使用 `after_turn_end`，目标为 `adjacent_turn_player_minions`，表示只治疗与生命之泉 8 邻接且属于刚结束回合玩家的正面随从。触发型 `heal` 效果会先播放治疗特效，再结算恢复。后续毒性、灼烧、眩晕倒计时等也应优先通过时点触发和效果目标规则扩展。
- 信仰圣光使用 `after_turn_end` + `active_zone: "hand"`，目标为 `turn_player_minions_by_card_ids`，并通过 `card_ids` 限定联动卡牌。这个目标规则表示：选择 `EventContext.TURN_PLAYER_ID` 拥有的、战场正面、类型为随从、且 `card_id` 在白名单内的单位。

## 有效治疗触发

- 治疗效果必须区分配置治疗量和实际恢复量。`CardState.heal()` 返回本次真正减少的 `damage_taken`，满血目标或溢出治疗不会产生有效治疗量。
- `HealEffect` 在实际恢复量大于 0 时，会给被治疗单位排入 `on_effective_heal` 触发，并通过 `EventContext.EFFECTIVE_HEAL_AMOUNT` 注入有效治疗量。
- 需要按有效治疗量缩放的效果，使用 `amount_source: "effective_heal"` 读取上下文数值。当前战斗牧师使用这套机制：它监听自身 `on_effective_heal`，通过通用 `gain_attack` 效果让自身攻击力增加等同于有效治疗量的数值。
- 后续“受到治疗时获得护盾”“治疗后抽牌”“治疗溢出转化”等规则，应优先复用 `on_effective_heal` 事件或补充新的治疗上下文字段，不要把具体卡牌判断写进 `HealEffect`。

## 中立牌库约定

- `data/cards.json` 根节点中的每个对象都是一个可被 `CardDatabase` 读取的卡牌数据包。玩家种族包和中立牌库包保持同级结构，避免为中立卡另建一套解析流程。
- 当前中立牌库 id 为 `neutral`，并用 `kind: "neutral_pool"` 标识语义。它不是玩家可选种族，不参与玩家 HUD 的种族显示和英雄选择。
- `GameManager.neutral_faction_ids` 默认包含 `neutral`。游戏开始构建公共牌池时，会把双方玩家种族和这些中立牌库 id 一起传给 `CardPool.from_factions()`，按各卡牌 `count` 展开后统一洗牌。
- 中立牌库已经支持配置中立随从、法术牌或资源单位。当前中立法术牌包含 `草药`、`无中生有`、`无中生有生有`、`暗箭`。`草药` 使用 `heal` 动画治疗一个正面随从 5 点生命；`无中生有` 和 `无中生有生有` 使用 `arcane` 动画并额外获得本回合翻牌次数；`暗箭` 是 2 级法术，使用 `dark_arrow` 投射物动画并对一个正面随从造成 4 点伤害。
- 当前中立建筑牌包含 `小型矿脉`、`中型矿脉`、`奥术矿脉`、`大型矿脉`、`超大型矿脉` 和 `生命之泉`。`小型矿脉`：1 级，0 攻 4 血，摧毁者获得 4 点资源分。`中型矿脉`：2 级，0 攻 8 血，摧毁者获得 8 点资源分。`奥术矿脉`：2 级，0 攻 16 血，摧毁者获得 16 点资源分和 1 点法力。`大型矿脉`：3 级，0 攻 20 血，摧毁者获得 20 点资源分。`超大型矿脉`：3 级，0 攻 30 血，摧毁者获得 30 点资源分。矿脉翻开后留在战场且不归属任何玩家，近战摧毁可以触发占领选择。`生命之泉`：1 级建筑，0 攻 20 血，配置 `after_turn_end` 治疗效果，在玩家回合结束后恢复相邻己方随从生命。
- 翻开中立牌时，`RevealResolver.can_player_claim_card()` 通过 `GameManager.neutral_faction_ids` 判断其归属规则：任意当前玩家都可以成功翻开并获得该牌。

## 交互提示约定

- 绿色背光：`CardState.is_action_available_hint`，表示当前空闲状态下这张牌至少有一个可用行动；由 `ActionHintResolver` 统一计算。
- 金色背光：`CardState.is_selected`，表示当前焦点牌。
- 白色背光：`CardState.is_valid_target`，表示当前行动可选择的目标。
- 蓝色填充：`CardState.is_area_preview`，表示当前悬停位置对应的 AOE 生效范围（如暴风雪的 3×3 区域）。蓝色填充从 `Card.draw_area_preview()` 绘制，在合法目标白色背光之前渲染，两者可叠加。
- 背光优先级由 `Card` 统一处理：焦点 > 合法目标 > 可行动。area 预览作为背景层优先绘制，不参与优先级互斥。
- `GameManager._on_interaction_changed()` 统一触发行动提示和调试面板刷新，行动提示具体计算交给 `ActionHintResolver`。
- `GameManager.is_game_busy()` 统一判断翻牌动画、移动/攻击动画和行动结算是否正在进行；忙碌期间忽略新的点击、右键取消和结束回合，降低异步动画带来的竞态。
- 右键取消约定：焦点状态下右键回到非焦点状态；目标选择状态下右键或 Esc 退回焦点状态和动作菜单。动作菜单的取消按钮、再次点击焦点牌仍然保留。

## 效果目标约定

- `target` 为空的目标型手牌法术或随从法术，会在执行前由 `EffectData.mark_selected_target()` 默认注入为 `selected`。
- 如果一张牌的多段效果需要不同目标，应在对应效果上显式写 `target`；运行时仍会保存选中目标上下文，但不会覆盖显式目标。
- `selected_adjacent_enemy_minions` 表示：以本次选中的目标为中心，取其 8 方向相邻、正面、敌方、类型为随从的单位。敌我判断优先使用效果拥有者；手牌法术会由 `HandPlayResolver` 注入拥有者，棋盘法术则使用来源随从 owner。
- `selected_area_enemy_minions` 表示：以本次选中的格子为中心，按效果配置的 `area_rows` × `area_cols` 展开区域，取区域内正面敌方随从。`selected_area_all_minions` 同理但不区分敌我。区域展开由 `BoardQuery.get_area_slots()` 计算，自动处理棋盘边缘裁剪；过滤逻辑在 `CardEffect.get_selected_area_targets()` 中统一处理。新增过滤类型（友方、全部单位等）只需扩展 `CardEffect.AreaFilter` 枚举。

## 生命值约定

- `CardData.health` 是卡牌基础生命上限。
- `CardState.origin.health` 是这张具体卡牌进入游戏时的初始生命上限快照。
- `CardState.max_health` 是当前生命上限，可被效果修改。
- `CardState.damage_taken` 是当前已受伤害。
- `CardState.shield` 是当前护盾值，会优先于生命承受伤害。
- `CardState.current_health` 是只读计算值：`max_health - damage_taken`。
- 造成伤害调用 `take_damage()`，它会先扣护盾，不足部分再转为已受伤害；治疗调用 `heal()`，增加护盾调用 `gain_shield()`，调整上限调用 `increase_max_health()` / `decrease_max_health()`。
- `increase_max_health` 效果用于“提高生命上限并同步提高当前生命”的卡牌。它调用 `CardState.increase_max_health(amount, false)`，保持已受伤害不变，因此 `max_health` 增加多少，`current_health` 也增加多少。
- `set_attack_to_current_health` 效果用于“攻击力等于当前生命值”这类一次性结算。它只在结算瞬间读取目标 `current_health` 并写入 `current_attack`，不会建立持续联动；后续生命或攻击力被其他效果改变时不会自动互相影响。
- 效果和行动不要直接写 `current_health`，避免治疗溢出或上限变化后状态不一致。

## 状态约定

- `CardState.statuses` 保存当前附着在这张棋盘单位上的 `CardStatus` 列表。状态会随棋盘状态快照一起交换、入坟和恢复；卡牌离开棋盘或格子被清空时状态也会清空。
- `CardStatus` 的核心字段包括：`status_id`、`display_name`、`tags`、`stacks`、`is_permanent`、`remaining_turns`、`duration_scope`、`expires_on_trigger`、`persists_after_death`、`source_card_id`、`source_owner_id`、`duration_owner_id` 和 `payload`。
- `is_permanent` 只表示“不按回合倒计时”，不表示死亡后保留。死亡、英雄进入复活冷却、离开棋盘时仍会清空状态。若未来需要真正跨死亡/跨区域保留的状态，使用 `persists_after_death` 表达，并在区域迁移流程中显式处理。
- 永久状态使用 `permanent: true` 或不配置 `duration_turns`；临时状态配置 `duration_turns`。当前默认在 `after_turn_end` 时点减少持续回合。
- `duration_scope` 决定临时状态按谁的回合倒计时：默认 `target_owner`，也支持 `source_owner` 和 `global`。`target_owner` 会在状态施加时记录目标当时的 owner，避免后续归属变化导致倒计时漂移。
- `apply_status` 是通用施加状态效果。配置示例：`{"id":"apply_status","status_id":"poison","status_name":"中毒","duration_turns":2,"target":"selected","status_tags":["damage_over_time"]}`。它只负责把状态写入目标，具体中毒伤害、圣盾抵挡、冻结禁用行动等规则应由对应状态 resolver 或行动/效果读取状态后处理。可选字段 `apply_animation` 指定状态施加瞬间的视觉动画 key；没有该字段时不播放额外动画，由施法来源自身的动画负责表现。
- 当前圣盾使用 `status_id: "divine_shield"`，属于永久但可消耗状态。`CardState.take_damage()` 在数值护盾和生命结算前会先消耗一层圣盾并完全抵消本次伤害效果；多层圣盾逐层消耗，最后一层消耗后从状态列表移除。
- `辉煌光环` 使用 `status_id: "arcane_aura"`，由安东尼达斯英雄配套法术施加到安东尼达斯自己身上。它的 `payload.turn_effects` 在 `before_turn_start` 时触发，`trigger_player: "source_owner"` 表示只在状态所在单位拥有者的回合开始前生效；状态层数会乘到效果 `amount` 上，因此多次释放可以叠加额外法力。
- `励蛊` 使用 `status_id: "encourage_gu"` 和 `status_tags: ["attack_modifier"]`，通过 `payload.attack_bonus` 为目标提供持续攻击力修正。`CardState.status_attack_bonus` 单独记录状态来源的攻击修正；状态叠层、驱散、过期或离场清空时会重新计算并回滚对应攻击力，不会污染一次性攻击力变化或手牌持续光环。需要提供生命上限修正的状态使用 `status_tags: ["health_modifier"]` 和 `payload.max_health_bonus`，由 `CardState.status_max_health_bonus` 统一回滚。
- `毒` 使用 `status_id: "poison"` 和 `status_tags: ["damage_over_time"]`，通过 `payload.poison_damage` 表示每次回合结束伤害，通过 `duration_turns` 表示持续几个目标拥有者回合。毒状态是唯一状态：新毒的剩余总伤害（`poison_damage * duration_turns`）高于已有毒时覆盖，否则忽略。`StatusResolver.resolve_pre_trigger_status_effects()` 会在 `after_turn_end` 的普通回合结束触发前先结算毒伤害，并立刻进入死亡/亡语/补牌流程，因此毒伤害早于生命之泉、手牌升级等回合结束治疗。毒的持续 UI 是数值图标，展示剩余总伤害而不是整卡紫色遮罩。苗疆族“毒性爆发”使用 `modify_applied_status` 将己方施加的新毒压缩为 `duration_turns: 1`，并把每回合毒伤调整为原剩余总伤害。
- `储毒` 使用 `status_id: "stored_venom"` 和 `status_tags: ["stored_resource"]`，通过 `payload.stored_venom_damage` 保存剧毒之泉储存的总毒量。它不是持续伤害状态，不会在回合结束跳伤害；`Card` 复用毒性数字图标在状态数字栈中显示储毒量。
- `同命蛊` 使用 `status_id: "life_link"` 和 `status_tags: ["death_link"]`。每次 `link_units` 施法都会生成唯一 `link_id`，分别给两个目标写入一层 `life_link` 状态；状态的 `payload.trigger_effects` 在 `on_destroyed` 时触发 `destroy_linked_units`，后者读取 `_trigger_status.payload.link_id` 找到同一链接的另一端并直接销毁。因为每次施法的 link id 独立，AB 和 CD 不互相影响；AB 与 BC 这种链式链接会通过死亡队列自然传播为 A 死亡、B 直接死亡、再触发 C 直接死亡。
- `薄葬` 使用 `status_id: "death_immunity"` 和 `status_tags: ["death_prevention"]`。死亡解析器只看 tag，不绑定状态 id；因此后续“不灭”“濒死保护”等机制可以复用同一死亡门控。薄葬期间单位受到过量伤害时生命会停在 0，但不会入死亡队列；当状态在回合时点到期后，`StatusResolver` 会再次检查，若目标仍为 0 生命则按 `status_expired` 原因进入标准死亡/亡语/补牌流程。
- 圣盾、辉煌光环、励蛊、同命蛊、薄葬和冻结的持续视觉不属于施法动画，而是状态覆盖表现：`CardStatusOverlay` 读取目标当前状态并绘制金色圣光盾、奥术光环、绿色蛊虫强化背光、链接绿纹、死亡庇护裹布或冰蓝色边框与冰晶雪花图案。毒性、护盾等数值状态由 `Card` 的状态数字栈展示。一次性施法动画仍由 `CardAnimationController` 管理。
- 冻结（`status_id: "freeze"`）是首个临时控制状态，配置 `duration_turns` + `expires_on_trigger: "after_turn_end"` + `duration_scope: "target_owner"`，完整覆盖对手一个回合。状态到期后自动移除，无需额外的"跳过恢复"或"强制清空行动力"逻辑。
- `TAG_ACTION_PREVENTION` 是控制状态的通用 tag，不绑定特定 status_id。`CardState` 提供 `has_status_with_tag(tag)` 通用门控；`can_move()`、`can_attack()` 和 `can_take_action_group()` 都通过此 tag 阻止行动。未来眩晕、定身等控制状态只需在 JSON 中配置 `"status_tags": ["action_prevention"]` 即可复用同一套门控，零代码改动。
- 同一来源、同一 `status_id` 的状态会按 `stack_policy` 合并：默认 `stack` 会叠层，`refresh` 会刷新持续信息但不额外叠层，`replace` 会用新状态替换旧状态，`ignore` 会忽略后续同源同名状态。蛇毒减攻使用 `refresh`，避免重复攻击把同一个“攻击-2”状态叠成无限减攻；毒状态仍走专门的强度比较逻辑。
- `吞噬` 使用 `status_id: "devour"`，同时带 `attack_modifier` 和 `health_modifier`。多次吞噬会叠层，但具体攻击/生命加成保存在累计 payload 中，并通过 `cumulative_status_modifier: true` 告诉 `CardState` 不再按 stacks 二次相乘。吞噬继承的毒性攻击放在状态 `payload.trigger_effects` 中，只保留最高级毒性包；未来驱散移除此状态时，属性和继承毒性攻击会一起消失。
- `StatusResolver` 会在 `GameManager.resolve_turn_timing_triggers()` 中分两段工作：先通过 `resolve_pre_trigger_status_effects()` 结算需要早于普通时点触发的状态规则（当前是毒伤害），然后在普通时点触发结算之后推进状态生命周期。这样毒伤害早于回合结束治疗，而到期前的状态仍可参与该时点触发，随后再过期。

## 行动资源约定

- `CardState.max_movement` / `current_movement` 表示每回合移动力。
- `CardState.max_attack_speed` / `current_attacks` 表示攻速和当前剩余攻击次数。
- `CardState.max_main_actions` / `current_main_actions` 表示本回合还能开启多少个新的行动类别，而不是还能执行多少次动作。
- `CardState.used_action_groups` 记录本回合已经开启的行动类别，例如 `move`、`attack`、`spell`。同一类别已经开启后，可以继续消耗自己的次数资源，例如多次移动或多次攻击。
- `CardState.allowed_action_group_pairs` 记录允许同时使用的行动类别组合。普通随从默认没有组合，所以移动、攻击、施法三选一；未来“移动攻击”“移动施法”“战斗法师”可以通过开放 `move|attack`、`move|spell`、`attack|spell` 组合实现。
- 所有随从默认主行动 1、移动力 1、攻速 1；非随从为 0。
- 当前玩家回合开始时，`GameManager.restore_minion_actions_for_player()` 清空行动类别锁，并恢复该玩家随从的移动力和攻击次数。
- `CardAction.action_group` 表示行动所属类别，`main_action_cost` 表示是否需要登记类别，默认是 1。当前移动属于 `move`，攻击属于 `attack`。`main_action_cost = 0` 的副动作不登记主行动类别；如果仍需要限制频率，设置 `once_per_turn = true`，由 `CardState.used_action_ids` 在回合恢复时统一清空。
- `CardAction.can_reuse_action_group` 表示同一个行动类别在本回合是否可以重复执行。移动和攻击依靠移动力/攻速限制，所以可以重复；施法当前没有独立次数资源，所以治疗术不可重复施放。
- `special` 行动组用于非移动、非攻击、非施法的主动能力，默认仍是主动作并与移动/攻击/施法互斥。当前 `注入毒液` 和 `毒爆` 都属于 `special`，其中毒爆是剧毒之泉自己的主动作，不走施法回合。
- `爪击` 是配置型副动作示例：`FixedMeleeDamageAction` 使用近战相邻单位目标，造成配置的固定伤害，不消耗主行动力，也不消耗攻速，但每回合只能使用一次。
- 攻击行动只有在 `current_attack > 0`、`current_attacks > 0` 且允许使用 `attack` 类别时可用；移动同理要求 `current_movement > 0` 且允许使用 `move` 类别。

## 翻牌资源约定

- `PlayerState.base_flips_per_turn` 表示玩家每回合基础翻牌次数，来自战局初始化配置。
- `PlayerState.flip_capacity_bonus` 表示持续效果提供的翻牌上限加成，例如手牌中的金手指。
- `PlayerState.max_flips_per_turn` 表示当前有效的每回合翻牌上限，等于基础值加持续加成。
- `PlayerState.remaining_flips` 表示当前回合剩余翻牌次数，可以高于基础上限。
- `GameManager.player_max_flips_per_turn` 是战局初始化时使用的基础翻牌次数配置，当前默认 4。
- 当前回合临时增加翻牌次数调用 `PlayerState.gain_flips()`；它只增加 `remaining_flips`，不修改基础上限。
- `gain_flips` 效果用于配置“本回合额外翻牌”类法术，例如奥术智慧。它和持续提高翻牌上限的 `modify_flip_capacity` 不同，不能混用。
- `modify_flip_capacity` 是手牌持续被动效果，目前由 `HandPassiveResolver` 在卡牌进入手牌和玩家回合开始时统一刷新。未来如果升级牌离开手牌、被禁用或拥有冷却，也应通过刷新手牌持续被动来重新计算上限。
- `set_unit_movement` 是手牌持续单位光环效果，按 `card_ids` 过滤己方战场正面随从，并把其移动力上限设为 `amount`。刷新时会保留本回合已消耗的移动点，避免中途获得光环直接回满移动力。
- `modify_unit_attack` 是手牌持续单位光环效果，按 `card_ids` 过滤己方战场正面随从，并给其 `current_attack` 增加 `amount`。`CardState.passive_attack_bonus` 单独记录这层光环，刷新时先移除旧光环再应用新光环，避免反复刷新导致攻击力无限叠加，也不会覆盖“心灵之火”这类一次性攻击力修改。
- `modify_unit_attack_speed` 是手牌持续单位光环效果，按 `card_ids` 过滤己方战场正面随从，并在原始攻速上增加 `amount`。刷新时会保留本回合已消耗的攻击次数；当光环失效或时间条件不满足时，攻速会回落到 `origin.attack_speed`。
- 手牌持续被动可以通过 `required_runtime_state_id` 绑定玩家种族运行时状态，例如“满月时生效”。种族状态跳转或推进后，`GameManager` 会刷新该玩家手牌被动，避免 UI 时间变化但战场数值未更新。

## 英雄、手牌与冷却设计约定

- 英雄是特殊随从，仍然属于可在棋盘上存在的单位，但英雄身份不依赖 `keywords`。静态数据使用明确字段 `role: "hero"`，并由 `CardData.is_hero()` / `CardState.is_hero()` 统一判断。
- `keywords` 只用于描述能力或标签，例如 `ranged`、`cavalry`、`magic_immune`。英雄卡牌不再在 `keywords` 中写入 `hero` 标识，避免“身份”和“能力”混在一起。
- 每个种族一场游戏只会使用一个英雄。一个种族可以有多个可选英雄，但英雄选择属于进入战局前的配置流程，后续再开发。
- 英雄选择已经由入口页 `StartMenu` 负责。当前双方玩家各自选择一个种族和一个英雄，默认英雄是种族 `heroes` 中的第一个条目。
- 英雄配套牌在种族层级定义，而不是写进英雄随从卡本身。当前 `cards.json` 使用 `heroes` 字段，每个条目通过 `card_id` 指向英雄卡牌，并预留 `attached_cards` 保存配套法术牌、武器牌等；牌池构建时只加载已选英雄的 `attached_cards`，加载后会把对应 `CardData.owner_hero_card_id` 标记为所属英雄。
- 英雄配套牌的使用限制统一在手牌规则层处理：只要手牌牌带有 `owner_hero_card_id`，释放时就要求该玩家对应英雄当前正面在战场上。这样未来英雄法术、英雄武器、英雄专属随从都能复用同一条规则。
- 当前乌瑟尔英雄配套牌包括：1 级 `圣盾术`，目标规则为 `all_minions`，使一个随从获得可消耗圣盾；2 级 `洗礼`，目标规则为 `all_minions`，治疗选中随从 4 点生命，并对选中随从 8 邻接范围内的敌方随从造成 4 点伤害；3 级 `复活术`，从己方坟场选择最多 6 个随从移入手牌（使用通用 `resurrect` 效果和 `CardMultiSelectController` 多选面板）；3 级武器 `光明使者之锤`，装备后乌瑟尔攻击后会自动以自身为目标释放 `洗礼`。
- 当前陈朵英雄配套牌包括：1 级 `励蛊`，对一个随从施加可被驱散的攻击增益状态；2 级 `子母蛊`，使用 `link_units` 在两个可被法术影响的随从之间建立同命链接；3 级 `生蛊王蛇`，把生蛊王蛇衍生随从置入手牌。
- 注意区分：法术型复活（`resurrect` 效果，从坟场选牌移入手牌）和英雄自身复活是两套机制。英雄死亡不进入普通坟场，而是离开棋盘，并生成一张进入玩家手牌的英雄随从牌实例。
- 这张复活后的英雄手牌不是立即可用，而是带有 3 回合使用冷却。冷却在所属玩家自己的回合开始时减少 1；冷却归零后，玩家可以像使用普通手牌随从一样，主动把英雄放置到棋盘上。
- “手牌牌有冷却”应作为通用手牌机制实现，不是英雄专属字段。未来一些法术牌、武器牌、随从牌也可以在手牌中处于冷却状态，冷却结束前不可使用。
- 手牌随从牌的放置流程已作为通用手牌动作实现：玩家选择一张可用手牌随从，再选择棋盘空格或允许覆盖的背面格子放置。
- 英雄复活只负责把英雄牌放入手牌并设置冷却，不强制弹窗要求玩家立刻放置。玩家何时重新部署英雄，应由手牌使用流程决定。
- 如果手牌随从允许放置到未翻开卡牌上，则该未翻开卡牌应返回公共牌池或供应池。这是“从手牌放置单位”的格子替换规则，不应写死在英雄复活流程里。
- 当前已引入 `HandCardState` 保存手牌运行时字段，例如 `data`、`owner_id`、`cooldown_turns`、`source`、`tags`。棋盘上的 `CardState` 继续负责 board slot 状态；手牌牌不应依赖 `slot_index`。未来如果手牌也需要独立强化、费用修改、来源快照或更复杂区域流转，可在 `HandCardState` 基础上继续演进为更完整的 `CardInstance`。
- 英雄复活进入手牌时，应优先使用英雄实例的 `origin` 或英雄定义数据创建新的手牌实例，避免回 JSON 重新推断具体初始状态。
- 当前左侧手牌抽屉已经作为表现层入口存在。它随当前回合玩家切换读取 `PlayerState.hand`，并按法术、随从、升级、装备四类区域展示为接近棋盘尺寸的卡面；手牌卡只展示卡图，不额外叠加描述文字。手牌卡悬浮时会复用棋盘卡的右侧大图预览风格。可主动使用的手牌显示绿色柔光，已选中手牌显示金色焦点柔光；法术显示“施放”，随从显示“放置”，纯被动升级牌可以展示在升级牌区域但不显示动作菜单。带 `cooldown_turns` 的手牌会在卡面右上角显示冷却数字，冷却归零前不显示可用绿光也不提供动作。未来禁用、费用不足等状态应由手牌规则层计算后传给 UI。
- 当前手牌允许同时保存旧式 `CardData` 和运行时 `HandCardState`。读取手牌卡牌数据时应通过 `PlayerState.get_hand_card_data_at()` 或 `HandCardState.get_card_data()` 统一解析，消耗时通过 `PlayerState.remove_from_hand_at()` 按手牌索引移除，并用 `expected_card_data` 做防护。
- 在升级为真正手牌实例之前，手牌交互暂时使用“当前玩家手牌索引”区分同名牌：手牌焦点、动作菜单定位、目标选择回退和消耗都记录 `selected_hand_index`。不要用 `CardData` 对象本身判断某一张手牌是否被选中，因为多张同名牌会共享同一份静态数据。

## 装备约定

- 装备牌静态类型为 `type: "equipment"`，并用 `equipment_type` 表示互斥槽位，例如 `weapon`。翻开装备牌后进入手牌，和法术、升级牌一样遵守归属与英雄配套牌限制。
- 手牌装备使用通用 `hand:equip` 动作。装备后从手牌移除，进入 `PlayerState.equipped_cards_by_type`；同一 `equipment_type` 同时只保留一张生效装备。装备新装备时，如果该槽位已有旧装备，旧装备会回到玩家手牌，保证玩家可以在多张永久装备之间来回替换。
- 装备触发统一由 `EquipmentTriggerResolver` 解析。装备不在棋盘上，因此触发时需要由攻击者等棋盘来源提供上下文。当前支持 `after_attack`：攻击伤害、击杀/占领结算完成后，重新定位仍在战场上的攻击者，再结算其所属玩家装备的触发效果。
- 装备可以通过通用效果 `play_spell_action` 复用既有法术牌定义，例如 `光明使者之锤` 配置 `card_id: "baptism"`，避免复制洗礼的多段治疗/伤害配置。复用法术时仍通过 `SpellTargetResolver.get_rule_from_card_data()` 读取目标规则，并校验自动目标是否合法；不要绕过法术目标体系。后续武器的耐久、攻击力加成、受击触发等应继续扩展装备触发或装备状态，不要写进 `AttackAction`。
- 当前回合玩家的装备通过右侧 `EquipmentDisplayController` 展示。展示区读取玩家装备槽位，不修改 `PlayerState`，避免 UI 和装备规则互相耦合。

## 施法约定

- 随从拥有的施法能力写在 `CardData.spell_actions`，而不是写死在具体行动代码里。
- 由升级牌解锁的施法能力不要预埋进随从自身 `spell_actions` 再特殊禁用；优先让升级牌通过 `grant_spell_actions` 授予动作。授予规则的 JSON 解释放在 `GrantedSpellResolver`，这样未获得升级时单位基础定义保持干净，未来升级牌也可以授予不同单位不同法术。
- 法术动作只在当前玩家开启施法回合后展示；施法回合状态保存在 `GameManager.is_spell_turn_active`，回合结束时清空。
- 每个 spell action 至少包含 `id`、`name`、`target_rule` 和 `effects`；可选 `animation` 用于指定表现层动画 key。`CardAction.get_area_info()` 是多态方法，基类返回空字典，`SpellAction` 覆写并通过 `SpellTargetResolver` 返回 area 尺寸；`InteractionManager` 不依赖具体行动类的内部字段。
- 法术目标规则由 `SpellTargetResolver` 统一解释。当前常用 `all_minions`、`non_hero_minions`、`minions_by_card_ids`、`none` 和 `area_3x3`；`all_minions` 只选正面随从，`non_hero_minions` 只选正面非英雄随从，`minions_by_card_ids` 只选 `spell_data.card_ids` 白名单里的正面随从并排除施法者自身，`none` 表示无目标法术，点击动作菜单后直接结算。`all_units` 解析能力仍保留给未来明确允许影响建筑的机制，但当前普通施法不应使用它。后续”不能选英雄””只能选建筑””只选友方”等规则应在这里扩展。
- `area_3x3` 是首个 AOE 范围目标规则。它不选择单位，而是选择棋盘格子作为范围中心。`SpellTargetResolver.is_area_rule()` 统一判断 area 类型；`get_area_dimensions()` 从规则名解析尺寸。新增 area 形状（如 5×5、十字）只需在 `SpellTargetResolver` 中注册常量和映射，交互层和效果层自动适配。
- AOE 目标选择复用同一套 `InteractionManager.start_action_selection()`：area 模式下全棋盘格子均为合法目标（白色边框），悬停时通过 `mouse_entered_card` 信号触发 `update_area_preview()`，调用 `BoardQuery.get_area_slots()` 计算影响范围并标记 `CardState.is_area_preview`（蓝色填充）。点击任意合法格子后，该格子作为”选中中心”注入效果上下文。
- `empty_or_hidden_slots` 是格子型法术目标规则，允许选择空格或未翻开的背面牌格。它不要求目标是正面单位，当前用于“诱蛊”设置陷阱；释放时仍通过 `EffectData.mark_selected_target()` 把目标格子的 `CardState` 注入效果上下文。
- `target_rule: "none"` 不一定表示完全没有后续交互。若某个效果在法术成功施放后需要多段棋盘选择，应由对应效果启动专门的选择协作者。例如 `swap_board_slots` 使用 `BoardPairSelectionController`，在效果结算期间最多选择三组格子并逐组交换；`link_units` 使用 `BoardUnitPairSelectionController`，在效果结算期间从合法随从中选两个建立链接。它们不把每次点击塞回 `InteractionManager` 的单次目标流程，避免和普通施法目标、手牌目标、AOE 预览互相耦合。
- `swap_board_slots` 交换的是单元格本身：两个位置上的 `BoardCell.is_land` 等单元格性质会互换，地面层卡牌内容也随之交换；屏幕上的 CardSlot / Card 节点仍保持原物理坐标。7x7 棋盘中，初始内圈地面格被交换到外圈后仍可补牌/放置普通随从，初始外圈边缘格被交换到内圈后仍不可补牌/放置普通随从。
- 格子效果使用 `set_slot_trap` 这类效果写入 `BoardSlotEffectResolver`。触发时机由 `slot_effect_trigger` 描述，当前支持 `unit_entered`；进入检查由移动交换、手牌随从放置和翻开进入棋盘三个入口统一调用 `GameManager.resolve_slot_unit_entered()`。持续展示默认不显示，释放和触发分别走 `gu_lure` / `gu_trap_trigger` 等一次性动画。
- 手牌法术的目标选择同样由 `InteractionManager.start_hand_card_target_selection()` 进入目标选择模式；如果手牌法术的 `target_rule` 是 area 规则，也会读取 `SpellTargetResolver.get_area_dimensions()` 并启用相同的蓝色范围预览。不要为手牌 AOE 法术另写一套交互状态。
- 法术效果复用 `EffectRegistry`，治疗、伤害、护盾、翻牌次数等公共效果不和某个法术绑定。`SpellAction` 会通过 `EffectData.mark_selected_target()` 把选中的目标以 `selected` 注入运行时效果数据；效果自身负责执行规则变化，可能导致死亡的效果也负责调用死亡检查。
- 效果可用性也属于效果系统：`CardEffect.can_execute()` 默认返回可用，特殊效果可以覆写它，例如复活效果会检查坟场候选和目标区域。`HandPlayResolver` 不应按具体效果类型写分支，而是注入施法者上下文后调用 `EffectRegistry.can_execute_effect()`。
- `GameManager.play_spell_cast_animation()` 是规则层保留的法术视觉入口；具体表现由 `CardAnimationController` 按 spell action 的 `animation` 分派。当前治疗术使用 `heal` 绿色治疗脉冲，火球术使用 `fireball` 橙红色投射物和命中反馈，炎爆术使用 `pyroblast` 放大版火球投射物，冰霜护盾使用 `shield` 蓝色屏障脉冲，奥术智慧使用 `arcane` 紫蓝色奥术脉冲；未来可以让多个法术复用同一种表现 key。
- 手牌法术不消耗法力水晶，也不要求进入“施法回合”；它消耗的是手牌本身。手牌法术的 `target_rule` 和 `animation` 写在卡牌自身数据上，效果仍复用 `EffectRegistry`。`HandPlayResolver` 与 `SpellAction` 都通过 `SpellTargetResolver` 获取目标，后续目标规则只在一个地方扩展。
- 手牌法术运行时修正统一由 `HandSpellModifierResolver` 处理。升级牌通过 `modify_hand_spell_effects`、`card_ids`、`target_relation`、`replace_effects` / `append_effects` 和可选 `animation` 配置，不要在某张法术或 `HandPlayResolver` 中写死“如果是草药就改效果”。AI 手牌评分同样通过 `HandPlayResolver.get_resolved_spell_effects()` 读取修正后的效果。
- 英雄配套手牌由 `CardData.owner_hero_card_id` 标记。它来自种族 `heroes[].attached_cards`，不是每张牌单独写死判断。`HandPlayResolver` 在手牌绿光、动作菜单和实际执行前统一检查：所属玩家的对应英雄必须正面在战场上，否则这张英雄配套牌不能释放；具体棋盘扫描通过 `BoardQuery.has_face_up_hero()` 完成。

## AI 对手约定

- 入口页可把某个玩家标记为 AI，并把控制权写入 `MatchSetup`；战斗初始化时 `GameManager.initialize_players()` 将它同步到 `PlayerState.is_ai` 和 `ai_difficulty`。
- `GameManager.schedule_ai_turn_if_needed()` 是 AI 回合调度入口。回合切换完成、UI 和状态刷新之后，通过 `call_deferred()` 启动 `_run_ai_turn()`，避免在 `end_turn()` 内部直接递归等待 AI 再次结束回合。
- `_run_ai_turn()` 会为每个 AI 回合启动 `ai_turn_watchdog_seconds` 超时保护。如果异步动作、动画或效果没有正常返回，watchdog 会在仍处于同一个 AI 回合时清理 busy flag 并强制走正常 `end_turn()`，避免 AI 永久卡住。
- AI 行动分为手牌评估、战场行动评估和翻牌评估。AI 不模拟鼠标点击，也不调用表现层菜单；它调用规则层入口，例如 `HandPlayResolver`、`CardAction.execute()` 和翻牌/补位协作者。
- AI 回合使用“候选动作评分循环”：每一步收集当前所有可执行候选（手牌、战场行动、翻牌、开启施法回合），执行最高分候选并等待结算完成，然后重新评估。不要恢复成固定的“先手牌、再随从、再翻牌”流水线。
- 需要玩家从候选牌中选择的效果（例如 `resurrect`、`choose_card_to_hand`）必须先判断当前效果拥有者是否为 AI。人类玩家走 `CardMultiSelectController`，AI 玩家走 `GameManager.choose_card_indices_for_ai()` 自动选择候选索引。新增选择型效果时不要把选择面板写死进效果逻辑。需要多段棋盘点击的效果也必须有 AI 路径或显式跳过 AI；例如 `link_units` 的人类路径使用 `BoardUnitPairSelectionController`，AI 路径直接按单位价值选择候选，避免 AI 回合等待玩家输入。
- AI 战场评估必须同时考虑有目标和无目标行动。`CardAction.requires_target() == false` 的动作不应依赖 `get_valid_targets()` 返回非空；这类动作应按空目标评分并直接执行。
- AI 攻击评分按收益计算：击杀高威胁敌方随从、获得资源分、获得法力和破圣盾是正收益；攻击己方单位或无法摧毁且没有奖励的中立建筑是低收益或负收益。新增建筑奖励时应通过 `on_destroyed` 效果反映价值，而不是在 AI 中写死卡牌名。

## 动画与表现约定

- `GameManager` 可以保留语义化动画入口，例如 `play_card_attack_animation()`、`play_spell_cast_animation()`、`play_hand_spell_card_animation()`、`play_card_to_hand_animation()`，供行动、效果和区域路由调用。
- 具体 tween、投射物、特效面板、层级和样式应放在 `CardAnimationController` 或更细的表现控制器中。
- 动画控制器只操作 `Card` 节点和临时表现节点，不直接修改 `CardState`、`PlayerState`、坟场、牌池等规则数据。
- 如果动画结束后需要改变规则状态，由 `GameManager` 在 `await` 动画之后统一处理，例如交换内容、造成伤害、入坟或补位。
- 覆盖层动画统一通过 `GameManager.get_overlay_animation_root()` 获取根节点。补位飞牌仍归 `CardPoolViewController` 管理，因为它依赖公共牌池固定视图；手牌飞入归 `HandDrawerController` 管理，因为它依赖手牌抽屉的区域定位。
- 法术表现通过卡牌或 spell action 的 `animation` key 分派。当前支持的 key 包括：`heal`（治疗脉冲）、`medical_practice`（行医：草药光点与苗疆药雾脉冲）、`shield`（护盾屏障）、`arcane`（奥术脉冲）、`arcane_aura`（奥术光环法阵与目标附着脉冲）、`summon`（水蓝召唤法阵与水滴扩散）、`gu_summon`（苗疆蛊术召唤：暗绿蛊雾、蛇形脉冲和蛊光爆散）、`gu_infusion`（励蛊：暗绿色蛊虫注入 + 毒绿力量脉冲）、`gu_life_link`（子母蛊：双目标蛊环与绿色生命线连接）、`thin_burial`（薄葬：暗绿裹布与蛊印庇护脉冲）、`gu_lure`（诱蛊释放：暗绿诱蛊法阵落到目标格）、`gu_trap_trigger`（诱蛊触发：毒红咬合脉冲 + 蛊孢爆散）、`fireball`（火球投射物）、`pyroblast`（放大版火球投射物）、`dark_arrow`（暗箭投射物）、`moonblade`（月刃：银蓝旋刃依次命中第一目标和弹射目标）、`baptism`（洗礼：目标金色治疗脉冲 + 周围圣光冲击）、`resurrection`（复活：默认法术特效，预留独立动画扩展）、`blizzard`（暴风雪：冰蓝色矩形区域覆盖 + 消散特效，走 `play_area_spell_cast()` 专用 AOE 动画入口）。未匹配的 key 走通用法术特效。

## 玩家资源约定

- `PlayerState.resource_score` 表示玩家当前资源分，初始为 0。
- `GameManager.victory_resource_score` 是资源分胜利目标，当前为 80。
- 玩家资源分变化统一通过 `GameManager.award_resource_score()` 或 `PlayerState.gain_resource_score()` 入口完成；前者会在加分后调用 `VictoryResolver` 检查胜利。
- `gain_resource_score` 是通用卡牌效果，当前支持 `target: "destroyer"`、`target: "owner"`、`target: "turn_player"` 和 `target: "current_player"`。这些玩家目标由 `CardEffect` 基类统一解析。`DeathResolver` 在卡牌清空前把 `on_destroyed` 交给 `TriggerResolver`，并把摧毁者 owner 作为上下文传入，因此中立单位也能把资源分给摧毁它的玩家。
- `gain_mana` 复用同一套玩家目标解析，当前用于奥术矿脉被摧毁时给摧毁者增加 1 点法力；后续其他玩家数值类效果也应优先复用基类目标解析，而不是在效果类里重复判断 owner/destroyer/current_player。
- 任意玩家资源分达到 `GameManager.victory_resource_score` 后，`GameManager` 进入 `is_game_over` 状态，清理当前交互并在右上角 HUD 显示获胜者。后续结算画面应从这个状态进入场景流程，而不是让具体卡牌直接切场景。
- `PlayerState.max_mana` 当前只表示法力保留上限，默认是 `PlayerState.MANA_CAPACITY`，也就是 5。
- 每个玩家自己的回合开始时，`mana` 增加 1，最多保留到 5。
- 使用法力会消耗 `mana`；回合开始不会自动回满已经消耗的法力。
- 初始化时所有玩家都是 `0/5`，第一个实际回合开始后变为 `1/5`；第二名玩家第一次轮到自己时也从 `0/5` 增长到 `1/5`。
- `GameManager.spell_turn_mana_cost` 是开启施法回合的费用，标准值为 3；测试模式可以通过 `data/test_config.json` 的 `game_params.spell_turn_mana_cost` 临时覆盖。

## 关键词被动约定

- 静态关键词来自 `CardData.keywords`，判断入口统一走 `CardData.has_keyword()` 或 `CardState.has_keyword()`。
- 关键词带来的基础属性修正集中在 `CardState.apply_keyword_passives()`，在卡牌数据绑定时一次性应用，并写入 `origin` 快照。
- `cavalry` / 骑兵：单位每回合移动力为 3，并且本回合允许同时开启 `move` 与 `attack` 两个行动类别。因此骑兵可以先移动再攻击，也可以先攻击再移动；多次移动仍然消耗移动力，多次攻击仍然消耗攻速。
- `ranged` / 远程：攻击范围由 `AttackAction` 计算。目标集合是自身相邻正面单位、所有友方正面随从、以及所有友方正面随从相邻的正面单位的并集。远程单位击杀远程目标时不触发占领；只有目标在攻击者自身相邻格时，才视为近战攻击并进入占领选择。
- `mobile_assault` / 移动攻击：单位同一回合内可以移动并攻击。它通过 `CardState.apply_keyword_passives()` 增加主行动余量，并允许 `move` 与 `attack` 行动组在同回合共存；它不等同于移动施法，未来移动施法应使用独立关键词或升级效果。
- `flying` / 飞行：单位使用飞行层，可进入外圈边缘格，并可与同格地面单位或建筑共存。飞行移动目标由 `MoveAction` 检查 `GameManager.can_place_aerial_card_on_slot()`；手牌放置由 `HandPlayResolver.can_place_minion_on_target()` 转入飞行层；翻开飞行随从时由 `RevealResolver` 调用 `GameManager.promote_ground_flying_to_aerial()`，先把飞行单位提升到飞行层，再补回地面牌池。
- `can_attack_with_zero_attack`：允许 0 攻单位发起攻击，仅用于依赖 `after_attack` 被动的单位。是否真的有收益由该单位的触发效果决定。
- `magic_immune` / 魔法免疫：单位不能成为法术牌、随从施法和区域法术的可选目标；法术效果结算时也会在 `CardEffect.get_target_states()` 再次过滤魔免单位，确保 AOE、自动施法和未来新增法术型效果不会影响它。新增法术目标规则时优先扩展 `SpellTargetResolver`，不要在具体卡牌中写死魔免判断。

## 面向未来的架构方向

- 卡牌类型不要在规则层和 UI 层直接比较 JSON 字符串。类型语义统一通过 `CardData.is_minion()`、`CardData.is_spell()`、`CardData.is_building()`、`CardData.is_upgrade()` 和 `CardState` 的同名状态方法读取。
- 当前行动系统只给随从注册移动和攻击。未来加入建筑时，建筑可以作为 `is_unit()` 留在棋盘上，但不注册移动行动；是否能攻击、防守、被选择，应由对应行动决定。
- 建筑默认不可移动、不可主动操作。攻击目标使用 `CardState.is_unit()` 判断，因此建筑可以被攻击和摧毁；近战摧毁建筑可以触发占领，行动来源、远程锚点和绿色可行动提示仍限制在随从上。
- 法术牌、升级牌和装备牌走翻开后的 Reveal/Zone 路由：翻开成功后进入对应玩家手牌，原格子腾空后调用统一补位入口。归属校验仍先于区域路由执行，因此自己种族和中立牌库的手牌类卡牌可以进入手牌，敌方种族的手牌类卡牌会扣回背面；随从、建筑仍进入棋盘并归属。建筑可以被攻击和被摧毁，但当前不作为施法目标；伤害法术等默认应使用 `all_minions` 这类随从目标规则，不要因为文案写“单位”就放宽到建筑。
- 手牌类卡牌进入手牌前会先播放从棋盘卡位飞向手牌抽屉对应区域的表现动画；动画完成后才更新 `PlayerState.hand`、清空棋盘格并触发补位。
- 公共牌池未来会演进为分级供应池，例如 `TieredCardPool` 或 `SupplyDeck`：内部持有 1/2/3 级牌池，`BoardSlotResolver` 只向它请求下一张牌，不关心当前消耗到哪个等级。
- 玩家区域会从当前 `hand/deck/discard/graveyard` 字段逐步变成更明确的 Zone 概念。建议所有“入手牌、使用手牌、入坟场、弃牌、英雄复活进手牌、召回”都走统一区域方法，不直接在行动或 UI 中改数组。
- 击杀后的占领目前是 `GameManager.resolve_attack_kill()` 内的攻击后结算，选择弹窗已经拆到 `AttackOccupyChoiceController`。若后续出现掠夺、连击、击杀得分、阵营特性，建议抽成“行动后副作用/事件结算器”，由攻击行动发出上下文，再按规则链处理。亡语和摧毁后资源分不属于占领副作用，统一走 `TriggerResolver`。
- 资源分胜利条件作为独立胜负检查流程存在于 `VictoryResolver`。击杀中立单位只负责增加资源分，资源变化后统一检查是否达到 `GameManager.victory_resource_score`，不要把胜负逻辑写进某张牌或某个行动。
- 入口界面、种族选择和结算画面应作为场景流程层处理。战局内脚本只接收已经确定的玩家种族、牌池配置和初始规则，避免战斗逻辑依赖菜单 UI。
- 入口选择页不要直接拼接战斗牌池，也不要修改棋盘状态。它只产出 `MatchSetup` 结果；牌池构建仍由战斗初始化阶段的 `GameManager` / `CardPool.from_match_selection()` 完成。
- `GameManager` 目前仍是合适的战局编排者；翻牌区域路由已经拆到 `RevealResolver`，死亡/攻击击杀后结算拆到 `DeathResolver`，手牌交互编排拆到 `HandInteractionController`。后续复杂度上来后，优先继续拆出 `ZoneManager`、`HeroLifecycleResolver`、`PostActionResolver`、`VictoryResolver` 这类协作者；UI 和动画继续交给独立 Controller。

## 扩展约定

- 新增或修改卡牌数据：先运行 `python tools/validate_cards.py`，再运行 JSON 和 Godot 校验。校验器只检查数据结构、引用和资源路径，不替代规则测试；如果新增了合法的 target rule、effect id、status tag、animation key，应优先把运行时代码里的常量或注册补齐，而不是在数据里绕过校验。
- 新增行动：放在 `scripts/actions`，继承 `CardAction`。
- 新增行动目标规则：实现该行动的 `get_valid_targets()`，由 `InteractionManager` 统一标记目标；如果需要相邻、正面单位、正面随从等棋盘通用查询，优先复用 `BoardQuery`。
- 新增卡牌效果：放在 `scripts/effects`，继承 `CardEffect` 并注册到 `EffectRegistry`。
- 新增效果配置字段、触发名或手牌 active zone 语义：优先补到 `EffectData`，再让具体 resolver 使用，不要在多个模块里直接写同一个字符串。
- 新增状态：优先用 `apply_status` 写入 `CardStatus`；如果状态需要影响行动、受伤或回合时点，再新增专门 resolver 或在对应规则入口读取 `CardState.has_status()` / `get_status()`；如果只是持续视觉表现，优先扩展 `CardStatusOverlay`。如果状态有明确数值（毒性总伤害、护盾值、未来燃烧层数等），优先扩展 `Card` 的状态数字栈，放在血量图标上方纵向排列。
- 新增状态触发效果：优先把效果写入状态 `payload.trigger_effects`，由 `EffectRegistry.execute_status_triggers()` 统一结算；如果效果需要知道是哪一层状态触发，读取 `EffectData.get_trigger_status()`，不要通过 `status_id` 全局猜测。
- 新增状态施加修正升级牌：使用 `modify_applied_status`，通过 `status_ids` 指定影响哪些状态；需要压缩持续伤害时可配置 `set_duration_turns` 和 `preserve_total_damage`。这类规则应走 `StatusModifierResolver`，不要在具体状态效果或卡牌名里写死。
- 新增控制状态（眩晕、定身等）：只需在 JSON 中配置 `"status_tags": ["action_prevention"]`，`CardState` 的 `has_status_with_tag(TAG_ACTION_PREVENTION)` 已注册到所有行动门控，零代码改动。不要为每个控制状态写专用的 `is_xxx()` 判断方法。
- 新增 AOE 形状（5×5、十字等）：在 `SpellTargetResolver` 新增规则常量和 `is_area_rule()`/`get_area_dimensions()` 映射；如需非矩形形状，在 `BoardQuery` 新增对应静态方法。交互层和效果层通过 `get_area_dimensions()` 和效果 JSON 中的 `area_rows`/`area_cols` 自动适配。
- 新增 UI 菜单按钮：优先从 `ActionRegistry.get_available_actions()` 动态生成。
- 新增状态字段：优先放到 `CardState` 或 `PlayerState`，避免散落在节点脚本中。
- 新增手牌内状态：优先放到 `HandCardState`，例如手牌冷却、来源、标签、手牌归属、可使用状态，不要塞进棋盘专用的 `CardState.slot_index` 流程；如果状态需要跨区域长期跟随，再考虑演进为更完整的 `CardInstance`。
- 新增衍生牌：在对应种族的 `tokens[]` 字段下添加卡牌定义，由 `CardDatabase` 自动注册到全局查表。生成衍生牌的效果使用通用 `add_card_to_hand` 效果并指定 `card_id`，需要多张时配置 `amount`；需要三选一或多选奖励时使用 `choose_card_to_hand`、`card_ids` 和 `bonus_cards`；不要在效果或行动中手动构造 CardData。
- 新增手牌法术：在卡牌自身配置 `type: "spell"`、`target_rule`、`animation` 和 `effects`，由 `HandPlayResolver` 解释；不要把手牌法术写成随从的 `spell_actions`。如果它属于某个英雄，把卡牌 id 放入该英雄的 `heroes[].attached_cards`，不要在规则层写死卡牌名。
- 新增手牌法术修正升级牌：使用 `modify_hand_spell_effects`，通过 `card_ids` 指定影响的手牌法术，通过 `target_relation` 指定目标关系（`friendly` / `enemy` / `any`），再配置 `replace_effects` 或 `append_effects`。这类规则应走 `HandSpellModifierResolver`，保持法术静态数据、升级牌数据和手牌执行流程分离。
- 新增动态授予法术：优先扩展 `GrantedSpellResolver` 和 `PlayerState` 中的施法历史，不要在 `ActionRegistry` 或 UI 层根据卡牌名临时拼动作。像“学习最近一次法术”这种规则使用 `grant_last_spell_action`、`card_ids` 和 `source_card_ids` 配置。
- 新增动态授予单位触发效果：使用 `grant_unit_trigger_effects`、`card_ids`、`granted_trigger` 和 `granted_effects`，由 `GrantedUnitTriggerResolver` 在 `TriggerResolver` / `EffectRegistry.execute_trigger()` 之后统一结算；不要把升级牌授予的攻击附带效果写进 `AttackAction` 或随从静态 `effects`。
- 新增法术强度：装备或其他区域效果使用 `modify_spell_power`。法术施放入口通过 `EffectData.mark_spell_power_enabled()` 给运行时效果打标，`CardEffect.get_spell_scaled_amount()` 统一读取玩家装备法强；回合触发、亡语、建筑治疗等非施法效果不会自动吃法强。默认加成 `damage`、`heal`、`shield`、`increase_max_health` 这类直接数值法术效果，如需某个效果不吃法强，可配置 `spell_power_scaling: false`。
## 种族运行时状态

- 某些种族可以拥有自己的运行时状态，例如暗夜精灵哨兵的“时间”循环。该类状态属于玩家种族状态，不属于单张战场卡牌状态，因此保存在 `PlayerState`，而不是 `CardState.statuses`。
- 静态配置写在 `data/cards.json` 的种族字段 `runtime_state` 中。当前字段包括：`id`、`name`、`default_state_id`、`advance_trigger` 和 `cycle`。`cycle` 中的每个节点包含 `id`、`name`、`card_id`，其中 `card_id` 指向一张 `type: "time"` 的展示卡。
- `CardDatabase.get_faction_runtime_state_config()` 只负责读取配置；`PlayerState.setup_faction_runtime_state()` 初始化当前状态；`PlayerState.advance_faction_runtime_state()` 推进状态。回合流程由 `GameManager.advance_faction_runtime_state_for_player()` 在对应触发点调用。
- 当前暗夜精灵哨兵配置为：日出 -> 正午 -> 黄昏 -> 月升 -> 满月 -> 月落，并在该玩家自己的回合结束后推进到下一状态。回合结束触发效果仍先按旧状态结算，随后再推进时间。
- 种族状态展示由 `FactionTimePanelController` 管理。它只读取玩家当前状态和对应展示卡图，不参与规则结算。未来新增天气、仪式、季节等种族循环状态，应复用同一套 `runtime_state` 数据结构和面板入口。
- `type: "time"` 是非牌池展示型卡牌；这类卡可以被 `CardDatabase` 全局查表和 UI 展示，但 `count: 0`，不会进入公共牌池，也不会进入手牌或战场。
## 精准射击与一次性攻击状态

- `精准射击` 是暗夜精灵哨兵英雄泰兰德的英雄配套法术，属于 1 级手牌法术。它不选择棋盘目标，而是给泰兰德本体施加 `status_id: "precision_shot"` 的状态。
- 该状态使用 `payload.trigger_effects` 在 `after_attack` 时点触发，效果目标为 `attack_target_unit`，表示本次普通攻击的目标单位。这样额外伤害不会写死在攻击行动里，后续其他“下一次攻击附加效果”也可以复用同一触发结构。
- 多张 `精准射击` 会叠加到同一状态层数；触发效果配置 `scale_amount_by_status_stacks: true`，结算时会按状态层数放大伤害。触发完成后通过 `consume_on_trigger: true` 移除该状态实例，因此所有层数会在同一次普通攻击中一起释放。
- `is_permanent` 只表示不按回合倒计时，不表示死亡后保留。泰兰德离场、进入英雄复活冷却或状态被驱散时，该状态仍应按普通附着状态处理。
- 持续视觉由 `CardStatusOverlay` 读取当前状态绘制，不属于施法瞬间动画；施法瞬间仍由 `CardAnimationController` 根据卡牌的 `animation` key 处理。

## 种族运行时状态跳转

- `set_faction_runtime_state` 是通用玩家级效果，用于把效果拥有者的种族运行时状态设置到指定 `runtime_state_id`，当前用于暗夜精灵哨兵的 `满月之蔽`。
- 该效果只改 `PlayerState.faction_runtime_state_cycle_index` 指向的当前节点，不修改 `runtime_state.cycle` 本身；因此跳到 `full_moon` 后，后续回合结束仍会按原顺序推进到 `moonset`。
- 新增“跳到日出/跳到月升/进入特定季节”等卡牌时，优先复用这个效果，不要在具体卡牌或 UI 面板里手动改种族时间。
- `满月之蔽` 的施法表现使用 `animation: "full_moon_cover"`，由 `CardAnimationController` 绘制月盘、银蓝光环和星尘扩散；这是施法瞬间动画，不负责维持种族时间面板状态。

## 机械与攻城关键词

- `mechanical` 是单位类型关键词。机械单位不会获得 `poison` 状态，毒性回合结算和剧毒之泉毒爆也会跳过机械单位；治疗入口 `CardState.heal()` 对机械返回 0，因此治疗法术可以正常结算但不会产生有效治疗量。
- `siege_N` 是参数化攻城关键词，当前已有 `siege_3`。普通攻击结算时，如果目标是建筑，`AttackAction.calculate_attack_damage()` 会在攻击力之外追加 `N` 点伤害。
- 新增其他数值的攻城时，优先继续使用 `siege_数字` 命名，并由 `CardData.get_siege_bonus()` 解析，不要为每个攻城数值写独立攻击逻辑。
