-- vimバッファをタブ風表示する
return {
    {
        'romgrk/barbar.nvim',
        dependencies = {
            'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
            'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
        },
        init = function() vim.g.barbar_auto_setup = false end,
        opts = {
            animation = true,
            insert_at_start = true,
            exclude_ft = {'terminal'},
            exclude_name = {'claude-code', 'claude-code-*', 'term://*'},
        },
        config = function(_, opts)
            require('barbar').setup(opts)
            -- claude-codeターミナルバッファを非表示にする
            vim.api.nvim_create_autocmd({'BufAdd', 'BufEnter', 'BufNew'}, {
                pattern = '*',
                callback = function(ev)
                    local bufname = vim.api.nvim_buf_get_name(ev.buf)
                    local buftype = vim.api.nvim_buf_get_option(ev.buf, 'buftype')
                    local name = vim.fn.fnamemodify(bufname, ':t') -- ファイル名のみ取得
                    -- claude-codeターミナルバッファを非表示
                    -- ターミナルバッファかつclaude-code関連の名前を含む場合
                    if buftype == 'terminal' and
                       (string.match(name, 'claude%-code') or
                        string.match(bufname, 'term://.*claude%-code') or
                        string.match(bufname, 'claude%-code')) then
                        vim.api.nvim_buf_set_option(ev.buf, 'buflisted', false)
                        vim.api.nvim_buf_set_option(ev.buf, 'bufhidden', 'hide')
                        -- デバッグ情報出力
                        print("Hiding claude-code buffer: " .. bufname)
                    end
                end,
            })
        end,
    }
}
