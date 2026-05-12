#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.config/borders/bordersrc"

# 設定ファイルが存在しない場合は即時失敗し、配置漏れを検知する。
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "JankyBorders の設定ファイルが見つかりません: $CONFIG_FILE" >&2
  exit 1
fi

# JankyBorders は設定ファイルを実行するため、実行権限の不足を検知する。
if [[ ! -x "$CONFIG_FILE" ]]; then
  echo "JankyBorders の設定ファイルに実行権限がありません: $CONFIG_FILE" >&2
  exit 1
fi

# 実際の borders を起動しないよう、一時ディレクトリに検証用コマンドを配置する。
TEMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

BIN_DIR="$TEMP_ROOT/bin"
CAPTURE_FILE="$TEMP_ROOT/borders-arguments.txt"
mkdir -p "$BIN_DIR"

cat >"$BIN_DIR/borders" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$BORDERS_CAPTURE_FILE"
SH
chmod +x "$BIN_DIR/borders"

# 設定ファイルが JankyBorders に渡す引数だけを検証し、実装の書き方には依存しない。
BORDERS_CAPTURE_FILE="$CAPTURE_FILE" PATH="$BIN_DIR:/usr/bin:/bin" "$CONFIG_FILE"

for expected_key in \
  "style=" \
  "order=" \
  "width=" \
  "hidpi=" \
  "ax_focus=" \
  "active_color=" \
  "inactive_color="; do
  if ! grep -Eq "^${expected_key}" "$CAPTURE_FILE"; then
    echo "JankyBorders に期待した設定項目が渡されていません: $expected_key" >&2
    echo "実際の引数:" >&2
    cat "$CAPTURE_FILE" >&2
    exit 1
  fi
done

if ! grep -Fxq "ax_focus=on" "$CAPTURE_FILE"; then
  echo "サブモニター向けのフォーカス検出設定が有効ではありません。" >&2
  exit 1
fi

echo "PASS: JankyBorders の設定ファイルはフォーカス中のウィンドウだけを強調する引数を渡します。"
