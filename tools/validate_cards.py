#!/usr/bin/env python3
"""Validate card JSON against the project's current rule vocabulary.

The script is intentionally dependency-free. It reads the GDScript files that
own rule constants and registered effect ids, then checks data/cards.json for
broken references, missing resources, and suspicious card definitions.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CARDS_PATH = ROOT / "data" / "cards.json"


class Reporter:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, path: str, message: str) -> None:
        self.errors.append(f"ERROR {path}: {message}")

    def warn(self, path: str, message: str) -> None:
        self.warnings.append(f"WARN {path}: {message}")


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def parse_string_constants(relative_path: str, prefix: str | None = None) -> dict[str, str]:
    content = read_text(relative_path)
    constants: dict[str, str] = {}
    pattern = re.compile(r'^\s*const\s+([A-Z0-9_]+)\s*:=\s*"([^"]*)"', re.MULTILINE)
    for name, value in pattern.findall(content):
        if prefix is None or name.startswith(prefix):
            constants[name] = value
    return constants


def parse_effect_registry_ids() -> set[str]:
    content = read_text("scripts/effects/effect_registry.gd")
    ids: set[str] = set()

    for literal in re.findall(r'register_effect\("([^"]+)"', content):
        ids.add(literal)

    effect_constants = parse_string_constants("scripts/game/effect_data.gd", "EFFECT_")
    for constant_name in re.findall(r"register_effect\(EffectData\.([A-Z0-9_]+)", content):
        value = effect_constants.get(constant_name)
        if value:
            ids.add(value)

    return ids


def parse_animation_keys() -> set[str]:
    keys: set[str] = set()
    animation_files = [ROOT / "scripts/ui/card_animation_controller.gd"]
    provider_root = ROOT / "scripts/ui/animation"
    if provider_root.exists():
        animation_files.extend(provider_root.glob("*_animation_provider.gd"))

    for animation_file in animation_files:
        content = animation_file.read_text(encoding="utf-8")
        for line in content.splitlines():
            stripped = line.strip()
            if stripped.endswith(":") and stripped.startswith('"'):
                keys.update(re.findall(r'"([^"]+)"', stripped))

        for match in re.finditer(
            r"const\s+[A-Z0-9_]*KEYS\s*:[^=]+?=\s*\[(.*?)\]",
            content,
            re.DOTALL,
        ):
            keys.update(re.findall(r'"([^"]+)"', match.group(1)))
    return keys


def res_path_exists(res_path: str) -> bool:
    if not res_path.startswith("res://"):
        return False
    return (ROOT / res_path.removeprefix("res://")).exists()


def load_cards() -> list[dict[str, Any]]:
    with CARDS_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)
    if not isinstance(data, list):
        raise ValueError("cards.json root must be an array")
    return data


class CardValidator:
    def __init__(self) -> None:
        self.reporter = Reporter()
        self.data = load_cards()

        self.card_data_constants = parse_string_constants("scripts/data/card_data.gd")
        self.effect_data_constants = parse_string_constants("scripts/game/effect_data.gd")
        self.event_constants = parse_string_constants("scripts/game/event_context.gd")
        self.status_constants = parse_string_constants("scripts/data/card_status.gd")
        self.slot_effect_constants = parse_string_constants("scripts/data/board_slot_effect.gd")
        self.target_rule_constants = parse_string_constants("scripts/game/spell_target_resolver.gd", "TARGET_RULE_")

        self.card_types = {
            value for name, value in self.card_data_constants.items() if name.startswith("TYPE_")
        }
        self.equipment_types = {
            value for name, value in self.card_data_constants.items() if name.startswith("EQUIPMENT_TYPE_")
        }
        self.upgrade_types = {
            value for name, value in self.card_data_constants.items() if name.startswith("UPGRADE_TYPE_")
        }
        self.roles = {
            value for name, value in self.card_data_constants.items() if name.startswith("ROLE_")
        }
        self.keywords = {
            value for name, value in self.card_data_constants.items() if name.startswith("KEYWORD_")
        }
        self.target_rules = set(self.target_rule_constants.values())
        self.effect_ids = set(parse_string_constants("scripts/game/effect_data.gd", "EFFECT_").values())
        self.effect_ids.update(parse_effect_registry_ids())
        self.triggers = {
            value for name, value in self.event_constants.items() if name.startswith("TRIGGER_")
        }
        self.triggers.update(
            value for name, value in self.effect_data_constants.items() if name.startswith("TRIGGER_")
        )
        self.targets = {
            value for name, value in self.effect_data_constants.items() if name.startswith("TARGET_")
        }
        self.target_relations = {
            value for name, value in self.effect_data_constants.items() if name.startswith("TARGET_RELATION_")
        }
        self.trigger_players = {
            value for name, value in self.effect_data_constants.items() if name.startswith("TRIGGER_PLAYER_")
        }
        self.death_reasons = {
            value for name, value in self.effect_data_constants.items() if name.startswith("DEATH_REASON_")
        }
        self.active_zones = {
            value for name, value in self.effect_data_constants.items() if name.startswith("ACTIVE_ZONE_")
        }
        self.target_zones = {
            value for name, value in self.effect_data_constants.items() if name.startswith("TARGET_ZONE_")
        }
        self.amount_sources = {
            value for name, value in self.effect_data_constants.items() if name.startswith("AMOUNT_SOURCE_")
        }
        self.status_ids = {
            value for name, value in self.status_constants.items() if name.startswith("STATUS_")
        }
        self.status_tags = {
            value for name, value in self.status_constants.items() if name.startswith("TAG_")
        }
        self.stack_policies = {
            value for name, value in self.status_constants.items() if name.startswith("STACK_POLICY_")
        }
        self.duration_scopes = {
            value for name, value in self.status_constants.items() if name.startswith("DURATION_SCOPE_")
        }
        self.slot_triggers = {
            value for name, value in self.slot_effect_constants.items() if name.startswith("TRIGGER_")
        }
        self.slot_effect_ids = {
            value for name, value in self.slot_effect_constants.items() if name.startswith("EFFECT_")
        }
        self.animation_keys = parse_animation_keys()
        # These keys are intentionally routed through the generic fallback
        # animation today, but are still part of the card-data vocabulary.
        self.animation_keys.update({"resurrection"})

        self.cards_by_id: dict[str, dict[str, Any]] = {}
        self.card_faction_by_id: dict[str, str] = {}
        self.faction_cards: dict[str, dict[str, dict[str, Any]]] = {}
        self.faction_tokens: dict[str, dict[str, dict[str, Any]]] = {}

    def run(self) -> int:
        self.collect_cards()
        self.validate_back_textures()
        self.validate_factions()

        for warning in self.reporter.warnings:
            print(warning)
        for error in self.reporter.errors:
            print(error)

        total_cards = len(self.cards_by_id)
        if self.reporter.errors:
            print(
                f"FAILED: card data validation found {len(self.reporter.errors)} errors "
                f"and {len(self.reporter.warnings)} warnings across {total_cards} cards."
            )
            return 1

        print(
            f"OK: card data validation passed for {total_cards} cards "
            f"with {len(self.reporter.warnings)} warnings."
        )
        return 0

    def collect_cards(self) -> None:
        for faction_index, faction in enumerate(self.data):
            faction_path = f"factions[{faction_index}]"
            if not isinstance(faction, dict):
                self.reporter.error(faction_path, "faction entry must be an object")
                continue

            faction_id = str(faction.get("id", ""))
            if not faction_id:
                self.reporter.error(faction_path, "missing faction id")
                continue

            self.faction_cards[faction_id] = {}
            self.faction_tokens[faction_id] = {}
            self.collect_card_list(faction, faction_id, "cards", self.faction_cards[faction_id])
            self.collect_card_list(faction, faction_id, "tokens", self.faction_tokens[faction_id])

    def collect_card_list(
        self,
        faction: dict[str, Any],
        faction_id: str,
        list_key: str,
        faction_index: dict[str, dict[str, Any]],
    ) -> None:
        raw_cards = faction.get(list_key, [])
        if raw_cards is None:
            raw_cards = []
        if not isinstance(raw_cards, list):
            self.reporter.error(f"faction[{faction_id}].{list_key}", "must be an array")
            return

        for card_index, card in enumerate(raw_cards):
            path = f"faction[{faction_id}].{list_key}[{card_index}]"
            if not isinstance(card, dict):
                self.reporter.error(path, "card entry must be an object")
                continue

            card_id = str(card.get("id", ""))
            if not card_id:
                self.reporter.error(path, "missing card id")
                continue
            if card_id in self.cards_by_id:
                owner = self.card_faction_by_id.get(card_id, "?")
                self.reporter.error(path, f"duplicate card id '{card_id}', first defined in faction '{owner}'")
                continue

            self.cards_by_id[card_id] = card
            self.card_faction_by_id[card_id] = faction_id
            faction_index[card_id] = card

    def validate_back_textures(self) -> None:
        for level in (1, 2, 3):
            path = f"res://assets/img/卡背/{level}.png"
            if not res_path_exists(path):
                self.reporter.error(f"assets.card_back[{level}]", f"missing card back resource {path}")

    def validate_factions(self) -> None:
        for faction_index, faction in enumerate(self.data):
            if not isinstance(faction, dict):
                continue
            faction_id = str(faction.get("id", f"#{faction_index}"))
            path = f"faction[{faction_id}]"
            kind = str(faction.get("kind", ""))

            if kind == "neutral_pool" and faction.get("heroes"):
                self.reporter.warn(path, "neutral pool should not define heroes")

            self.validate_heroes(faction, faction_id, path)

            for card_index, card in enumerate(faction.get("cards", []) or []):
                if isinstance(card, dict):
                    self.validate_card(card, faction_id, f"{path}.cards[{card_index}]", is_token=False)

            for token_index, card in enumerate(faction.get("tokens", []) or []):
                if isinstance(card, dict):
                    self.validate_card(card, faction_id, f"{path}.tokens[{token_index}]", is_token=True)

    def validate_heroes(self, faction: dict[str, Any], faction_id: str, path: str) -> None:
        heroes = faction.get("heroes", [])
        if heroes is None:
            return
        if not isinstance(heroes, list):
            self.reporter.error(f"{path}.heroes", "must be an array")
            return

        local_cards = self.faction_cards.get(faction_id, {})
        for index, hero in enumerate(heroes):
            hero_path = f"{path}.heroes[{index}]"
            if not isinstance(hero, dict):
                self.reporter.error(hero_path, "hero entry must be an object")
                continue

            hero_id = str(hero.get("card_id", ""))
            hero_card = local_cards.get(hero_id)
            if hero_card is None:
                self.reporter.error(hero_path, f"hero card_id '{hero_id}' is not defined in faction cards")
            else:
                if str(hero_card.get("type", "")) != "minion":
                    self.reporter.error(hero_path, f"hero card '{hero_id}' must be a minion")
                if str(hero_card.get("role", "")) != "hero":
                    self.reporter.error(hero_path, f"hero card '{hero_id}' must have role='hero'")

            attached_cards = hero.get("attached_cards", [])
            if not isinstance(attached_cards, list):
                self.reporter.error(f"{hero_path}.attached_cards", "must be an array")
                continue
            for attached_index, attached_id_raw in enumerate(attached_cards):
                attached_id = str(attached_id_raw)
                if attached_id not in local_cards:
                    self.reporter.error(
                        f"{hero_path}.attached_cards[{attached_index}]",
                        f"attached card '{attached_id}' is not defined in faction cards",
                    )

    def validate_card(self, card: dict[str, Any], faction_id: str, path: str, is_token: bool) -> None:
        card_id = str(card.get("id", ""))
        self.require_string(card, "id", path)
        self.require_string(card, "name", path)
        self.require_string(card, "url", path)

        card_type = str(card.get("type", ""))
        if not card_type:
            self.reporter.error(path, "missing card type")
        elif card_type not in self.card_types:
            self.reporter.error(path, f"unknown card type '{card_type}'")

        count = card.get("count", None)
        if not isinstance(count, int):
            self.reporter.error(f"{path}.count", "must be an integer")
        elif count < 0:
            self.reporter.error(f"{path}.count", "must be non-negative")
        elif is_token and count > 0:
            self.reporter.warn(f"{path}.count", "token count is ignored; prefer count: 0")

        level = card.get("level", None)
        if level is None:
            self.reporter.warn(f"{path}.level", "missing level; runtime defaults to 1")
        elif not isinstance(level, int) or level not in (1, 2, 3):
            self.reporter.error(f"{path}.level", "must be one of 1, 2, 3")

        url = str(card.get("url", ""))
        if url and not res_path_exists(url):
            self.reporter.error(f"{path}.url", f"resource does not exist: {url}")

        role = str(card.get("role", ""))
        if role and role not in self.roles:
            self.reporter.error(f"{path}.role", f"unknown role '{role}'")
        if role == "hero" and card_type != "minion":
            self.reporter.error(f"{path}.role", "hero cards must be minions")

        self.validate_keywords(card, path)
        self.validate_reborn(card, path, card_type)

        if card_type in {"minion", "building"}:
            self.require_int(card, "attack", path)
            self.require_int(card, "health", path)
            if "armor" in card:
                armor = card["armor"]
                if not isinstance(armor, int):
                    self.reporter.error(f"{path}.armor", "must be an integer")
                elif armor < 0:
                    self.reporter.error(f"{path}.armor", "must be non-negative")
        if card_type == "building" and int(card.get("attack", 0)) != 0:
            self.reporter.warn(f"{path}.attack", "buildings are expected to have 0 attack")
        if card_type == "equipment":
            equipment_type = str(card.get("equipment_type", ""))
            if not equipment_type:
                self.reporter.error(f"{path}.equipment_type", "equipment cards require equipment_type")
            elif equipment_type not in self.equipment_types:
                self.reporter.error(f"{path}.equipment_type", f"unknown equipment type '{equipment_type}'")

        upgrade_type = str(card.get("upgrade_type", ""))
        if upgrade_type:
            if card_type != "upgrade":
                self.reporter.error(f"{path}.upgrade_type", "only upgrade cards may define upgrade_type")
            elif upgrade_type not in self.upgrade_types:
                self.reporter.error(f"{path}.upgrade_type", f"unknown upgrade type '{upgrade_type}'")

        target_rule = str(card.get("target_rule", ""))
        if target_rule and target_rule not in self.target_rules:
            self.reporter.error(f"{path}.target_rule", f"unknown target rule '{target_rule}'")

        self.validate_selection(card.get("selection", None), target_rule, path)
        self.validate_animation(card, path)

        self.validate_effect_list(card.get("effects", []), f"{path}.effects")
        self.validate_actions(card.get("actions", []), f"{path}.actions")
        self.validate_spell_actions(card.get("spell_actions", []), f"{path}.spell_actions")
        self.validate_mounted_attacks(card.get("mounted_attacks", []), f"{path}.mounted_attacks")

    def validate_selection(self, raw_selection: Any, target_rule: str, path: str) -> None:
        if raw_selection is None:
            if target_rule == "direction_ray":
                self.reporter.error(f"{path}.selection", "direction_ray cards require selection config")
            return
        if not isinstance(raw_selection, dict):
            self.reporter.error(f"{path}.selection", "must be an object")
            return

        selection_path = f"{path}.selection"
        kind = str(raw_selection.get("kind", ""))
        if kind not in {"line_vector", "direction_ray"}:
            self.reporter.error(f"{selection_path}.kind", "must be one of line_vector, direction_ray")
            return
        if target_rule == "direction_ray" and kind != "direction_ray":
            self.reporter.error(f"{selection_path}.kind", "direction_ray target rule requires direction_ray selection")

        directions = str(raw_selection.get("directions", "8_way"))
        if directions not in {"4_way", "8_way"}:
            self.reporter.error(f"{selection_path}.directions", "must be one of 4_way, 8_way")

        if "max_distance" in raw_selection:
            max_distance = raw_selection["max_distance"]
            if not isinstance(max_distance, int) or max_distance == 0 or max_distance < -1:
                self.reporter.error(f"{selection_path}.max_distance", "must be -1 or a positive integer")

        stop_rule = str(raw_selection.get("stop_rule", "first_unit"))
        if stop_rule not in {"first_unit", "first_matching"}:
            self.reporter.error(f"{selection_path}.stop_rule", "must be one of first_unit, first_matching")

        hit_target_rule = str(raw_selection.get("hit_target_rule", ""))
        if hit_target_rule and hit_target_rule not in self.target_rules:
            self.reporter.error(
                f"{selection_path}.hit_target_rule",
                f"unknown target rule '{hit_target_rule}'",
            )
        if "require_hit" in raw_selection and not isinstance(raw_selection["require_hit"], bool):
            self.reporter.error(f"{selection_path}.require_hit", "must be a boolean")

    def validate_keywords(self, card: dict[str, Any], path: str) -> None:
        raw_keywords = card.get("keywords", [])
        if not isinstance(raw_keywords, list):
            self.reporter.error(f"{path}.keywords", "must be an array")
            return
        for index, keyword_raw in enumerate(raw_keywords):
            keyword = str(keyword_raw)
            if not self.is_known_keyword(keyword):
                self.reporter.warn(f"{path}.keywords[{index}]", f"unknown keyword '{keyword}'")

    def validate_reborn(self, card: dict[str, Any], path: str, card_type: str) -> None:
        if "reborn_health_values" not in card:
            return

        raw_values = card["reborn_health_values"]
        field_path = f"{path}.reborn_health_values"
        if card_type != "minion":
            self.reporter.error(field_path, "is only valid for minions")
        if not isinstance(raw_values, list):
            self.reporter.error(field_path, "must be an array of non-negative integers")
            return
        if not raw_values:
            self.reporter.warn(field_path, "empty array grants no reborn charges")

        max_health = card.get("health", 0)
        for index, health_value in enumerate(raw_values):
            value_path = f"{field_path}[{index}]"
            if not isinstance(health_value, int) or isinstance(health_value, bool):
                self.reporter.error(value_path, "must be a non-negative integer")
                continue
            if health_value < 0:
                self.reporter.error(value_path, "must be non-negative; use 0 for full health")
            elif isinstance(max_health, int) and max_health > 0 and health_value > max_health:
                self.reporter.error(value_path, "cannot exceed the card's printed maximum health")

        raw_keywords = card.get("keywords", [])
        if isinstance(raw_keywords, list) and any(
            str(keyword) == "reborn" or str(keyword).startswith("reborn_")
            for keyword in raw_keywords
        ):
            self.reporter.error(
                field_path,
                "cannot be combined with legacy reborn/reborn_N keywords",
            )

    def is_known_keyword(self, keyword: str) -> bool:
        if keyword in self.keywords:
            return True

        if keyword.startswith("siege_"):
            amount_text = keyword.removeprefix("siege_")
            return amount_text.isdigit() and int(amount_text) >= 0

        if keyword.startswith("reborn_"):
            amount_text = keyword.removeprefix("reborn_")
            return amount_text.isdigit() and int(amount_text) >= 0

        if keyword.startswith("splash_"):
            amount_text = keyword.removeprefix("splash_")
            return amount_text.isdigit() and int(amount_text) >= 0

        if keyword.startswith("frontal_width_"):
            width_text = keyword.removeprefix("frontal_width_")
            return width_text.isdigit() and int(width_text) > 0 and int(width_text) % 2 == 1

        return False

    def validate_spell_actions(self, raw_actions: Any, path: str) -> None:
        if raw_actions in (None, []):
            return
        if not isinstance(raw_actions, list):
            self.reporter.error(path, "must be an array")
            return
        for index, action in enumerate(raw_actions):
            action_path = f"{path}[{index}]"
            if not isinstance(action, dict):
                self.reporter.error(action_path, "spell action must be an object")
                continue
            self.require_string(action, "id", action_path)
            self.require_string(action, "name", action_path)
            target_rule = str(action.get("target_rule", ""))
            if target_rule and target_rule not in self.target_rules:
                self.reporter.error(f"{action_path}.target_rule", f"unknown target rule '{target_rule}'")
            self.validate_animation(action, action_path)
            self.validate_effect_list(action.get("effects", []), f"{action_path}.effects")

    def validate_actions(self, raw_actions: Any, path: str) -> None:
        if raw_actions in (None, []):
            return
        if not isinstance(raw_actions, list):
            self.reporter.error(path, "must be an array")
            return
        for index, action in enumerate(raw_actions):
            action_path = f"{path}[{index}]"
            if not isinstance(action, dict):
                self.reporter.error(action_path, "action must be an object")
                continue

            action_id = str(action.get("action_id", action.get("id", "")))
            if not action_id:
                self.reporter.error(f"{action_path}.action_id", "must define action_id or id")
            self.require_string(action, "name", action_path)
            target_rule = str(action.get("target_rule", ""))
            if target_rule and target_rule not in self.target_rules:
                self.reporter.error(f"{action_path}.target_rule", f"unknown target rule '{target_rule}'")
            if "once_per_turn" in action and not isinstance(action["once_per_turn"], bool):
                self.reporter.error(f"{action_path}.once_per_turn", "must be a boolean")
            if "once_per_lifetime" in action and not isinstance(action["once_per_lifetime"], bool):
                self.reporter.error(f"{action_path}.once_per_lifetime", "must be a boolean")
            self.validate_animation(action, action_path)
            self.validate_effect_list(action.get("effects", []), f"{action_path}.effects")

    def validate_mounted_attacks(self, raw_actions: Any, path: str) -> None:
        if raw_actions in (None, []):
            return
        if not isinstance(raw_actions, list):
            self.reporter.error(path, "must be an array")
            return
        for index, action in enumerate(raw_actions):
            action_path = f"{path}[{index}]"
            if not isinstance(action, dict):
                self.reporter.error(action_path, "mounted attack must be an object")
                continue

            self.require_string(action, "id", action_path)
            self.require_string(action, "name", action_path)
            self.validate_card_id_reference(str(action.get("rider_card_id", "")), f"{action_path}.rider_card_id")

            if not isinstance(action.get("amount", None), int):
                self.reporter.error(f"{action_path}.amount", "must be an integer")
            if "attack_speed" in action and not isinstance(action["attack_speed"], int):
                self.reporter.error(f"{action_path}.attack_speed", "must be an integer")
            if str(action.get("range", "melee")) not in {"melee", "ranged"}:
                self.reporter.error(f"{action_path}.range", "must be one of melee, ranged")

    def validate_effect_list(self, raw_effects: Any, path: str) -> None:
        if raw_effects in (None, []):
            return
        if not isinstance(raw_effects, list):
            self.reporter.error(path, "must be an array")
            return
        for index, effect in enumerate(raw_effects):
            effect_path = f"{path}[{index}]"
            if not isinstance(effect, dict):
                self.reporter.error(effect_path, "effect must be an object")
                continue
            self.validate_effect(effect, effect_path)

    def validate_effect(self, effect: dict[str, Any], path: str) -> None:
        effect_id = str(effect.get("id", ""))
        if not effect_id:
            self.reporter.error(path, "missing effect id")
        elif effect_id not in self.effect_ids:
            self.reporter.error(path, f"unknown effect id '{effect_id}'")

        self.validate_choice(effect, path, "trigger", self.triggers)
        self.validate_choice(effect, path, "granted_trigger", self.triggers)
        self.validate_choice(effect, path, "active_zone", self.active_zones)
        self.validate_choice(effect, path, "target_zone", self.target_zones)
        self.validate_choice(effect, path, "target", self.targets)
        self.validate_choice(effect, path, "death_reason", self.death_reasons)
        self.validate_choice(effect, path, "trigger_player", self.trigger_players)
        self.validate_choice(effect, path, "target_relation", self.target_relations)
        self.validate_choice(effect, path, "amount_source", self.amount_sources)
        self.validate_choice(effect, path, "stack_policy", self.stack_policies)
        self.validate_choice(effect, path, "duration_scope", self.duration_scopes)
        self.validate_choice(effect, path, "expires_on_trigger", self.triggers)
        self.validate_choice(effect, path, "slot_effect_trigger", self.slot_triggers)
        self.validate_choice(effect, path, "slot_effect_id", self.slot_effect_ids)

        if "filter_type" in effect and str(effect["filter_type"]) not in {"minion", "building", "all"}:
            self.reporter.error(f"{path}.filter_type", "must be one of minion, building, all")
        if "filter_owner" in effect and str(effect["filter_owner"]) not in {"self", "any"}:
            self.reporter.error(f"{path}.filter_owner", "must be one of self, any")
        if "target_faction_id" in effect and not isinstance(effect["target_faction_id"], str):
            self.reporter.error(f"{path}.target_faction_id", "must be a string")

        self.validate_status_fields(effect, path)
        self.validate_card_references(effect, path)
        self.validate_animation(effect, path, key_name="animation")
        self.validate_animation(effect, path, key_name="apply_animation")
        self.validate_animation(effect, path, key_name="trigger_animation")
        self.validate_animation(effect, path, key_name="source_animation")
        self.validate_death_slot_replacement(
            effect.get("death_slot_replacement", None),
            f"{path}.death_slot_replacement",
        )

        self.validate_effect_list(effect.get("replace_effects", []), f"{path}.replace_effects")
        self.validate_effect_list(effect.get("append_effects", []), f"{path}.append_effects")
        self.validate_effect_list(effect.get("granted_effects", []), f"{path}.granted_effects")
        self.validate_spell_actions(effect.get("spell_actions", []), f"{path}.spell_actions")
        self.validate_bonus_cards(effect.get("bonus_cards", []), f"{path}.bonus_cards")
        if effect_id == "maintain_card_reserve":
            self.validate_card_reserve_effect(effect, path)
        elif effect_id == "modify_card_reserve_capacity":
            self.require_string(effect, "reserve_id", path)
            self.require_int(effect, "amount", path)
        elif effect_id == "transform_unit":
            transform_mode = str(effect.get("transform_mode", "cover"))
            if transform_mode not in {"cover", "evolution"}:
                self.reporter.error(
                    f"{path}.transform_mode",
                    "must be one of cover, evolution",
                )
            if "preserve_original_identity" in effect and not isinstance(
                effect["preserve_original_identity"], bool
            ):
                self.reporter.error(
                    f"{path}.preserve_original_identity",
                    "must be a boolean",
                )
        elif effect_id == "claim_death_slot":
            self.validate_death_slot_replacement(effect, path)

        payload = effect.get("payload", {})
        if isinstance(payload, dict):
            self.validate_effect_list(payload.get("turn_effects", []), f"{path}.payload.turn_effects")
            self.validate_effect_list(payload.get("trigger_effects", []), f"{path}.payload.trigger_effects")
            self.validate_actions(payload.get("actions", []), f"{path}.payload.actions")
        elif "payload" in effect:
            self.reporter.error(f"{path}.payload", "must be an object")

    def validate_death_slot_replacement(self, raw_claim: Any, path: str) -> None:
        if raw_claim is None:
            return
        if not isinstance(raw_claim, dict):
            self.reporter.error(path, "must be an object")
            return

        self.validate_card_id_reference(str(raw_claim.get("card_id", "")), f"{path}.card_id")
        slot_owner = str(raw_claim.get("slot_owner", "defeated_owner"))
        if slot_owner not in {"source_owner", "defeated_owner"}:
            self.reporter.error(
                f"{path}.slot_owner",
                "must be one of source_owner, defeated_owner",
            )

        for key in ("victim_layer", "destination_layer"):
            layer = str(raw_claim.get(key, "ground"))
            if layer not in {"ground", "aerial"}:
                self.reporter.error(f"{path}.{key}", "must be one of ground, aerial")

        priority = raw_claim.get("priority", 100)
        if not isinstance(priority, int) or isinstance(priority, bool):
            self.reporter.error(f"{path}.priority", "must be an integer")
        self.validate_animation(raw_claim, path, key_name="animation")

    def validate_card_reserve_effect(self, effect: dict[str, Any], path: str) -> None:
        self.require_string(effect, "reserve_id", path)
        self.require_int(effect, "capacity", path)
        self.require_int(effect, "cooldown_turns", path)

        if isinstance(effect.get("capacity"), int) and effect["capacity"] <= 0:
            self.reporter.error(f"{path}.capacity", "must be greater than zero")
        if isinstance(effect.get("cooldown_turns"), int) and effect["cooldown_turns"] < 0:
            self.reporter.error(f"{path}.cooldown_turns", "must be non-negative")

        zones = effect.get("count_zones", [])
        if not isinstance(zones, list) or not zones:
            self.reporter.error(f"{path}.count_zones", "must be a non-empty array")
        else:
            for index, zone_raw in enumerate(zones):
                zone = str(zone_raw)
                if zone not in {"hand", "board"}:
                    self.reporter.error(
                        f"{path}.count_zones[{index}]",
                        "must be one of hand, board",
                    )

        if str(effect.get("draw_mode", "")) != "without_replacement":
            self.reporter.error(f"{path}.draw_mode", "currently must be without_replacement")
        if str(effect.get("restock_mode", "")) != "finite":
            self.reporter.error(f"{path}.restock_mode", "currently must be finite")

        pool = effect.get("pool", [])
        if not isinstance(pool, list) or not pool:
            self.reporter.error(f"{path}.pool", "must be a non-empty array")
            return
        for index, entry in enumerate(pool):
            entry_path = f"{path}.pool[{index}]"
            if not isinstance(entry, dict):
                self.reporter.error(entry_path, "pool entry must be an object")
                continue
            self.validate_card_id_reference(str(entry.get("card_id", "")), f"{entry_path}.card_id")
            count = entry.get("count", None)
            if not isinstance(count, int):
                self.reporter.error(f"{entry_path}.count", "must be an integer")
            elif count <= 0:
                self.reporter.error(f"{entry_path}.count", "must be greater than zero")

    def validate_status_fields(self, effect: dict[str, Any], path: str) -> None:
        status_id = str(effect.get("status_id", ""))
        if status_id and status_id not in self.status_ids:
            self.reporter.warn(f"{path}.status_id", f"unknown status id '{status_id}'")

        raw_status_ids = effect.get("status_ids", [])
        if raw_status_ids and not isinstance(raw_status_ids, list):
            self.reporter.error(f"{path}.status_ids", "must be an array")
        elif isinstance(raw_status_ids, list):
            for index, status_id_raw in enumerate(raw_status_ids):
                status_id = str(status_id_raw)
                if status_id not in self.status_ids:
                    self.reporter.warn(f"{path}.status_ids[{index}]", f"unknown status id '{status_id}'")

        raw_tags = effect.get("status_tags", [])
        if raw_tags and not isinstance(raw_tags, list):
            self.reporter.error(f"{path}.status_tags", "must be an array")
        elif isinstance(raw_tags, list):
            for index, tag_raw in enumerate(raw_tags):
                tag = str(tag_raw)
                if tag not in self.status_tags:
                    self.reporter.warn(f"{path}.status_tags[{index}]", f"unknown status tag '{tag}'")

    def validate_card_references(self, effect: dict[str, Any], path: str) -> None:
        for key in ("card_id", "target_card_id", "source_card_id"):
            if key in effect:
                self.validate_card_id_reference(str(effect.get(key, "")), f"{path}.{key}")

        for key in ("card_ids", "source_card_ids"):
            raw_ids = effect.get(key, [])
            if raw_ids and not isinstance(raw_ids, list):
                self.reporter.error(f"{path}.{key}", "must be an array")
                continue
            if isinstance(raw_ids, list):
                for index, card_id_raw in enumerate(raw_ids):
                    self.validate_card_id_reference(str(card_id_raw), f"{path}.{key}[{index}]")

    def validate_bonus_cards(self, raw_bonus_cards: Any, path: str) -> None:
        if raw_bonus_cards in (None, []):
            return
        if not isinstance(raw_bonus_cards, list):
            self.reporter.error(path, "must be an array")
            return
        for index, bonus_card in enumerate(raw_bonus_cards):
            bonus_path = f"{path}[{index}]"
            if not isinstance(bonus_card, dict):
                self.reporter.error(bonus_path, "bonus card entry must be an object")
                continue
            self.validate_card_id_reference(str(bonus_card.get("card_id", "")), f"{bonus_path}.card_id")
            if "amount" in bonus_card and not isinstance(bonus_card["amount"], int):
                self.reporter.error(f"{bonus_path}.amount", "must be an integer")

    def validate_card_id_reference(self, card_id: str, path: str) -> None:
        if not card_id:
            self.reporter.error(path, "missing card id reference")
        elif card_id not in self.cards_by_id:
            self.reporter.error(path, f"unknown card id '{card_id}'")

    def validate_animation(self, data: dict[str, Any], path: str, key_name: str = "animation") -> None:
        animation = str(data.get(key_name, ""))
        if animation and animation not in self.animation_keys:
            self.reporter.warn(f"{path}.{key_name}", f"unknown animation key '{animation}', runtime will fall back")

    def validate_choice(self, data: dict[str, Any], path: str, key: str, allowed: set[str]) -> None:
        value = str(data.get(key, ""))
        if value and value not in allowed:
            self.reporter.error(f"{path}.{key}", f"unknown value '{value}'")

    def require_string(self, data: dict[str, Any], key: str, path: str) -> None:
        value = data.get(key, None)
        if not isinstance(value, str) or value == "":
            self.reporter.error(f"{path}.{key}", "must be a non-empty string")

    def require_int(self, data: dict[str, Any], key: str, path: str) -> None:
        if key not in data or not isinstance(data[key], int):
            self.reporter.error(f"{path}.{key}", "must be an integer")


def main() -> int:
    try:
        return CardValidator().run()
    except json.JSONDecodeError as error:
        print(f"ERROR {CARDS_PATH}: invalid JSON: {error}")
        return 1
    except Exception as error:  # pragma: no cover - command-line guard
        print(f"ERROR validator: {error}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
