#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.config/karabiner/karabiner.json"
RULE_FILE="$ROOT_DIR/.config/karabiner/assets/complex_modifications/f_hjkl_arrows.json"
HUD_BIN="$ROOT_DIR/.bin/karabiner-keymap-hud"
HUD_JS="$ROOT_DIR/.config/karabiner/scripts/keymap-hud.js"
HUD_HTML="$ROOT_DIR/.config/karabiner/scripts/keymap-hud.html"
LAYERS_FILE="$ROOT_DIR/.config/karabiner/keymap-layers.json"

# 設定ファイルが存在しない場合は即時失敗し、配置漏れを検知する。
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Karabiner の設定ファイルが見つかりません: $CONFIG_FILE" >&2
  exit 1
fi

if [[ ! -f "$RULE_FILE" ]]; then
  echo "Karabiner の complex modification が見つかりません: $RULE_FILE" >&2
  exit 1
fi

if [[ ! -x "$HUD_BIN" ]]; then
  echo "キーマップ HUD ランチャーが見つからないか実行権限がありません: $HUD_BIN" >&2
  exit 1
fi

if [[ ! -f "$HUD_JS" ]]; then
  echo "キーマップ HUD ランチャーが見つかりません: $HUD_JS" >&2
  exit 1
fi

if [[ ! -f "$HUD_HTML" ]]; then
  echo "キーマップ HUD HTML が見つかりません: $HUD_HTML" >&2
  exit 1
fi

if [[ ! -f "$LAYERS_FILE" ]]; then
  echo "キーマップレイヤー定義が見つかりません: $LAYERS_FILE" >&2
  exit 1
fi

python3 -m json.tool "$LAYERS_FILE" >/dev/null

for layer_id in base f d v c x; do
  if ! grep -Fq "\"id\": \"$layer_id\"" "$LAYERS_FILE"; then
    echo "レイヤー定義に $layer_id が含まれていません。" >&2
    exit 1
  fi
done
if ! grep -Fq '"control": "z/⌃"' "$LAYERS_FILE"; then
  echo "ベースレイヤーに control tap=z hold=Control の表示がありません。" >&2
  exit 1
fi

if ! grep -Fq '"layout": "jis"' "$LAYERS_FILE"; then
  echo "レイヤー定義が JIS 配列ではありません。" >&2
  exit 1
fi

if ! grep -Fq '"rows"' "$LAYERS_FILE"; then
  echo "レイヤー定義にキーボード配列 rows が含まれていません。" >&2
  exit 1
fi

# 旧 fn ベースの定義が残っていないことを確認する。
if [[ -e "$ROOT_DIR/.config/karabiner/assets/complex_modifications/fn_hjkl_arrows.json" ]]; then
  echo "旧 fn ベースの Karabiner 定義が残っています。" >&2
  exit 1
fi

# JSON として読み込めることを確認し、壊れた設定の共有を防ぐ。
python3 -m json.tool "$CONFIG_FILE" >/dev/null
python3 -m json.tool "$RULE_FILE" >/dev/null

# f レイヤーと HUD 呼び出しの定義が含まれていることを確認する。
for expected in \
  '"key_code": "f"' \
  '"name": "f_held"' \
  '"key_code": "h"' \
  '"key_code": "j"' \
  '"key_code": "k"' \
  '"key_code": "l"' \
  '"key_code": "a"' \
  '"key_code": "b"' \
  '"key_code": "tab"' \
  '"key_code": "e"' \
  '"key_code": "m"' \
  '"key_code": "left_arrow"' \
  '"key_code": "down_arrow"' \
  '"key_code": "up_arrow"' \
  '"key_code": "right_arrow"' \
  '"key_code": "delete_or_backspace"' \
  'karabiner-keymap-hud show jis' \
  'karabiner-keymap-hud show torabo' \
  'karabiner-keymap-hud hide' \
  '"mandatory": [' \
  'left_command' \
  '"type": "variable_if"' \
  '"to_if_alone"' \
  '"simultaneous"' \
  'simultaneous_threshold_milliseconds' \
  '"to_after_key_up"' \
  'japanese_eisuu' \
  'japanese_kana' \
  'return_or_enter' \
  'left_shift' \
  'spacebar' \
  '"name": "d_held"' \
  '"key_code": "w"' \
  '"key_code": "d"' \
  '"key_code": "semicolon"' \
  '"key_code": "1"' \
  '"key_code": "0"' \
  'd layer' \
  '"name": "v_held"' \
  'v layer' \
  '"name": "c_held"' \
  'c layer' \
  '"name": "x_held"' \
  'x layer' \
  '"key_code": "z"' \
  'left_control' \
  'control tap=z hold=Control' \
  '"key_code": "escape"' \
  '"key_code": "delete_forward"' \
  'launchpad' \
  'mission_control' \
  'volume_increment'; do
  if ! grep -Fq "$expected" "$CONFIG_FILE"; then
    echo "Karabiner 設定に期待した定義が含まれていません: $expected" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "$RULE_FILE"; then
    echo "Karabiner complex modification に期待した定義が含まれていません: $expected" >&2
    exit 1
  fi
done

# プロファイルでルールが有効化されていることを確認する。
if ! grep -Fq 'karabiner-keymap-hud show jis' "$CONFIG_FILE"; then
  echo "Karabiner プロファイルに内蔵向け HUD（show jis）ルールがありません。" >&2
  exit 1
fi
if ! grep -Fq '"kana": "␣/⇧"' "$LAYERS_FILE" || ! grep -Fq '"command_r": "↩/⌘"' "$LAYERS_FILE"; then
  echo "ベースレイヤーに右あいう=␣/⇧・右command=↩/⌘ の表示がありません。" >&2
  exit 1
fi
if ! grep -Fq 'japanese_eisuu' "$CONFIG_FILE" || ! grep -Fq 'japanese_kana' "$CONFIG_FILE"; then
  echo "Karabiner プロファイルに 英数/かな の tap-hold ルールがありません。" >&2
  exit 1
fi
if ! grep -Fq 'spacebar' "$CONFIG_FILE" || ! grep -Fq 'left_shift' "$CONFIG_FILE"; then
  echo "Karabiner プロファイルに space hold=Shift ルールがありません。" >&2
  exit 1
fi

# fn 修飾子ベースの定義へ戻っていないことを確認する。
if grep -Fq '"mandatory": ["fn"]' "$CONFIG_FILE" || grep -Fq '"mandatory": ["fn"]' "$RULE_FILE"; then
  echo "Karabiner 設定が fn 修飾子ベースのままです。" >&2
  exit 1
fi

echo "PASS: Karabiner は f レイヤーと f+m キーマップ HUD の設定を保持しています。"
