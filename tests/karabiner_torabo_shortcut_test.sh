#!/usr/bin/env bash
set -euo pipefail

# キーボードごとに設定が適用され、Torabo のファームウェアの割り当てが保たれることを確認する。
[[ "${1:-}" == --env=localdev ]] || { echo "--env=localdev を指定してください。" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$root" <<'PY'
import json
from pathlib import Path
import sys

directory = Path(sys.argv[1]) / ".config/karabiner"
config = json.loads((directory / "karabiner.json").read_text())
active = next(profile for profile in config["profiles"] if profile["selected"])
rules = active["complex_modifications"]["rules"]
asset = directory / "assets/complex_modifications/f_hjkl_arrows.json"
assert rules == json.loads(asset.read_text())["rules"]
changes = [m for rule in rules for m in rule["manipulators"]]
external = [m for m in changes if m["from"].get("key_code") == "f24"]
assert len(external) == 1, "Torabo からの表示用キーが一意ではありません。"
shortcut = external[0]
assert shortcut["conditions"] == [{"type": "device_if", "identifiers": [
    {"vendor_id": 65261, "product_id": 48301, "is_keyboard": True}
]}], "Torabo 以外にも表示用キーが適用されています。"
assert shortcut["to"][0]["shell_command"].endswith("keymap-hud show torabo'")
assert shortcut["to_after_key_up"][0]["shell_command"].endswith("keymap-hud hide'")

# ZMK ではキー入力とカーソル操作が一つの機器として届くため、両方を Karabiner で受け取る。
torabo_identifiers = {
    "vendor_id": 65261, "product_id": 48301, "is_keyboard": True, "is_pointing_device": True
}
torabo_devices = [device for device in active.get("devices", []) if device["identifiers"] == torabo_identifiers]
assert len(torabo_devices) == 1 and torabo_devices[0].get("ignore") is False, "ZMK 版 Torabo のキー入力が変換の対象になっていません。"

def targets_torabo_only(manipulator):
    for condition in manipulator.get("conditions") or []:
        if condition.get("type") != "device_if":
            continue
        for ident in condition.get("identifiers") or []:
            if ident.get("vendor_id") == 65261 and ident.get("product_id") == 48301:
                return True
    return False

def excludes_torabo(manipulator):
    for condition in manipulator.get("conditions") or []:
        if condition.get("type") != "device_unless":
            continue
        for ident in condition.get("identifiers") or []:
            if ident.get("vendor_id") == 65261 and ident.get("product_id") == 48301:
                return True
    return False

for manipulator in changes:
    if targets_torabo_only(manipulator):
        continue
    assert excludes_torabo(manipulator), "Torabo 向け以外の Karabiner 変換が Torabo にも掛かっています。"

def applies_to_keyboard(manipulator, built_in):
    identifiers = {"is_built_in_keyboard": built_in, "is_keyboard": True}
    for condition in manipulator.get("conditions", []):
        if condition["type"] not in ("device_if", "device_unless"):
            continue
        found = any(all(identifiers.get(name) == value for name, value in candidate.items()
                        if name != "description") for candidate in condition["identifiers"])
        if found != (condition["type"] == "device_if"):
            return False
    return True

# 内蔵からは移動後の JIS 配列を開き、外付けからは従来の配列を開く。
for built_in, chord_key, mode in [(True, "f", "jis"), (False, "b", "external")]:
    hud = [m for m in changes if m["from"].get("key_code") == chord_key and applies_to_keyboard(m, built_in)
           and any(event.get("shell_command", "").endswith(f"keymap-hud show {mode}'") for event in m.get("to", []))]
    assert len(hud) == 1, f"キーボードに対して {mode} の HUD を開くルールが必要です。"

# 右 Shift の左隣のキーは、Torabo ではファームウェアの割り当てをそのまま使う。
assert not any(m["from"].get("key_code") == "international1" for m in active.get("simple_modifications", [])), (
    "全キーボードに適用されるハイフン変換が Torabo の INTERNATIONAL_1 を上書きしています。"
)
for built_in, expected in [(True, "vk_none"), (False, "hyphen")]:
    outputs = [m["to"] for m in changes if m["from"].get("key_code") == "international1"
               and applies_to_keyboard(m, built_in)]
    assert outputs == [[{"key_code": expected}]], "右 Shift の左隣のキーがキーボードごとの割り当てと合いません。"

fkeys_setting = "system.use_fkeys_as_standard_function_keys"

def matches_fkeys_setting(conditions, standard_fkeys):
    for condition in conditions:
        if condition.get("name") == fkeys_setting:
            equals = condition["value"] is standard_fkeys
            if equals != (condition["type"] == "variable_if"):
                return False
    return True

def check_function_key(manipulators, key, source):
    # macOS の設定のどちらでも、標準ファンクションキーになる出力が一つだけ必要。
    for standard_fkeys, modifiers in [(True, []), (False, ["fn"])]:
        outputs = [(event["key_code"], event.get("modifiers", []))
                   for m in manipulators if matches_fkeys_setting(m.get("conditions", []), standard_fkeys)
                   for event in m.get("to", []) if "key_code" in event
                   and matches_fkeys_setting(event.get("conditions", []), standard_fkeys)]
        assert outputs == [(key, modifiers)], f"{source}: {key} の出力が macOS の設定 {standard_fkeys} と合いません。"

# Torabo 本体から送る F キーは、macOS の設定に関わらずそのまま使う。
for number in range(1, 13):
    fkey = f"f{number}"
    check_function_key([m for m in changes if targets_torabo_only(m) and m["from"].get("key_code") == fkey],
                       fkey, "Torabo")

# 論理 C の位置は内蔵と外付けで異なり、どちらでも長押し・同時押しで標準 F キーを使える。
for built_in, hold, targets in [
    (True, "s", ["semicolon", "quote", "backslash", "p", "open_bracket", "close_bracket",
                 "hyphen", "equal_sign", "international3", "return_or_enter", "o", "0"]),
    (False, "c", ["n", "m", "comma", "j", "k", "l", "u", "i", "o", "p", "h", "y"]),
]:
    scoped = [m for m in changes if applies_to_keyboard(m, built_in)]
    for number, target in enumerate(targets, 1):
        fkey = f"f{number}"
        check_function_key([m for m in scoped if m["from"].get("key_code") == target
                            and any(c["type"] == "variable_if" and c.get("name", "").endswith("c_held")
                                    for c in m.get("conditions", []))], fkey, "C を先に長押し")
        check_function_key([m for m in scoped if m["from"].get("simultaneous") == [
            {"key_code": hold}, {"key_code": target}
        ]], fkey, "C と対象キーを続けて押す")

print("成功: キー一覧、ハイフン、標準ファンクションキーのキーボード別設定を確認しました。")
PY
