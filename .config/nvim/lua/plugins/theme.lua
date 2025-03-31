----------------------------------------------------
-- テーマの設定
----------------------------------------------------
return {
    -- the colorscheme should be available when starting Neovim
    { "sainnhe/gruvbox-material" },
    -- 透過プラグイン
    {
        "xiyaowong/nvim-transparent",
        config = function()
            require("transparent").setup({
                enable = true, -- 透過を有効化
                extra_groups = {
                    "NeoTree",
                    "NormalFloat",
                    "FloatBorder", 
                    "TelescopeNormal",
                    "TelescopeBorder",
                    "WhichKeyFloat",
                    "all"
                },
                exclude_groups = {}, -- 透過から除外するグループ
            })
        end,
    },
}
