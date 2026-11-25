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
    verify_yen(manipulators)
    verify_device_scope(manipulators)
    verify_command_layer(manipulators)
    verify_control_tab(manipulators)
    verify_control_layers(manipulators)
    verify_repeated_actions(manipulators)
    verify_external_layer_modifiers(manipulators)
    verify_keymap_release(manipulators)
    print("成功: キーボード別のレイヤーと、移動・編集・アプリ切り替えの連続入力を確認しました。")


def verify_yen(manipulators):
    # ABCで円記号を入力する組み合わせを、素早い同時押しとレイヤー保持の両方で送る。
    yen = [{"key_code": "y", "modifiers": ["left_option"]}]
    unchanged = [{"key_code": "international3"}]
    for device, layer, target in ((BUILT_IN, "d", "0"), (EXTERNAL, "v", "y")):
        chord = first_match(manipulators, (layer, target), device)
        assert key_events(chord) == yen, f"{layer}+{target} の同時押しで円記号を入力できません。"
        hold = first_match(manipulators, (layer,), device)
        active = variable_values(hold)
        action = first_match(manipulators, (target,), device, variables=active)
        assert key_events(action) == yen, f"{layer} を保持した状態で {target} から円記号を入力できません。"
        assert (key_codes(first_match(manipulators, (target,), device)) or [target]) == ["y"]
        # ShiftやCaps Lockの併用時に、Optionが追加されてアクセント付き文字に変わらない。
        for modifiers in ACCEPTED_MODIFIERS[1:]:
            assert key_events(first_match(manipulators, (layer, target), device, modifiers)) == unchanged
            assert key_events(first_match(manipulators, (target,), device, modifiers, active)) == unchanged
        for modifier in ("control", "option", "command"):
            for side in ("left", "right"):
                modifiers = (f"{side}_{modifier}",)
                assert not first_match(manipulators, (layer, target), device, modifiers)
                assert key_events(first_match(manipulators, (target,), device, modifiers, active)) == unchanged

    # Torabo が記号レイヤーから送る円記号用キーだけを変換する。
    assert key_events(first_match(manipulators, ("international3",), TORABO)) == yen
    for modifiers in ACCEPTED_MODIFIERS[1:]:
        assert not first_match(manipulators, ("international3",), TORABO, modifiers)
    assert not first_match(manipulators, ("international3",), EXTERNAL)
    assert not first_match(manipulators, ("international3",), {**TORABO, "is_keyboard": False})


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
    # Commandの押し方に関わらず、Fを押したまま矢印と順・逆方向のTabを続けて使える。
    for device, layer, arrow, tab, command, shift_keys in (
        (BUILT_IN, "e", "o", "tab", "right_command", ("spacebar", "japanese_kana")),
        (EXTERNAL, "f", "h", "a", "japanese_eisuu", ("spacebar",)),
    ):
        command_key = first_match(manipulators, (command,), device)
        assert command_key["to_if_alone"] == [{"key_code": "return_or_enter"}]
        for modifiers, initial in ((("left_command",), {}), ((), variable_values(command_key))):
            hold = first_match(manipulators, (layer,), device, modifiers, initial)
            active = {**initial, **variable_values(hold)}
            target = first_match(manipulators, (arrow,), device, modifiers, active)
            assert key_codes(target) == ["left_arrow"]
            assert release_key(target, active) == [("up", "left_arrow")]
            again = first_match(manipulators, (arrow,), device, modifiers, active)
            assert key_codes(again) == ["left_arrow"]

            forward = [{"key_code": "tab", "modifiers": ["left_command"]}]
            backwards = [{"key_code": "tab", "modifiers": ["left_command", "left_shift"]}]
            assert first_match(manipulators, (tab,), device, modifiers, active)["to"] == forward
            for key in shift_keys:
                shift = first_match(manipulators, (key,), device, modifiers, active)
                assert key_codes(shift) == ["left_shift"]
                if key == "spacebar":
                    assert "to_if_alone" not in shift
                else:
                    assert shift["to_if_alone"] == [{"key_code": "spacebar"}]
                active.update(variable_values(shift))
                inverse_tab = first_match(manipulators, (tab,), device, modifiers, active)
                assert inverse_tab["to"] == backwards
                assert release_key(inverse_tab, active) == [("up", "tab")]
                assert first_match(manipulators, (tab,), device, modifiers, active)["to"] == backwards
                release_key(shift, active)
                assert first_match(manipulators, (tab,), device, modifiers, active)["to"] == forward
            release_key(hold, active)
            for key in (arrow, tab):
                after = first_match(manipulators, (key,), device, modifiers, active)
                assert after == first_match(manipulators, (key,), device, modifiers, initial)

        # Fの後に英数を押した場合も、Fだけを離すと通常配列へ戻る。
        hold = first_match(manipulators, (layer,), device)
        active = variable_values(hold)
        eisuu = first_match(manipulators, ("japanese_eisuu",), device, variables=active)
        active.update(variable_values(eisuu))
        assert first_match(manipulators, (tab,), device, variables=active)["to"] == forward
        release_key(hold, active)
        for key in (arrow, tab):
            after = first_match(manipulators, (key,), device, variables=active)
            assert after == first_match(manipulators, (key,), device)


def verify_control_tab(manipulators):
    # 論理Zを保持してからFとAを押す。ZのControlを保ったままTabを送る。
    for device, z_key, f_key, a_key in (
        (BUILT_IN, "left_control", "e", "tab"),
        (EXTERNAL, "z", "f", "a"),
    ):
        control = first_match(manipulators, (z_key,), device)
        assert control["to_if_alone"] == [{"key_code": "z"}]
        assert key_codes(control) == ["left_control"]

        for modifier in ("left_control", "right_control"):
            modifiers = (modifier,)
            hold = first_match(manipulators, (f_key,), device, modifiers)
            assert not hold["from"]["modifiers"].get("mandatory"), "単独のCtrl+FでControlを維持できません。"
            output = [event for event in hold.get("to", []) if "key_code" in event] or hold.get("to_if_alone")
            assert output == [{"key_code": "f"}], "短いCtrl+Fが論理Fを出力しません。"

            active = variable_values(hold)
            for pressed in (modifiers, (*modifiers, "left_shift")):
                for _ in range(2):
                    tab = first_match(manipulators, (a_key,), device, pressed, active)
                    assert not tab["from"]["modifiers"].get("mandatory"), "Tabの出力にControlとShiftを引き継げません。"
                    assert tab.get("to") == [{"key_code": "tab"}], f"{pressed} + F + A がTabになりません。"
                    release_key(tab, active)
            release_key(hold, active)
            assert first_match(manipulators, (a_key,), device, modifiers, active) == first_match(
                manipulators, (a_key,), device, modifiers
            ), "Fを離したあとも移動レイヤーが残っています。"


def verify_control_layers(manipulators):
    # 論理ZでControlを保持したまま、各レイヤーを開いて出力・解放まで確認する。
    standard_fkeys = {"system.use_fkeys_as_standard_function_keys": True}
    for device, f_key, examples in (
        (BUILT_IN, "e", (
            ("w", "d", "semicolon", {"key_code": "1"}),
            ("d", "v", "semicolon", {"key_code": "comma"}),
            ("s", "c", "0", {"key_code": "f12"}),
            ("a", "x", "0", {"consumer_key_code": "volume_increment"}),
        )),
        (EXTERNAL, "f", (
            ("d", "d", "n", {"key_code": "1"}),
            ("v", "v", "n", {"key_code": "comma"}),
            ("c", "c", "y", {"key_code": "f12"}),
            ("x", "x", "y", {"consumer_key_code": "volume_increment"}),
        )),
    ):
        for control in ("left_control", "right_control"):
            modifiers = (control,)
            f_held = variable_values(first_match(manipulators, (f_key,), device, modifiers))
            for key, letter, target, output in examples:
                hold = first_match(manipulators, (key,), device, modifiers)
                active = variable_values(hold)
                assert any(active.values()), f"{control}+{key} で{letter.upper()}レイヤーに入りません。"
                assert hold.get("to_if_alone") == [{"key_code": letter}], f"{control}+{key} の短押しが変わりました。"
                assert not hold["from"]["modifiers"].get("mandatory"), "短押しでControlが消えます。"

                action = first_match(manipulators, (target,), device, modifiers, active)
                assert not action.get("from", {}).get("modifiers", {}).get("mandatory"), "レイヤーの出力でControlが消えます。"
                outputs = [{k: v for k, v in event.items() if k != "conditions"}
                           for event in action.get("to", []) if conditions_match(event, device, standard_fkeys)]
                assert outputs == [output], f"{control}+{key}+{target} の出力が {outputs} です。"

                release_key(hold, active)
                assert first_match(manipulators, (target,), device, modifiers, active) == first_match(
                    manipulators, (target,), device, modifiers
                ), "レイヤーキーを離したあとも変換が続いています。"
                assert not variable_values(first_match(manipulators, (key,), device, modifiers, f_held)), (
                    "Fの保持中に別のレイヤーへ入っています。"
                )
                for shortcut in ("left_command", "left_option"):
                    assert not variable_values(first_match(manipulators, (key,), device, (shortcut,))), (
                        f"{shortcut}+{key} がレイヤーに入り、通常のショートカットと競合します。"
                    )


def verify_external_layer_modifiers(manipulators):
    # 短くFだけを押したときは、先に押した修飾キーを保って通常のFを返す。
    for modifier in ("control", "option", "shift"):
        for side in ("left", "right"):
            modifiers = (f"{side}_{modifier}",)
            hold = first_match(manipulators, ("f",), EXTERNAL, modifiers)
            assert not hold["from"]["modifiers"].get("mandatory"), modifiers
            assert hold["to_if_alone"] == [{"key_code": "f"}], modifiers
            active = variable_values(hold)
            assert key_codes(first_match(manipulators, ("h",), EXTERNAL, modifiers, active)) == ["left_arrow"]


def verify_repeated_actions(manipulators):
    # 内蔵JISでは論理Fの位置が物理Eになる。外付けでは物理Fで同じ操作を行う。
    for device, layer, actions in (
        (BUILT_IN, "e", {"o": "left_arrow", "p": "down_arrow", "open_bracket": "up_arrow",
                         "close_bracket": "right_arrow", "tab": "tab", "q": "tab", "3": "delete_or_backspace",
                         "hyphen": "delete_or_backspace", "1": "escape", "return_or_enter": "delete_forward",
                         "w": "left_command", "semicolon": "japanese_eisuu", "quote": "japanese_kana"}),
        (EXTERNAL, "f", {"h": "left_arrow", "j": "down_arrow", "k": "up_arrow", "l": "right_arrow",
                         "a": "tab", "s": "tab", "e": "delete_or_backspace", "u": "delete_or_backspace",
                         "q": "escape", "p": "delete_forward", "d": "left_command",
                         "n": "japanese_eisuu", "m": "japanese_kana"}),
    ):
        hold = first_match(manipulators, (layer,), device)
        for target, output in actions.items():
            assert not first_match(manipulators, (layer, target), device), (layer, target)
            active = variable_values(hold)
            other = next(key for key, value in actions.items() if value != output)

            # Fを保持したまま同じキーを押し直し、別の移動キーにも切り替える。
            for key in (target, target, other):
                action = first_match(manipulators, (key,), device, variables=active)
                assert key_codes(action) == [actions[key]], (layer, target, key)
                assert release_key(action, active) == [("up", actions[key])]

            # 相手キーより先にFを離した直後にも通常の入力ができる。
            pending = first_match(manipulators, (target,), device, variables=active)
            assert key_codes(pending) == [output]
            release_key(hold, active)
            ordinary = first_match(manipulators, (other,), device)
            assert first_match(manipulators, (other,), device, variables=active) == ordinary

            # Fを押し直してから古い相手キーを離しても、新しいF保持は解除されない。
            active.update(variable_values(hold))
            assert release_key(pending, active) == [("up", output)]
            assert key_codes(first_match(manipulators, (other,), device, variables=active)) == [actions[other]]
            release_key(hold, active)
            assert not any(active.values())


def verify_keymap_release(manipulators):
    # キー一覧を閉じても、Fを持ったままなら矢印とキー一覧の再表示ができる。
    for device, layer, keymap, arrow, mode in (
        (BUILT_IN, "e", "f", "o", "jis"),
        (EXTERNAL, "f", "b", "h", "external"),
    ):
        hold = first_match(manipulators, (layer,), device)
        active = variable_values(hold)
        show = ("command", f"/bin/bash -lc '$HOME/.bin/karabiner-keymap-hud show {mode}'")
        hide = ("command", "/bin/bash -lc '$HOME/.bin/karabiner-keymap-hud hide'")
        assert not first_match(manipulators, (layer, keymap), device)
        for _ in range(2):
            display = first_match(manipulators, (keymap,), device, variables=active)
            assert command_events(display["to"]) == [show]
            assert release_key(display, active) == [hide]
            follow = first_match(manipulators, (arrow,), device, variables=active)
            assert key_codes(follow) == ["left_arrow"]
        release_key(hold, active)
        assert not any(active.values())


def command_events(events):
    return [("command", event["shell_command"]) for event in events if "shell_command" in event]


def release_key(manipulator, active):
    # 出力列の最後のイベントと、入力キーの解放を待つ処理を反映する。
    events = manipulator.get("to", [])
    last = events[-1].get("set_variable", {}) if events else {}
    if "key_up_value" in last:
        active[last["name"]] = last["key_up_value"]
    after = manipulator.get("to_after_key_up", [])
    active.update(variable_values({"to": after}))
    return [("up", key) for key in key_codes(manipulator)] + command_events(after)


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
    return key_events(first_match(manipulators, keys, BUILT_IN, modifiers))


def first_match(manipulators, keys, device, modifiers=(), variables=None):
    # Karabinerと同じ順序で、押したキーと条件の両方が一致する最初のルールを探す。
    for entry in manipulators:
        source = entry["from"]
        inputs = tuple(event["key_code"] for event in source.get("simultaneous", ()))
        if not inputs:
            inputs = (source.get("key_code"),)
        if inputs != keys:
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
    return [event["key_code"] for event in key_events(entry)]


def key_events(entry):
    return [event for event in entry.get("to", []) if "key_code" in event]


def variable_values(entry):
    # Karabinerは出力列の最後以外のイベントを、入力キーの解放を待たずに押して離す。
    events = entry.get("to", [])
    return {item["name"]: item.get("key_up_value", item["value"]) if index + 1 < len(events) else item["value"]
            for index, event in enumerate(events) if (item := event.get("set_variable"))}


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
