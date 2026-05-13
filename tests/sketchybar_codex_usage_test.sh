#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.config/sketchybar/sketchybarrc"
CONFIG_TEXT="$(find "$ROOT_DIR/.config/sketchybar" -maxdepth 2 -type f \( -name '*.sh' -o -name 'sketchybarrc' \) -print0 | xargs -0 cat)"
PLUGIN_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/codex_usage.sh"
RIGHT_ITEMS_FILE="$ROOT_DIR/.config/sketchybar/items/right.sh"
SESSION_FILE="$(mktemp)"

cleanup() {
  rm -f "$SESSION_FILE"
}
trap cleanup EXIT

cat >"$SESSION_FILE" <<'JSONL'
{"type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":13.0,"window_minutes":300,"resets_at":1778659356},"secondary":{"used_percent":6.0,"window_minutes":10080,"resets_at":1779183809}}}}
JSONL

if [[ ! -x "$PLUGIN_SCRIPT" ]]; then
  echo "Codex 使用量表示スクリプトが見つからないか、実行できません: $PLUGIN_SCRIPT" >&2
  exit 1
fi

if ! awk '/for popup_item in/{inside_popup_loop=1} inside_popup_loop && /background.drawing=off/{found=1} inside_popup_loop && /^done$/{exit found ? 0 : 1}' "$RIGHT_ITEMS_FILE"; then
  echo "Codex 使用量の popup 項目が、再読み込み時にホバー表示を初期化していません。" >&2
  exit 1
fi

for expected in "codex.usage" "codex.usage.five_hour" "codex.usage.weekly" "popup.codex.usage" "mouse.entered" "mouse.exited.global" "codex_usage.sh" "menu_popup_hover.sh"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "SketchyBar の設定に Codex 使用量表示の構成が不足しています: $expected" >&2
    exit 1
  fi
done

OUTPUT="$(NAME=codex.usage CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"

if ! grep -Fq -- "--set codex.usage" <<<"$OUTPUT" || ! grep -Fq "label=5h\\ 87%" <<<"$OUTPUT"; then
  echo "Codex 使用量表示スクリプトが5時間の残り率を通常表示に反映していません。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

if ! grep -Fq "codex.usage.five_hour" <<<"$OUTPUT" || ! grep -Fq "label=5h\\ 87%\\ until\\ 05/13\\ 17:02" <<<"$OUTPUT"; then
  echo "Codex 使用量表示スクリプトがホバー表示用の5時間残り率を更新していません。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

if ! grep -Fq "codex.usage.weekly" <<<"$OUTPUT" || ! grep -Fq "label=7d\\ 94%\\ until\\ 05/19\\ 18:43" <<<"$OUTPUT"; then
  echo "Codex 使用量表示スクリプトがホバー表示用の週間残り率を更新していません。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

HOVER_OUTPUT="$(NAME=codex.usage SENDER=mouse.entered CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "popup.drawing=on" <<<"$HOVER_OUTPUT"; then
  echo "Codex 使用量表示スクリプトがホバー時に詳細表示を開いていません。" >&2
  echo "$HOVER_OUTPUT" >&2
  exit 1
fi
if ! grep -Fq "close-other-popups codex.usage" <<<"$HOVER_OUTPUT"; then
  echo "Codex 使用量表示を開いたときに、ほかの popup を閉じていません。" >&2
  echo "$HOVER_OUTPUT" >&2
  exit 1
fi
if ! grep -Fq "clear-popup-hover codex.usage" <<<"$HOVER_OUTPUT" || ! grep -Fq "codex.usage.weekly background.drawing=off" <<<"$HOVER_OUTPUT"; then
  echo "Codex 使用量表示を開いたときに、前回残った項目ホバー表示を消していません。" >&2
  echo "$HOVER_OUTPUT" >&2
  exit 1
fi

EXIT_OUTPUT="$(NAME=codex.usage SENDER=mouse.exited CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "popup.drawing=off" <<<"$EXIT_OUTPUT"; then
  echo "Codex 使用量表示スクリプトが親項目から離れただけで詳細表示を閉じています。" >&2
  echo "$EXIT_OUTPUT" >&2
  exit 1
fi

GLOBAL_EXIT_OUTPUT="$(NAME=codex.usage SENDER=mouse.exited.global CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "schedule-popup-close codex.usage" <<<"$GLOBAL_EXIT_OUTPUT" || ! grep -Fq "clear-popup-hover codex.usage" <<<"$GLOBAL_EXIT_OUTPUT"; then
  echo "Codex 使用量表示スクリプトが詳細表示へ移動する猶予を作っていません。" >&2
  echo "$GLOBAL_EXIT_OUTPUT" >&2
  exit 1
fi

POPUP_OUTPUT="$(NAME=codex.usage.weekly SENDER=mouse.entered CONFIG_DIR="$ROOT_DIR/.config/sketchybar" bash "$ROOT_DIR/.config/sketchybar/plugins/menu_popup_hover.sh" --env=localdev --dry-run)"
if ! grep -Fq "cancel-popup-close codex.usage" <<<"$POPUP_OUTPUT" || ! grep -Fq "background.drawing=on" <<<"$POPUP_OUTPUT"; then
  echo "Codex 詳細表示の popup 項目がホバー維持と強調表示に対応していません。" >&2
  echo "$POPUP_OUTPUT" >&2
  exit 1
fi

POPUP_EXIT_OUTPUT="$(NAME=codex.usage.weekly SENDER=mouse.exited CONFIG_DIR="$ROOT_DIR/.config/sketchybar" bash "$ROOT_DIR/.config/sketchybar/plugins/menu_popup_hover.sh" --env=localdev --dry-run)"
if grep -Fq "schedule-popup-close codex.usage" <<<"$POPUP_EXIT_OUTPUT" || ! grep -Fq "background.drawing=off" <<<"$POPUP_EXIT_OUTPUT"; then
  echo "Codex 詳細表示の popup 項目間を移動しただけで閉じる予約が入っています。" >&2
  echo "$POPUP_EXIT_OUTPUT" >&2
  exit 1
fi

echo "PASS: SketchyBar は Codex の5時間残り率を通常表示し、ホバー時に残り率と回復日時を表示できます。"
