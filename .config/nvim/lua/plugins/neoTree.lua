local neo_tree_git_refresh = require("config.neo_tree_git_refresh")

-- NeoTree バッファへ入った直後に相対行番号を有効化し、一覧移動を見やすくする。
local function enable_relative_number()
  vim.opt_local.relativenumber = true
end

-- 外部端末やシェル経由の Git 操作後にも状態を取り直せるよう、自動更新の契機を登録する。
local function register_git_refresh_autocmd()
  local group = vim.api.nvim_create_augroup("NeoTreeGitDynamicRefresh", { clear = true })

  vim.api.nvim_create_autocmd(neo_tree_git_refresh.get_trigger_events(), {
    group = group,
    callback = function()
      neo_tree_git_refresh.refresh_visible_git_sources()
    end,
    desc = "NeoTree の Git 状態を外部操作後にも再評価する",
  })
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- 画像ではなくファイル種別をすぐ判別できるようにする。
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim", -- プレビューに画像を使いたい場合だけ有効にする。
    },
    init = register_git_refresh_autocmd,
    opts = {
      position = "current",
      sources = { "filesystem", "git_status", "buffers" }, -- Git の変更一覧も同じ UI で切り替えられるようにする。
      default_source = "filesystem",
      filesystem = {
        use_libuv_file_watcher = true, -- 作業ツリーと Git ディレクトリの変化を監視し、手動更新の頻度を減らす。
      },
      source_selector = {
        winbar = true,
        content_layout = "center",
        sources = {
          { source = "filesystem", display_name = "Files" },
          { source = "git_status", display_name = "Git" }, -- Git で変化したファイルだけを素早く追えるようにする。
          { source = "buffers", display_name = "Buffers" },
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = enable_relative_number,
        },
      },
      window = {
        width = 45,
      },
    },
  },
}
