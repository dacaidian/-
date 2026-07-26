# Codex 工作索引

> Encoding guard: this document must stay valid UTF-8. If Chinese text becomes unreadable or `apply_patch` cannot edit this file, first repair/normalize the file as UTF-8. Do not append around broken bytes.
>
> 中文说明：本文档必须保持 UTF-8。它是以后开发时的快速导航，不是完整架构说明。真正的系统边界看 `docs/architecture.md`。

## 每次先检查

- `git status --short --branch`：仓库可能已有本地提交或用户修改。
- `python tools/validate_cards.py`：修改 `data/cards.json` 后运行。
- `powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1`：修改脚本、场景、玩法或 UI 后运行。该入口会等待 Godot 真正退出并在超时时清理本次进程。
- 多个 Godot 校验命令必须串行运行；不要直接或并行启动 editor、check-only 和主场景，它们会争用 `user://logs` 与导入缓存，并可能留下隐藏进程。
- 每波完成后提交并推送。若 GitHub 无法连接，报告本地 commit hash 和 ahead 数量。
- 新机制先确定唯一 owner：数据模型、action/effect、resolver、对局协调器或 UI controller。若两个层都在判断同一合法性，先收拢边界再加功能。

## 编码规则

文档必须是 UTF-8。如果 markdown 文件乱码或 `apply_patch` 无法编辑，先修复编码，不要继续在坏文件上追加内容。

## 卡牌数据任务

优先读：

- `data/cards.json`
- `scripts/data/card_data.gd`
- `scripts/data/card_database.gd`
- `tools/validate_cards.py`

常见规则：

- 常规卡牌放在种族的 `cards[]`。
- 衍生牌放在对应种族的 `tokens[]`。
- 新增可选种族时，先在 `cards.json` 中加入种族块、`heroes[]` 和至少一张英雄牌；中立牌库必须继续保持最后一个 faction。
- 英雄附属牌必须加入 `heroes[].attached_cards`。
- 同一种族新增可选英雄时，同时维护 `heroes[]` 和英雄卡牌定义；共享升级牌通过效果目标 `card_ids` 显式声明适用英雄，避免英雄选择之间串牌或漏掉共享增益。
- 棋盘展示图和种族选择英雄预览使用同目录同名 `-table.png` 自动覆盖，例如 `牧师.png` -> `牧师-table.png`；没有 table 图时回退原 `url` 卡图。手牌、悬浮预览和装备预览仍使用原图。战场翻开的随从和建筑左上角会自动读取卡图同目录 `logo.png` 作为种族标识。
- `CardData` 的正面、战场和卡背纹理使用惰性属性。数据库加载阶段只保存路径，禁止在 `from_dictionary()` 中批量 `load()` 全部卡图，否则随着 `-table.png` 增长会造成启动内存峰值。
- 指定拥有者英雄/卡牌时，优先使用 `target: "owner_card_by_id"` 加 `target_card_id` 或 `card_ids`。
- 修改后运行 `python tools/validate_cards.py`。

## 新效果

优先读：

- `scripts/game/effect_data.gd`
- `scripts/effects/card_effect.gd`
- `scripts/effects/effect_registry.gd`
- 最接近新行为的已有 effect

常见规则：

- 在 `EffectData` 增加 effect id 和配置键。
- 在 `scripts/effects/` 实现通用效果。
- 在 `EffectRegistry` 注册。
- 效果层只做规则，不做 UI。
- 单位翻开或从手牌放置进入棋盘时触发的效果，使用 `on_enter_board`。
- 友方单位攻击后响应，使用 `after_friendly_attack` 加 `source_card_ids` 过滤。

## 新行动

优先读：

- `scripts/actions/card_action.gd`
- `scripts/actions/action_registry.gd`
- `scripts/game/action_resource_resolver.gd`
- `scripts/game/granted_action_resolver.gd`
- `scripts/game/action_hint_resolver.gd`

常见规则：

- 只有会和移动/攻击/施法互斥的行动，才加入主行动组。
- 主行动次数、移动攻击、施法移动、施法攻击等兼容关系统一放在 `ActionResourceResolver`。
- “选择目标并执行效果”的行动优先使用 `EffectAction`。
- 固定方向无目标移动使用 `DirectionalMoveAction`。
- 合法性判断放在行动/resolver，不放在 UI。

## 手牌

优先读：

- `scripts/game/hand_play_resolver.gd`
- `scripts/game/hand_interaction_controller.gd`
- `scripts/ui/hand_drawer_controller.gd`
- `scripts/data/hand_card_state.gd`
- `scripts/data/player_state.gd`

常见规则：

- 读取手牌条目使用 `HandCardState.get_card_data(entry)`。
- 焦点和行动菜单刷新时保留手牌区域滚动位置。
- 手牌随从放置必须尊重棋盘层级和格子能力。
- 同类型装备替换时，旧装备返回手牌。

## 棋盘与移动

优先读：

- `scripts/data/board_cell.gd`
- `scripts/game/board_query.gd`
- `scripts/game/board_layer_resolver.gd`
- `scripts/game/board_slot_resolver.gd`
- `scripts/game/board_movement_resolver.gd`
- `scripts/actions/move_action.gd`

常见规则：

- 不要假设一个格子只有一张牌。
- 地面/空中层查询、土地格判断、放置与补牌能力优先放在 `BoardLayerResolver`。
- 牌池抽牌、空格补牌、清空格子、等级卡背解析优先放在 `BoardSlotResolver`。
- 地面层和空中层独立。
- 飞行单位可使用外圈和空中层。
- 瞬移允许移动到全场任意合法空目的地。
- 交换单元格时，格子的原始能力必须随格子移动。
- 兽径等单元格地形效果存放在 `BoardCell`，通过 `BoardLayerResolver` 同步到 `CardState` 显示；`CardState.has_beast_path` 只是显示镜像，不属于卡牌内容，不能在 `clear_card()` / `set_card_data(null)` 时清掉。奥术空间交换单元格时必须随 cell 一起移动。野兽人地面随从的兽径移动由 `MoveAction` 查询当前连通兽径图，不消耗主行动力和移动力，但不能绕过行动禁止状态。

## 攻击与伤害

优先读：

- `scripts/actions/attack_action.gd`
- `scripts/actions/mounted_attack_action.gd`
- `scripts/data/card_state.gd`
- `scripts/game/death_resolver.gd`
- `scripts/game/death_slot_claim_resolver.gd`
- `scripts/game/poison_attack_resolver.gd`

常见规则：

- 普通攻击使用护甲减伤。
- 法术、毒、固定伤害、反弹伤害不默认受护甲影响。
- 正面宽度攻击与数值关键字 `splash_N` 的固定溅射集中在 `AttackAction`。`frontal_width_N` 以攻击方向为中心命中面前奇数宽度 N 个格子的地面层和飞行层，`giant` 统一视为宽度 3；`ranged_attack_immune` 在同一入口过滤非贴身远程普通攻击，但不阻止近战、法术或效果。固定溅射扫描主目标周围八个相邻格，并同时读取每格地面层和飞行层；同格另一层不算相邻目标。新增类似普通攻击次级伤害时复用二次伤害、`play_secondary_attack_impact_animation()` 表现门面和死亡归属链，不要在卡牌脚本中自行扣血或直接操作视觉节点。
- 同格地面/空中单位在近战相关逻辑中视为可近战接触。
- 嘲讽规则集中在 `AttackAction`；常态标识在 `CardStatusOverlay`，普通攻击选目标时的动态嘲讽光晕由 `InteractionManager.is_taunt_target_hint` + `Card` 绘制。

## 状态

跨回合状态、周期能力或同一能力的多种施加入口，先读 `docs/runtime-effect-lifecycle.md`。不要用“当前模式已关闭”代替状态到期，也不要让被动刷新函数提前删除仍在合法持续窗口内的快照状态。

优先读：

- `scripts/data/card_status.gd`
- `scripts/data/card_state.gd`
- `scripts/game/status_resolver.gd`
- `scripts/game/status_modifier_resolver.gd`
- `scripts/effects/apply_status_effect.gd`
- `scripts/effects/transform_unit_effect.gd`
- `scripts/effects/cleanse_effect.gd`
- `scripts/ui/card_status_overlay.gd`
- `scripts/ui/board_persistent_visual_controller.gd`
- `scripts/ui/persistent_visuals/`

常见规则：

- 可驱散属性变化应使用状态 payload/modifier。
- 状态失效时不要写死恢复固定数值，除非状态自己保存了精确修正量。
- 固定最终攻击力使用状态 payload `attack_override`，不要在法术或攻击动作中直接覆盖后再手写恢复。`CardState` 会在覆盖期间维护底层攻击变化，状态结束后恢复；多个攻击覆盖由最新施加者生效。修改后运行 `tools/test_status_attack_override.gd`。
- `action_prevention` 通用阻止行动。
- 净化走 `CleanseEffect`。默认 `cleanse_mode: "all"`，可配置 `positive` 只驱散正面状态，或 `negative` 只解除负面状态。全场阵营目标优先用 `friendly_units` / `enemy_units`；只影响随从时用 `friendly_minions`，避免误作用到建筑。
- `breaks_on_attack_or_spell` 会在攻击或施法后移除，除非法术配置 `breaks_stealth: false`。
- `rooted` 的表现是金色遮罩和中心“定”字。
- 毒状态按总伤害唯一化，回合结束时先于治疗结算。
- 火焰伤害状态 `fire` 复用 DOT 生命周期，按总剩余伤害唯一化，回合结束由 `StatusResolver` 结算；持续数字图标使用 `assets/img/火焰数字`，不要用持续粒子替代可读数值。
- 变身使用 `transform_unit` 效果和 `transform` 状态。变身状态不可净化；进化变身死亡时正常死亡，覆盖变身死亡时先恢复原形。主动结束覆盖变身使用通用 `restore_transform`，它必须调用 `CardState.restore_from_transform_status()`，不得自行复制快照恢复。变身和恢复原形不能刷新行动力，必须保留本回合已消耗的行动经济。变身不能嵌套；需要让形态不再满足原英雄/原卡牌在场条件时配置 `preserve_original_identity: false`，默认值仍为 `true`。
- 原生复生使用卡牌顶层 `reborn_health_values`，运行时与快照统一使用 `CardState.reborn_health_values`。数组每项代表一层复生的恢复生命，`0` 为满血，正整数为指定生命；按队首依次消费。文案 `复生[1,4]` 对应数据 `[4]`，层数直接取数组长度。动态授予继续使用 `grant_reborn.health_values` 向队尾追加。不要同时配置旧 `reborn` / `reborn_N` 关键字和显式数组，也不要另建“层数”字段。修改后运行 `tools/test_dalaran_council.gd`。

## 法术目标

优先读：

- `scripts/game/spell_target_resolver.gd`
- `scripts/game/target_state_resolver.gd`
- `scripts/game/selection_request.gd`
- `scripts/game/selection_result.gd`
- `scripts/game/board_selection_controller.gd`
- `scripts/game/direction_ray_target_resolver.gd`
- `scripts/game/board_query.gd`

常见规则：

- 新目标规则加到 `SpellTargetResolver`，不要在单张卡里手写过滤。
- 直接点选时的魔法免疫和隐身过滤集中在 `SpellTargetResolver`；间接命中不能直接套用点选限制。方向射线可以碰撞隐身和魔免单位，但后续法术效果仍由 `CardEffect` 过滤魔免。
- 多目标/多阶段法术应复用通用选择控制器。
- `SpellTargetResolver` 只管目标合法性；`BoardQuery` 管棋盘几何；`BoardSelectionController` 管多阶段交互；效果/行动消费 `SelectionResult` 后再修改规则数据。
- 固定长度直线/矢量选择使用 `SelectionRequest.KIND_LINE_VECTOR`，当前兽径已走这条入口。
- 方向射线选择使用 `SelectionRequest.KIND_DIRECTION_RAY`，适合以英雄或某单位为中心选择上下左右/斜向。卡牌静态参数放在 `CardData.selection`；命中与停止规则集中在 `DirectionRayTargetResolver`，玩家面板和 AI 都消费其 `SelectionResult`。修改后运行 `tools/test_direction_ray_selection.gd`。

## 死亡、坟场与补牌

优先读：

- `scripts/game/death_resolver.gd`
- `scripts/game/death_slot_claim_resolver.gd`
- `scripts/game/reveal_resolver.gd`
- `scripts/game/trigger_resolver.gd`
- `scripts/game/turn_trigger_resolver.gd`
- `scripts/data/player_state.gd`

常见规则：

- 死亡快照应保留原始数据和最后运行时状态。
- 英雄死亡生成冷却手牌，不进坟场。
- 指定卡牌复活应复用 `resurrect` 的 `card_ids` 过滤，例如孙悟空“身外身法”只复活 `hair_clone`。
- 只有具备补牌能力的格子才补牌。
- 任何补牌入口都应调用 `GameManager.refill_board_slot_from_pool()` / `draw_card_to_slot()`，不要直接从 `card_pool.draw_random()` 后写入棋盘。
- 所有死亡入口都必须 `await`。范围伤害、巨兽溅射、月刃、毒爆、反弹、陷阱、献祭、吞噬、链接死亡等都应走 `GameManager.resolve_dead_states()` / `destroy_card_with_refill()`，不要直接清空卡牌。
- 需要给矿脉等 `on_destroyed` 奖励归属时，调用死亡入口必须传入造成击杀的 `source_state`。`DeathResolver` 会保存 `source_snapshot`，防止嵌套亡语或排队死亡在 source 被清空后丢失 destroyer。
- 普通攻击中心目标死亡可进入占领流程；巨兽范围伤害、`splash_N` 固定溅射和其他范围死亡不占领，但必须保留原攻击者来源并正常触发亡语、资源分、复生和补牌。
- 原格召唤统一提交死亡格占位请求。优先级为复生 > `claim_death_slot` 亡语（默认 200）> `death_slot_replacement` 击杀效果（默认 100）> 公共牌池补牌；高优先级请求不合法时继续尝试低优先级请求。
- `damage.death_slot_replacement` 适合“被此伤害击败后在其原格召唤”；`claim_death_slot` 适合死亡单位自身的 `on_destroyed` 原地召唤。两者都不得直接清空或写入棋盘。
- 顺序献祭使用 `sacrifice_friendly_minions`，保证前一个死亡能影响后一个死亡。

## 装备

优先读：

- `scripts/data/player_state.gd`
- `scripts/game/hand_play_resolver.gd`
- `scripts/game/hand_passive_resolver.gd`
- `scripts/ui/equipment_display_controller.gd`

常见规则：

- 装备类型决定替换关系。
- 持续装备加成使用 `trigger: "while_equipped"`。
- 手牌/装备持续被动统一由 `HandPassiveResolver.collect_active_passive_effects()` 收集一次，再由各子刷新器消费；新增属性型被动时优先接入这个 snapshot，不要在多个刷新函数里重复扫描手牌。
- 场上单位被动应用范围使用 owner 的 face-up minion 集合，飞行层和地面层都通过 `GameManager.get_all_board_states()` 进入。
- 不要把装备属性逻辑写进 UI。

## 随从库牌

优先读：

- `scripts/game/card_reserve_resolver.gd`
- `scripts/game/game_manager.gd` 中 `refresh_hand_passives_for_player()` 与玩家回合开始入口
- `scripts/data/player_state.gd` 的 `effect_runtime_values`
- `scripts/game/effect_data.gd`
- `scripts/ui/hand_drawer_controller.gd`
- `tools/test_card_reserve.gd`

常见规则：

- 随从库牌保持 `type: "upgrade"`，并用 `upgrade_type: "minion_library"` 声明语义子类；不要新增手牌第五分区。
- 同一玩家的多张随从库牌依靠不同的稳定 `reserve_id` 隔离运行时；新增库存时必须验证两份库存可同时初始化、抽取和计时，不能复用另一张牌的 `reserve_id`。
- 库存来源使用 `maintain_card_reserve`，配置 `reserve_id`、`capacity`、`cooldown_turns`、`count_zones`、`draw_mode`、`restock_mode` 和 `pool`。库存随从通常定义在所属种族 `tokens[]`，不进入普通牌池。
- 在役只统计己方手牌和己方正面战场随从；战场计数必须调用 `CardState.represents_card_id()` 兼容临时变身，不统计坟场、牌库和被敌方控制的单位。
- 缺口冷却只在来源玩家自己的回合开始推进；冷却期间继续减员不重置，完成后补足当前缺口。来源离开手牌时暂停并保存运行时，重新入手继续。
- 容量增长走 `modify_card_reserve_capacity`，只即时补充新增容量对应数量，不重置已有冷却；容量降低不强制移除单位。
- 随从库是缺口状态机，不是固定相位周期。不要复用 `PeriodicCycleResolver`，也不要在死亡、放置、控制权或 UI 代码中直接增减库存。
- 手牌上的在役/库存/冷却徽标只消费 resolver 生成的只读 view data。修改后运行 `python tools/validate_cards.py` 和 `tools/test_card_reserve.gd`。

## 种族系统

优先读：

- `scripts/data/player_state.gd`
- `scripts/game/faction_skill_resolver.gd`
- `scripts/ui/faction_skill_panel_controller.gd`
- `scripts/ui/faction_time_panel_controller.gd`
- `scripts/game/faction_runtime_state_resolver.gd`
- 相关种族 action/effect

当前系统：

- 暗夜精灵时间循环。
- 苗疆毒生态。优先读 `scripts/game/status_resolver.gd`、`scripts/game/status_modifier_resolver.gd`、`scripts/effects/link_units_effect.gd`、`scripts/effects/destroy_linked_units_effect.gd`、`scripts/effects/devour_effect.gd`、`scripts/data/board_slot_effect.gd` 和 `data/cards.json` 中的 `miao_jiang`。子母蛊使用 `life_link_larva -> life_link` 两阶段状态：施放只注入幼虫，施术者下个回合开始前置状态结算时才成熟为同命链接；不要在 `link_units` 施放流程里直接挂死亡连带状态。毒种通过 payload 的 `tick_animation` 配置结算反馈；毒性爆发只由 `StatusModifierResolver.preserve_total_damage()` 压缩持续时间并写入 `status_compressed`，不得更改总剩余伤害。薄葬的正常释放与零生命断裂分别使用 `expire_animation`、`death_on_expire_animation`，新增类似状态时复用生命周期元数据，不按卡牌 id 分支。
- 狐妖仙尾数与献祭。
- 种族技能按钮由 `FactionSkillPanelController` 展示，点击后交给 `FactionSkillResolver` 把 skill config 转成 `CardAction` 并进入目标选择；新增种族技能类型时优先扩展 resolver 的 `create_action()`，不要把 action 构造写回 `GameManager`。
- 猴妖仙施法/移动/攻击混合、透视、定身、隐身/暴击、护甲装备、固定方向副动作、分身协攻、阵营型净化。孙悟空四张 1 阶默认入手神通说明牌只用于文本展示，配置为 `count: 0`、`start_in_hand: true`、`effects: []`；真实能力仍在孙悟空自身 `spell_actions` 中。
- 野兽人同系斩杀进化、卡扎克杀戮成长、混沌腐蚀爆发、兽径地形、鹰身女妖咆哮体系、野性呼唤和万魔岩仪式。优先读 `scripts/game/beastmen_evolution_resolver.gd`、`scripts/effects/chaos_corruption_burst_effect.gd`、`scripts/effects/set_beast_path_effect.gd`、`scripts/game/board_selection_controller.gd`、`scripts/game/board_query.gd`、`scripts/game/death_resolver.gd`、`scripts/data/board_cell.gd`、`scripts/data/card_state.gd` 和 `data/cards.json` 中的 `evolution_rules` / `evolution_line`。进化规则放种族块，不要写死在单张随从里；规则展示牌可用 `start_in_hand` 默认入手。卡扎克成长由普通攻击击杀友方非英雄随从触发，不要做成新动作；永久成长写入 `CardState.permanent_stat_overrides`，不要改写 `origin`。野兽人卡牌可配置 `movement` 和 `chaos_corruption` 静态字段；混沌腐蚀爆发由手牌区升级牌的 `after_turn_end` 效果统一结算；兽径使用 `set_beast_path` + `SelectionRequest.KIND_LINE_VECTOR` 五格直线选择，不要写成单位状态；野蛮咆哮这类授予施法动作的升级牌走 `grant_spell_actions`，群体随从增益用 `apply_status` + `target: "friendly_minions"`；随机获得候选卡使用 `add_card_to_hand` + `card_ids` 候选池；按状态层数生成卡牌使用 `add_card_to_hand` + `amount_source: "status_stacks"` + `status_id`，需要消耗资源时配置 `consume_source_status: true`。
- 东京喰种 RC 浓度与赫子解放。优先读 `scripts/game/turn_event_ledger.gd`、`scripts/game/faction_runtime_state_resolver.gd`、`scripts/game/rc_concentration_resolver.gd`、`scripts/game/kagune_power_resolver.gd`、`scripts/game/card_reserve_resolver.gd`、`scripts/game/death_resolver.gd`、`scripts/game/granted_action_resolver.gd`、`scripts/actions/effect_action.gd`、`scripts/actions/attack_action.gd`、`scripts/ui/faction_time_panel_controller.gd`、`scripts/ui/turn_status_controller.gd`、`scripts/ui/card_status_overlay.gd`、`scripts/ui/animation/spell_animation_router.gd`、`scripts/ui/animation/tokyo_ghoul_animation_provider.gd` 和 `data/cards.json` 中的 `tokyo_ghoul`。固定循环状态仍由 `PlayerState` 推进；依赖回合事件的状态转移通过 `transition_policy` 交给 `FactionRuntimeStateResolver`，不要把 RC 条件写进 `PlayerState` 或 UI。运行时状态面板只展示当前行动玩家，切换回合时由 `GameHudCoordinator` 传入新的当前玩家；不要重新遍历双方状态。合格杀戮只统计当前行动玩家造成的、有玩家归属的非英雄随从死亡，友军和敌军均可，英雄、中立单位和建筑不计；状态 DOT 要保留 `source_owner_id`，无场上来源的效果要传运行时 `effect_owner_id`。赫子能力是施法回合期间动态附加的不可净化状态，使用通用 `attack_bonus`、`armor_bonus`、`movement_bonus`、`keywords` 和 `actions` payload；同一单位可拥有多个赫子关键字，`KagunePowerResolver` 必须合并全部 payload，例如死堪同时获得四类赫子能力，不要按卡牌 id 写组合分支。单位原生护甲使用静态 `armor` 字段，并由 `CardState` 与 `HandPassiveResolver` 以“原生护甲 + 非状态被动 + 状态护甲”组合；不要用不可净化状态伪造基础护甲。羽针由状态授予通用 `EffectAction`，因此 AI 和玩家共用动作发现链。S 阶与 SSS 阶喰种情报都使用通用有限随从库，并用独立 `reserve_id` 从本族 `tokens[]` 不放回供给各自四名随从；旧多二福使用通用 `frontal_width_5`、`magic_immune` 和 `ranged_attack_immune`，不得在东京喰种 resolver 中写专用攻击分支。开启赫子解放的全战场演出走 `SpellAnimationRouter` 的 board 路由，种族 provider 只消费 `kagune_release`；不要在 `GameManager` 内创建视觉节点，也不要让规则解析器等待动画。修改后运行 `tools/test_tokyo_ghoul.gd` 和 `tools/test_card_reserve.gd`。
- RC 初始为高浓度。每次击杀敌方非英雄随从立即提升一级，同一回合可连续提升；整回合没有合格杀戮时才在回合结束降低一级。友方非英雄随从的杀戮只阻止衰减，不提升浓度；低浓度无杀戮则保持低浓度并随机分食一个友方非英雄东京喰种随从。
- `TurnEventLedger.record_death()` 返回标准化记录，`FactionRuntimeStateResolver.resolve_after_death_event()` 负责分派即时种族状态变化。不要让 `DeathResolver` 知道 RC 状态 id。
- HUD 卡牌缩略图悬浮大图统一使用 `scripts/ui/card_texture_preview_controller.gd`。种族运行时状态牌和装备牌都只负责绑定 `CardData`，不要复制预览节点、定位和销毁逻辑。
- 修改 RC 规则后运行 `tools/test_rc_concentration.gd`；修改 HUD 卡图预览后运行 `tools/test_card_texture_preview.gd`。
- 东京喰种单独触发赫子能力时使用 `scripts/effects/apply_kagune_power_effect.gd`，能力 payload 必须来自 `KagunePowerResolver.create_kagune_payload()`，不要复制尾赫、鳞赫、甲赫或羽赫的具体数值。尾赫通过通用 `attack_speed_bonus` 状态数值获得攻速 +1，普通与高浓度完全一致；鳞赫在普通和高浓度都动态授予移动攻击，高浓度额外增加攻击并授予吸血。状态攻速变化必须保留本回合已消耗攻击次数，不能在状态添加或移除时刷新攻击。赫子解放按开启时的 RC 浓度生成能力快照，状态持续经过敌方回合，在来源玩家下一个回合开始时到期；被动刷新不得在来源玩家回合结束时主动删除或按新的 RC 等级重写。临时赫子状态使用 `kagune_power` 标签接入持续表现；同一张牌的数值叠加与赫子能力是否叠加应拆成不同状态策略。英雄所属法术继续依赖 `represents_card_id()` 校验，修改覆盖变身身份时必须运行 `tools/test_tokyo_ghoul.gd`。
- 棋盘来源的持续被动使用 `trigger: "while_on_board"`。英雄复活冷却由 `DeathResolver.get_active_hero_revive_cooldown_modifier()` 汇总装备与仍存活、正面朝上的己方棋盘来源，再用 `card_ids` 过滤目标英雄；13区咖啡店是当前示例。建筑离场、背面或生命归零时不得继续提供减免。
- 芳村功善“免单”使用 `friendly_minions_by_faction` + `target_faction_id` 过滤己方喰种，并复用 `set_faction_runtime_state` 设置高 RC；不要在动作里遍历棋盘或直接写玩家状态。芳村功善与高槻泉的“赫者化”是卡牌静态 `actions[]` 中的通用 `EffectAction`，使用 `once_per_lifetime: true` 与 `transform_unit`。金木研三形态和两种枭形态的“恢复原形”同样是静态副动作，但效果统一使用 `restore_transform`；非覆盖变身或缺少原形快照时动作不可用。一次性消耗保存在 `CardState.consumed_action_ids`，跨回合及覆盖形态恢复保留，新实例重置。修改此机制后运行 `tools/test_tokyo_ghoul.gd`。
- 影月议会邪能基础体系。优先读 `scripts/game/spell_cast_trigger_resolver.gd`、`scripts/game/hand_spell_modifier_resolver.gd`、`scripts/game/hand_passive_resolver.gd`、`scripts/actions/spell_action.gd`、`scripts/actions/effect_action.gd`、`scripts/actions/attack_action.gd`、`scripts/game/granted_action_resolver.gd`、`scripts/game/hand_play_resolver.gd`、`scripts/game/spell_target_resolver.gd`、`scripts/game/status_resolver.gd`、`scripts/game/periodic_cycle_resolver.gd`、`scripts/effects/card_effect.gd`、`scripts/effects/life_drain_effect.gd`、`scripts/effects/destroy_units_effect.gd`、`scripts/effects/periodic_status_aura_effect.gd`、`scripts/effects/periodic_trigger_effect.gd`、`scripts/data/card_status.gd`、`scripts/data/card_state.gd`、`scripts/data/player_state.gd`、`scripts/ui/card_status_overlay.gd`、`scenes/card/scripts/card.gd`、`scripts/ui/card_animation_controller.gd` 和 `data/cards.json` 中的 `shadowmoon_council`。邪能法术或施法动作通过 `spell_tags: ["fel"]` 标记；默认入手升级牌“邪能狂乱”通过 `trigger: "after_spell_cast"` + `active_zone: "hand"` + `required_spell_tags` 监听成功施法，再用 `apply_status` 给对应随从附加疯狂状态。生命吸取使用通用 `life_drain` 效果，按目标实际失去生命给指定 owner card 增加临时当前生命；该生命可超过上限，但不修改 `max_health`，也不触发有效治疗。需要让疯狂临时授予副动作时，把 `actions` 放在状态 `payload` 中，由 `GrantedActionResolver` 读取；需要临时授予关键字时，把 `keywords` 放在状态 `payload` 中，由 `CardState.has_keyword()` 读取，例如魅魔临时 `lifesteal`、末日守卫临时 `giant`；需要临时改写已有施法动作时，把 `spell_modifiers` 放在状态 `payload` 中，由 `HandSpellModifierResolver` 读取，例如术士疯狂后改写“诅咒”。装备改写施法动作时，使用 `modify_spell_ability` + `trigger: "while_equipped"`，由 `HandSpellModifierResolver` 从装备区读取；古尔丹之杖就是这个模式。地狱犬“法力燃烧”使用目标规则 `spellcaster_minions_or_heroes` 和表现 key `mana_burn`；术士“诅咒”使用目标规则 `non_hero_minions` 和通用状态 `damage_amplify`，该数值在 `CardState.take_damage()` 中并入同一次伤害事件，因此能被圣盾一次性格挡；地狱火“献祭”使用无目标施法动作 + `apply_status` + `target: "adjacent_enemy_non_hero_minions"` 施加 `fire`，火焰数值键为 `payload.fire_damage`，表现 key 为 `immolation`；基尔加丹的低语使用 `periodic_status_aura`，黑暗之门使用 `periodic_trigger`，两者都用 `cycle_length` / `active_phases` / `runtime_state_id` 描述周期，并共用 `PeriodicCycleResolver` 把运行时相位保存在玩家 `effect_runtime_values`；翻出即触发且需要重建周期的来源使用 `reset_phase: true`；混乱狼骑兵“撕咬”使用目标规则 `adjacent_minions`、表现 key `fel_bite`，并通过同一个 `EffectAction` 同时执行伤害和自我治疗；古尔丹之杖把“邪能灌注”升级为 `fel_overload`，通过状态 `turn_effects` 和通用 `destroy_units` 实现回合结束爆裂。“恶魔召唤”和“黑暗之门”都使用 `add_card_to_hand` 获取同族恶魔/邪兽人牌，其中魅魔来自同族 `tokens[]`。嘲讽关键字 `taunt`、巨兽关键字 `giant` 和吸血关键字 `lifesteal` 属于普通攻击规则，入口都在 `AttackAction`，不要在 UI 或单张卡牌里写死。新增更多疯狂分支、周期光环或周期事件时优先增加通用配置，不要在 `SpellAction`、`GameManager` 或具体随从代码中按卡牌 id 写死。

## 未来地图与设计笔记

优先读：

- `docs/architecture.md` 的“未来设计笔记”。
- `data/cards.json` 中当前中立牌和各族卡牌数量。

设计地图、中立牌包、种族主题或节奏时看这里。

常见规则：

- 中立牌应创造战场目标和地图质感，不应替代种族终结手段。
- 未来地图应拥有中立牌包、环境规则、棋盘修正和可选事件。
- 每个种族尽量围绕两条主路线和一条副路线。
- 偏向某个种族的中立牌，优先作为地图替换牌，而不是全局公共牌。
- 未来种族概念先作为设计储备，真正实现时再拆成数据和系统任务。

## AI

优先读：

- `scripts/ai/ai_candidate_builder.gd`
- `scripts/ai/ai_board_evaluator.gd`
- `scripts/ai/ai_hand_evaluator.gd`
- `scripts/ai/ai_action_executor.gd`
- `scripts/ai/ai_common.gd`

常见规则：

- AI 应调用和玩家一样的行动/手牌 API。
- 合法性放在行动/resolver，评分放在 evaluator。

## UI 与视觉

优先读：

- `scripts/game/game_animation_resolver.gd`
- `scripts/ui/card_animation_controller.gd`
- `scripts/ui/animation/spell_animation_router.gd`
- 对应种族的 `scripts/ui/animation/*_animation_provider.gd`
- `scripts/ui/card_status_overlay.gd`
- `scripts/audio/audio_manager.gd`
- `data/audio.json`
- `scenes/card/scripts/card.gd`
- `scripts/ui/hand_drawer_controller.gd`
- `scripts/game/game_hud_coordinator.gd`
- `scripts/ui/right_side_hud_layout_controller.gd`
- `scripts/ui/right_side_hud_style.gd`
- `scripts/ui/hud_symbol_icon.gd`
- 相关 panel controller

常见规则：

- 一次性特效从 `CardAnimationController` 进入；通用移动/攻击留在控制器，种族主题实现放在对应 animation provider。
- 需要从 `CardState`、手牌锚点、牌池面板解析 UI 节点并发起动画时，放在 `GameAnimationResolver`；`GameManager.play_*` 只做门面。
- 全战场触发型特效（例如普通施法回合 `spell_turn_activation`、赫子解放 `kagune_release`、野兽人 `chaos_corruption_burst`）走 `GameManager.play_board_effect_animation()`，不要伪造某个目标单位来播放。普通施法回合表现位于 `scripts/ui/animation/generic_spell_animation_provider.gd`；种族专属表现应使用不同 key 覆盖调用分支，避免与通用效果重复播放。
- 手牌四区布局优先读 `scenes/ui/hand_drawer_panel.tscn`、`scripts/ui/hand_drawer_controller.gd` 和 `scripts/ui/hand_section_layout_policy.gd`。分区高度只由可用高度、卡牌数量和每行容量决定：空区折叠，非空区按内容需求加权分配；不要重新给四个 section 设置 `EXPAND_FILL`，也不要让焦点卡牌或动作菜单参与高度权重。刷新时必须先捕获各区滚动偏移，立即移除旧滚动节点，并在自适应高度生效后恢复。修改算法后运行 `tools/test_hand_section_layout.gd` 和 `tools/test_hand_drawer_layout.gd`。
- 多格路径特效（例如 `beast_path`）走 `GameManager.play_path_effect_animation()`，由 `GameAnimationResolver` 收集格子 rect 后交给 `SpellAnimationRouter` 的 path 路由；范围区域特效（例如 `foxfire`）声明 area 路由。
- 猴妖仙法术/技能释放特效由 `MonkeyAnimationProvider` 按 animation key 生成金瞳、筋斗云、毫毛、金铁、蟠桃、敕令、定身、气雾、法象等符号化部件；新增猴妖仙技能时扩展 provider 的 key 和主题数据，不要回退到通用光圈。
- 白银之手法术由 `SilverHandAnimationProvider` 和 `HolySpellVisual` 负责，使用 `divine_shield`、`baptism`、`holy_heal`、`power_word_shield`、`inner_fire`、`faith_light`、`healing_to_resolve`、`resurrection` 八个专属 key。视觉必须保持白金核心、象牙金中层、珍珠银防御面、盾形/战锤/誓约印记、垂直圣光和军事秩序，禁止重新使用绿色治疗、普通红焰或无结构通用光圈。信仰圣光使用 `multi_rect` 同步军阵反馈；有效治疗转攻击在治疗结算后播放 `healing_to_resolve`。圣盾施放属于 provider，持续盾面、真言术·盾叠层和圣盾破碎属于 `CardStatusOverlay`；破碎由 `CardState.damage_prevented` 事件驱动，规则层不得创建视觉节点。修改后运行 `tools/test_silver_hand_animation_provider.gd`。
- 野兽人特效由 `BeastmenAnimationProvider` 按语义拆 key：`savage_roar` 是咆哮冲击波，`wild_call` 是荒野召唤，`wanmo_ritual` 是万魔岩仪式，`beast_path` 是兽径地道贯通，`beastmen_evolution` / `beastmen_slaughter` 继续表示适者生存和卡扎克杀戮成长。狐妖仙由 `FoxSpiritAnimationProvider` 负责。
- 苗疆表现优先读 `scripts/ui/animation/miao_animation_provider.gd`、`scripts/ui/animation/miao_spell_visual.gd`、`scripts/ui/card_status_overlay.gd`、`scripts/ui/gu_trap_slot_overlay.gd`、`scenes/card_board/scripts/card_board.gd` 和 `scripts/game/board_slot_effect_resolver.gd`。一次性蛊术采用“引蛊 → 注蛊 → 潜伏 → 成熟/结算 → 余韵”的有机节奏；`MiaoSpellVisual` 维护暗翡翠、朱砂、草药琥珀及蝎/蛇/王毒的共享形状，provider 只负责路由与临时节点生命周期。毒持续状态只显示总伤害数字，不恢复大面积毒雾；励蛊、蛇毒、链接、薄葬和吞噬由 `CardStatusOverlay` 读取真实状态绘制。诱蛊潜伏标记属于单元格，通过 `BoardSlotEffect.persistent_animation` 和 `CardBoard.set_slot_effect_visual()` 管理，卡牌移动或消失不得带走它；消费陷阱时先清除标记再播放触发。修改后运行 `tools/test_miao_animation_provider.gd`，至少验证所有 key 能释放临时节点、动态状态移除后停止处理、毒性压缩保持总伤害及链接死亡动画元数据完整。
- 音频放在 `scripts/audio/audio_manager.gd` 和 `data/audio.json`。规则层只传递 `audio` key 或 animation key，不直接加载音频资源；背景音乐、攻击音效、法术音效统一走 `GameManager` 的音频门面。
- 卡面内的持续状态标识放在 `CardStatusOverlay`。覆盖多个格子并跟随来源移动的持续动态效果，通过状态 payload 的 `persistent_visuals` 声明，交给 `BoardPersistentVisualController`；新增主题时注册独立 renderer，不要让 `Card` 越界绘制。
- 数值图标和战场种族 logo 放在 `Card`；logo 路径由卡牌 `front_texture_path.get_base_dir() + "/logo.png"` 推导，不要为每个种族写分支。
- 右侧 HUD 面板排布交给 `RightSideHudLayoutController`；它统一列宽、边距、间距并防止面板重叠，只排列已有 panel，不负责面板内容、可见性或玩法规则。各 panel controller 禁止再实现自己的 `position_panel()` 或固定 `TOP_MARGIN`。
- 右侧 HUD 的面板外壳、标题、按钮、指标块与资源刻度统一复用 `RightSideHudStyle`；无专属贴图的稳定语义图标复用 `HudSymbolIcon`。法力、翻牌和资源分采用图标加短数值；最大值不超过 12 的种族资源用离散刻度显示并通过 tooltip 提供精确值。修改后运行 `tools/test_right_side_hud.gd`。
- 对局 HUD 的创建与刷新顺序交给 `GameHudCoordinator`；`GameManager.update_*_view()` 是兼容门面。新增面板时，把内容控制留在独立 panel controller，把生命周期接入协调器，把位置交给布局控制器。
- 通用法术与种族主题特效注册到 `SpellAnimationRouter`，并按卡牌到卡牌、直接矩形、来源矩形到卡牌、全战场、多格路径、范围区域、多目标矩形组七种上下文声明 key。`multi_rect` 只接收一组已解析的可见目标矩形，用于同一时点同步播放群体治疗/祝福；未注册该上下文时调用方必须回退原有逐目标动画。主题节点和 Tween 放在 provider；通用攻击、移动和默认法术仍由 `CardAnimationController` 处理。不要让规则层直接调用某个 provider；`GameManager` 只负责选择稳定 animation key，不创建表现节点。
- 达拉然表现优先读 `scripts/ui/animation/dalaran_animation_provider.gd`、`dalaran_spell_visual.gd`、`dalaran_fire_animation_player.gd`、`dalaran_space_swap_player.gd`、`scripts/ui/persistent_visuals/extreme_cold_storm_area_visual.gd` 和 `scripts/ui/card_status_overlay.gd`。`DalaranSpellVisual` 只提供奥术、冰霜、火焰、水元素的共享形状语言；provider 负责路由和生命周期；火球/炎爆的投射物阶段与奥术空间的双格交换分别由专用 player 管理。冰锥术必须表现为“凝聚→沿方向飞行→命中碎裂→冻结反馈”，魔免只保留碰撞碎裂，不显示冻结结晶。辉煌光环属于卡面局部持续状态，回合产蓝反馈由 `gain_mana.source_animation` 配置；极寒风暴的 3x3 常驻风场属于 `BoardPersistentVisualController`，施放、回合结算坠落冰暴和原格召唤仍是一次性 provider 动画。不要把持续节点留在 provider，也不要让规则效果识别具体卡牌 id。
- 新增或迁移动画 key 后运行 `python tools/validate_cards.py` 和 `tools/test_animation_routing.gd`；前者扫描中央控制器、provider 的 `*_KEYS` 数组和 `*_ANIMATION_KEY` 常量，后者验证 provider 的上下文路由契约。拥有复杂自绘或持续刷新生命周期的主题还应提供独立测试，至少验证动画节点完整释放、状态移除后停止处理；达拉然使用 `tools/test_dalaran_animation_provider.gd`，苗疆使用 `tools/test_miao_animation_provider.gd`。
- UI 控制器不拥有玩法规则。

## VFX 与素材资源

优先读：

- `docs/architecture.md` 的“特效资源与未来 VFX 管线”。
- `scripts/game/game_animation_resolver.gd`
- `scripts/ui/card_animation_controller.gd`
- `scripts/audio/audio_manager.gd`
- `data/audio.json`
- 未来 `data/vfx.json`、`scripts/vfx/`、`scenes/vfx/`

常见规则：

- 小型通用代码特效可留在 `CardAnimationController`；种族主题代码特效进入 provider，复杂粒子、shader、投射物、区域特效和持续特效逐步迁移到 `VfxManager` + PackedScene。
- 规则层不直接实例化 VFX，也不直接加载贴图、粒子或音频。
- 外部素材进入项目前，保留来源和授权信息；优先使用 CC0、明确可商用或已购买授权的素材。
- 推荐素材来源：Godot Asset Library、itch.io、GameDev Market、Kenney、OpenGameArt、Freesound。Unity/Fab/ArtStation/Gumroad 素材只优先使用通用 PNG 序列、sprite sheet、flipbook、贴图、模型和音频。
- 外部素材建议先放 `assets/vfx/source/`，处理后的项目运行资源放 `assets/vfx/textures/`；音效放 `assets/audio/sfx/`。

## 验证与提交清单

1. 修改卡牌后运行 `python tools/validate_cards.py`。
2. 修改脚本、场景、玩法或 UI 后运行 `powershell -ExecutionPolicy Bypass -File tools/run_godot_validation.ps1`。Windows 下禁止直接使用项目模式 `--check-only`，它可能留下隐藏的常驻 Godot 进程并持续占用内存。
3. 检查 `git diff --stat`。
4. 使用清晰的中文提交信息提交。
5. 推送。若推送失败，报告本地 commit hash 和 ahead 数量。
