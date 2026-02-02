local function build_idledungeon_spec()
  local local_dir = "/home/dev_local/dev_plugin/idle-dungeon.nvim"
  -- ローカル開発版の有無を確認するため、ファイルシステムを参照する。
  local stat = (vim.uv or vim.loop).fs_stat(local_dir)
  -- 既定設定でセットアップするための関数を準備する。
  local config = function()
    require("idle_dungeon").setup({})
  end

  if stat and stat.type == "directory" then
    return {
      -- ローカルで開発中の idle-dungeon.nvim を直接読み込む。
      dir = local_dir,
      name = "idle-dungeon.nvim",
      config = config,
    }
  end

  return {
    -- ローカル開発版が無い場合は GitHub から取得する。
    "ishiooon/idle-dungeon.nvim",
    name = "idle-dungeon.nvim",
    config = config,
  }
end

return {
  build_idledungeon_spec(),
}
