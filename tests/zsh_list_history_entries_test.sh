#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_SCRIPT="$ROOT_DIR/.zsh/scripts/list_history_entries.sh"

# 検証対象スクリプトが存在しない場合は即時失敗し、実装漏れを検知する。
if [[ ! -f "$TARGET_SCRIPT" ]]; then
  echo "検証対象が見つかりません: $TARGET_SCRIPT" >&2
  exit 1
fi

# 一時的な履歴ファイルを作成し、テスト終了時に必ず削除する。
TEMP_HISTORY="$(mktemp)"
cleanup() {
  rm -f "$TEMP_HISTORY"
}
trap cleanup EXIT

cat > "$TEMP_HISTORY" <<'EOF'
echo first
echo second
echo first
setopt share_history
# comment
: 1710000000:0;echo third
: 1710000001:0;echo third
EOF

# tac が存在しない macOS 既定環境を想定し、最小の PATH で実行する。
ACTUAL_OUTPUT="$(
  HISTFILE="$TEMP_HISTORY" PATH="/usr/bin:/bin" zsh "$TARGET_SCRIPT"
)"
EXPECTED_OUTPUT=$'echo third\necho second\necho first'

if [[ "$ACTUAL_OUTPUT" != "$EXPECTED_OUTPUT" ]]; then
  echo "出力が期待と一致しません。" >&2
  echo "--- expected ---" >&2
  printf '%s\n' "$EXPECTED_OUTPUT" >&2
  echo "--- actual ---" >&2
  printf '%s\n' "$ACTUAL_OUTPUT" >&2
  exit 1
fi

echo "PASS: zsh 履歴一覧は tac 非依存で生成できました。"
