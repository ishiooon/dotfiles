return{
    {
        "vim-denops/denops.vim",
        config = function()
            -- Denopsプラグインのデバッグ有効化 (副作用: デバッグ出力)
            vim.g['denops#debug'] = 1
            -- Denoのパスを明示的に設定
            vim.g['denops#deno'] = '/home/dev_local/.local/bin/deno'
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

