#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_LUA_DIR="$ROOT_DIR/.config/nvim/lua"
PLUGIN_FILE="$ROOT_DIR/.config/nvim/lua/plugins/codex.lua"

if ! grep -Fq 'config.codex_wezterm' "$PLUGIN_FILE"; then
  echo "codex.nvim の初期化時に WezTerm 連携モジュールを読み込む必要があります。" >&2
  exit 1
fi

if ! LUA_PATH="$NVIM_LUA_DIR/?.lua;$NVIM_LUA_DIR/?/init.lua;;" luajit <<'LUA'
local sent_sequences = {}

_G.vim = {
  env = {},
  v = { stderr = 2 },
  fn = {
    chansend = function(channel, sequence)
      table.insert(sent_sequences, { channel = channel, sequence = sequence })
      return #sequence
    end,
    getbufinfo = function(bufnr)
      if bufnr == 10 then
        return { { windows = { 100 } } }
      end
      return { { windows = {} } }
    end,
  },
  loop = {
    now = function()
      return 1000
    end,
    new_timer = function()
      return {
        start = function() end,
        stop = function() end,
        close = function() end,
      }
    end,
  },
  schedule = function(callback)
    callback()
  end,
  api = {
    nvim_create_augroup = function()
      return 1
    end,
    nvim_create_autocmd = function() end,
  },
}

local function fail(message)
  io.stderr:write(message .. "\n")
  os.exit(1)
end

local require_ok, codex_wezterm = pcall(require, "config.codex_wezterm")
if not require_ok then
  fail("Codex WezTerm 連携モジュールを読み込めません: " .. tostring(codex_wezterm))
end

if codex_wezterm.base64_encode("codex") ~= "Y29kZXg=" then
  fail("Codex 状態通知に使う base64 エンコードが期待と一致しません。")
end

if codex_wezterm.resolve_tab_state("busy", false) ~= "loading" then
  fail("Codex 応答中は WezTerm の loading 状態へ変換する必要があります。")
end

if codex_wezterm.resolve_tab_state("wait", false) ~= "attention" then
  fail("Codex 選択待ちは WezTerm の attention 状態へ変換する必要があります。")
end

if codex_wezterm.resolve_tab_state("idle", true) ~= "active" then
  fail("Codex ターミナル表示中の idle は active 状態として扱う必要があります。")
end

if codex_wezterm.resolve_tab_state("idle", false) ~= "" then
  fail("Codex ターミナルが非表示の idle は、通常の Neovim 表示へ戻す必要があります。")
end

codex_wezterm.publish("wait", false)
if #sent_sequences ~= 2 then
  fail("Codex 状態通知では tool と state の2つの user var を送る必要があります。")
end
if not sent_sequences[1].sequence:find("SetUserVar=CODEX_NVIM_TOOL=Y29kZXg=", 1, true) then
  fail("Codex 状態通知では CODEX_NVIM_TOOL=codex を送る必要があります。")
end
if not sent_sequences[2].sequence:find("SetUserVar=CODEX_NVIM_STATE=YXR0ZW50aW9u", 1, true) then
  fail("Codex 選択待ちでは CODEX_NVIM_STATE=attention を送る必要があります。")
end

sent_sequences = {}
codex_wezterm.publish("idle", false)
if #sent_sequences ~= 2 then
  fail("Codex 非表示時は tool と state の2つの user var を消す必要があります。")
end
if not sent_sequences[1].sequence:find("SetUserVar=CODEX_NVIM_TOOL=", 1, true) then
  fail("Codex 非表示時は CODEX_NVIM_TOOL を空にする必要があります。")
end
if not sent_sequences[2].sequence:find("SetUserVar=CODEX_NVIM_STATE=", 1, true) then
  fail("Codex 非表示時は CODEX_NVIM_STATE を空にする必要があります。")
end
LUA
then
  echo "Neovim の Codex WezTerm 連携が期待と一致しません。" >&2
  exit 1
fi

echo "PASS: Neovim は codex.nvim の状態を WezTerm の user vars へ変換できます。"
