#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_FILE="$ROOT_DIR/.config/nvim/lua/plugins/fzf.lua"

# Telescope の設定ファイルが無い場合は、プラグイン定義の配置漏れとして失敗させる。
if [[ ! -f "$PLUGIN_FILE" ]]; then
  echo "Telescope のプラグイン設定が見つかりません: $PLUGIN_FILE" >&2
  exit 1
fi

# 現在利用している Neovim v0.11.0 では telescope-frecency.nvim v2 系が要求する v0.11.7 に届かない。
# そのため、互換性のある v1 系へ固定して起動時エラーを防ぐ。
if ! awk '
  /"nvim-telescope\/telescope-frecency.nvim"/ { in_plugin = 1 }
  in_plugin && /version[[:space:]]*=[[:space:]]*"\^1\.0\.0"/ { found = 1 }
  in_plugin && /^    },/ { in_plugin = 0 }
  END { exit(found ? 0 : 1) }
' "$PLUGIN_FILE"; then
  echo "telescope-frecency.nvim が Neovim v0.11.0 互換の ^1.0.0 に固定されていません。" >&2
  exit 1
fi

echo "PASS: telescope-frecency.nvim は Neovim v0.11.0 互換の v1 系へ固定されています。"
