# Codex Working Map

这份文件用于降低后续开发的上下文消耗。开始新任务时，优先读本文件，再按任务类型精准读取 2-5 个相关文件；只有做架构复盘或跨模块重构时才完整阅读 `docs/architecture.md`。

## 默认流程

1. 先用 `rg` 定位关键词和调用点。
2. 只读相关文件的局部片段；避免无目的完整读取 `scripts/game/game_manager.gd`。
3. 修改后按影响范围运行验证命令。
4. 如果改了规则边界、数据结构或模块职责，同步更新 `docs/architecture.md`。

## 必读入口

- 详细架构：`docs/architecture.md`
- 历史会话：`docs/codex-session-2026-05-11-godot-intro.md`
- 卡牌数据：`data/cards.json`
- 主场景：`main.tscn`

历史会话很长，默认不要读。只有用户明确追溯早期设计，或当前文档无法解释历史决策时再查。

## 任务索引

### 入口与战局配置

优先读：

- `scenes/start_menu/start_menu.tscn`
- `scripts/ui/start_menu.gd`
- `scripts/game/match_setup.gd`
- `scripts/data/card_database.gd`
- `scripts/game/board_query.gd`，如果规则需要确认英雄是否在战场。
- `scripts/data/card_pool.gd`
- `scripts/game/game_manager.gd` 中 `player_faction_ids`、`selected_hero_card_ids`、`create_initial_card_pool()` 局部。

常见修改：

- 种族选择、英雄选择、禁止双方选择相同种族。
- 英雄 `attached_cards` 是否进入本局牌池。
- 英雄配套手牌是否需要英雄在战场才能使用：优先查 `CardData.owner_hero_card_id`、`CardDatabase.apply_hero_attachment_metadata()`、`HandPlayResolver.is_required_hero_on_board()`。
- 进入战斗场景前传入玩家配置。

### 卡牌静态数据

优先读：

- `data/cards.json`
- `scripts/data/card_data.gd`
- `scripts/data/card_database.gd`

常见修改：

- 新增卡牌、类型、关键词、法术动作、效果配置。
- 衍生牌（token）定义在对应种族的 `tokens[]` 字段下，结构同普通卡牌。
- 扩展 `CardData.is_*()` 或静态字段解析。
- 测试模式：编辑 `data/test_config.json` 配置白名单、数量覆盖和游戏参数（`game_params` 节：`spell_turn_mana_cost`、`victory_resource_score`）。`CardDatabase` 提供通用 `get_test_game_param()` 读取，`GameManager._apply_test_game_params()` 应用覆盖。关闭只需 `"enabled": false`。

验证：

- `python -m json.tool data/cards.json`
- `godot --headless --path . --check-only`

### 棋盘单位状态

优先读：

- `scripts/data/card_state.gd`
- `scripts/data/card_status.gd`
- `scripts/game/status_resolver.gd`
- `scripts/ui/card_status_overlay.gd`，如果是状态持续视觉。
- `scripts/ui/card.gd`
- `scenes/card/scripts/card.gd`，如果项目同时保留旧路径，需要确认实际场景引用。
- 棋盘卡牌 hover 信号 `mouse_entered_card` / `mouse_exited_card` 在 `scenes/card/scripts/card.gd` 中定义，携带 Card 引用，供 GameManager 连接 area 预览等 hover 行为。

常见修改：

- 攻击、生命、护盾、移动力、攻速、行动锁、背光标记。
- 新增棋盘单位运行时字段。
- 新增中毒、圣盾、冻结、临时增益等状态及其持续回合。
- 圣盾当前是 `divine_shield` 永久可消耗状态；伤害入口在 `CardState.take_damage()`，它会先消耗一层圣盾并抵消本次伤害，再进入数值护盾/生命结算。
- 冻结当前是 `freeze` 临时控制状态，配置 `duration_turns: 1` + `expires_on_trigger: "after_turn_end"` + `duration_scope: "target_owner"`。状态到期后自动移除，无需特殊恢复逻辑。
- 辉煌光环当前是 `arcane_aura` 状态；状态的 `payload.turn_effects` 可在回合时点触发效果，状态层数会乘到效果 `amount` 上。
- 励蛊当前是 `encourage_gu` 状态；使用 `status_tags: ["attack_modifier"]` 和 `payload.attack_bonus` 提供持续攻击力修正，移除状态时由 `CardState.status_attack_bonus` 自动回滚。
- 毒当前是 `poison` 唯一状态；使用 `status_tags: ["damage_over_time"]`、`payload.poison_damage` 和 `duration_turns`。新毒只在剩余总伤害更高时覆盖旧毒。毒伤害在 `after_turn_end` 普通触发前由 `StatusResolver.resolve_pre_trigger_status_effects()` 结算，早于回合结束治疗。
- 状态施加前修正由 `StatusModifierResolver` 统一处理；`modify_applied_status` 可按 `status_ids` 修改己方施加的新状态，例如毒性爆发把毒的总伤害压缩到 1 回合内结算。
- 同源同名状态默认叠层；需要刷新不叠层、替换或忽略时，在状态配置中使用 `stack_policy`（`stack` / `refresh` / `replace` / `ignore`）。例如蛇毒减攻使用 `refresh`，重复施加不继续叠加攻击惩罚。
- `apply_status` 效果支持可选 `apply_animation` 字段，指定状态施加瞬间的动画 key；没有该字段时不播放额外动画。
- 状态覆盖视觉统一放在 `CardStatusOverlay`；`Card` 只负责绑定状态、摆放覆盖层和棋盘数值图标。当前持续覆盖视觉包括圣盾、辉煌光环、冻结和励蛊；毒性这类有数值的状态走 `Card` 的状态数字栈，放在血量图标上方并显示剩余总伤害。
- **控制状态通用门控**：`CardState.has_status_with_tag(TAG_ACTION_PREVENTION)` 同时阻止 `can_move()`、`can_attack()` 和 `can_take_action_group()`。新增控制状态只需 JSON 配置 `"status_tags": ["action_prevention"]`，不要写 `is_frozen()` 等专用判断。

### 翻牌与补牌

优先读：

- `scripts/game/reveal_resolver.gd`
- `scripts/game/board_slot_resolver.gd`
- `scripts/ui/card_pool_view_controller.gd`
- `scripts/game/game_manager.gd` 中 `_on_card_clicked()`、`refill_board_slot_from_pool()`、`animate_refill_board_slot()` 局部。

常见修改：

- 翻开后留在战场、进手牌、扣回、补位动画。
- 中立牌库、敌方牌归属规则、未来分级牌池。

### 手牌

优先读：

- `scripts/game/hand_interaction_controller.gd`
- `scripts/game/hand_play_resolver.gd`
- `scripts/game/hand_passive_resolver.gd`
- `scripts/ui/hand_drawer_controller.gd`
- `scripts/data/player_state.gd`

常见修改：

- 手牌焦点、动作菜单、手牌法术使用、手牌被动、手牌 UI 展示。
- 英雄配套手牌的可用性统一由 `HandPlayResolver` 判断；手牌绿光、动作菜单和真正执行都应传入 `GameManager` 上下文，不要只看卡牌自身效果。
- 手牌持续被动由 `HandPassiveResolver` 统一刷新；`modify_flip_capacity` 改翻牌上限，`set_unit_movement` 按 `card_ids` 改己方战场单位移动力，`modify_unit_attack` 按 `card_ids` 给己方战场单位叠加可刷新的攻击力光环。
- 手牌法术运行时修正由 `HandSpellModifierResolver` 统一处理；`modify_hand_spell_effects` 可按 `card_ids` 和 `target_relation` 替换/追加效果，不要在某张法术牌或 `HandPlayResolver` 里写死卡牌名。
- 手牌抽屉高度由 `HandDrawerController` 根据视窗动态设置；各分区内部用 `ScrollContainer` 承载 `HFlowContainer`，手牌变多时应滚动而不是撑出外边框。
- 同名手牌仍依赖 `selected_hand_index` 区分；需要冷却、来源、标签等运行时字段的手牌已使用 `HandCardState`，未来可继续演进为更完整的 `CardInstance` / Zone。
- 装备牌使用 `hand:equip` 动作，装备后进入 `PlayerState.equipped_cards_by_type`。同一 `equipment_type` 只保留一张生效装备；新装备会把同槽位旧装备退回手牌。英雄配套装备仍通过 `owner_hero_card_id` 要求英雄在场。

### 装备

优先读：

- `scripts/game/hand_play_resolver.gd`
- `scripts/game/equipment_trigger_resolver.gd`
- `scripts/actions/attack_action.gd`，如果涉及攻击后触发。
- `scripts/data/player_state.gd`
- `scripts/data/card_data.gd`

常见修改：

- 新增装备类型：在 JSON 配置 `type: "equipment"` 和 `equipment_type`。
- 新增装备触发：优先放到 `EquipmentTriggerResolver`，不要塞进具体行动。
- 装备法术强度：使用 `modify_spell_power` 效果；法强通过 `CardEffect.get_spell_scaled_amount()` 统一加成伤害/治疗/护盾数值，只有施法入口打了 `_apply_spell_power` 的运行时效果会吃法强。
- 复用既有法术定义：使用 `play_spell_action` + `card_id`，例如光明使者之锤在 `after_attack` 触发洗礼；自动目标仍必须通过 `SpellTargetResolver` 校验。
- 装备展示：右侧 `EquipmentDisplayController` 读取当前玩家的 `PlayerState.equipped_cards_by_type` / `get_equipped_cards()`；只改展示时优先碰这个文件，不要把装备规则写进 UI。

### 法术目标

优先读：

- `scripts/game/spell_target_resolver.gd`
- `scripts/game/granted_spell_resolver.gd`
- `scripts/ui/card_animation_controller.gd`
- `data/cards.json`

常见修改：

- 建筑当前不能作为施法目标。伤害、治疗、护盾等可选目标默认应使用 `all_minions`；只有明确设计为可影响建筑时，才扩展目标规则。
- `area_3x3` 是 AOE 范围目标规则：选择棋盘格子作为范围中心，影响 `area_rows × area_cols` 区域。`SpellTargetResolver.is_area_rule()` 统一判断；新增 area 形状只在 `SpellTargetResolver` 注册常量和尺寸映射。
- 升级牌授予法术仍走 `grant_spell_actions`，不要把授予逻辑写进具体随从。
- 新法术动画优先新增 `animation` key，让 `CardAnimationController` 复用或扩展既有表现，例如 `pyroblast` 是放大版 `fireball`。AOE 法术使用专用动画入口 `play_area_spell_cast()`。

### 复活与坟场筛选

优先读：

- `scripts/data/hand_card_state.gd`
- `scripts/effects/resurrect_effect.gd`
- `scripts/ui/card_multi_select_controller.gd`
- `scripts/data/player_state.gd`，如果涉及 `graveyard`、`remove_from_graveyard_at()`。
- `scripts/game/death_resolver.gd`，如果涉及英雄死亡、入坟场或英雄复活冷却。
- `scripts/game/effect_data.gd`，如果涉及 `filter_type`、`filter_owner`、`target_zone` 配置字段。
- `scripts/game/hand_play_resolver.gd`，因为复活术是手牌法术。

常见修改：

- 坟场过滤：`filter_type`（`"minion"` / `"building"` / `"all"`）、`filter_owner`（`"self"` / `"any"`）。
- 卡牌多选面板 `CardMultiSelectController` 是通用 UI，不绑定坟场语义；标题、卡牌列表、最大可选数量均由调用方传入。
- 复活从坟场移入手牌后，对应手牌随从通过通用 `hand:place` 动作放置到战场；合法目标为空格或未翻开的背面牌，背面牌会返回公共牌池。
- 英雄自身复活不走普通坟场：英雄死亡后由 `DeathResolver` 生成带 `cooldown_turns = 3` 的 `HandCardState` 进入所属玩家手牌。冷却在玩家自己的回合开始时推进，UI 会在手牌右上角显示冷却数字。
- 坟场移除必须从高索引到低索引删除，避免索引偏移。

### 衍生牌与卡牌生成

优先读：

- `scripts/effects/add_card_to_hand_effect.gd`
- `scripts/effects/choose_card_to_hand_effect.gd`
- `scripts/data/card_database.gd` 中 `load_faction()` 对 `tokens[]` 的处理。
- `scripts/data/card_data.gd`
- `data/cards.json`

常见修改：

- 新增衍生牌：在目标种族 `tokens[]` 中定义卡牌（`count: 0`，不入牌池）。
- 新增生成衍生牌的效果：使用通用效果 `add_card_to_hand` + `card_id`；需要多张时配置 `amount`，省略则默认 1；不要为每种衍生牌写专用效果。
- 新增三选一或多选获取：使用通用效果 `choose_card_to_hand` + `card_ids`；固定额外奖励用 `bonus_cards` 配置，不要把选择面板逻辑写进具体卡牌。
- 衍生牌也可用于英雄配套法术生成的随从（如安东尼达斯的召唤水元素），享受完整的英雄关联约束。

### 行动系统

优先读：

- `scripts/actions/card_action.gd`
- `scripts/actions/action_registry.gd`
- 对应行动文件：`move_action.gd`、`attack_action.gd`、`spell_action.gd`
- `scripts/game/interaction_manager.gd`

常见修改：

- 新增行动、目标选择、行动资源消耗、动作菜单可见性。
- 行动规则不要写进 UI；优先新增或修改 `CardAction` 子类。
- AOE 范围目标选择复用 `InteractionManager` 的目标选择状态：战场行动通过 `start_action_selection()` + `action.get_area_info()` 判断 area 模式，手牌法术通过 `start_hand_card_target_selection()` + `SpellTargetResolver.get_area_dimensions()` 判断 area 模式；area 模式下全棋盘格子为合法目标，悬停显示蓝色 area 预览。
- 动态法术授予（例如学习最近一次法术）优先改 `GrantedSpellResolver` 和 `PlayerState` 的施法历史；`ActionRegistry` 只负责把解析出来的 spell data 转成动作。

### 攻击、死亡、占领

优先读：

- `scripts/actions/attack_action.gd`
- `scripts/game/death_resolver.gd`
- `scripts/game/trigger_resolver.gd`
- `scripts/game/event_context.gd`
- `scripts/ui/attack_occupy_choice_controller.gd`
- `scripts/ui/card_animation_controller.gd`，仅当改攻击表现。

常见修改：

- 攻击范围、远程/近战区分、击杀后占领、死亡触发、入坟、摧毁后效果。
- 当前近战击杀随从或摧毁建筑都可占领；远程击杀不触发占领。
- 攻击后的单位自身触发效果走 `TriggerResolver` 的 `after_attack`；目标被攻击敌方单位时使用 `target: "attack_target_enemy_unit"`，只作用于被攻击敌方随从时使用 `target: "attack_target_enemy_minion"`。0 攻但需要攻击触发的单位使用关键词 `can_attack_with_zero_attack`。手牌升级牌授予单位触发效果时使用 `grant_unit_trigger_effects` + `granted_trigger` + `granted_effects`。
- 死亡触发统一走 `TriggerResolver`；效果伤害应先伤害全部目标，再调用 `GameManager.resolve_dead_states()` 做批量死亡结算。
- 死亡事件上下文 key 和触发名统一放在 `EventContext`。

### 法术和效果

优先读：

- `scripts/actions/spell_action.gd`
- `scripts/game/spell_target_resolver.gd`
- `scripts/game/hand_play_resolver.gd`，如果是手牌法术。
- `scripts/game/board_slot_effect_resolver.gd`，如果是陷阱、地形、格子光环等固定格子效果。
- `scripts/data/board_slot_effect.gd`，如果需要新增格子效果数据字段。
- `scripts/effects/effect_registry.gd`
- `scripts/effects/card_effect.gd`
- `scripts/game/trigger_resolver.gd`，如果涉及触发时机。
- `scripts/game/event_context.gd`，如果效果需要读取触发上下文。
- 对应效果文件。

常见修改：

- 新增治疗、伤害、护盾、翻牌、资源分、复活、卡牌生成等公共效果。
- 法术强度统一走 `modify_spell_power` 与 `CardEffect.get_spell_scaled_amount()`；只有施法入口打了 `_apply_spell_power` 的运行时效果会吃法强，非施法触发不要手动加成。
- 复活效果 `resurrect` 通过 `filter_type`/`filter_owner`/`amount`/`target_zone` 配置，可被不同卡牌复用；当前支持复活到 `hand`。选中 UI 委托给 `CardMultiSelectController`。是否有合法坟场候选由 `ResurrectEffect.can_execute()` 判断，手牌施放入口只通过 `EffectRegistry.can_execute_effect()` 询问，不直接依赖具体效果类。
- 有效治疗联动走 `on_effective_heal` 触发。`HealEffect` 只负责计算实际恢复量并排队触发；按有效治疗量缩放的效果使用 `amount_source: "effective_heal"`，例如战斗牧师的 `gain_attack`。
- 法术目标规则统一放在 `SpellTargetResolver`。
- 魔法免疫统一由 `SpellTargetResolver` 和 `CardEffect.get_target_states()` 处理。新增法术目标规则、AOE 或自动施法时不要绕过这两个入口。
- `all_minions` 只选正面随从，是当前普通施法的默认目标规则；`all_units` 会选正面随从和建筑，只能在明确设计为“法术可影响建筑”时使用。
- `empty_or_hidden_slots` 选空格或背面格，当前用于诱蛊这类设置到格子上的法术。格子效果不要写进 `CardState`，应通过 `set_slot_trap` 写入 `BoardSlotEffectResolver`，并在移动、手牌放置、翻开三个入口统一触发。
- 多段效果如果需要不同目标，要在效果上显式写 `target`；`selected_adjacent_enemy_minions` 可用于以选中目标为中心，伤害/影响周围 8 方向敌方随从。
- `selected_area_enemy_minions` 和 `selected_area_all_minions` 用于 AOE 范围效果：读取效果配置的 `area_rows`/`area_cols`，通过 `BoardQuery.get_area_slots()` 展开区域，再按 `CardEffect.AreaFilter` 过滤。区域尺寸从效果 JSON 配置，与 target_rule 解耦。
- 效果如果可能致死，应优先批量收集受影响目标并调用 `GameManager.resolve_dead_states()`；单体特殊流程才使用 `check_and_destroy_if_dead()`。
- 固定授予法术用 `grant_spell_actions`；根据玩家历史动态授予法术用 `grant_last_spell_action` + `source_card_ids`，不要在 UI 或具体卡牌名分支里拼动作。

### 玩家资源、回合、胜负

优先读：

- `scripts/data/player_state.gd`
- `scripts/game/victory_resolver.gd`
- `scripts/ui/turn_status_controller.gd`
- `scenes/debug/scripts/debug_panel.gd`
- `scripts/game/game_manager.gd` 中 `initialize_players()`、`end_turn()`、`update_turn_status_view()`、`award_resource_score()` 局部。

常见修改：

- 法力、翻牌次数、资源分、胜利目标、HUD 展示。
- 当前资源分初始 0，达到 `GameManager.victory_resource_score`，默认 80，触发胜利。

### HUD 和调试面板

优先读：

- `main.tscn`
- `scripts/ui/turn_status_controller.gd`
- `scenes/debug/scripts/debug_panel.gd`

常见修改：

- 右上角玩家信息、法力、翻牌数、资源分、施法按钮。
- 右侧装备展示区由 `scripts/ui/equipment_display_controller.gd` 管理，随当前玩家切换刷新。
- DebugPanel 只展示状态，不参与规则；当前支持收起成右上角小按钮，避免遮挡棋盘和右侧展示区。

### 动画表现

优先读：

- `scripts/ui/card_animation_controller.gd`
- `scripts/ui/card_pool_view_controller.gd`
- `scripts/ui/hand_drawer_controller.gd`
- `scripts/game/game_manager.gd` 中 `play_*_animation()` 局部。

常见修改：

- 移动、近战攻击、远程攻击、法术特效、补牌飞行、入手牌飞行。
- `summon` 是召唤水元素的水蓝法阵与水滴扩散表现，`gu_summon` 是苗疆蛊术召唤的暗绿蛊雾与蛇形脉冲表现；二者都属于无目标手牌法术的 `play_spell_cast_at_rect()` 分支。
- `arcane_aura` 是辉煌光环的一次性施法/附着动画，持续视觉由 `CardStatusOverlay` 绘制。
- `baptism` 是洗礼的金色治疗脉冲和扩散圣光冲击表现。
- `gu_lure` 是诱蛊释放到格子的暗绿法阵表现；`gu_trap_trigger` 是诱蛊触发时的毒红咬合和蛊孢爆散表现。
- `blizzard` 是暴风雪的冰蓝色区域覆盖 + 消散特效，走 `play_area_spell_cast()` → `play_blizzard_area_spell()` 专用 AOE 动画入口。区域效果面板由 `create_blizzard_area_effect()` 创建。
- 动画控制器不直接改规则状态；规则变化由 `GameManager` 在 `await` 后处理。

### 建筑

优先读：

- `scripts/data/card_data.gd`
- `scripts/data/card_state.gd`
- `scripts/actions/attack_action.gd`
- `scripts/game/reveal_resolver.gd`
- `scripts/game/death_resolver.gd`

当前约定：

- `type: "building"`。
- 建筑是 `is_unit()`，可被攻击和摧毁。
- 中立建筑翻开后无 owner、不可操纵。
- 玩家种族建筑翻开后归属该玩家。
- 建筑默认不可移动、不可主动操作。

### 中立牌库

优先读：

- `data/cards.json`
- `scripts/game/game_manager.gd` 中 `create_initial_card_pool()` 局部。
- `scripts/game/reveal_resolver.gd`
- `scripts/data/card_pool.gd`

当前约定：

- 中立牌库 id 是 `neutral`，`kind: "neutral_pool"`。
- 双方种族牌库和中立牌库一起洗入公共牌池。
- 中立手牌类卡牌翻开后进入当前玩家手牌。
- 中立棋盘单位翻开后留在战场且通常无 owner。

### AI 对手

优先读：

- `scripts/ai/ai_controller.gd`
- `scripts/ai/ai_board_evaluator.gd`
- `scripts/ai/ai_hand_evaluator.gd`
- `scripts/ai/ai_common.gd`
- `scripts/game/game_manager.gd` 中 `schedule_ai_turn_if_needed()`、`_run_ai_turn()` 和 `choose_card_indices_for_ai()`。

常见修改：

- 新增 AI 可用行动：先确认 `CardAction.requires_target()`，无目标动作要单独评分，不要依赖 `get_valid_targets()` 返回非空。
- AI 回合使用候选动作评分循环，每执行一步都要重新收集候选。不要把逻辑重新写成固定的“先手牌、再随从、再翻牌”顺序。
- AI 卡住优先查 `_run_ai_turn()` 和 `ai_turn_watchdog_seconds`。watchdog 只做兜底结束回合；真正的根因通常是某个 `await` 的动作、动画或选择型效果没有返回。
- 新增需要选择候选牌的效果：人类玩家可以调用 `CardMultiSelectController`，AI 玩家必须走自动选择路径，当前统一从 `GameManager.choose_card_indices_for_ai()` 获取索引。
- 新增手牌玩法时，AI 应调用 `GameManager.get_hand_play_resolver()` 暴露的规则入口，不要穿过 UI 控制器访问 resolver。

## 尽量避免的高消耗行为

- 不要每次完整读取 `docs/codex-session-2026-05-11-godot-intro.md`。
- 不要每次完整读取 `scripts/game/game_manager.gd`；先 `rg` 函数名，再局部读取。
- 不要为了小改动完整复盘 `docs/architecture.md`。
- 不要把 UI、规则、数据、动画全局扫一遍，除非用户明确要求架构整理。

## 常用验证

基础验证：

```powershell
python -m json.tool data\cards.json
godot --headless --path . --check-only
godot --headless --path . --quit-after 1
```

搜索建议：

```powershell
rg -n "关键词" scripts data docs main.tscn
rg --files scripts scenes data docs
```

读取建议：

- PowerShell 读取中文文件时优先使用 UTF-8 语义，避免乱码影响补丁判断。
- 需要修改中文密集文件时，尽量用稳定结构锚点，而不是依赖终端里显示出的乱码文本。
