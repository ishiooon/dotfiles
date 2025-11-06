----------------------------------------------
-- シンプルな通知プラグイン
-- LSPの進捗のみを表示する
----------------------------------------------
return{
    {
        "j-hui/fidget.nvim",
        opts = {
            progress = {
                display = {
                  progress_icon = { pattern = 'meter', period = 1 },
                },
            },
        },
        config = function()
            require("fidget").setup({
                progress = {
                    display = {
                        progress_icon = { pattern = 'meter', period = 1 },
                    },
                },
            })
        end,
    }
}
