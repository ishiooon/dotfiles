#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境の指定を求め、設定ファイルの読み取りだけで検証する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$TEST_ROOT" <<'PY'
import json
import sys
from pathlib import Path

# 数字と記号の出力は、設定ファイルの値ではなく利用者向けのキー配列から定義する。
LAYER_OUTPUTS = {
    # 内蔵キーボードのレイヤーは、移動後の文字の位置から開く。
    "w": {
        "semicolon": "1", "quote": "2", "backslash": "3", "p": "4", "open_bracket": "5",
        "close_bracket": "6", "hyphen": "7", "equal_sign": "8", "international3": "9",
        "return_or_enter": "0",
    },
    "d": {
        "semicolon": "comma", "quote": "period", "backslash": "slash", "p": "semicolon",
        "open_bracket": "quote", "close_bracket": "backslash", "hyphen": "hyphen",
        "equal_sign": "equal_sign", "international3": "open_bracket",
        "return_or_enter": "close_bracket", "o": "grave_accent_and_tilde",
        "0": "international3",
    },
}
BUILT_IN = {"is_built_in_keyboard": True, "is_keyboard": True}
EXTERNAL = {"is_built_in_keyboard": False, "is_keyboard": True}
TORABO = {**EXTERNAL, "vendor_id": 65261, "product_id": 48301}
LOGICAL_HOLDS = {"e": "f", "w": "d", "d": "v", "s": "c", "a": "x"}
SIDED_MODIFIERS = ("command", "control", "option", "shift")
ACCEPTED_MODIFIERS = (
    (), ("caps_lock",), ("left_shift",), ("right_shift",),
    ("caps_lock", "left_shift"), ("caps_lock", "right_shift"),
)


def main():
    # 有効なプロファイルと配布用ルールを照合し、片方だけ修正されることを防ぐ。
    directory = Path(sys.argv[1]) / ".config" / "karabiner"
    config = json.loads((directory / "karabiner.json").read_text(encoding="utf-8"))
    asset = directory / "assets" / "complex_modifications" / "f_hjkl_arrows.json"
    distributed = json.loads(asset.read_text(encoding="utf-8"))
    selected = next(profile for profile in config["profiles"] if profile["selected"])
    rules = selected["complex_modifications"]["rules"]
    assert rules == distributed["rules"], "有効な設定と配布用ルールが一致しません。"

    manipulators = [manipulator for rule in rules for manipulator in rule["manipulators"]]
    for layer, outputs in LAYER_OUTPUTS.items():
        for key, output in outputs.items():
            verify_chord(manipulators, layer, key, output)
    verify_device_scope(manipulators)
    verify_command_layer(manipulators)
    print("成功: キーボードごとにレイヤーが適用され、通常のショートカットとアプリ切り替えを保ちます。")


def verify_device_scope(manipulators):
    # 違うキーボードを併用しても、通常入力と右 Shift の左隣の出力が混ざらない。
    for device, expected in ((BUILT_IN, ("q", "p", "vk_none")), (EXTERNAL, ("1", "return_or_enter", "hyphen")),
                             (TORABO, ("1", "return_or_enter", "international1"))):
        for key, output in zip(("1", "return_or_enter", "international1"), expected):
            match = first_match(manipulators, (key,), device)
            assert (key_codes(match) or [key]) == [output], (device, key, output)

    for key, logical in LOGICAL_HOLDS.items():
        for modifier in ("left_control", "left_option", "right_command"):
            match = first_match(manipulators, (key,), BUILT_IN, (modifier,))
            outputs = key_codes(match) or [event["key_code"] for event in match.get("to_if_alone", [])]
            assert outputs == [logical], f"{modifier}+{key} で論理配置の {logical} を入力できません。"
    assert key_codes(first_match(manipulators, ("d", "n"), EXTERNAL)) == ["1"]
    assert key_codes(first_match(manipulators, ("v", "n"), EXTERNAL)) == ["comma"]
    assert not first_match(manipulators, ("w", "semicolon"), EXTERNAL)
    assert not first_match(manipulators, ("d", "n"), TORABO)
    external_hold = variable_values(first_match(manipulators, ("d",), EXTERNAL))
    internal_hold = variable_values(first_match(manipulators, ("w",), BUILT_IN))
    assert key_codes(first_match(manipulators, ("semicolon",), BUILT_IN, variables=external_hold)) == ["n"]
    assert not first_match(manipulators, ("n",), EXTERNAL, variables=internal_hold)


def verify_command_layer(manipulators):
    # 右 Command を先に押してから移動レイヤーに入ると、矢印と逆方向のアプリ切り替えが使える。
    right_command = first_match(manipulators, ("right_command",), BUILT_IN)
    right_command_state = variable_values(right_command)
    assert key_codes(right_command) == ["right_command"]
    assert right_command["to_if_alone"] == [{"key_code": "return_or_enter"}]
    for modifiers in ((), ("right_command",)):
        hold = first_match(manipulators, ("e",), BUILT_IN, modifiers, right_command_state)
        active = {**right_command_state, **variable_values(hold)}
        arrow = first_match(manipulators, ("o",), BUILT_IN, modifiers, active)
        assert key_codes(arrow) == ["left_arrow"]
        switch = first_match(manipulators, ("tab",), BUILT_IN, modifiers, active)
        assert switch["to"] == [{"key_code": "tab", "modifiers": ["left_command"]}]
        space = first_match(manipulators, ("spacebar",), BUILT_IN, modifiers, active)
        assert key_codes(space) == ["left_shift"] and "to_if_alone" not in space
        kana = first_match(manipulators, ("japanese_kana",), BUILT_IN, modifiers, active)
        assert kana["to_if_alone"] == [{"key_code": "spacebar"}]
        for shift in (space, kana):
            backwards = first_match(manipulators, ("tab",), BUILT_IN, modifiers,
                                    {**active, **variable_values(shift)})
            assert backwards["to"] == [{"key_code": "tab", "modifiers": ["left_command", "left_shift"]}]
    chord = first_match(manipulators, ("e", "o"), BUILT_IN, ("right_command",), allow_first_key=True)
    assert key_codes(chord) == ["left_arrow"], "Command と移動レイヤーの同時押しが単独の保持より先に必要です。"


def verify_chord(manipulators, layer, key, output):
    # Shift の記号入力を維持し、左右の Command、Control、Option では同時押しを変換しない。
    expected = {"key_code": output}
    if (layer, key) == ("d", "o"):
        expected["modifiers"] = ["left_shift"]
    for modifiers in ACCEPTED_MODIFIERS:
        result = chord_outputs(manipulators, (layer, key), modifiers)
        assert result == [expected], f"{modifiers} {layer}+{key} の出力が {result} です。期待値は {expected} です。"

    for modifier in SIDED_MODIFIERS:
        if modifier == "shift":
            continue
        for side in ("left", "right"):
            named = f"{side}_{modifier}"
            for modifiers in ((named,), (named, "left_shift")):
                result = chord_outputs(manipulators, (layer, key), modifiers)
                assert not result, f"{modifiers} {layer}+{key} が {result} に変換され、ショートカットと競合します。"


def chord_outputs(manipulators, keys, modifiers):
    match = first_match(manipulators, keys, BUILT_IN, modifiers)
    return [event for event in match.get("to", []) if "key_code" in event]


def first_match(manipulators, keys, device, modifiers=(), variables=None, allow_first_key=False):
    # Karabiner と同じ順序で条件を照合し、必要に応じて同時押しの先頭キーも候補にする。
    for entry in manipulators:
        source = entry["from"]
        inputs = tuple(event["key_code"] for event in source.get("simultaneous", ()))
        if not inputs:
            inputs = (source.get("key_code"),)
        if inputs not in (keys, keys[:1] if allow_first_key else keys):
            continue
        if modifiers_match(source.get("modifiers", {}), modifiers) and conditions_match(entry, device, variables or {}):
            return entry
    return {}


def conditions_match(entry, device, variables):
    for condition in entry.get("conditions", []):
        kind = condition["type"]
        if kind in ("device_if", "device_unless"):
            found = any(all(device.get(key) == value for key, value in identifier.items() if key != "description")
                        for identifier in condition["identifiers"])
        elif kind in ("variable_if", "variable_unless"):
            found = variables.get(condition["name"], 0) == condition["value"]
        else:
            raise AssertionError(f"未対応の条件 {kind}")
        if found != kind.endswith("_if"):
            return False
    return True


def key_codes(entry):
    return [event["key_code"] for event in entry.get("to", []) if "key_code" in event]


def variable_values(entry):
    return {item["name"]: item["value"] for event in entry.get("to", []) if (item := event.get("set_variable"))}


def modifiers_match(specification, modifiers):
    # Karabiner の左右共通指定は左右どちらにも一致する。optional にない余分な修飾キーは許可されない。
    active = set(modifiers)
    optional = expand_sides(specification.get("optional", ()))
    mandatory = specification.get("mandatory", ())
    if any(not (active & expand_sides((modifier,))) for modifier in mandatory):
        return False
    return "any" in optional or active <= optional | expand_sides(mandatory)


def expand_sides(modifiers):
    return {
        name
        for modifier in modifiers
        for name in (
            (f"left_{modifier}", f"right_{modifier}")
            if modifier in SIDED_MODIFIERS else (modifier,)
        )
    }


if __name__ == "__main__":
    main()
PY
