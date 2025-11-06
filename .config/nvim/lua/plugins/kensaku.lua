return{
    {
        "vim-denops/denops.vim",
        -- Denopsの読み込み前にバージョンチェックを抑制（NVIM 0.11.3未満での警告対策）
        init = function()
            vim.g.denops_disable_version_check = 1
            -- デバッグ出力を無効化（起動時の[denops]メッセージ抑制）
            vim.g['denops#debug'] = 0
        end,
        config = function()
            -- Denoのパスはoptions.luaで統一設定済み（~/.deno/bin/deno）
        end
    },
    {'lambdalisue/kensaku.vim'},
    {
        'lambdalisue/kensaku-search.vim',
        config = function()
        vim.api.nvim_set_keymap(
            'c',
            '<CR>',
            '<Plug>(kensaku-search-replace)<CR>',
            { noremap = true, silent = true }
        )
        end
    },
}
