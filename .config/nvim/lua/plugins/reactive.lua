------------------------------------------------------------
--- モードに応じて表示色を変更するプラグイン
------------------------------------------------------------
return{
    {
        'rasulomaroff/reactive.nvim',
        opts = {
            builtin = {
                cursorline = true,
                cursor = true,
                modemsg = true
            }
        }
    }
}
