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
- 净化走 `CleanseEffect`。默认 `cleanse_mode: "all"`，可配置 `positive` 只驱散正面状态，或 `negative` 只解除负面状态。全场阵营目标优先用 `friendly_units` / `enemy_units`。
- `breaks_on_attack_or_spell` 会在攻击或施法后移除，除非法术配置 `breaks_stealth: false`。
- `rooted` 的表现是金色遮罩和中心“定”字。
- 毒状态按总伤害唯一化，回合结束时先于治疗结算。
- 变身使用 `transform_unit` 效果和 `transform` 状态。变身状态不可净化；进化变身死亡时正常死亡，覆盖变身死亡时先恢复原形。变身和恢复原形不能刷新行动力，必须保留本回合已消耗的行动经济。

## 法术目标

优先读：

- `scripts/game/spell_target_resolver.gd`
- `scripts/game/target_state_resolver.gd`
- `scripts/game/` 下的多阶段选择控制器

常见规则：

- 新目标规则加到 `SpellTargetResolver`，不要在单张卡里手写过滤。
- 魔法免疫和隐身过滤应集中处理。
- 多目标/多阶段法术应复用通用选择控制器。

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
- 苗疆毒生态。
- 狐妖仙尾数与献祭。
- 猴妖仙施法/移动/攻击混合、透视、定身、隐身/暴击、护甲装备、固定方向副动作、分身协攻、阵营型净化。
- 野兽人同系斩杀进化。优先读 `scripts/game/beastmen_evolution_resolver.gd`、`scripts/game/death_resolver.gd` 和 `data/cards.json` 中的 `evolution_rules` / `evolution_line`。进化规则放种族块，不要写死在单张随从里；规则展示牌可用 `start_in_hand` 默认入手。

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
- 猴妖仙法术/技能释放特效使用 `play_monkey_spell_at_rect()`，按 animation key 生成金瞳、筋斗云、毫毛、金铁、蟠桃、敕令、定身、气雾、法象等符号化部件；新增猴妖仙技能时优先扩展这一组主题函数，不要回退到通用光圈。
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
