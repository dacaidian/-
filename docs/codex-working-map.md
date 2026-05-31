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
- `scenes/start_menu/player_panel.tscn` 和 `scenes/start_menu/scripts/player_panel.gd`，如果修改种族选择面板样式。
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
- 入口页背景氛围使用 `StartMenu._add_ambient_lighting()` 动态创建低透明度微光层。调整质感时优先改粒子数量、透明度、速度和尺寸；避免把明显装饰圆点放到 UI 上层，也不要让氛围层接管任何点击。

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

- `python tools/validate_cards.py`
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
- 生命上限类状态使用 `status_tags: ["health_modifier"]` 和 `payload.max_health_bonus`，移除状态时由 `CardState.status_max_health_bonus` 自动回滚。吞噬这类“多次叠加但 payload 已累计”的状态需要配置/写入 `cumulative_status_modifier: true`，避免按 stacks 二次相乘。
- 毒当前是 `poison` 唯一状态；使用 `status_tags: ["damage_over_time"]`、`payload.poison_damage` 和 `duration_turns`。新毒只在剩余总伤害更高时覆盖旧毒。毒伤害在 `after_turn_end` 普通触发前由 `StatusResolver.resolve_pre_trigger_status_effects()` 结算，早于回合结束治疗。
- 剧毒之泉的储毒不是 DOT，使用 `stored_venom` + `payload.stored_venom_damage` 表示建筑储存资源，并复用毒性数字图标显示总量。
- 状态施加前修正由 `StatusModifierResolver` 统一处理；`modify_applied_status` 可按 `status_ids` 修改己方施加的新状态，例如毒性爆发把毒的总伤害压缩到 1 回合内结算。
- 同源同名状态默认叠层；需要刷新不叠层、替换或忽略时，在状态配置中使用 `stack_policy`（`stack` / `refresh` / `replace` / `ignore`）。例如蛇毒减攻使用 `refresh`，重复施加不继续叠加攻击惩罚。
- `apply_status` 效果支持可选 `apply_animation` 字段，指定状态施加瞬间的动画 key；没有该字段时不播放额外动画。
- 状态自身也可以通过 `payload.trigger_effects` 提供触发效果，由 `EffectRegistry.execute_status_triggers()` 结算。当前用于蛊巨蜥“吞噬”继承最高级毒性攻击，以及子母蛊 `life_link` 在 `on_destroyed` 时触发 `destroy_linked_units`；不要把这种状态授予的触发效果写进 `AttackAction` 或 `DeathResolver`。
- 同命/链接类状态读取 `EffectData.get_trigger_status()` 获取触发的具体状态层，再用 `payload.link_id` 找到同一链接另一端。AB、BC 链式链接依赖死亡队列自然传播，独立链接必须使用独立 link id。
- 免疫死亡类状态使用 `status_tags: ["death_prevention"]`。`DeathResolver` 会跳过带该 tag 的单位；状态到期后由 `StatusResolver` 重新检查 0 生命单位并按标准死亡队列处理，不要在具体伤害效果里写“如果是薄葬”。
- 状态覆盖视觉统一放在 `CardStatusOverlay`；`Card` 只负责绑定状态、摆放覆盖层和棋盘数值图标。当前持续覆盖视觉包括圣盾、辉煌光环、冻结、励蛊、同命蛊和薄葬；毒性这类有数值的状态走 `Card` 的状态数字栈，放在血量图标上方并显示剩余总伤害。
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
- 手牌持续被动由 `HandPassiveResolver` 统一刷新；`modify_flip_capacity` 改翻牌上限，`set_unit_movement` 按 `card_ids` 改己方战场单位移动力，`modify_unit_attack` 按 `card_ids` 给己方战场单位叠加可刷新的攻击力光环，`modify_unit_attack_speed` 改攻速。需要绑定种族时间/季节时使用 `required_runtime_state_id`。
- 限制种族运行时状态循环也属于手牌持续被动：使用 `restrict_faction_runtime_cycle` + `runtime_state_ids` + `fallback_runtime_state_id`，保持回合推进流程通用，不按卡牌名分支。
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
- 新法术动画优先新增 `animation` key，让 `CardAnimationController` 复用或扩展既有表现，例如 `pyroblast` 是放大版 `fireball`、`moonblade` 是二段弹射投射物。AOE 法术使用专用动画入口 `play_area_spell_cast()`。

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
- 对应行动文件：`move_action.gd`、`attack_action.gd`、`mounted_attack_action.gd`、`spell_action.gd`
- `scripts/game/interaction_manager.gd`

常见修改：

- 新增行动、目标选择、行动资源消耗、动作菜单可见性。
- 动态非施法行动优先接入 `GrantedActionResolver`，不要在 UI 或 `GameManager` 里按卡牌名临时添加按钮。当前剧毒之泉体系使用 `InjectVenomAction` 和 `VenomBurstAction`。
- 手牌升级牌授予非施法行动使用 `grant_actions` + `active_zone: "hand"` + `card_ids` + `actions`；具体行动由 `GrantedActionResolver.create_action_from_data()` 创建。当前“精英月刃豹”授予女猎手副动作 `claw_strike`。
- 骑乘攻击使用卡牌静态字段 `mounted_attacks`，由 `ActionRegistry` 转换为 `MountedAttackAction`。骑乘者的增益按 `rider_card_id` 读取；不要通过给承载单位临时添加 `ranged` 等关键字来模拟骑手能力。
- 副动作不消耗主行动力时设置 `main_action_cost = 0`；需要每回合限次时设置 `once_per_turn = true`，不要把限次状态写进 UI。
- 判断“普攻附毒能力”优先读 `PoisonAttackResolver`，它会合并静态攻击触发、升级牌授予触发和状态 payload 触发；不要只靠卡牌 id 判定毒虫。
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
- 状态授予的攻击后效果走 `CardStatus.payload.trigger_effects`，由 `EffectRegistry.execute_status_triggers()` 与静态/升级授予触发共用同一上下文。
- 死亡触发统一走 `TriggerResolver`；效果伤害应先伤害全部目标，再调用 `GameManager.resolve_dead_states()` 做批量死亡结算。
- 死亡事件上下文 key 和触发名统一放在 `EventContext`。

### 法术和效果

优先读：

- `scripts/actions/spell_action.gd`
- `scripts/game/spell_target_resolver.gd`
- `scripts/game/hand_play_resolver.gd`，如果是手牌法术。
- `scripts/game/board_slot_effect_resolver.gd`，如果是陷阱、地形、格子光环等固定格子效果。
- `scripts/data/board_slot_effect.gd`，如果需要新增格子效果数据字段。
- `scripts/game/board_pair_selection_controller.gd`，如果效果需要多次选择两个棋盘格。
- `scripts/game/board_unit_pair_selection_controller.gd`，如果效果需要在施放后选择两个棋盘单位。
- `scripts/effects/effect_registry.gd`
- `scripts/effects/card_effect.gd`
- `scripts/game/trigger_resolver.gd`，如果涉及触发时机。
- `scripts/game/event_context.gd`，如果效果需要读取触发上下文。
- 对应效果文件。

常见修改：

- 新增治疗、伤害、护盾、翻牌、资源分、复活、卡牌生成、吞噬、单位链接等公共效果。
- 法术强度统一走 `modify_spell_power` 与 `CardEffect.get_spell_scaled_amount()`；只有施法入口打了 `_apply_spell_power` 的运行时效果会吃法强，非施法触发不要手动加成。
- 复活效果 `resurrect` 通过 `filter_type`/`filter_owner`/`amount`/`target_zone` 配置，可被不同卡牌复用；当前支持复活到 `hand`。选中 UI 委托给 `CardMultiSelectController`。是否有合法坟场候选由 `ResurrectEffect.can_execute()` 判断，手牌施放入口只通过 `EffectRegistry.can_execute_effect()` 询问，不直接依赖具体效果类。
- 有效治疗联动走 `on_effective_heal` 触发。`HealEffect` 只负责计算实际恢复量并排队触发；按有效治疗量缩放的效果使用 `amount_source: "effective_heal"`，例如战斗牧师的 `gain_attack`。
- 法术目标规则统一放在 `SpellTargetResolver`。
- 魔法免疫统一由 `SpellTargetResolver` 和 `CardEffect.get_target_states()` 处理。新增法术目标规则、AOE 或自动施法时不要绕过这两个入口。
- `minions_by_card_ids` 使用 `spell_data.card_ids` 做目标白名单，并排除施法者自身；当前用于蛊巨蜥“吞噬”可选毒蝎、蛊毒蛇、生蛊王蛇和其他蛊巨蜥。
- `all_minions` 只选正面随从，是当前普通施法的默认目标规则；`non_hero_minions` 只选正面非英雄随从，适合火球术这类不能打英雄的法术；`all_units` 会选正面随从和建筑，只能在明确设计为“法术可影响建筑”时使用。
- `empty_or_hidden_slots` 选空格或背面格，当前用于诱蛊这类设置到格子上的法术。格子效果不要写进 `CardState`，应通过 `set_slot_trap` 写入 `BoardSlotEffectResolver`，并在移动、手牌放置、翻开三个入口统一触发。
- 多段棋盘格/单位选择不要硬塞进普通 `target_rule`。如果法术先成功施放、后续还要多次选择格子或单位，优先实现效果内部选择协作者；当前 `swap_board_slots` 通过 `BoardPairSelectionController` 执行“选格 A、选格 B、交换内容”的重复流程，`link_units` 通过 `BoardUnitPairSelectionController` 执行“双单位选择并建立状态链接”，`moonblade` 通过 `BoardUnitBounceSelectionController` 在第一目标确定后选择相邻弹射目标。单位选择控制器必须按 `CardState` 选择，不按 slot 选择，否则飞行单位与地面单位同格时会选错层。
- 如果第一段目标还依赖效果内部条件（例如月刃要求第一目标附近存在可弹射随从），在对应 `CardEffect.can_execute()` 中实现校验；`SpellAction` 会把候选目标注入运行时效果并过滤掉不可执行目标。
- 交换单元格会同时交换 `BoardCell` 性质和 `CardState` 内容。初始内圈地面格被换到外圈后仍可补牌/放置普通随从，初始外圈边缘格被换到内圈后仍不可补牌/放置普通随从；普通移动仍只交换卡牌内容。
- 多段效果如果需要不同目标，要在效果上显式写 `target`；`selected_adjacent_enemy_minions` 可用于以选中目标为中心，伤害/影响周围 8 方向敌方随从。
- `selected_area_enemy_minions` 和 `selected_area_all_minions` 用于 AOE 范围效果：读取效果配置的 `area_rows`/`area_cols`，通过 `BoardQuery.get_area_slots()` 展开区域，再按 `CardEffect.AreaFilter` 过滤。区域尺寸从效果 JSON 配置，与 target_rule 解耦。
- `enemy_and_neutral_units` 用于全场效果：选择所有非己方正面单位，包含敌方单位和中立随从/建筑；当前用于流星陨落的回合结束状态伤害。
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
- `summon` 是召唤水元素的水蓝法阵与水滴扩散表现，`gu_summon` 是苗疆蛊术召唤的暗绿蛊雾与蛇形脉冲表现，`medical_practice` 是巫医行医的草药光点与苗疆药雾脉冲；这些都属于无目标法术的 `play_spell_cast_at_rect()` / 自身施法分支。
- `arcane_aura` 是辉煌光环的一次性施法/附着动画，持续视觉由 `CardStatusOverlay` 绘制。
- `gu_life_link` 是子母蛊的双目标蛊环与生命线连接动画；持续链接视觉由 `CardStatusOverlay` 绘制。
- `thin_burial` 是薄葬的一次性施法/附着动画；持续死亡庇护视觉由 `CardStatusOverlay` 绘制。
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
- 种族包可通过 `pool_modifiers.exclude_neutral_card_ids` 排除中立卡；当前苗疆族会让公共牌池去掉 `生命之泉`。
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
python tools\validate_cards.py
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

### 棋盘单元格

优先读：

- `scripts/data/board_cell.gd`
- `scripts/game/game_manager.gd` 中 `board_cells`、`is_land_slot()`、`can_refill_ground_slot()`、`can_place_ground_card_on_slot()`。
- `scenes/card_board/scripts/card_board.gd`
- `scripts/game/board_slot_resolver.gd`
- `scripts/game/hand_play_resolver.gd`
- `scripts/game/spell_target_resolver.gd`

常见修改：

- 当前物理棋盘是 7x7，初始内圈 5x5 是普通地面格，初始外圈是战场边缘。奥术空间会交换 `BoardCell.is_land`，所以后续某个物理坐标是否可补牌/放置必须查当前 `BoardCell`，不要按几何位置重算。
- 普通补牌必须走 `can_refill_ground_slot()`；普通随从放置、移动、格子型法术必须走 `can_place_ground_card_on_slot()`。
- 交换单元格（例如奥术空间）不等同于普通放置或补牌，不应调用 `can_place_ground_card_on_slot()` 限制可交换格。交换后由被交换过去的 `BoardCell` 性质决定该位置后续能否补牌/放置。
- 飞行单位进入 `BoardCell.aerial_states`，不要改变现有地面层 `board_states` 的兼容语义。需要“所有单位”的逻辑读 `GameManager.get_all_board_states()`；需要“同一格里的地面/飞行单位”的逻辑读 `GameManager.get_board_states_at_slot()`；补牌、未翻开牌、地面放置仍只走地面层。
- 地面/飞行层查询和落位判断集中在 `scripts/game/board_layer_resolver.gd`，`GameManager` 只保留兼容入口。后续扩展 7x7 外圈、飞行层容量、特殊地形时，优先改这个 resolver。
- 同格多层目标点击由 `scripts/game/target_state_resolver.gd` 解析。玩家可能视觉上点到飞行牌，但当前行动真正需要的是同格地面层；不要把这种层解析逻辑写回 `GameManager` 或具体 UI 节点。
- 会移动棋盘内容且可能播放移动动画的流程集中在 `scripts/game/board_movement_resolver.gd`。普通移入空格、飞行层移动、翻开飞行随从后的提升都走这里；行动或死亡结算只调用 `GameManager` 的语义入口。
- 飞行随从手牌放置、移动、翻开提升分别走 `HandPlayResolver`、`MoveAction`、`RevealResolver.promote_ground_flying_to_aerial()` 相关入口；不要在具体卡牌里直接挪数组。
### 种族运行时状态

优先读：

- `data/cards.json` 中目标种族的 `runtime_state` 配置。
- `scripts/data/player_state.gd` 中 `setup_faction_runtime_state()`、`advance_faction_runtime_state()`。
- `scripts/data/card_database.gd` 中 `get_faction_runtime_state_config()`。
- `scripts/game/game_manager.gd` 中 `initialize_players()`、`end_turn()`、`advance_faction_runtime_state_for_player()`。
- `scripts/ui/faction_time_panel_controller.gd`。

常见修改：

- 新增种族循环状态：在种族 JSON 上添加 `runtime_state`，并用 `cycle[].card_id` 指向 `type: "time"`、`count: 0` 的展示卡。
- 修改状态推进时机：优先改 `runtime_state.advance_trigger` 和 `GameManager.advance_faction_runtime_state_for_player()` 的触发接入，不要把状态推进写进具体卡牌效果。
- 如果要收窄种族运行时状态循环，在升级牌手牌被动中添加 `restrict_faction_runtime_cycle`；有效循环和兜底状态由 `PlayerState` 维护。
- 修改展示样式：只改 `FactionTimePanelController`；它不参与规则结算。
- 新增依赖时间的卡牌效果时，效果应读取 `PlayerState.faction_runtime_state_id`，不要从 UI 面板反查。
### 一次性攻击状态

优先读：

- `data/cards.json` 中 `precision_shot` 这类手牌法术的 `apply_status` 配置。
- `scripts/effects/effect_registry.gd` 的 `execute_status_triggers()`。
- `scripts/effects/card_effect.gd` 的状态触发目标解析。
- `scripts/data/card_status.gd` 和 `scripts/ui/card_status_overlay.gd`。

常见修改：

- 新增“下一次攻击附加效果”时，优先使用 `payload.trigger_effects` + `trigger: "after_attack"`，不要直接改 `AttackAction`。
- 如果效果需要随状态层数叠加，配置 `scale_amount_by_status_stacks: true`。
- 如果状态触发后要消耗，配置 `consume_on_trigger: true`。
- 如果触发效果要作用于本次普通攻击目标，使用 `target: "attack_target_unit"`。

### 种族运行时状态跳转

优先读：

- `scripts/effects/set_faction_runtime_state_effect.gd`
- `scripts/data/player_state.gd` 的 `set_faction_runtime_state_by_id()`。
- `data/cards.json` 中目标种族的 `runtime_state` 配置。
- `scripts/ui/faction_time_panel_controller.gd`

常见修改：

- 新增跳转时间/季节/仪式阶段的卡牌时，使用 `set_faction_runtime_state` + `runtime_state_id`。
- 该效果只改变当前玩家的运行时状态索引，不改循环配置；后续推进仍按原 `cycle` 顺序。
- UI 面板只读 `PlayerState` 当前状态，不参与规则结算。
- 这类卡牌需要施法瞬间表现时，优先在 `CardAnimationController` 中新增独立 `animation` key，例如 `full_moon_cover`。

### 关键词单位类型与攻城

优先读：

- `scripts/data/card_data.gd` 的 `KEYWORD_*` 和 `get_siege_bonus()`。
- `scripts/data/card_state.gd` 的 `add_status()`、`heal()`。
- `scripts/actions/attack_action.gd` 的 `calculate_attack_damage()`。
- `scripts/game/status_resolver.gd` 的毒性结算。

常见修改：

- 新增机械单位：给卡牌配置 `mechanical`；机械不获得毒，不吃毒爆和毒结算，也无法被有效治疗。
- 新增攻城单位：给卡牌配置 `siege_数字`；对建筑普攻时由攻击行动统一追加伤害。
- 不要把机械免毒或攻城额外伤害写进具体卡牌效果里。

### ������Դ�����弼��

���ȶ���

- `scripts/data/player_state.gd`��`faction_resource_*`��`faction_skill_*`��ÿ�غϼ���ʹ�ô������á�
- `scripts/ui/faction_skill_panel_controller.gd`����ǰ���������Դ���ѽ������弼�ܰ�ť��
- `scripts/actions/sacrifice_faction_skill_action.gd`�������ɵ�һ�����弼�ܡ��׼�����
- `scripts/game/hand_passive_resolver.gd`������������ͨ�� `grant_faction_skills` �������弼�ܡ�
- `data/cards.json`������� `faction_resources` / `faction_skills`���Լ� `start_in_hand` Ĭ�����������ơ�

�����޸ģ�

- ����������ֵ����������ɡ�β�����������������ݵ� `faction_resources`���� `PlayerState.setup_faction_resources()` ��ʼ���ͳ־û���
- �������弼�ܣ������������ݵ� `faction_skills`��UI ֻչʾ��ǰ����ѽ����ļ��ܣ������Ƿ����������/Ĭ�����������Ƶ� `grant_faction_skills` Ч��������
- Ĭ�������Ҳ����Ƴص������ƣ����� `start_in_hand: true` �� `count: 0`����ʼ�����ʱ��������ƣ�`CardPool` ��������������ơ�
- ���ܰ�ť���������ͨ��Ŀ��ѡ��� `CardAction`����Ҫ�� UI ��������ֱ�Ӹ�����״̬��

### 授予单位关键词

- 默认入手升级牌授予单位关键词时，使用 `grant_unit_keywords` + `card_ids` + `keywords`。
- `HandPassiveResolver` 将这类手牌持续被动刷新到 `CardState.passive_keywords`，`CardState.has_keyword()` 会同时读取静态关键词和被动关键词。
- 当前狐妖仙“三尾”用它让苏妲己和小狐精获得 `ranged`；不要直接改静态 `CardData.keywords`，避免升级牌失效或离手时无法回滚。

### 右侧 HUD 与种族技能按钮

- 右侧 HUD 位置统一由 `GameManager.update_right_side_hud_layout()` 排布，不要在新增面板里单独写会与装备/时间/回合 HUD 重叠的固定位置。
- 种族技能按钮的启用状态由 `GameManager.get_usable_faction_skill_ids()` 计算：已解锁、未使用、且当前存在合法目标时才可点击。
- 新增种族技能时，优先实现 `CardAction` 子类，并让 `GameManager.create_faction_skill_action()` 创建它；UI 面板只发出 `skill_requested`，不直接改规则数据。

### 种族技能手牌锚点

- 如果种族技能来自默认入手升级牌，点击技能后用 `InteractionManager.start_hand_anchored_action_selection()`，让手牌升级牌保持焦点，同时把实际规则执行者放到 `selected_action_user_state`。
- 目标解析和执行行动时读取 `selected_action_user_state`，不要再默认用 `focused_state`，否则手牌锚点行动会丢失执行上下文。

### 手牌被动资源门槛

- 需要按种族资源实时开关的手牌被动，配置 `required_resource_id` 和 `required_resource_min`。
- 资源变动后要刷新手牌被动；当前“献祭”增加尾数后会调用 `refresh_hand_passives_for_player()`，让“三尾”在尾数达到 3 时立刻生效。

### 狐妖仙尾数升级

- 新增狐妖仙尾数门槛升级时，优先复用 `grant_unit_keywords` + `required_resource_id: "tail"` + `required_resource_min`。
- 当前 `三尾` 授予远程，`六尾` 授予魔法免疫；尾数变化后依赖 `refresh_hand_passives_for_player()` 实时生效或失效。

### 献祭动画

- `献祭` 的规则入口在 `scripts/actions/sacrifice_faction_skill_action.gd`，动画 key 为 `sacrifice`。
- 表现层在 `scripts/ui/card_animation_controller.gd` 的 `play_sacrifice_at_rect()`；新增狐妖仙献祭类表现时只扩展动画控制器，不要把死亡/尾数规则写进动画层。

### 勾魄与临时减攻状态

- 数据入口：`data/cards.json` 中的 `gou_po`，属于苏妲己英雄配套牌。
- 规则入口：复用 `apply_status` + `attack_modifier` + `payload.attack_bonus`，不直接修改静态攻击力。
- 持续表现：`scripts/ui/card_status_overlay.gd` 绘制 `soul_hook` 锁链覆盖层；施加瞬间表现在 `scripts/ui/card_animation_controller.gd` 的 `soul_hook` key。
- 新增类似减攻/增攻状态时，优先复用这套状态修正机制，便于后续驱散统一回滚。

### 魅惑与控制状态

- 目标规则在 `scripts/game/spell_target_resolver.gd`：`low_stat_non_hero_minions` = 非英雄随从且当前攻击力+当前生命值 < 8。
- 控制效果是状态：`CardStatus.STATUS_CHARM` + `TAG_CONTROL`。新增类似控制/反控效果时优先复用 `CardState.recalculate_status_modifiers()` 的归属回滚机制，不直接在法术效果里写 `set_owner()` 后就结束。
- 表现：`CardAnimationController` 中 `charm` key 跑施加动画；`CardStatusOverlay` 持续绘制魅惑光环。

### 战场持续被动与种族资源数值

- 数据入口：卡牌 `effects` 配置 `trigger: "while_on_board"`。当前苏妲己用 `set_unit_attack_to_resource` 让攻击力等于 `tail`。
- 规则入口：`scripts/game/hand_passive_resolver.gd` 的 `refresh_unit_attack_passives()` 会同时合并手牌持续被动和战场单位自身的 `while_on_board` 被动。
- 新增类似“数值等于资源”效果时，优先复用 `set_unit_attack_to_resource` 或扩展同类战场被动，不要在献祭/资源变动效果里写死某张卡的数值修改。

### 行动恢复与攻击修正截断

- 回合开始恢复行动资源走 `GameManager.restore_unit_actions_for_all_players()`，不再只恢复当前玩家单位，以支持魅惑/控制权变化。
- 攻击力被状态减到 0 以下时，`CardState.status_attack_floor_debt` 会保留被截断的部分，状态移除时用它恢复真实基础值。

### 随从施法与短暂控制

- 随从自带的施法动作写在卡牌 `spell_actions` 中，由 `SpellAction` / `SpellTargetResolver` / `EffectRegistry` 走同一套流程。
- 短暂控制类效果复用 `apply_status` + `status_tags: ["control"]`，并用 `duration_turns` / `duration_scope` / `expires_on_trigger` 描述回滚时点。
- `狐念之术` 的范例：目标规则 `low_stat_non_hero_minions`，控制状态持续到施法者回合结束。

### 法术能力修正

- 优先读：`scripts/game/hand_spell_modifier_resolver.gd`、`scripts/game/hand_play_resolver.gd`、`scripts/actions/action_registry.gd`、`scripts/actions/spell_action.gd`。
- 新增改目标规则、动画、效果列表的升级牌时，优先使用 `modify_spell_ability`。手牌法术用 `card_ids` 命中，随从施法动作用 `spell_ids` 命中。
- `魅影` 是首个范例：把 `charm_spell` 和 `fox_mind_art` 的 `target_rule` 改成 `non_hero_minions`。
- 检查手牌法术目标规则时，目标预览、点击解析和最终执行都要带上 `selected_hand_owner_id` 对应的玩家；否则会绕过 `HandSpellModifierResolver` 的动态改写。


### Reborn And Faction Skill Modifiers

Read first:

- `scripts/data/card_state.gd` for reborn layer storage and in-place revival reset.
- `scripts/game/death_resolver.gd` for reborn death events, death trigger timing, and skipped refill/occupy.
- `scripts/effects/grant_reborn_effect.gd` for the reusable reborn-granting effect.
- `scripts/actions/sacrifice_faction_skill_action.gd` for faction skill modifiers.
- `scripts/ui/card_status_overlay.gd` and `scripts/ui/card_animation_controller.gd` for reborn visuals.

Common changes:

- New reborn sources should prefer `grant_reborn`; `health_values: [0]` means full-health revival, positive values mean exact current health after revival.
- Reborn is real death followed by in-place revival: death triggers still happen, but successful reborn does not enter graveyard, refill the slot, or allow occupy.
- Faction skill rewrites should use `modify_faction_skill` with `card_ids` as the affected scope plus `before_target_effects` and/or `suppress_resource_gain`, not UI-specific branches.
