return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
        'nvim-lua/plenary.nvim',
        --  カナ検索を使う
        {
            "Allianaab2m/telescope-kensaku.nvim",
            config = function()
                require("telescope").load_extension("kensaku") -- :Telescope kensaku
            end
        },
    },
    extensions = {
        -- ソート性能を大幅に向上させるfzfを使う
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },
    },
    {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
    },
    {
        "nvim-telescope/telescope-frecency.nvim",
        config = function()
            require("telescope").load_extension "frecency"
        end,
    },
    -- ~/.config/memolistのファイルを検索する
    {
        "delphinus/telescope-memo.nvim",
        config = function()
          require("telescope").load_extension "memo"
        end,
    },
}
