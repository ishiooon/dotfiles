----------------------------------------------------
-- テーマの設定
----------------------------------------------------
return {
    -- the colorscheme should be available when starting Neovim
    { "sainnhe/gruvbox-material" },
    { "kdheepak/monochrome.nvim" },
    -- 透過プラグイン
    {
        "xiyaowong/nvim-transparent",
        opts = {
            enable = true,
        },
    },
}
