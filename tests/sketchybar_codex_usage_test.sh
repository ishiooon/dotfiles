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

for expected in "codex.usage" "codex_usage.sh"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "SketchyBar の設定に Codex 使用量表示の構成が不足しています: $expected" >&2
    exit 1
  fi
done

for forbidden in "codex.usage.five_hour" "codex.usage.weekly" "popup.codex.usage" "mouse.entered" "mouse.exited" "menu_popup_hover.sh"; do
  if grep -Fq "$forbidden" "$RIGHT_ITEMS_FILE"; then
    echo "Codex 使用量表示に hover popup 用の構成が残っています: $forbidden" >&2
    exit 1
  fi
done

OUTPUT="$(NAME=codex.usage CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"

if ! grep -Fq -- "--set codex.usage" <<<"$OUTPUT" || ! grep -Fq "label=5h\\ 87%" <<<"$OUTPUT"; then
  echo "Codex 使用量表示スクリプトが5時間の残り率を通常表示に反映していません。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

if grep -Fq "codex.usage.five_hour" <<<"$OUTPUT" || grep -Fq "codex.usage.weekly" <<<"$OUTPUT"; then
  echo "Codex 使用量表示スクリプトが不要な popup 用項目を更新しています。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

HOVER_OUTPUT="$(NAME=codex.usage SENDER=mouse.entered CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "popup.drawing=on" <<<"$HOVER_OUTPUT" || grep -Fq "close-other-popups" <<<"$HOVER_OUTPUT" || grep -Fq "clear-popup-hover" <<<"$HOVER_OUTPUT"; then
  echo "Codex 使用量表示スクリプトがホバー時に popup を開いています。" >&2
  echo "$HOVER_OUTPUT" >&2
  exit 1
fi

EXIT_OUTPUT="$(NAME=codex.usage SENDER=mouse.exited CODEX_USAGE_SESSION_FILE="$SESSION_FILE" bash "$PLUGIN_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "schedule-popup-close" <<<"$EXIT_OUTPUT" || grep -Fq "popup.drawing=off" <<<"$EXIT_OUTPUT"; then
  echo "Codex 使用量表示スクリプトがマウス退出で popup を閉じようとしています。" >&2
  echo "$EXIT_OUTPUT" >&2
  exit 1
fi

echo "PASS: SketchyBar は Codex の5時間残り率だけを通常表示し、hover popup を開きません。"
