#!/usr/bin/env bash
set -euo pipefail

# 通常の設定読み込みと区別し、ローカル開発用の指定がある場合だけ検証する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# プラグイン取得や履歴保存を行わず、最小構成の Neovim でキーマップだけを検証する。
ROOT_DIR="$ROOT_DIR" NVIM_LOG_FILE=/dev/null nvim --clean --headless -u NONE -i NONE -n \
  -c "lua local ok, err = pcall(dofile, '$ROOT_DIR/tests/nvim_triforce_keymap_test.lua'); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c "qa!"
