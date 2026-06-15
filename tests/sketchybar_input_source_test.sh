#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_SOURCE_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/input_source.sh"
MOCK_DIR="$(mktemp -d)"
OUTPUT_FILE="$MOCK_DIR/sketchybar.commands"

# テスト用の sketchybar コマンドを用意し、実際のバーへ設定を書き込まずに表示内容を確認する。
trap 'rm -rf "$MOCK_DIR"' EXIT
cat >"$MOCK_DIR/sketchybar" <<'MOCK'
#!/usr/bin/env bash
printf 'sketchybar' >>"$SKETCHYBAR_COMMAND_LOG"
printf ' %s' "$@" >>"$SKETCHYBAR_COMMAND_LOG"
printf '\n' >>"$SKETCHYBAR_COMMAND_LOG"
MOCK
chmod +x "$MOCK_DIR/sketchybar"

if [[ ! -x "$INPUT_SOURCE_SCRIPT" ]]; then
  echo "入力状態表示スクリプトが見つからないか、実行できません: $INPUT_SOURCE_SCRIPT" >&2
  exit 1
fi

SKETCHYBAR_COMMAND_LOG="$OUTPUT_FILE" CONFIG_DIR="$ROOT_DIR/.config/sketchybar" PATH="$MOCK_DIR:$PATH" NAME=input.source SKETCHYBAR_INPUT_SOURCE_NAME=Hiragana bash "$INPUT_SOURCE_SCRIPT" --env=localdev
JAPANESE_OUTPUT="$(cat "$OUTPUT_FILE")"
: >"$OUTPUT_FILE"
SKETCHYBAR_COMMAND_LOG="$OUTPUT_FILE" CONFIG_DIR="$ROOT_DIR/.config/sketchybar" PATH="$MOCK_DIR:$PATH" NAME=input.source SKETCHYBAR_INPUT_SOURCE_NAME=ABC bash "$INPUT_SOURCE_SCRIPT" --env=localdev
ENGLISH_OUTPUT="$(cat "$OUTPUT_FILE")"

if ! grep -Fq -- "--set input.source" <<<"$JAPANESE_OUTPUT" || ! grep -Fq "label=あ" <<<"$JAPANESE_OUTPUT"; then
  echo "日本語入力時に入力状態が「あ」と表示されません。" >&2
  echo "$JAPANESE_OUTPUT" >&2
  exit 1
fi

if ! grep -Fq -- "--set input.source" <<<"$ENGLISH_OUTPUT" || ! grep -Fq "label=A" <<<"$ENGLISH_OUTPUT"; then
  echo "英字入力時に入力状態が「A」と表示されません。" >&2
  echo "$ENGLISH_OUTPUT" >&2
  exit 1
fi

echo "PASS: SketchyBar は現在の入力状態を日本語入力かどうかで表示できます。"
