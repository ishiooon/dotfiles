------------------------------------------------------------
--- スクロールバーの設定
------------------------------------------------------------
return {
    {
        "petertriho/nvim-scrollbar",
        opts = {
            handle = {
                color = "#3c3836", -- グレー系の色
            },
            marks = {
                Search = { color = "#fe8019" }, -- オレンジ
                Error = { color = "#fb4934" },  -- 赤
                Warn = { color = "#fabd2f" },   -- 黄色
                Info = { color = "#83a598" },   -- 青
                Hint = { color = "#8ec07c" },   -- 緑
                Misc = { color = "#d3869b" },   -- 紫
            }
        }
    }
}
