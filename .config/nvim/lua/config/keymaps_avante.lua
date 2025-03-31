-- prefil edit window with common scenarios to avoid repeating query and submit immediately
local prefill_edit_window = function(request)
    require("avante.api").edit()
    local code_bufnr = vim.api.nvim_get_current_buf()
    local code_winid = vim.api.nvim_get_current_win()
    if code_bufnr == nil or code_winid == nil then
        return
    end
    vim.api.nvim_buf_set_lines(code_bufnr, 0, -1, false, { request })
    -- Optionally set the cursor position to the end of the input
    vim.api.nvim_win_set_cursor(code_winid, { 1, #request + 1 })
    -- Simulate Ctrl+S keypress to submit
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("", true, true, true), "v", true)
end


-- NOTE: most templates are inspired from ChatGPT.nvim -> chatgpt-actions.json
local avante_code_readability_analysis = [[
  以下の点を考慮しコードの可読性の問題を特定、リファクタリングしてください。
  考慮すべき可読性の問題:
  - 不明瞭な命名
  - 不明瞭な目的
  - 冗長なコメント
  - コメントの欠如
  - コメントには日本語を使用する
  - 長いまたは複雑な一行のコード
  - ネストが多すぎる
  - 長すぎる変数名
  - 命名とコードスタイルの不一致
  - コードの繰り返し
  上記以外の問題を特定しても構いません。
  問題がない場合は褒めてください。
]]
local avante_optimize_code = "次のコードを最適化してください。"
local avante_fix_bugs = "次のコード内でバグが起こる可能性のある箇所を特定し、修正してください。"
local avante_add_tests = "次のコードのテストを実装してください。"
local avante_add_docstring = "次のコードにdocstringを追加してください。"
local avante_divide_code = "次のコードを可読性を考慮していくつかのファイルに分割してください。"
local avante_read= "初学者向けに何のためのファイルで何がどのように実装され動くのかを丁寧に説明してください。"
local avante_code_review = "プロの開発者として、気になる部分を加味しつつコードレビューをしてください。"

-- avante.nvim
local avante_ask = require("avante.api").ask

vim.keymap.set("n", "<leader>al", function()
    avante_ask({ question = avante_code_readability_analysis })
end, { noremap = true, silent = true, desc = "[avante]可読性" })

vim.keymap.set("n", "<leader>ao", function()
    avante_ask({ question = avante_optimize_code })
end, { noremap = true, silent = true, desc = "[avante]最適化" })

vim.keymap.set("n", "<leader>ab", function()
    avante_ask({ question = avante_fix_bugs })
end, { noremap = true, silent = true, desc = "[avante]バグ修正" })

vim.keymap.set("n", "<leader>au", function()
    avante_ask({ question = avante_add_tests })
end, { noremap = true, silent = true, desc = "[avante]テスト実装" })

vim.keymap.set("n", "<leader>ad", function()
    avante_ask({ question = avante_add_docstring })
end, { noremap = true, silent = true, desc = "[avante]docstring" })

vim.keymap.set("n", "<leader>af", function()
    avante_ask({ question = avante_divide_code })
end, { noremap = true, silent = true, desc = "[avante]ファイル分割" })

vim.keymap.set("n", "<leader>ar", function()
    avante_ask({ question = avante_read })
end, { noremap = true, silent = true, desc = "[avante]読み解き" })

vim.keymap.set("n", "<leader>ac", function()
    avante_ask({ question = avante_code_review })
end, { noremap = true, silent = true, desc = "[avante]コードレビュー" })
