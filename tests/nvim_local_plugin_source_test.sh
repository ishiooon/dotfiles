#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境の指定を必須にして、通常の設定読み込みと区別する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# ファイルシステムの照会を置き換え、外部取得や開発用ディレクトリの作成を行わない。
ROOT_DIR="$ROOT_DIR" NVIM_LOG_FILE=/dev/null nvim --clean --headless -u NONE -i NONE -n \
  -c "lua local ok, err = pcall(dofile, '$ROOT_DIR/tests/nvim_local_plugin_source_test.lua'); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c "qa!"
