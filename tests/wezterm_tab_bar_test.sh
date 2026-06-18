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
  "config.hide_tab_bar_if_only_one_tab = false" \
  "config.integrated_title_button_style = 'MacOsNative'" \
  "config.integrated_title_button_alignment = 'Left'"; do
  if ! grep -Fq "$expected" "$CONFIG_FILE"; then
    echo "WezTerm のタブバー表示設定が期待と一致しません: $expected" >&2
    exit 1
  fi
done

# macOS では閉じるボタンなどのウィンドウ操作ボタンをタブバーへ統合し、上下二段表示を避ける。
if ! grep -Fq "config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'" "$CONFIG_FILE"; then
  echo "WezTerm のタブバーがタイトルバーの行へ統合されていません。" >&2
  exit 1
fi

for expected in "require('tab_title')" "tab_title.apply"; do
  if ! grep -Fq "$expected" "$CONFIG_FILE"; then
    echo "WezTerm の設定にタブタイトル調整が含まれていません: $expected" >&2
    exit 1
  fi
done

# WezTerm 本体を起動せず、イベント登録先だけを差し替えてタブ名の振る舞いを検証する。
if ! LUA_PATH="$WEZTERM_DIR/?.lua;;" luajit <<'LUA'
local tab_title = require('tab_title')
local registered = {}
local wezterm = {
  on = function(event_name, callback)
    registered[event_name] = callback
  end,
}

local function fail(message)
  io.stderr:write(message .. "\n")
  os.exit(1)
end

tab_title.apply(wezterm)

local callback = registered['format-tab-title']
if type(callback) ~= 'function' then
  fail('format-tab-title イベントが登録されていません。')
end

local function resolve_title(current_working_dir, pane_title, foreground_process_name, user_vars, tab_index)
  return callback({
    tab_index = tab_index or 0,
    tab_title = '',
    active_pane = {
      current_working_dir = current_working_dir,
      title = pane_title,
      foreground_process_name = foreground_process_name or '/usr/local/bin/' .. pane_title,
      user_vars = user_vars or {},
    },
  }, {}, {}, {}, false, 100)
end

if resolve_title({ file_path = '/Users/example/projects/dotfiles' }, 'nvim') ~= '1:dotfiles(nvim)' then
  fail('Neovim のタブ名は、タブ番号、プロジェクト名、Neovim 表記を組み合わせる必要があります。')
end

if resolve_title('file:///Users/example/projects/api', 'nvim', nil, nil, 2) ~= '3:api(nvim)' then
  fail('文字列形式の作業ディレクトリでも、Neovim のタブ名はタブ番号、プロジェクト名、Neovim 表記にする必要があります。')
end

if resolve_title({ file_path = '/Users/example/projects/dotfiles' }, 'codex') ~= '1:dotfiles(codex)' then
  fail('Codex のタブ名は、タブ番号、プロジェクト名、Codex 表記を組み合わせる必要があります。')
end

if resolve_title({ file_path = '/Users/example/projects/api' }, 'node', '/opt/homebrew/bin/codex') ~= '1:api(codex)' then
  fail('Codex の実行ファイル名を検出した場合も、タブ名はタブ番号、プロジェクト名、Codex 表記にする必要があります。')
end

if resolve_title({ file_path = '/Users/example/projects/api' }, 'nvim', nil, {
  CODEX_NVIM_TOOL = 'codex',
  CODEX_NVIM_STATE = 'loading',
}) ~= '1:api(codex...)' then
  fail('codex.nvim が応答中の場合は、タブ番号と Codex のローディング表示を出す必要があります。')
end

if resolve_title({ file_path = '/Users/example/projects/api' }, 'nvim', nil, {
  CODEX_NVIM_TOOL = 'codex',
  CODEX_NVIM_STATE = 'attention',
}) ~= '1:api(codex!)' then
  fail('codex.nvim が選択待ちの場合は、タブ番号と Codex の注意表示を出す必要があります。')
end

if resolve_title({ file_path = '/Users/example/projects/api' }, 'nvim', nil, {
  CODEX_NVIM_TOOL = 'codex',
  CODEX_NVIM_STATE = 'active',
}) ~= '1:api(codex)' then
  fail('codex.nvim が表示中の場合は、タブ番号付きの Codex 表記にする必要があります。')
end

if resolve_title({ file_path = '/Users/example/projects/dotfiles' }, 'zsh') ~= '1:zsh' then
  fail('Neovim 以外のタブ名は、タブ番号付きの標準ペインタイトルへ戻す必要があります。')
end
LUA
then
  echo "WezTerm のタブタイトルの振る舞いが期待と一致しません。" >&2
  exit 1
fi

echo "PASS: WezTerm のタブバーはタイトルバーの行に統合され、Neovim と Codex のタブ名はプロジェクト名を使います。"
