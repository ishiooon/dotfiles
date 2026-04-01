#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# NeoTree 向けの更新判定は純粋関数として切り出し、Neovim の最小構成で安全に検証する。
TEST_SCRIPT="$ROOT_DIR/tests/nvim_neo_tree_git_refresh_test.lua"

if [[ ! -f "$TEST_SCRIPT" ]]; then
  echo "検証対象が見つかりません: $TEST_SCRIPT" >&2
  exit 1
fi

ROOT_DIR="$ROOT_DIR" nvim --clean --headless -u NONE \
  -c "luafile $TEST_SCRIPT" \
  -c "qa!"
