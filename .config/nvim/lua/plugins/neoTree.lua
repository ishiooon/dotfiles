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
            position =  'current',
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
