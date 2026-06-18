local M = {}

function M.apply(wezterm)
  -- WezTerm のタブ表示名を、端末アプリが送るタイトルではなく現在の作業ディレクトリから決める。
  wezterm.on('format-tab-title', function(tab)
    return M.format_tab_title(tab)
  end)
end

function M.format_tab_title(tab)
  local pane = tab and tab.active_pane
  local directory_name = M.current_directory_name(pane)

  if directory_name ~= '' then
    return directory_name
  end

  return M.fallback_title(tab, pane)
end

function M.current_directory_name(pane)
  if not pane then
    return ''
  end

  -- Neovim などが端末タイトルを書き換えても、作業ディレクトリ名を優先する。
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
