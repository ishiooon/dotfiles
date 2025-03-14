return {
  -- neovimの使用時間を蓄積するプラグイン
  {
    "Aityz/usage.nvim",
    config = function()
        require('usage').setup()
    end
  }
}
