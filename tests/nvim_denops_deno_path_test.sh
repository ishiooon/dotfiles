#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SCRIPT="$ROOT_DIR/tests/nvim_denops_deno_path_test.lua"

# denops.vim 向けの Deno パス設定を、Neovim の最小構成で安全に検証する。
OUTPUT="$(ROOT_DIR="$ROOT_DIR" nvim --clean --headless -u NONE \
  -c "luafile $TEST_SCRIPT" \
  -c "qa!" 2>&1)"

if ! grep -Fq "PASS: denops.vim は実行可能な deno だけを参照します。" <<<"$OUTPUT"; then
  echo "$OUTPUT" >&2
  exit 1
fi

echo "$OUTPUT"
