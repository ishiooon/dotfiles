-- 開発版が無い Mac でも、本人の公開版から音楽のコード練習機能を読み込めるようにする。
return {
    require("config.plugin_source").resolve("ishiooon/random-chord.nvim", {
        -- 開発用の Neovim プラグインをまとめた配置から読み込む。
        "~/develop/nvim_plugins/random-chord.nvim",
    }, { opts = {} }),
}
