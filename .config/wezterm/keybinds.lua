local wezterm = require 'wezterm'
local act = wezterm.action
return {
  keys = {
    -- Ctrl+Shift系
    -- paneの分割
    {key = 'd', mods = 'SHIFT|CTRL', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
    -- paneの削除
    { key = 'w', mods = 'SHIFT|CTRL', action = wezterm.action.CloseCurrentPane { confirm = true } },
    -- ランチャーを開く
    { key = "f", mods = "SHIFT|CTRL", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY" }) }
  },
  key_tables = {
    copy_mode = {
      --
    },
    search_mode = {
      --
    },
  }
}
