# War Card Architecture

> Encoding: this document is UTF-8. If a document cannot be edited by apply_patch, treat it as a bug and normalize it back to UTF-8 instead of appending around broken bytes.

## Project Shape

This is a Godot tabletop card battler. The match starts at the faction/hero selection page, then enters a board scene. The rules are data-driven through `data/cards.json`; runtime behavior is implemented by reusable actions, effects, status resolvers, and UI controllers.

Main directories:

- `data/`: card and faction definitions.
- `scenes/`: Godot scenes, including board, card, start menu, and debug UI.
- `scripts/data/`: persistent and runtime data models.
- `scripts/actions/`: player-visible board actions such as move, attack, spell, inject venom, venom burst, mounted attack, and faction skill actions.
- `scripts/effects/`: reusable effect implementations referenced by JSON.
- `scripts/game/`: orchestration, target resolution, triggers, death, hand play, passives, board layers, AI helpers, and match setup.
- `scripts/ui/`: panels, animation controllers, action menu, hand drawer, equipment display, status overlay, faction panels, and victory screen.
- `scripts/ai/`: AI candidate generation, evaluation, and execution.

## Core Data Model

`CardData` is immutable card definition data loaded from `cards.json`: id, type, role, level, count, keywords, stats, effects, spell actions, configured actions, mounted attacks, equipment type, and hero metadata.

`CardState` is a board instance. It owns runtime properties such as owner, slot, layer, face-up state, current attack/health, max health, shield, armor, statuses, action counters, and origin snapshot.

`HandCardState` wraps hand entries that need cooldown or runtime metadata, such as hero revival cards. Code that reads player hands should use `HandCardState.get_card_data(entry)` instead of casting directly to `CardData`.

`PlayerState` owns faction identity, hand, equipment, mana, resource score, graveyard, faction resources, board vision, and current-turn counters.

`BoardCell` stores slot identity and capability. The 7x7 board has logical cells whose properties travel with the cell during swaps. A cell that began as an inner 5x5 battlefield cell remains refill/place-capable even if swapped outward; an original outer cell remains non-refill/non-ground-place even if swapped inward.

## Card Data Rules

`cards.json` contains factions. A faction can define `heroes`, `cards`, `tokens`, and faction-specific runtime configuration.

Card types currently include minion, spell, building, upgrade, and equipment. Card levels drive the refill pool. Level 1 is used first, then level 2, then level 3. Neutral cards are mixed with both selected factions unless a faction rule removes them, such as Miaojiang removing Life Spring.

Hero attached cards enter the pool only when that hero is selected. Hero-attached hand cards require the owning hero to be on board before they can be used unless a future card explicitly opts out.

Default-in-hand upgrades are placed directly into the player's hand at match start and can provide persistent passives without entering the board pool.

## Board And Layers

The board is 7x7. The inner 5x5 cells are normal battlefield cells. Outer cells are normally not refilled and not valid for ground placement, but flying units may use the air layer there.

A slot can hold independent ground and air layers. Ground and air occupancy are independent. A flying unit must not block clicks intended for the empty ground layer in the same slot.

Refill, placement, and card-pool logic must use the board cell capability, not the current visual position.

## Interaction State

`InteractionManager` owns idle, focused board card, board target selection, focused hand card, hand target selection, and multi-step selection states. Right click and Escape should leave target/focus states consistently.

`ActionMenuController` only displays actions. Action availability belongs to actions/resolvers.

## Actions

Every board action extends `CardAction`. Primary action groups include movement, attack, and spell. Action locks decide whether a unit can combine groups in a turn. Keywords such as cavalry, mobile assault, spell_move, and spell_attack modify these locks.

Important action classes:

- `MoveAction`: adjacent movement by default; `teleport` keyword allows all legal empty slots for the unit layer.
- `DirectionalMoveAction`: configured no-target side movement. It moves one slot in a fixed direction and reuses `MoveAction` legality/execution. Current example: `westward` / 西行 on 通风猕猴 moves left, costs no main action, spends no movement, and can be used repeatedly while the left slot remains legal.
- `AttackAction`: normal attack, ranged logic, giant splash, occupy prompt, armor reduction, stealth target filtering, and break-stealth after attack.
- `SpellAction`: configured spell actions on units. It resolves targets through `SpellTargetResolver`, executes effects, and breaks stealth by default unless `breaks_stealth: false` is configured.
- `EffectAction`: generic configured action wrapper for actions that only need target selection plus effect execution.
- `MountedAttackAction`: independent rider-style attack such as Hippogryph rider archer attack.
- `FixedMeleeDamageAction`: fixed-damage melee side action such as claw strike.

## Effects

Effects are JSON-driven and registered in `EffectRegistry`. `EffectData` is the shared configuration vocabulary. Add new keys there before using strings across code.

Reusable effects include healing, damage, shield, resource, mana, flips, apply/cleanse status, grant actions/spell actions/keywords/reborn, add or choose cards into hand, resurrect, evolve, ordered sacrifice, board traps, board cell swaps, linked death, faction runtime states, board vision, moonblade, and multi-target spell effects.

Rules should prefer generic effects over one-card scripts. A card-specific effect is acceptable only when the mechanic cannot be expressed as reusable data.

`on_enter_board` is the shared trigger for a unit entering the board through reveal or hand placement. Use it for triggered entry effects instead of duplicating `on_reveal` and placement branches.

`after_friendly_attack` is broadcast to other friendly board units after a normal attack. Effects can use `source_card_ids` to filter the original attacker. Current example: Monkey Spirit `hair_clone` copies Sun Wukong's stats on enter and uses `assist_attack_attack_target` to attack Sun Wukong's attack target when in legal range.

## Targeting

`SpellTargetResolver` owns target rules. Existing rules include all minions, all units, non-hero minions, non-buildings, selected areas, 2x2 regions, adjacent targets, card-id filtered targets, stealth and magic immune filtering.

Magic immune is a base capability: magic immune units cannot be selected by spells and are skipped by spell AOE. Stealth prevents enemy actions from selecting that unit. Friendly actions may still select friendly stealth units.

Multi-step target flows should use shared controllers such as board pair selection or card multi-select rather than embedding state in a single card implementation.

## Status System

`CardStatus` records temporary and persistent modifiers. Statuses can have id, tags, duration, duration scope, stack policy, payload modifiers, trigger effects, turn effects, and death persistence.

A status with no turn duration can still be non-permanent in the gameplay sense. Most buffs, shields, charms, links, and spell-granted states should disappear on death unless explicitly marked `persists_after_death`.

Important status tags:

- `damage_prevention`: divine shield style prevention.
- `action_prevention`: cannot act, used by rooted/frozen style control.
- `stealth`: target invisibility.
- `breaks_on_attack_or_spell`: removed after normal attack or spell action.

Specific status families:

- `rooted`: action prevention until the unit takes real shield/health damage. Its visual is a golden mask with a central `?` seal.
- `stealth`: enemies cannot target; current Sun Wukong `gather_scatter_qi` grants stealth, teleport, and critical.
- `poison`: unique status by total damage. Higher total poison replaces lower poison. Poison turn-end damage resolves before healing.
- `snake_venom`: temporary attack reduction linked to poison duration; must restore actual previous amount, not a fixed value.
- `charm`: control-changing status that can be cleansed.
- `death_immunity`: keeps unit at 0 health until status ends; death is checked when it expires.
- `reborn`: death triggers still happen, then the unit revives in place and skips graveyard/refill/occupy.
- `health_modifier`: stackable max-health modifiers such as Power Word: Shield. Cleansing lowers max/current health and may cause death resolution.

`CardState.recalculate_status_modifiers()` is responsible for derived stat changes. Do not manually add fixed values back when a status expires; store or derive the actual modifier.

## Damage, Death, Refill

Damage should flow through `CardState.take_damage()` unless a mechanic explicitly kills without damage. This keeps shield, armor-independent damage, rooted break, poison immunity, death immunity, and death checks consistent.

Armor reduces normal attack damage only. It is not part of `take_damage()` because poison, spells, fixed damage, and reflected damage should not automatically be reduced.

Death is resolved by `DeathResolver`. It handles graveyard snapshots, death triggers, hero revival, reborn, linked death, resource score, refill, and occupy side effects.

Hero death does not enter graveyard. A hero becomes a hand minion card with cooldown. Equipment such as Dragon Palace Treasure can modify revive cooldown.

Refill must use cell capability and level-based pool order.

## Hand, Equipment, And Passives

The hand drawer has zones for spells, minions, upgrades, and equipment. Hand cards can focus and show an action list.

Hand actions include spell cast, minion placement, equipment equip, and passive upgrades. Equipment slots are per type. Equipping a second item of the same type returns the old item to hand.

Equipment passives use `trigger: "while_equipped"` and are refreshed through `HandPassiveResolver`. Do not write equipment behavior directly in `PlayerState.equip_card()` unless it is truly zone bookkeeping.

## Faction Runtime Systems

Faction resources and skills are player state, not UI state.

Implemented examples:

- Night Elf time cycle: sunrise, noon, dusk, moonrise, full moon, moonset.
- Miaojiang poison ecosystem: toxic spring, venom storage, venom burst, poison insects, poison upgrades.
- Fox spirit tails: starts at 1, max 9. Default-in-hand upgrades unlock thresholds and faction skill sacrifice.
- Monkey spirit action-resource keywords: `spell_move` and `spell_attack` allow spellcasting to coexist with movement or attacking.
- Board vision: temporary full-board or future per-slot preview for face-down cards.

## AI

AI is split into candidate building, board evaluation, hand evaluation, and action execution. It should use the same public action and target APIs as the player. Put legality in actions/resolvers, scoring in evaluators.

## UI And Animation

UI controllers are presentation-only. They should not mutate rule data except through explicit callbacks to game/action/effect layers.

One-shot effects go in `CardAnimationController`. Persistent status visuals go in `CardStatusOverlay`. Numeric icons go in the card status/value stack in `Card`.

## Documentation And Encoding

All docs must be UTF-8. If a doc is not valid UTF-8, normalize or rewrite it first. Do not keep appending around broken bytes.

Use `docs/codex-working-map.md` as the quick index for common task types. Use this file for conceptual boundaries and architectural rules.
