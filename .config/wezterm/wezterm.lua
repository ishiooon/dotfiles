-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- OSによって設定を分ける
local os_name = wezterm.target_triple

-- リロード
config.automatically_reload_config = true

-- Windows固有の設定
if os_name:find('windows') then
  -- Changing the default program: wsl
  config.default_prog = { "wsl.exe", "--distribution", "ubuntu", "--cd", "~" }

  -- OpenGLフロントエンドを使用（WebGPUだと透明度が効かない）
  config.front_end = "OpenGL"
  
  -- 透明度設定
  config.window_background_opacity = 0.5
  -- アクリル
  config.win32_system_backdrop = "Acrylic"

  -- 最初からフルスクリーンで起動（フルスクリーンでは透明化が効かない可能性）
  local mux = wezterm.mux
  wezterm.on("gui-startup", function(cmd)
  ---@diagnostic disable-next-line: unused-local
      local tab, pane, window = mux.spawn_window(cmd or {})
      window:gui_window():toggle_fullscreen()
  end)
end

-- macOS固有の設定
if os_name:find('darwin') then
  -- macOS専用の背景ぼかし設定
  config.macos_window_background_blur = 30
  -- macOS専用の背景透過設定
  config.window_background_opacity = 0.8

  -- macOS用フォントサイズ設定（macOS特有のDPI対応）
  config.font_size = 14

  -- macOS用ウィンドウサイズ設定
  config.initial_cols = 120
  config.initial_rows = 40

end

-- Linux固有の設定（WSL以外のLinux環境）
if os_name:find('linux') and not os_name:find('windows') then
  config.window_background_opacity = 0.8
end

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
-- デフォルトフォントサイズ設定
config.font_size = 14

config.window_padding = {
  left = '0.25cell',
  right = '0.25cell',
  top = '0cell',
  bottom = '0cell',
}

-- タブバー設定
-- 非表示
config.enable_tab_bar = false

-- 最後に、設定をweztermに返す
return config





