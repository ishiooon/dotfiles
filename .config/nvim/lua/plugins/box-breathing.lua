-- 開発版が無い Mac では本人の公開版を使い、呼吸ガイドの既存設定を維持する。
return {
    require("config.plugin_source").resolve("ishiooon/box-breathing.nvim", {
        -- 開発用の Neovim プラグインをまとめた配置から読み込む。
        "~/develop/nvim_plugins/box-breathing.nvim",
    }, {
        opts = {
            duration = 4, -- 画面の各辺を移動する時間を4秒にする。
            animation_interval = 50, -- アニメーションを50ミリ秒ごとに更新する。
        },
    }),
}
