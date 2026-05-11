#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_SCRIPT="$ROOT_DIR/.zsh/scripts/delete_history_entry.sh"
LIST_SCRIPT="$ROOT_DIR/.zsh/scripts/list_history_entries.sh"

# 検証対象スクリプトが存在しない場合は即時失敗し、配置漏れを検知する。
if [[ ! -f "$TARGET_SCRIPT" ]]; then
  echo "検証対象が見つかりません: $TARGET_SCRIPT" >&2
  exit 1
fi

# 削除後の一覧生成に必要な共通スクリプトが存在することを確認する。
if [[ ! -f "$LIST_SCRIPT" ]]; then
  echo "履歴一覧生成スクリプトが見つかりません: $LIST_SCRIPT" >&2
  exit 1
fi

# テスト用のHOMEと履歴ファイルを作成し、実環境の履歴に影響しないようにする。
TEMP_HOME="$(mktemp -d)"
TEMP_HISTORY="$(mktemp)"
cleanup() {
  rm -rf "$TEMP_HOME"
  rm -f "$TEMP_HISTORY"
}
trap cleanup EXIT

# 削除スクリプトはHOME配下の共通スクリプトを参照するため、テスト用HOMEへ接続する。
mkdir -p "$TEMP_HOME/.zsh/scripts"
ln -s "$LIST_SCRIPT" "$TEMP_HOME/.zsh/scripts/list_history_entries.sh"

cat > "$TEMP_HISTORY" <<'EOF'
: 1710000000:0;echo keep
: 1710000001:0;echo remove
: 1710000002:0;echo remain
EOF

# fzfの表示行として渡されるコマンド名で、zsh拡張履歴から対象行を削除できることを確認する。
ACTUAL_OUTPUT="$(
  HOME="$TEMP_HOME" HISTFILE="$TEMP_HISTORY" zsh "$TARGET_SCRIPT" "echo remove"
)"
EXPECTED_OUTPUT=$'echo remain\necho keep'
ACTUAL_HISTORY="$(cat "$TEMP_HISTORY")"
EXPECTED_HISTORY=$': 1710000000:0;echo keep\n: 1710000002:0;echo remain'

if [[ "$ACTUAL_OUTPUT" != "$EXPECTED_OUTPUT" ]]; then
  echo "削除後の履歴一覧が期待と一致しません。" >&2
  echo "--- expected ---" >&2
  printf '%s\n' "$EXPECTED_OUTPUT" >&2
  echo "--- actual ---" >&2
  printf '%s\n' "$ACTUAL_OUTPUT" >&2
  exit 1
fi

if [[ "$ACTUAL_HISTORY" != "$EXPECTED_HISTORY" ]]; then
  echo "履歴ファイルの内容が期待と一致しません。" >&2
  echo "--- expected ---" >&2
  printf '%s\n' "$EXPECTED_HISTORY" >&2
  echo "--- actual ---" >&2
  printf '%s\n' "$ACTUAL_HISTORY" >&2
  exit 1
fi

echo "PASS: zsh拡張履歴の表示コマンドから対象履歴を削除できました。"
