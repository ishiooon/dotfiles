local M = {}

function M.apply(wezterm)
  -- Neovim が端末タイトルを nvim にしても、タブには開いているプロジェクト名を表示する。
  wezterm.on('format-tab-title', function(tab)
    return M.format_tab_title(tab)
  end)
end

function M.format_tab_title(tab)
  local pane = tab and tab.active_pane
  local tool_name = M.active_tool_label(pane)
  local title = nil

  if tool_name ~= '' then
    local directory_name = M.current_directory_name(pane)
    if directory_name ~= '' then
      title = M.project_tool_title(directory_name, tool_name)
    end
  end

  return M.with_tab_number(tab, title or M.fallback_title(tab, pane))
end

function M.active_tool_label(pane)
  if not pane then
    return ''
  end
  -- Neovim内のcodex.nvimは前景プロセスとして見えないため、pane user varを優先する。
  return M.codex_label_from_user_vars(pane) or M.active_tool_name(pane)
end

function M.codex_label_from_user_vars(pane)
  local user_vars = pane and pane.user_vars
  if type(user_vars) ~= 'table' or user_vars.CODEX_NVIM_TOOL ~= 'codex' then
    return nil
  end
  return 'codex' .. M.codex_state_suffix(user_vars.CODEX_NVIM_STATE)
end

function M.codex_state_suffix(state)
  if state == 'loading' then
    return '...'
  end
  if state == 'attention' then
    return '!'
  end
  return ''
end

function M.active_tool_name(pane)
  if not pane then
    return ''
  end
  return M.match_tool_name(pane.title) or M.match_tool_name(pane.foreground_process_name) or ''
end

function M.current_directory_name(pane)
  if not pane then
    return ''
  end
  return M.basename(M.current_directory_path(pane.current_working_dir))
end

function M.fallback_title(tab, pane)
  if tab and type(tab.tab_title) == 'string' and tab.tab_title ~= '' then
    return tab.tab_title
  end
  if pane and type(pane.title) == 'string' then
    return pane.title
  end
  return ''
end

function M.with_tab_number(tab, title)
  local tab_index = tab and tab.tab_index
  if type(tab_index) ~= 'number' then
    return title
  end
  -- WezTerm のタブ番号は 0 始まりなので、表示とショートカットに合わせて 1 始まりにする。
  return tostring(tab_index + 1) .. ':' .. title
end

function M.current_directory_path(current_working_dir)
  local file_path = M.file_path_from_working_dir(current_working_dir)
  if file_path ~= '' then
    return file_path
  end
  if type(current_working_dir) == 'userdata' then
    return M.remove_file_scheme(tostring(current_working_dir))
  end
  return ''
end

function M.match_tool_name(name)
  local executable_name = M.basename(name)

  if executable_name == 'nvim' or executable_name == 'nvim.exe' then
    return 'nvim'
  end

  if executable_name == 'codex' or executable_name == 'codex.exe' then
    return 'codex'
  end
  return nil
end

function M.project_tool_title(directory_name, tool_name)
  return directory_name .. '(' .. tool_name .. ')'
end

function M.basename(path)
  local normalized_path = M.trim_trailing_separator(path)
  if normalized_path == '' then
    return ''
  end

  return normalized_path:gsub('(.*[/\\])(.*)', '%2')
end

function M.remove_file_scheme(path)
  return path:gsub('^file://', '')
end

function M.file_path_from_working_dir(current_working_dir)
  if type(current_working_dir) == 'string' then
    return M.remove_file_scheme(current_working_dir)
  end

  -- WezTerm の URL オブジェクトは file_path を持つため、表とユーザーデータの両方を受け付ける。
  local ok, file_path = pcall(function()
    return current_working_dir.file_path
  end)

  if ok and type(file_path) == 'string' then
    return file_path
  end

  return ''
end

function M.trim_trailing_separator(path)
  if type(path) ~= 'string' then
    return ''
  end

  return path:gsub('[/\\]+$', '')
end

return M
