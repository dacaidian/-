# War Card 架构说明

快速定位开发文件时，先阅读 `docs/codex-working-map.md`；本文件保留完整架构和规则约定。

## 分层

### 数据层

位置：`scripts/data`

- `CardData`：静态卡牌数据，来自 `data/cards.json`；卡牌所属的数据包通过 `faction_id` 记录，玩家种族包和中立牌库包都走同一读取结构。
- `CardState`：运行时卡牌状态，例如归属、正反面、攻击、生命上限、已受伤害、主行动次数、移动力、攻速/剩余攻击次数、当前状态、交互提示标记；同时保存 `origin`，表示这张具体卡牌进入游戏时的初始属性快照。
- `CardStatus`：附着在棋盘单位上的运行时状态，例如中毒、圣盾、冻结、临时增益等。它记录状态 id、名称、tag、层数、来源、持续时间和到期时点，不直接执行具体规则。
- `PlayerState`：玩家运行时状态，例如所属种族、资源分、翻牌次数、法力、手牌/牌库预留区、独立坟场。
- `CardDatabase`：读取并缓存 JSON 静态数据。
- `CardPool`：公共牌池，负责按 `count` 展开、洗牌、无放回抽取。
- 衍生牌（Token）：不进入牌池、仅由卡牌效果生成的卡牌。在 `cards.json` 中定义在对应种族的 `tokens[]` 字段下，结构和普通卡牌一致。`CardDatabase.load_faction()` 会把 token 注册到 `cards_by_id`（全局可查），但不加入 `cards_by_faction_id`，因此牌池构造链路天然跳过。
- 入口选择会从 `CardDatabase.get_playable_faction_ids()` 读取可选种族，排除 `kind: "neutral_pool"` 的中立牌库；该列表保持 `cards.json` 中的加载顺序，避免默认种族选择被字典排序打乱。英雄列表优先读取种族层级 `heroes` 字段。

原则：数据层只保存和转换数据，不处理玩家点击和 UI。

## 规则层

位置：`scripts/game`、`scripts/actions`、`scripts/effects`

- `GameManager`：战局编排者，管理回合、玩家、棋盘、行动执行入口等核心流程；复杂规则和表现编排通过协作者拆分，避免继续膨胀。
- `MatchSetup`：战局配置数据对象，保存玩家名称、双方选择的种族和英雄，并负责“双方种族不可重复”和开始游戏合法性校验。入口 UI 修改它，战斗场景只读取最终结果。
- `BoardSlotResolver`：棋盘格填充与补位规则协作者，负责从公共牌池抽牌放入空格、清空格子、批量补空格；未来分级牌池或翻开进手牌后的补位策略优先在这里扩展。
- `RevealResolver`：翻牌成功后的归属与区域路由协作者，负责判断当前玩家能否获得这张牌，并决定卡牌留在棋盘、进入手牌还是扣回背面。
- `DeathResolver`：死亡、入坟、销毁和攻击击杀后占领结算协作者。`GameManager` 保留 `check_and_destroy_if_dead()` 等对外入口，具体死亡流程放在这里。
- `TriggerResolver`：触发队列协作者。当前负责排队并结算 `on_reveal`、`on_destroyed`、`on_effective_heal`；后续亡语、受伤、召唤、施法等触发都应优先接入这里。
- `StatusResolver`：状态生命周期协作者。当前负责在回合时点推进临时状态的剩余回合；状态本身保存在 `CardState.statuses`，具体中毒伤害、圣盾抵挡等规则后续通过状态 id/tag 接入。
- `EventContext`：触发名和运行时上下文 key 的常量集合，例如 `TRIGGER_ON_DESTROYED`、`DESTROYER_PLAYER_ID`。规则层和效果层跨模块传上下文时优先使用这里的常量，避免字符串散落。
- `EffectData`：卡牌效果 JSON 的字段名和基础读取工具，例如 `id`、`trigger`、`active_zone`、`card_ids`、`spell_actions`、`target`、`death_reason`、`filter_type`、`filter_owner`、`target_zone`、`amount_source`、`card_id`。它只定义配置语言，不执行效果；解析升级牌、时点触发、目标过滤、复活坟场筛选、上下文数值来源和运行时目标注入时优先使用这里，避免字符串散落。
- `BoardQuery`：棋盘几何和常用目标过滤工具，例如八方向相邻、正面单位、正面随从集合、指定玩家英雄是否正面在场。攻击范围、法术目标、英雄配套牌使用限制、时点光环等规则需要扫描棋盘时优先复用这里，避免每个规则自己计算格子坐标。
- `HandInteractionController`：手牌 UI 与手牌规则之间的交互编排层，负责手牌焦点、可用提示、动作菜单锚点和手牌点击后的动作流转。
- `HandCardState`：手牌运行时状态。旧手牌仍可直接保存 `CardData`，但需要冷却、来源、标签等运行时字段的手牌应保存为 `HandCardState`。当前英雄死亡复活会生成带 `cooldown_turns` 的英雄手牌。
- `HandPlayResolver`：手牌使用规则协作者。当前负责手牌法术的可用性、目标规则、效果结算和消耗手牌，也负责手牌随从放置到棋盘的通用流程；后续装备、升级牌主动使用也优先在这里扩展。
- `HandPassiveResolver`：手牌持续被动规则协作者，统一解析 `while_in_hand` 这类手牌中持续生效的数值修正。当前用于升级牌“金手指”的每回合翻牌上限加成、骑术的移动力覆盖、达拉然法术能量的攻击力光环。
- `SpellTargetResolver`：法术目标规则解释器。随从施法和手牌法术都通过它解释 `target_rule`，避免未来扩展目标限制时出现两套规则。
- `VictoryResolver`：胜负检查协作者。当前检查玩家资源分是否达到胜利目标，后续其他胜利条件也应在这里扩展。
- `ActionHintResolver`：计算空闲状态下哪些己方卡牌应显示绿色可行动提示；后续冻结、沉默、建筑操作等可行动性提示规则优先在这里扩展。
- `InteractionManager`：只管理当前交互状态，例如当前焦点牌、当前选择的行动、合法目标格子。
- `CardAction`：行动基类。
- `MoveAction`：移动行动，检查移动力，计算移动目标，消耗移动力并执行格子交换。
- `AttackAction`：普通攻击行动，登记一次攻击类别并消耗一次攻击次数；通过 attack profile 统一给出目标是否合法、是否近战、是否允许占领，再造成攻击力伤害。
- `SpellAction`：配置化施法行动，从 `CardData.spell_actions` 和手牌升级牌授予的 `spell_actions` 创建；负责法术目标规则、登记 `spell` 行动类别、播放施法动画，并把选中目标交给效果系统。
- `ActionRegistry`：行动注册表，决定一张牌当前拥有哪些行动；它只把静态或授予的 spell data 转成 `SpellAction`，不直接解释升级牌 JSON。
- `GrantedSpellResolver`：授予法术解析器，负责从当前玩家手牌升级牌中读取 `grant_spell_actions`，并根据 `card_ids` 判断哪些随从获得这些法术。
- `AddCardToHandEffect`：通用效果，通过 `card_id` 从 CardDatabase 查卡并置入效果归属玩家手牌。用于衍生牌、奖励牌等不进入牌池的卡牌获取。
- `EffectRegistry`：效果注册表，负责触发 JSON 中配置的卡牌效果，并统一转发效果的施放前可用性判断。已注册效果包括 `heal`、`damage`、`shield`、`increase_max_health`、`set_attack_to_current_health`、`gain_flips`、`gain_resource_score`、`gain_mana`、`gain_attack`、`play_spell_action`、`apply_status`、`resurrect`、`add_card_to_hand`。玩家级效果统一通过 `CardEffect.get_target_player_id()` / `get_target_player()` 解析目标玩家，避免资源、法力、未来金币等效果各自维护一套 target 规则。触发上下文合并统一使用 `EffectData.duplicate_with_context()`，运行时法术目标注入统一使用 `EffectData.mark_selected_target()`；手牌法术会额外注入效果拥有者，供“目标周围敌方单位”这类规则判断敌我。
- 死亡解析：外部仍调用 `GameManager.check_and_destroy_if_dead()` / `destroy_card()`，内部委托 `DeathResolver` 统一处理死亡或销毁；死亡不作为玩家动作显示在动作菜单中。

原则：新增攻击、施法、技能时，优先新增一个 `CardAction` 子类，再注册到 `ActionRegistry`。行动自己决定 `can_start()`、`get_valid_targets()` 和 `execute()`，不要把行动规则写进 UI。需要目标的行动只有在存在合法目标时才会显示在动作菜单中。行动基类提供通用判断，例如 `is_controlled_face_up_minion()`，避免每个行动重复写当前玩家归属和随从检查。

## 表现层

位置：`scenes`、`scripts/ui`

- `Card`：只负责卡牌显示、翻牌动画、背光提示、点击信号和棋盘数值图标。血量与护盾显示在右下角，攻击显示在左下角；攻击数字从卡牌正面图所属种族目录下的 `攻击数字/{attack}.png` 加载。数值图标节点的创建和资源设置集中在 `create_value_texture()` / `set_value_texture()`，避免每新增一个图标都复制一套 TextureRect 初始化。
- `CardStatusOverlay`：负责棋盘卡牌上的持续状态覆盖表现。当前读取 `CardState.statuses` 绘制圣盾金色圣光盾；未来中毒、冻结、沉默等持续视觉优先扩展这里，不要继续塞进 `Card` 主脚本。
- `StartMenu`：游戏入口选择页。它只负责双方玩家选择种族和英雄，保证两名玩家不能选择相同种族；点击开始后实例化战斗场景并把 `player_faction_ids`、`selected_hero_card_ids` 传给 `GameManager`。
- `CardBoard`：只负责 5x5 棋盘布局和响应窗口尺寸变化。
- `DebugPanel`：只负责展示运行时状态；面板可一键收起为右上角小按钮，避免遮挡棋盘和右侧展示区。
- `ActionMenuController`：负责动作菜单 UI 的创建、显示、定位和按钮事件。
- `CardPoolViewController`：负责公共牌池的表现，例如固定牌堆节点绑定、剩余数量显示、补位飞牌动画。
- `TurnStatusController`：负责右上角当前回合铭牌，显示当前玩家、种族和回合数；它是正式 HUD，不依赖 DebugPanel。
- `HandDrawerController`：负责左侧手牌抽屉表现，按当前回合玩家展示其手牌池，并预留法术牌、随从牌、升级牌、装备牌四个区域；抽屉高度会随视窗刷新，每个区域内部用滚动容器承载手牌，避免手牌数量增长时溢出边框；同时负责翻牌入手牌的飞行动画、手牌卡悬浮预览和手牌点击信号，不处理手牌使用规则。
- `EquipmentDisplayController`：负责右侧当前玩家装备展示区，读取 `PlayerState.get_equipped_cards()` 展示当前生效装备、装备类型和悬浮大图预览；只做展示，不参与装备规则。
- `CardAnimationController`：负责卡牌交换、攻击、远程投射物、施法特效、占领移动等卡牌表现动画；规则层只通过 `GameManager` 的动画入口间接调用它。
- `AttackOccupyChoiceController`：负责攻击击杀后”是否占领”的选择弹窗，`GameManager` 只关心选择结果和后续规则结算。
- `CardMultiSelectController`：通用卡牌多选面板。不绑定任何特定区域或卡牌语义；调用方传入标题、待选卡牌列表和最大可选数量，面板展示卡牌缩略图、名称和数值，用户通过复选框多选后点击确认。当前用于坟场复活选择，未来可复用于牌库发现、手牌弃置、坟场放逐等场景。

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
   - 当前玩家先在右上角 HUD 点击“开启施法”并消耗法力。测试阶段费用为 1，标准规则目标为 3。
   - 施法回合开启后，`ActionRegistry` 才会从当前随从的 `CardData.spell_actions` 和当前玩家手牌升级牌授予的 `spell_actions` 动态创建 `SpellAction`。
   - `SpellAction` 根据 `target_rule` 计算合法目标，当前 `all_minions` 表示所有正面随从。
   - 点击目标后登记 `spell` 行动类别，通过 `GameManager.play_spell_cast_animation()` 委托 `CardAnimationController` 播放表现，再执行配置中的效果。
   - 当前已配置的随从法术包括：牧师的治疗术，目标规则为 `all_minions`，治疗目标 7 点生命；火焰女巫的火球术，目标规则为 `all_minions`，对目标造成 6 点伤害；冰霜女巫的冰霜护盾，目标规则为 `all_minions`，使目标获得 6 点护盾；奥术法师的奥术智慧，目标规则为 `none`，使当前玩家本回合额外获得 2 次翻牌。
14. 玩家使用手牌法术：
	- `HandDrawerController` 只发出手牌点击信号，`HandInteractionController` 记录焦点与菜单锚点，并把当前玩家和卡牌数据交给 `HandPlayResolver`。
	- 点击可用手牌先进入和棋盘卡一致的焦点态；手牌卡显示金色焦点柔光，动作菜单显示“施放”。
	- 点击“施放”后，`HandPlayResolver` 根据手牌牌自己的 `target_rule` 计算目标，并通过 `InteractionManager.start_hand_card_target_selection()` 进入和棋盘行动相同的目标选择模式。
	- 手牌随从会显示“放置”动作。放置目标为棋盘空格或未翻开的背面牌；若放到背面牌上，该背面牌先返回公共牌池，再将手牌随从正面放入目标格并归属当前玩家。
	- 合法目标仍写入 `CardState.is_valid_target`，所以白色背光、右键/Esc 取消、点击目标结算都和移动/攻击/随从施法共用一套交互。
	- 目标选择阶段右键或 Esc 会退回这张手牌的焦点态和动作菜单；再次点击已选中的手牌或动作菜单取消按钮会回到空闲状态。
	- 手牌动作菜单定位使用点击瞬间记录的手牌卡全局矩形，而不是刷新后的 UI 节点；这样同名手牌、手牌重排和抽屉重绘不会让菜单错位到第一张牌。
	- 当前第一张手牌法术是中立法术牌“草药”：目标规则为 `all_minions`，点击一个正面随从后播放治疗表现，恢复 5 点生命，并从当前玩家手牌中消耗。
15. 玩家获得手牌升级牌：
	- 升级牌、法术牌、装备牌都通过 `RevealResolver` 在翻开成功后进入当前玩家手牌，并腾空原棋盘格补牌。
	- 手牌持续被动由 `HandPassiveResolver` 统一刷新，不放在 `PlayerState` 中硬编码具体卡牌 id。
	- 当前中立升级牌“金手指”：`type: "upgrade"`，`trigger: "while_in_hand"`，`effect id: "modify_flip_capacity"`，每张使玩家每回合可翻牌上限 +1。
	- 手牌持续单位光环也由 `HandPassiveResolver` 统一刷新。当前白银之手“骑术”使用 `set_unit_movement` + `card_ids: ["knight"]`，使己方战场骑士移动力变为 5；达拉然议会“初级/中级/终极法术能量”使用 `modify_unit_attack` + `card_ids`，使指定法系单位攻击力 +1。新单位翻开归属后会重新刷新该玩家手牌光环。
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
- 当前等级定义：1 级为乌瑟尔、受祝福的步兵、信仰圣光、安东尼达斯、法师学徒、初级法术能量、召唤水元素、金手指、小型矿脉、生命之泉、无中生有、草药；2 级为牧师、骑士、真言术·盾、骑术、火焰女巫、冰霜女巫、奥术法师、中级法术能量、中型矿脉、奥术矿脉、暗箭、无中生有生有；3 级为奥术傀儡、战斗牧师、心灵之火、终极法术能量、炎爆术、复活术、光明使者之锤、大型矿脉、超大型矿脉。
- `CardPool.from_match_selection()` 是战斗牌池构建入口：玩家种族牌通过 `CardDatabase.build_weighted_pool_for_selection()` 加入，中立牌库仍通过普通 `build_weighted_pool()` 加入。
- 玩家种族牌池构建会根据 `selected_hero_card_ids` 过滤英雄：只加入选中的英雄，不加入同种族未选英雄。`heroes[].attached_cards` 中列出的子卡牌只会在对应英雄被选中时加入，避免未来多个英雄包互相污染。

## 回合时点触发

- 回合时点触发统一由 `TurnTriggerResolver` 收集，再交给 `TriggerResolver` 和 `EffectRegistry` 执行；不要把具体卡牌效果写进 `GameManager.end_turn()`。
- 当前支持两个公共时点：`before_turn_start` 和 `after_turn_end`。`after_turn_end` 在刚结束回合玩家执行 `PlayerState.end_turn()` 后触发；`before_turn_start` 在下一名玩家执行 `PlayerState.start_turn()` 前触发。
- 时点触发上下文会注入 `EventContext.TURN_PLAYER_ID`，表示该时点对应的玩家。效果需要判断“当前回合玩家”时应读取这个上下文，而不是猜测来源牌归属。
- 回合时点触发源来自战场上所有正面牌，按 `slot_index` 从小到大稳定入队。每张牌是否触发由自身 `effects[].trigger` 决定。
- 手牌中的升级牌也可以成为回合时点效果来源，但必须显式配置 `active_zone: "hand"`。`TurnTriggerResolver` 会在战场时点触发后，结算当前回合玩家手牌中满足该时点的升级牌效果；具体效果仍交给 `EffectRegistry`。
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
- 背光优先级由 `Card` 统一处理：焦点 > 合法目标 > 可行动。
- `GameManager._on_interaction_changed()` 统一触发行动提示和调试面板刷新，行动提示具体计算交给 `ActionHintResolver`。
- `GameManager.is_game_busy()` 统一判断翻牌动画、移动/攻击动画和行动结算是否正在进行；忙碌期间忽略新的点击、右键取消和结束回合，降低异步动画带来的竞态。
- 右键取消约定：焦点状态下右键回到非焦点状态；目标选择状态下右键或 Esc 退回焦点状态和动作菜单。动作菜单的取消按钮、再次点击焦点牌仍然保留。

## 效果目标约定

- `target` 为空的目标型手牌法术或随从法术，会在执行前由 `EffectData.mark_selected_target()` 默认注入为 `selected`。
- 如果一张牌的多段效果需要不同目标，应在对应效果上显式写 `target`；运行时仍会保存选中目标上下文，但不会覆盖显式目标。
- `selected_adjacent_enemy_minions` 表示：以本次选中的目标为中心，取其 8 方向相邻、正面、敌方、类型为随从的单位。敌我判断优先使用效果拥有者；手牌法术会由 `HandPlayResolver` 注入拥有者，棋盘法术则使用来源随从 owner。

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
- `CardStatus` 的核心字段包括：`status_id`、`display_name`、`tags`、`stacks`、`is_permanent`、`remaining_turns`、`duration_scope`、`expires_on_trigger`、`source_card_id`、`source_owner_id`、`duration_owner_id` 和 `payload`。
- 永久状态使用 `permanent: true` 或不配置 `duration_turns`；临时状态配置 `duration_turns`。当前默认在 `after_turn_end` 时点减少持续回合。
- `duration_scope` 决定临时状态按谁的回合倒计时：默认 `target_owner`，也支持 `source_owner` 和 `global`。`target_owner` 会在状态施加时记录目标当时的 owner，避免后续归属变化导致倒计时漂移。
- `apply_status` 是通用施加状态效果。配置示例：`{"id":"apply_status","status_id":"poison","status_name":"中毒","duration_turns":2,"target":"selected","status_tags":["damage_over_time"]}`。它只负责把状态写入目标，具体中毒伤害、圣盾抵挡、冻结禁用行动等规则应由对应状态 resolver 或行动/效果读取状态后处理。
- 当前圣盾使用 `status_id: "divine_shield"`，属于永久但可消耗状态。`CardState.take_damage()` 在数值护盾和生命结算前会先消耗一层圣盾并完全抵消本次伤害效果；多层圣盾逐层消耗，最后一层消耗后从状态列表移除。
- 圣盾的持续视觉不属于施法动画，而是状态覆盖表现：`CardStatusOverlay` 读取目标当前状态并绘制金色圣光盾。一次性施法动画仍由 `CardAnimationController` 管理。
- 同一来源、同一 `status_id` 的状态会合并层数；永久状态合并后保持永久，临时状态合并后保留更长剩余回合。未来如果需要“同名不同来源互斥”“刷新不叠层”等规则，应在 `CardStatus.is_same_stack_key()` 或状态定义中扩展。
- `StatusResolver` 会在 `GameManager.resolve_turn_timing_triggers()` 的时点触发结算之后推进状态生命周期。这样到期前的状态仍可参与该时点触发，随后再过期。

## 行动资源约定

- `CardState.max_movement` / `current_movement` 表示每回合移动力。
- `CardState.max_attack_speed` / `current_attacks` 表示攻速和当前剩余攻击次数。
- `CardState.max_main_actions` / `current_main_actions` 表示本回合还能开启多少个新的行动类别，而不是还能执行多少次动作。
- `CardState.used_action_groups` 记录本回合已经开启的行动类别，例如 `move`、`attack`、`spell`。同一类别已经开启后，可以继续消耗自己的次数资源，例如多次移动或多次攻击。
- `CardState.allowed_action_group_pairs` 记录允许同时使用的行动类别组合。普通随从默认没有组合，所以移动、攻击、施法三选一；未来“移动攻击”“移动施法”“战斗法师”可以通过开放 `move|attack`、`move|spell`、`attack|spell` 组合实现。
- 所有随从默认主行动 1、移动力 1、攻速 1；非随从为 0。
- 当前玩家回合开始时，`GameManager.restore_minion_actions_for_player()` 清空行动类别锁，并恢复该玩家随从的移动力和攻击次数。
- `CardAction.action_group` 表示行动所属类别，`main_action_cost` 表示是否需要登记类别，默认是 1。当前移动属于 `move`，攻击属于 `attack`。
- `CardAction.can_reuse_action_group` 表示同一个行动类别在本回合是否可以重复执行。移动和攻击依靠移动力/攻速限制，所以可以重复；施法当前没有独立次数资源，所以治疗术不可重复施放。
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

## 英雄、手牌与冷却设计约定

- 英雄是特殊随从，仍然属于可在棋盘上存在的单位，但英雄身份不依赖 `keywords`。静态数据使用明确字段 `role: "hero"`，并由 `CardData.is_hero()` / `CardState.is_hero()` 统一判断。
- `keywords` 只用于描述能力或标签，例如 `ranged`、`cavalry`、`magic_immune`。英雄卡牌不再在 `keywords` 中写入 `hero` 标识，避免“身份”和“能力”混在一起。
- 每个种族一场游戏只会使用一个英雄。一个种族可以有多个可选英雄，但英雄选择属于进入战局前的配置流程，后续再开发。
- 英雄选择已经由入口页 `StartMenu` 负责。当前双方玩家各自选择一个种族和一个英雄，默认英雄是种族 `heroes` 中的第一个条目。
- 英雄配套牌在种族层级定义，而不是写进英雄随从卡本身。当前 `cards.json` 使用 `heroes` 字段，每个条目通过 `card_id` 指向英雄卡牌，并预留 `attached_cards` 保存配套法术牌、武器牌等；牌池构建时只加载已选英雄的 `attached_cards`，加载后会把对应 `CardData.owner_hero_card_id` 标记为所属英雄。
- 英雄配套牌的使用限制统一在手牌规则层处理：只要手牌牌带有 `owner_hero_card_id`，释放时就要求该玩家对应英雄当前正面在战场上。这样未来英雄法术、英雄武器、英雄专属随从都能复用同一条规则。
- 当前乌瑟尔英雄配套牌包括：1 级 `圣盾术`，目标规则为 `all_minions`，使一个随从获得可消耗圣盾；2 级 `洗礼`，目标规则为 `all_minions`，治疗选中随从 4 点生命，并对选中随从 8 邻接范围内的敌方随从造成 4 点伤害；3 级 `复活术`，从己方坟场选择最多 6 个随从移入手牌（使用通用 `resurrect` 效果和 `CardMultiSelectController` 多选面板）；3 级武器 `光明使者之锤`，装备后乌瑟尔攻击后会自动以自身为目标释放 `洗礼`。
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
- 每个 spell action 至少包含 `id`、`name`、`target_rule` 和 `effects`；可选 `animation` 用于指定表现层动画 key。
- 法术目标规则由 `SpellTargetResolver` 统一解释。当前常用 `all_minions` 和 `none`；`all_minions` 只选正面随从，`none` 表示无目标法术，点击动作菜单后直接结算。`all_units` 解析能力仍保留给未来明确允许影响建筑的机制，但当前普通施法不应使用它。后续“不能选英雄”“只能选建筑”“只选友方”等规则应在这里扩展。
- 法术效果复用 `EffectRegistry`，治疗、伤害、护盾、翻牌次数等公共效果不和某个法术绑定。`SpellAction` 会通过 `EffectData.mark_selected_target()` 把选中的目标以 `selected` 注入运行时效果数据；效果自身负责执行规则变化，可能导致死亡的效果也负责调用死亡检查。
- 效果可用性也属于效果系统：`CardEffect.can_execute()` 默认返回可用，特殊效果可以覆写它，例如复活效果会检查坟场候选和目标区域。`HandPlayResolver` 不应按具体效果类型写分支，而是注入施法者上下文后调用 `EffectRegistry.can_execute_effect()`。
- `GameManager.play_spell_cast_animation()` 是规则层保留的法术视觉入口；具体表现由 `CardAnimationController` 按 spell action 的 `animation` 分派。当前治疗术使用 `heal` 绿色治疗脉冲，火球术使用 `fireball` 橙红色投射物和命中反馈，炎爆术使用 `pyroblast` 放大版火球投射物，冰霜护盾使用 `shield` 蓝色屏障脉冲，奥术智慧使用 `arcane` 紫蓝色奥术脉冲；未来可以让多个法术复用同一种表现 key。
- 手牌法术不消耗法力水晶，也不要求进入“施法回合”；它消耗的是手牌本身。手牌法术的 `target_rule` 和 `animation` 写在卡牌自身数据上，效果仍复用 `EffectRegistry`。`HandPlayResolver` 与 `SpellAction` 都通过 `SpellTargetResolver` 获取目标，后续目标规则只在一个地方扩展。
- 英雄配套手牌由 `CardData.owner_hero_card_id` 标记。它来自种族 `heroes[].attached_cards`，不是每张牌单独写死判断。`HandPlayResolver` 在手牌绿光、动作菜单和实际执行前统一检查：所属玩家的对应英雄必须正面在战场上，否则这张英雄配套牌不能释放；具体棋盘扫描通过 `BoardQuery.has_face_up_hero()` 完成。

## 动画与表现约定

- `GameManager` 可以保留语义化动画入口，例如 `play_card_attack_animation()`、`play_spell_cast_animation()`、`play_hand_spell_card_animation()`、`play_card_to_hand_animation()`，供行动、效果和区域路由调用。
- 具体 tween、投射物、特效面板、层级和样式应放在 `CardAnimationController` 或更细的表现控制器中。
- 动画控制器只操作 `Card` 节点和临时表现节点，不直接修改 `CardState`、`PlayerState`、坟场、牌池等规则数据。
- 如果动画结束后需要改变规则状态，由 `GameManager` 在 `await` 动画之后统一处理，例如交换内容、造成伤害、入坟或补位。
- 覆盖层动画统一通过 `GameManager.get_overlay_animation_root()` 获取根节点。补位飞牌仍归 `CardPoolViewController` 管理，因为它依赖公共牌池固定视图；手牌飞入归 `HandDrawerController` 管理，因为它依赖手牌抽屉的区域定位。
- 法术表现通过卡牌或 spell action 的 `animation` key 分派。当前支持的 key 包括：`heal`（治疗脉冲）、`shield`（护盾屏障）、`arcane`（奥术脉冲）、`fireball`（火球投射物）、`pyroblast`（放大版火球投射物）、`dark_arrow`（暗箭投射物）、`baptism`（洗礼：目标金色治疗脉冲 + 周围圣光冲击）、`resurrection`（复活：默认法术特效，预留独立动画扩展）。未匹配的 key 走通用法术特效。

## 玩家资源约定

- `PlayerState.resource_score` 表示玩家当前资源分，初始为 0。
- `GameManager.victory_resource_score` 是资源分胜利目标，当前为 80。
- 玩家资源分变化统一通过 `GameManager.award_resource_score()` 或 `PlayerState.gain_resource_score()` 入口完成；前者会在加分后调用 `VictoryResolver` 检查胜利。
- `gain_resource_score` 是通用卡牌效果，当前支持 `target: "destroyer"`、`target: "owner"`、`target: "turn_player"` 和 `target: "current_player"`。这些玩家目标由 `CardEffect` 基类统一解析。`DeathResolver` 在卡牌清空前把 `on_destroyed` 交给 `TriggerResolver`，并把摧毁者 owner 作为上下文传入，因此中立单位也能把资源分给摧毁它的玩家。
- `gain_mana` 复用同一套玩家目标解析，当前用于奥术矿脉被摧毁时给摧毁者增加 1 点法力；后续其他玩家数值类效果也应优先复用基类目标解析，而不是在效果类里重复判断 owner/destroyer/current_player。
- 任意玩家资源分达到 80 后，`GameManager` 进入 `is_game_over` 状态，清理当前交互并在右上角 HUD 显示获胜者。后续结算画面应从这个状态进入场景流程，而不是让具体卡牌直接切场景。
- `PlayerState.max_mana` 当前只表示法力保留上限，默认是 `PlayerState.MANA_CAPACITY`，也就是 5。
- 每个玩家自己的回合开始时，`mana` 增加 1，最多保留到 5。
- 使用法力会消耗 `mana`；回合开始不会自动回满已经消耗的法力。
- 初始化时所有玩家都是 `0/5`，第一个实际回合开始后变为 `1/5`；第二名玩家第一次轮到自己时也从 `0/5` 增长到 `1/5`。
- `GameManager.spell_turn_mana_cost` 是开启施法回合的费用。当前为了测试是 1；两个种族施法验证完成后应改回标准值 3。

## 关键词被动约定

- 静态关键词来自 `CardData.keywords`，判断入口统一走 `CardData.has_keyword()` 或 `CardState.has_keyword()`。
- 关键词带来的基础属性修正集中在 `CardState.apply_keyword_passives()`，在卡牌数据绑定时一次性应用，并写入 `origin` 快照。
- `cavalry` / 骑兵：单位每回合移动力为 3，并且本回合允许同时开启 `move` 与 `attack` 两个行动类别。因此骑兵可以先移动再攻击，也可以先攻击再移动；多次移动仍然消耗移动力，多次攻击仍然消耗攻速。
- `ranged` / 远程：攻击范围由 `AttackAction` 计算。目标集合是自身相邻正面单位、所有友方正面随从、以及所有友方正面随从相邻的正面单位的并集。远程单位击杀远程目标时不触发占领；只有目标在攻击者自身相邻格时，才视为近战攻击并进入占领选择。

## 面向未来的架构方向

- 卡牌类型不要在规则层和 UI 层直接比较 JSON 字符串。类型语义统一通过 `CardData.is_minion()`、`CardData.is_spell()`、`CardData.is_building()`、`CardData.is_upgrade()` 和 `CardState` 的同名状态方法读取。
- 当前行动系统只给随从注册移动和攻击。未来加入建筑时，建筑可以作为 `is_unit()` 留在棋盘上，但不注册移动行动；是否能攻击、防守、被选择，应由对应行动决定。
- 建筑默认不可移动、不可主动操作。攻击目标使用 `CardState.is_unit()` 判断，因此建筑可以被攻击和摧毁；近战摧毁建筑可以触发占领，行动来源、远程锚点和绿色可行动提示仍限制在随从上。
- 法术牌、升级牌和装备牌走翻开后的 Reveal/Zone 路由：翻开成功后进入对应玩家手牌，原格子腾空后调用统一补位入口。归属校验仍先于区域路由执行，因此自己种族和中立牌库的手牌类卡牌可以进入手牌，敌方种族的手牌类卡牌会扣回背面；随从、建筑仍进入棋盘并归属。建筑可以被攻击和被摧毁，但当前不作为施法目标；伤害法术等默认应使用 `all_minions` 这类随从目标规则，不要因为文案写“单位”就放宽到建筑。
- 手牌类卡牌进入手牌前会先播放从棋盘卡位飞向手牌抽屉对应区域的表现动画；动画完成后才更新 `PlayerState.hand`、清空棋盘格并触发补位。
- 公共牌池未来会演进为分级供应池，例如 `TieredCardPool` 或 `SupplyDeck`：内部持有 1/2/3 级牌池，`BoardSlotResolver` 只向它请求下一张牌，不关心当前消耗到哪个等级。
- 玩家区域会从当前 `hand/deck/discard/graveyard` 字段逐步变成更明确的 Zone 概念。建议所有“入手牌、使用手牌、入坟场、弃牌、英雄复活进手牌、召回”都走统一区域方法，不直接在行动或 UI 中改数组。
- 击杀后的占领目前是 `GameManager.resolve_attack_kill()` 内的攻击后结算，选择弹窗已经拆到 `AttackOccupyChoiceController`。若后续出现掠夺、连击、击杀得分、阵营特性，建议抽成“行动后副作用/事件结算器”，由攻击行动发出上下文，再按规则链处理。亡语和摧毁后资源分不属于占领副作用，统一走 `TriggerResolver`。
- 资源分胜利条件作为独立胜负检查流程存在于 `VictoryResolver`。击杀中立单位只负责增加资源分，资源变化后统一检查是否达到 80 分，不要把胜负逻辑写进某张牌或某个行动。
- 入口界面、种族选择和结算画面应作为场景流程层处理。战局内脚本只接收已经确定的玩家种族、牌池配置和初始规则，避免战斗逻辑依赖菜单 UI。
- 入口选择页不要直接拼接战斗牌池，也不要修改棋盘状态。它只产出 `MatchSetup` 结果；牌池构建仍由战斗初始化阶段的 `GameManager` / `CardPool.from_match_selection()` 完成。
- `GameManager` 目前仍是合适的战局编排者；翻牌区域路由已经拆到 `RevealResolver`，死亡/攻击击杀后结算拆到 `DeathResolver`，手牌交互编排拆到 `HandInteractionController`。后续复杂度上来后，优先继续拆出 `ZoneManager`、`HeroLifecycleResolver`、`PostActionResolver`、`VictoryResolver` 这类协作者；UI 和动画继续交给独立 Controller。

## 扩展约定

- 新增行动：放在 `scripts/actions`，继承 `CardAction`。
- 新增行动目标规则：实现该行动的 `get_valid_targets()`，由 `InteractionManager` 统一标记目标；如果需要相邻、正面单位、正面随从等棋盘通用查询，优先复用 `BoardQuery`。
- 新增卡牌效果：放在 `scripts/effects`，继承 `CardEffect` 并注册到 `EffectRegistry`。
- 新增效果配置字段、触发名或手牌 active zone 语义：优先补到 `EffectData`，再让具体 resolver 使用，不要在多个模块里直接写同一个字符串。
- 新增状态：优先用 `apply_status` 写入 `CardStatus`；如果状态需要影响行动、受伤或回合时点，再新增专门 resolver 或在对应规则入口读取 `CardState.has_status()` / `get_status()`；如果只是持续视觉表现，优先扩展 `CardStatusOverlay`。
- 新增 UI 菜单按钮：优先从 `ActionRegistry.get_available_actions()` 动态生成。
- 新增状态字段：优先放到 `CardState` 或 `PlayerState`，避免散落在节点脚本中。
- 新增手牌内状态：优先放到 `HandCardState`，例如手牌冷却、来源、标签、手牌归属、可使用状态，不要塞进棋盘专用的 `CardState.slot_index` 流程；如果状态需要跨区域长期跟随，再考虑演进为更完整的 `CardInstance`。
- 新增衍生牌：在对应种族的 `tokens[]` 字段下添加卡牌定义，由 `CardDatabase` 自动注册到全局查表。生成衍生牌的效果使用通用 `add_card_to_hand` 效果并指定 `card_id`；不要在效果或行动中手动构造 CardData。
- 新增手牌法术：在卡牌自身配置 `type: "spell"`、`target_rule`、`animation` 和 `effects`，由 `HandPlayResolver` 解释；不要把手牌法术写成随从的 `spell_actions`。如果它属于某个英雄，把卡牌 id 放入该英雄的 `heroes[].attached_cards`，不要在规则层写死卡牌名。
