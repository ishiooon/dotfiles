return{
    {
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
          "nvim-lua/plenary.nvim",
          "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
          "MunifTanjim/nui.nvim",
          -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        opts =  {
            position =  "current",
            sources = { "filesystem", "git_status", "buffers" }, -- Git差分のみ表示するためにgit_statusソースを有効化
            source_selector = {
                winbar = true,
                content_layout = "center",
                sources = {
                    { source = "filesystem", display_name = "Files" },
                    { source = "git_status", display_name = "Git" }, -- Git変更のみをツリーに絞り込むフィルタ
                    { source = "buffers", display_name = "Buffers" },
                },
            },
            default_source = "filesystem",
            event_handlers = {
                {
                  event = "neo_tree_buffer_enter",
                  handler = function(arg)
                    vim.cmd [[
                      setlocal relativenumber
                    ]]
                  end,
                }
            },
            window = {
                width = 45,
            }
        }
    }
}
