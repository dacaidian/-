# Codex 工作索引

> Encoding guard: this document must stay valid UTF-8. If Chinese text becomes unreadable or `apply_patch` cannot edit this file, first repair/normalize the file as UTF-8. Do not append around broken bytes.
>
> 中文说明：本文档必须保持 UTF-8。它是以后开发时的快速导航，不是完整架构说明。真正的系统边界看 `docs/architecture.md`。

## 每次先检查

- `git status --short --branch`：仓库可能已有本地提交或用户修改。
- `python tools/validate_cards.py`：修改 `data/cards.json` 后运行。
- `godot --headless --path . --check-only`：修改脚本或场景后运行。
- `godot --headless --path . --quit-after 1`：修改玩法或 UI 后运行。
- 每波完成后提交并推送。若 GitHub 无法连接，报告本地 commit hash 和 ahead 数量。

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
- 棋盘展示图使用同目录同名 `-table.png` 自动覆盖，例如 `牧师.png` -> `牧师-table.png`；没有 table 图时回退原 `url` 卡图。手牌、悬浮预览和装备预览仍使用原图。
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
- `scripts/game/poison_attack_resolver.gd`

常见规则：

- 普通攻击使用护甲减伤。
- 法术、毒、固定伤害、反弹伤害不默认受护甲影响。
- 巨兽溅射集中在 `AttackAction`。
- 同格地面/空中单位在近战相关逻辑中视为可近战接触。

## 状态

优先读：

- `scripts/data/card_status.gd`
- `scripts/data/card_state.gd`
- `scripts/game/status_resolver.gd`
- `scripts/game/status_modifier_resolver.gd`
- `scripts/effects/apply_status_effect.gd`
- `scripts/effects/transform_unit_effect.gd`
- `scripts/effects/cleanse_effect.gd`
- `scripts/ui/card_status_overlay.gd`

常见规则：

- 可驱散属性变化应使用状态 payload/modifier。
- 状态失效时不要写死恢复固定数值，除非状态自己保存了精确修正量。
- `action_prevention` 通用阻止行动。
- 净化走 `CleanseEffect`。默认 `cleanse_mode: "all"`，可配置 `positive` 只驱散正面状态，或 `negative` 只解除负面状态。全场阵营目标优先用 `friendly_units` / `enemy_units`；只影响随从时用 `friendly_minions`，避免误作用到建筑。
- `breaks_on_attack_or_spell` 会在攻击或施法后移除，除非法术配置 `breaks_stealth: false`。
- `rooted` 的表现是金色遮罩和中心“定”字。
- 毒状态按总伤害唯一化，回合结束时先于治疗结算。
- 火焰伤害状态 `fire` 复用 DOT 生命周期，按总剩余伤害唯一化，回合结束由 `StatusResolver` 结算；持续数字图标使用 `assets/img/火焰数字`，不要用持续粒子替代可读数值。
- 变身使用 `transform_unit` 效果和 `transform` 状态。变身状态不可净化；进化变身死亡时正常死亡，覆盖变身死亡时先恢复原形。变身和恢复原形不能刷新行动力，必须保留本回合已消耗的行动经济。

## 法术目标

优先读：

- `scripts/game/spell_target_resolver.gd`
- `scripts/game/target_state_resolver.gd`
- `scripts/game/selection_request.gd`
- `scripts/game/selection_result.gd`
- `scripts/game/board_selection_controller.gd`
- `scripts/game/board_query.gd`

常见规则：

- 新目标规则加到 `SpellTargetResolver`，不要在单张卡里手写过滤。
- 魔法免疫和隐身过滤应集中处理。
- 多目标/多阶段法术应复用通用选择控制器。
- `SpellTargetResolver` 只管目标合法性；`BoardQuery` 管棋盘几何；`BoardSelectionController` 管多阶段交互；效果/行动消费 `SelectionResult` 后再修改规则数据。
- 固定长度直线/矢量选择使用 `SelectionRequest.KIND_LINE_VECTOR`，当前兽径已走这条入口。
- 方向射线选择使用 `SelectionRequest.KIND_DIRECTION_RAY`，适合以英雄或某单位为中心选择上下左右/斜向，并沿方向寻找第一个命中单位。

## 死亡、坟场与补牌

优先读：

- `scripts/game/death_resolver.gd`
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
- 普通攻击中心目标死亡可进入占领流程；巨兽溅射和其他范围死亡不占领，但必须正常触发亡语、资源分、复生和补牌。
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
- 不要把装备属性逻辑写进 UI。

## 种族系统

优先读：

- `scripts/data/player_state.gd`
- `scripts/ui/faction_skill_panel_controller.gd`
- `scripts/ui/faction_time_panel_controller.gd`
- 相关种族 action/effect

当前系统：

- 暗夜精灵时间循环。
- 苗疆毒生态。子母蛊使用 `life_link_larva -> life_link` 两阶段状态：施放只注入幼虫，施术者下个回合开始前置状态结算时才成熟为同命链接；不要在 `link_units` 施放流程里直接挂死亡连带状态。
- 狐妖仙尾数与献祭。
- 猴妖仙施法/移动/攻击混合、透视、定身、隐身/暴击、护甲装备、固定方向副动作、分身协攻、阵营型净化。
- 野兽人同系斩杀进化、卡扎克杀戮成长、混沌腐蚀爆发、兽径地形、鹰身女妖咆哮体系、野性呼唤和万魔岩仪式。优先读 `scripts/game/beastmen_evolution_resolver.gd`、`scripts/effects/chaos_corruption_burst_effect.gd`、`scripts/effects/set_beast_path_effect.gd`、`scripts/game/board_selection_controller.gd`、`scripts/game/board_query.gd`、`scripts/game/death_resolver.gd`、`scripts/data/board_cell.gd`、`scripts/data/card_state.gd` 和 `data/cards.json` 中的 `evolution_rules` / `evolution_line`。进化规则放种族块，不要写死在单张随从里；规则展示牌可用 `start_in_hand` 默认入手。卡扎克成长由普通攻击击杀友方非英雄随从触发，不要做成新动作；永久成长写入 `CardState.permanent_stat_overrides`，不要改写 `origin`。野兽人卡牌可配置 `movement` 和 `chaos_corruption` 静态字段；混沌腐蚀爆发由手牌区升级牌的 `after_turn_end` 效果统一结算；兽径使用 `set_beast_path` + `SelectionRequest.KIND_LINE_VECTOR` 五格直线选择，不要写成单位状态；野蛮咆哮这类授予施法动作的升级牌走 `grant_spell_actions`，群体随从增益用 `apply_status` + `target: "friendly_minions"`；随机获得候选卡使用 `add_card_to_hand` + `card_ids` 候选池；按状态层数生成卡牌使用 `add_card_to_hand` + `amount_source: "status_stacks"` + `status_id`，需要消耗资源时配置 `consume_source_status: true`。
- 影月议会邪能基础体系。优先读 `scripts/game/spell_cast_trigger_resolver.gd`、`scripts/game/hand_spell_modifier_resolver.gd`、`scripts/game/hand_passive_resolver.gd`、`scripts/actions/spell_action.gd`、`scripts/actions/effect_action.gd`、`scripts/actions/attack_action.gd`、`scripts/game/granted_action_resolver.gd`、`scripts/game/hand_play_resolver.gd`、`scripts/game/spell_target_resolver.gd`、`scripts/game/status_resolver.gd`、`scripts/effects/card_effect.gd`、`scripts/effects/life_drain_effect.gd`、`scripts/effects/destroy_units_effect.gd`、`scripts/effects/periodic_status_aura_effect.gd`、`scripts/data/card_status.gd`、`scripts/data/card_state.gd`、`scripts/data/player_state.gd`、`scripts/ui/card_status_overlay.gd`、`scenes/card/scripts/card.gd`、`scripts/ui/card_animation_controller.gd` 和 `data/cards.json` 中的 `shadowmoon_council`。邪能法术或施法动作通过 `spell_tags: ["fel"]` 标记；默认入手升级牌“邪能狂乱”通过 `trigger: "after_spell_cast"` + `active_zone: "hand"` + `required_spell_tags` 监听成功施法，再用 `apply_status` 给对应随从附加疯狂状态。生命吸取使用通用 `life_drain` 效果，按目标实际失去生命给指定 owner card 增加临时当前生命；该生命可超过上限，但不修改 `max_health`，也不触发有效治疗。需要让疯狂临时授予副动作时，把 `actions` 放在状态 `payload` 中，由 `GrantedActionResolver` 读取；需要临时授予关键字时，把 `keywords` 放在状态 `payload` 中，由 `CardState.has_keyword()` 读取，例如魅魔临时 `lifesteal`、末日守卫临时 `giant`。装备改写施法动作时，使用 `modify_spell_ability` + `trigger: "while_equipped"`，由 `HandSpellModifierResolver` 从装备区读取；古尔丹之杖就是这个模式。地狱犬“法力燃烧”使用目标规则 `spellcaster_minions_or_heroes` 和表现 key `mana_burn`；术士“诅咒”使用目标规则 `non_hero_minions` 和通用状态 `damage_amplify`，该数值在 `CardState.take_damage()` 中并入同一次伤害事件，因此能被圣盾一次性格挡；地狱火“献祭”使用无目标施法动作 + `apply_status` + `target: "adjacent_enemy_non_hero_minions"` 施加 `fire`，火焰数值键为 `payload.fire_damage`，表现 key 为 `immolation`；基尔加丹的低语使用 `periodic_status_aura`，用 `cycle_length` / `active_phases` / `runtime_state_id` 描述周期，运行时相位保存在玩家 `effect_runtime_values`；混乱狼骑兵“撕咬”使用目标规则 `adjacent_minions`、表现 key `fel_bite`，并通过同一个 `EffectAction` 同时执行伤害和自我治疗；古尔丹之杖把“邪能灌注”升级为 `fel_overload`，通过状态 `turn_effects` 和通用 `destroy_units` 实现回合结束爆裂。“恶魔召唤”使用 `add_card_to_hand` 获取同族 `tokens[]` 衍生牌“魅魔”。嘲讽关键字 `taunt`、巨兽关键字 `giant` 和吸血关键字 `lifesteal` 属于普通攻击规则，入口都在 `AttackAction`，不要在 UI 或单张卡牌里写死。新增更多疯狂分支时优先增加手牌升级牌的配置效果或通用筛选目标，不要在 `SpellAction`、`GameManager` 或具体随从代码中按卡牌 id 写死。

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
- `scripts/ui/card_status_overlay.gd`
- `scripts/audio/audio_manager.gd`
- `data/audio.json`
- `scenes/card/scripts/card.gd`
- `scripts/ui/hand_drawer_controller.gd`
- 相关 panel controller

常见规则：

- 一次性特效放在 `CardAnimationController`。
- 需要从 `CardState`、手牌锚点、牌池面板解析 UI 节点并发起动画时，放在 `GameAnimationResolver`；`GameManager.play_*` 只做门面。
- 全战场触发型特效（例如野兽人 `chaos_corruption_burst`）走 `GameManager.play_board_effect_animation()`，不要伪造某个目标单位来播放。
- 多格路径特效（例如 `beast_path`）走 `GameManager.play_path_effect_animation()`，由 `GameAnimationResolver` 收集格子 rect 后交给 `CardAnimationController`。
- 猴妖仙法术/技能释放特效使用 `play_monkey_spell_at_rect()`，按 animation key 生成金瞳、筋斗云、毫毛、金铁、蟠桃、敕令、定身、气雾、法象等符号化部件；新增猴妖仙技能时优先扩展这一组主题函数，不要回退到通用光圈。
- 野兽人特效按语义拆 key：`savage_roar` 是咆哮冲击波，`wild_call` 是荒野召唤，`wanmo_ritual` 是万魔岩仪式，`beast_path` 是兽径地道贯通，`beastmen_evolution` / `beastmen_slaughter` 继续表示适者生存和卡扎克杀戮成长。
- 音频放在 `scripts/audio/audio_manager.gd` 和 `data/audio.json`。规则层只传递 `audio` key 或 animation key，不直接加载音频资源；背景音乐、攻击音效、法术音效统一走 `GameManager` 的音频门面。
- 持续状态表现放在 `CardStatusOverlay`。
- 数值图标放在 `Card` 的状态/数值堆叠区域。
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

- 小型代码特效继续放在 `CardAnimationController`；复杂粒子、shader、投射物、区域特效和持续特效应逐步迁移到 `VfxManager` + PackedScene。
- 规则层不直接实例化 VFX，也不直接加载贴图、粒子或音频。
- 外部素材进入项目前，保留来源和授权信息；优先使用 CC0、明确可商用或已购买授权的素材。
- 推荐素材来源：Godot Asset Library、itch.io、GameDev Market、Kenney、OpenGameArt、Freesound。Unity/Fab/ArtStation/Gumroad 素材只优先使用通用 PNG 序列、sprite sheet、flipbook、贴图、模型和音频。
- 外部素材建议先放 `assets/vfx/source/`，处理后的项目运行资源放 `assets/vfx/textures/`；音效放 `assets/audio/sfx/`。

## 验证与提交清单

1. 修改卡牌后运行 `python tools/validate_cards.py`。
2. 修改脚本或场景后运行 `godot --headless --path . --check-only`。
3. 修改玩法或 UI 后运行 `godot --headless --path . --quit-after 1`。
4. 检查 `git diff --stat`。
5. 使用清晰的中文提交信息提交。
6. 推送。若推送失败，报告本地 commit hash 和 ahead 数量。
