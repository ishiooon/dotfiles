-- このファイルはcodex.nvimの状態をWezTermのタブ表示へ伝えるための連携を担当します。
local M = {}

local CODEX_TOOL_USER_VAR = "CODEX_NVIM_TOOL"
local CODEX_STATE_USER_VAR = "CODEX_NVIM_STATE"
local CODEX_TOOL_NAME = "codex"
local DEFAULT_UPDATE_INTERVAL_MS = 500
local user_var = require("config.wezterm_user_var")

local state = {
  timer = nil,
}

function M.setup(options)
  local resolved_options = M.resolve_options(options)
  if resolved_options.enabled == false then
    M.stop()
    return
  end

  M.stop()
  state.timer = M.start_timer(resolved_options.update_interval_ms)
  M.create_cleanup_autocmd()
  M.update()
end

function M.stop()
  -- 起動中のタイマーを止め、タブに残ったCodex状態を消します。
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
  M.clear()
end

function M.update()
  local status = M.current_codex_status()
  local terminal_visible = M.is_codex_terminal_visible()
  M.publish(status, terminal_visible)
end

function M.publish(status, terminal_visible)
  local tab_state = M.resolve_tab_state(status, terminal_visible)
  if tab_state == "" then
    M.clear()
    return
  end

  M.send_user_var(CODEX_TOOL_USER_VAR, CODEX_TOOL_NAME)
  M.send_user_var(CODEX_STATE_USER_VAR, tab_state)
end

function M.clear()
  user_var.send(CODEX_TOOL_USER_VAR, "")
  user_var.send(CODEX_STATE_USER_VAR, "")
end

function M.resolve_tab_state(status, terminal_visible)
  if status == "busy" then
    return "loading"
  end
  if status == "wait" then
    return "attention"
  end
  if terminal_visible then
    return "active"
  end
  return ""
end

function M.current_codex_status()
  local ok, indicator = pcall(require, "codex.status_indicator")
  if not ok or type(indicator._get_status) ~= "function" then
    return "disconnected"
  end
  local status_ok, status = pcall(indicator._get_status, M.now_ms(), nil)
  if status_ok and type(status) == "string" then
    return status
  end
  return "disconnected"
end

function M.is_codex_terminal_visible()
  local ok, terminal = pcall(require, "codex.terminal")
  if not ok or type(terminal.get_active_terminal_bufnr) ~= "function" then
    return false
  end
  local bufnr_ok, bufnr = pcall(terminal.get_active_terminal_bufnr)
  if not bufnr_ok or type(bufnr) ~= "number" or bufnr <= 0 then
    return false
  end
  if not (vim.fn and type(vim.fn.getbufinfo) == "function") then
    return false
  end
  local info_ok, bufinfo = pcall(vim.fn.getbufinfo, bufnr)
  local first = info_ok and type(bufinfo) == "table" and bufinfo[1] or nil
  return type(first) == "table" and type(first.windows) == "table" and #first.windows > 0
end

M.send_user_var = user_var.send
M.user_var_sequence = user_var.sequence
M.base64_encode = user_var.base64_encode

function M.resolve_options(options)
  return {
    enabled = not (options and options.enabled == false),
    update_interval_ms = tonumber(options and options.update_interval_ms or DEFAULT_UPDATE_INTERVAL_MS)
      or DEFAULT_UPDATE_INTERVAL_MS,
  }
end

function M.start_timer(update_interval_ms)
  -- 状態表示の変化をWezTermへ反映するため、短い周期でCodex状態を確認します。
  local timer = vim.loop.new_timer()
  timer:start(0, update_interval_ms, function()
    vim.schedule(function()
      M.update()
    end)
  end)
  return timer
end

function M.create_cleanup_autocmd()
  if not (vim.api and type(vim.api.nvim_create_autocmd) == "function") then
    return
  end
  local group = vim.api.nvim_create_augroup("CodexWeztermUserVars", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.clear,
    desc = "Clear Codex state from WezTerm tab title",
  })
end

function M.now_ms()
  if vim.loop and type(vim.loop.now) == "function" then
    return vim.loop.now()
  end
  return math.floor(os.time() * 1000)
end

return M
