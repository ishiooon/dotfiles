-- NeoTree の Git 状態更新を外部操作後にも追従させるための補助処理をまとめる。
local M = {}

-- Git 状態の更新対象にする NeoTree ソースだけを明示し、意図しない再描画を避ける。
local refreshable_sources = {
  filesystem = true,
  git_status = true,
}

-- 外部の Git 操作が終わった直後に再評価したいイベントだけを返す。
function M.get_trigger_events()
  return { "FocusGained", "ShellCmdPost", "TabEnter", "TermClose" }
end

-- 表示中の NeoTree ソースがある場合だけ更新イベントを飛ばし、不要な処理を抑える。
function M.refresh_visible_git_sources()
  local events_ok, events = pcall(require, "neo-tree.events")
  local manager_ok, manager = pcall(require, "neo-tree.sources.manager")
  local renderer_ok, renderer = pcall(require, "neo-tree.ui.renderer")

  if not (events_ok and manager_ok and renderer_ok) then
    return false
  end

  local states = {}
  manager._for_each_state(nil, function(state)
    states[#states + 1] = state
  end)

  local visible_sources = M.collect_refreshable_sources(states, vim.api.nvim_get_current_tabpage(), function(state)
    return renderer.window_exists(state)
  end)

  if not M.should_fire_refresh(visible_sources) then
    return false
  end

  events.fire_event(events.GIT_EVENT)
  return true
end

-- 現在のタブで見えている NeoTree ソースだけを抽出し、更新対象を最小化する。
function M.collect_refreshable_sources(states, current_tabid, is_window_open)
  local visible_sources = {}

  for _, state in ipairs(states or {}) do
    if M.is_refresh_target(state, current_tabid, is_window_open) then
      visible_sources[#visible_sources + 1] = state.name
    end
  end

  return visible_sources
end

-- 更新対象が一つでもあれば Git 状態を再取得する価値があるとみなす。
function M.should_fire_refresh(visible_sources)
  return next(visible_sources or {}) ~= nil
end

-- Git 表示に関係するソースで、かつ現在のタブで実際に見えている場合だけ対象にする。
function M.is_refresh_target(state, current_tabid, is_window_open)
  if type(state) ~= "table" then
    return false
  end

  if not refreshable_sources[state.name] then
    return false
  end

  if state.tabid ~= current_tabid or not state.path then
    return false
  end

  return is_window_open(state) == true
end

return M
