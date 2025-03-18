-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'MaterialDesignColors'

-- Changing the default program: wsl
config.default_prog = { "wsl.exe", "--distribution", "ubuntu", "--cd", "~" }

-- リロード
config.automatically_reload_config = true

-- IMEを有効にする
config.use_ime = true

-- ========================================
-- キーバインド設定
-- ========================================
config.keys = require('keybinds').keys
config.key_tables = require('keybinds').key_tables

-- ========================================
-- デザイン設定
-- ========================================

-- テーマを変更する:
config.color_scheme = 'Gruvbox Material (Gogh)'
-- フォントを変更する:
config.font = wezterm.font_with_fallback({
  {family="UDEV Gothic NFLG", weight="Regular"},
})
-- 透過
config.window_background_opacity = 0.0
-- ぼかし
config.macos_window_background_blur = 30
config.win32_system_backdrop = 'Mica'

config.window_padding = {
  left = '0.5cell',
  right = '0.5cell',
  top = '0cell',
  bottom = '-0.5cell',
}

-- タブバー設定
-- タブが一つの時は非表示
config.hide_tab_bar_if_only_one_tab = true
-- config.show_new_tab_button_in_tab_bar = false
-- config.tab_bar_at_bottom = true
-- config.tab_max_width = 5
-- config.show_close_tab_button_in_tabs = false


-- 最後に、設定をweztermに返す
return config
