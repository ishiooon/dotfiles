#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEZTERM_DIR="$ROOT_DIR/.config/wezterm"
CONFIG_FILE="$WEZTERM_DIR/wezterm.lua"
TITLE_MODULE="$WEZTERM_DIR/tab_title.lua"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "WezTerm の設定ファイルが見つかりません: $CONFIG_FILE" >&2
  exit 1
fi

if [[ ! -f "$TITLE_MODULE" ]]; then
  echo "WezTerm のタブタイトル設定モジュールが見つかりません: $TITLE_MODULE" >&2
  exit 1
fi

# タブバーは初期状態から表示し、単一タブでも隠さない方針を検証する。
for expected in \
  "config.enable_tab_bar = true" \
  "config.hide_tab_bar_if_only_one_tab = false"; do
  if ! grep -Fq "$expected" "$CONFIG_FILE"; then
    echo "WezTerm のタブバー表示設定が期待と一致しません: $expected" >&2
    exit 1
  fi
done

# WezTerm 本体を起動せず、イベント登録先だけを差し替えてタブ名の振る舞いを検証する。
LUA_PATH="$WEZTERM_DIR/?.lua;;" luajit <<'LUA'
local tab_title = require('tab_title')
local registered = {}
local wezterm = {
  on = function(event_name, callback)
    registered[event_name] = callback
  end,
}

tab_title.apply(wezterm)

local callback = registered['format-tab-title']
if type(callback) ~= 'function' then
  error('format-tab-title イベントが登録されていません。')
end

local function resolve_title(current_working_dir, pane_title)
  return callback({
    tab_title = '',
    active_pane = {
      current_working_dir = current_working_dir,
      title = pane_title,
    },
  }, {}, {}, {}, false, 100)
end

if resolve_title({ file_path = '/Users/example/projects/dotfiles' }, 'nvim') ~= 'dotfiles' then
  error('Neovim がペインタイトルを変更しても、タブ名はディレクトリ名を優先する必要があります。')
end

if resolve_title('file:///Users/example/projects/api', 'nvim') ~= 'api' then
  error('文字列形式の作業ディレクトリでも、末尾のディレクトリ名を表示する必要があります。')
end

if resolve_title({ scheme = 'file' }, 'zsh') ~= 'zsh' then
  error('作業ディレクトリのファイルパスが取れない場合は、従来のペインタイトルへ戻す必要があります。')
end

if resolve_title(nil, 'zsh') ~= 'zsh' then
  error('作業ディレクトリが取れない場合は、従来のペインタイトルへ戻す必要があります。')
end
LUA

echo "PASS: WezTerm のタブバー表示とタブタイトルは期待どおりに設定されています。"
