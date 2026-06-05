# Codex Working Map

> Encoding: UTF-8. This file is a quick routing map for future development. Read only the relevant section before editing.

## Always Check First

- `git status --short --branch`: the repo may already contain local commits or user edits.
- `python tools/validate_cards.py`: run after `data/cards.json` changes.
- `godot --headless --path . --check-only`: run after script or scene changes.
- `godot --headless --path . --quit-after 1`: run after gameplay/UI changes.
- Commit and push each finished wave. If GitHub push fails, report local commit hash and `ahead` count.

## Encoding Rule

Docs must be valid UTF-8. If `apply_patch` cannot read a markdown file, repair the file instead of adding more broken content.

## Card Data Tasks

Read first:

- `data/cards.json`
- `scripts/data/card_data.gd`
- `scripts/data/card_database.gd`
- `tools/validate_cards.py`

Common rules:

- Normal cards go in a faction `cards[]` list.
- Derived cards go in that faction's `tokens[]` list.
- Hero-attached cards must be listed under `heroes[].attached_cards`.
- For owner-card targeting, use `target: "owner_card_by_id"` plus `target_card_id` or `card_ids`.
- Run `python tools/validate_cards.py` after editing.

## New Effects

Read first:

- `scripts/game/effect_data.gd`
- `scripts/effects/card_effect.gd`
- `scripts/effects/effect_registry.gd`
- existing effect closest to the new behavior

Common rules:

- Add effect id and keys to `EffectData`.
- Implement a reusable effect in `scripts/effects/`.
- Register it in `EffectRegistry`.
- Keep effects rule-only and data-driven.
- Use `on_enter_board` for effects that trigger when a unit is revealed onto the board or placed from hand.
- Use `after_friendly_attack` plus `source_card_ids` for passive allies that respond to a specific friendly attacker, such as Monkey Spirit `hair_clone`.

## New Actions

Read first:

- `scripts/actions/card_action.gd`
- `scripts/actions/action_registry.gd`
- `scripts/game/granted_action_resolver.gd`
- `scripts/game/action_hint_resolver.gd`

Common rules:

- Choose a primary action group only if it should interact with move/attack/spell locks.
- Use `EffectAction` for configured target-plus-effects actions.
- Use `DirectionalMoveAction` for no-target one-step directional movement, such as 通风猕猴 `westward` / 西行.
- Target legality belongs in action/resolver code, not UI.

## Hand Cards

Read first:

- `scripts/game/hand_play_resolver.gd`
- `scripts/game/hand_interaction_controller.gd`
- `scripts/ui/hand_drawer_controller.gd`
- `scripts/data/hand_card_state.gd`
- `scripts/data/player_state.gd`

Common rules:

- Use `HandCardState.get_card_data(entry)` for hand entries.
- Preserve scroll offsets when focus/action menu refreshes.
- Minion placement must respect board layer and cell capability.
- Equipment replacement returns previous same-type equipment to hand.

## Board And Movement

Read first:

- `scripts/data/board_cell.gd`
- `scripts/game/board_query.gd`
- `scripts/game/board_layer_resolver.gd`
- `scripts/game/board_slot_resolver.gd`
- `scripts/game/board_movement_resolver.gd`
- `scripts/actions/move_action.gd`

Common rules:

- Do not assume one card per slot.
- Ground and air layers are independent.
- Flying units can use outer cells and air layer occupancy.
- Teleport allows movement to any legal empty destination for the unit layer.
- Swapping cells must preserve each cell's original capability.

## Attack And Damage

Read first:

- `scripts/actions/attack_action.gd`
- `scripts/actions/mounted_attack_action.gd`
- `scripts/data/card_state.gd`
- `scripts/game/death_resolver.gd`
- `scripts/game/poison_attack_resolver.gd`

Common rules:

- Normal attacks use armor reduction.
- Spell, poison, fixed damage, and reflected damage do not automatically use armor.
- Giant splash is centralized in `AttackAction`.
- Same-slot ground/air units count as melee-reachable where relevant.

## Statuses

Read first:

- `scripts/data/card_status.gd`
- `scripts/data/card_state.gd`
- `scripts/game/status_resolver.gd`
- `scripts/game/status_modifier_resolver.gd`
- `scripts/effects/apply_status_effect.gd`
- `scripts/effects/cleanse_effect.gd`
- `scripts/ui/card_status_overlay.gd`

Common rules:

- Use status payload/modifiers for dispellable stat changes.
- Do not manually restore fixed amounts on expiry unless the status stored that exact amount.
- `action_prevention` blocks actions generically.
- `breaks_on_attack_or_spell` statuses are removed by attack and by spell actions unless the spell config has `breaks_stealth: false`.
- `rooted` visual is the gold mask with a central `?` seal.
- Poison is unique by total damage and resolves at turn end before healing.

## Spell Targeting

Read first:

- `scripts/game/spell_target_resolver.gd`
- `scripts/game/target_state_resolver.gd`
- multi-selection controllers in `scripts/game/`

Common rules:

- Add target rules to `SpellTargetResolver` instead of custom filtering in a card.
- Magic immune and stealth should be filtered centrally.
- Multi-target spells should reuse multi-selection controllers.

## Death, Graveyard, Refill

Read first:

- `scripts/game/death_resolver.gd`
- `scripts/game/reveal_resolver.gd`
- `scripts/game/trigger_resolver.gd`
- `scripts/game/turn_trigger_resolver.gd`
- `scripts/data/player_state.gd`

Common rules:

- Death snapshots should preserve origin data and last runtime state.
- Hero death creates a cooldown hand card instead of graveyard entry.
- Refill only happens for cells that are refill-capable.
- Ordered sacrifice uses `sacrifice_friendly_minions` so each death can affect later deaths.

## Equipment

Read first:

- `scripts/data/player_state.gd`
- `scripts/game/hand_play_resolver.gd`
- `scripts/game/hand_passive_resolver.gd`
- `scripts/ui/equipment_display_controller.gd`

Common rules:

- Equipment type controls replacement.
- Persistent equipment bonuses use `trigger: "while_equipped"`.
- Do not put equipment stat logic inside UI.

## Faction Systems

Read first:

- `scripts/data/player_state.gd`
- `scripts/ui/faction_skill_panel_controller.gd`
- `scripts/ui/faction_time_panel_controller.gd`
- faction actions/effects

Current systems:

- Night Elf time cycle.
- Miaojiang poison ecosystem.
- Fox spirit tails and sacrifice skill.
- Monkey spirit spell/move/attack mixing, board vision, immobilize, stealth/critical, armor equipment.

## AI

Read first:

- `scripts/ai/ai_candidate_builder.gd`
- `scripts/ai/ai_board_evaluator.gd`
- `scripts/ai/ai_hand_evaluator.gd`
- `scripts/ai/ai_action_executor.gd`
- `scripts/ai/ai_common.gd`

Common rules:

- AI should call the same action and hand APIs as the player.
- Put legality in actions/resolvers, scoring in evaluators.

## UI And Visuals

Read first:

- `scripts/ui/card_animation_controller.gd`
- `scripts/ui/card_status_overlay.gd`
- `scenes/card/scripts/card.gd`
- `scripts/ui/hand_drawer_controller.gd`
- relevant panel controller

Common rules:

- One-shot effects go in `CardAnimationController`.
- Persistent status visuals go in `CardStatusOverlay`.
- Numeric icons go in the card status/value stack in `Card`.
- UI controllers should not own gameplay rules.

## Validation And Commit Checklist

1. Run `python tools/validate_cards.py` after card changes.
2. Run `godot --headless --path . --check-only` after script/scene changes.
3. Run `godot --headless --path . --quit-after 1` after gameplay or UI changes.
4. Check `git diff --stat`.
5. Commit with a clear Chinese message.
6. Push. If push fails because GitHub is unreachable, report local commit hash and `ahead` count.
