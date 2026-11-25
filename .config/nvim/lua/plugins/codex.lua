local LOCAL_CODEX_DIR_CANDIDATES = {
  -- Mac の開発版は他の Neovim プラグインと同じディレクトリにまとめる。
  "/Users/ishiooon/develop/nvim_plugins/codex.nvim",
  "/home/dev_local/dev_plugin/codex.nvim",
}
local REMOTE_CODEX_REPO = "ishiooon/codex.nvim"

local function setup_codex()
  -- Codex 統合を初期化し、コマンドやキーマップなどの登録を実行します
  require("codex").setup()
  local ok, codex_wezterm = pcall(require, "config.codex_wezterm")
  if ok and type(codex_wezterm.setup) == "function" then
    -- codex.nvimの内部状態をWezTermのタブタイトルへ反映します。
    codex_wezterm.setup()
  end
end

-- 他の開発用プラグインと同じ判定で、既存の候補順序と公開版への切り替えを維持する。
return {
  require("config.plugin_source").resolve(REMOTE_CODEX_REPO, LOCAL_CODEX_DIR_CANDIDATES, {
    config = setup_codex,
  }),
}
