return {
    {
        "nvim-treesitter/nvim-treesitter",
        -- 現行の Treesitter は遅延読み込みに対応していないため、起動時に読み込む。
        branch = "main",
        lazy = false,
        -- プラグイン更新に伴うパーサーの更新が終わるまで待ち、取得失敗もビルド失敗として伝える。
        build = function()
            assert(require("nvim-treesitter").update():wait(300000),
                "Treesitter のパーサーを更新できませんでした。")
        end,
        opts = {
            -- Blade 内の PHP・HTML と JavaScript も解析できるように必要な言語をそろえる。
            ensure_installed = {
                "bash", "c", "html", "lua", "markdown", "vim", "vimdoc",
                "tsx", "typescript", "regex", "blade", "php", "php_only", "javascript",
            },
        },
        config = function(_, opts)
            require("config.treesitter").setup(opts)
        end,
    },
    -- Treesitter で関数の引数の定義と使用箇所を強調表示する。
    { "m-demare/hlargs.nvim", opts = {} },
    -- 現在の関数やクラスの見出しを表示し、長いコードの編集位置を把握できるようにする。
    { "nvim-treesitter/nvim-treesitter-context", opts = {} },
}
