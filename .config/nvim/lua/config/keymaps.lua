-- neoetree用のキーマップ
vim.keymap.set('n', '<C-e>', '<Cmd>Neotree reveal toggle<CR>')
vim.keymap.set('n', '<leader>e', '<Cmd>Neotree reveal toggle<CR>', { desc = 'Neotree: トグル', })

-- spectre用のキーマップ
vim.keymap.set('n', '<C-f>', '<Cmd>lua require("spectre").toggle()<CR>')
vim.keymap.set('v', '<C-f>', '<Cmd>lua require("spectre").open_visual{select_word=true}<CR>')
vim.keymap.set('n', '<C-s>', '<cmd>lua require("spectre").open_file_search()<CR>')
vim.keymap.set('v', '<C-s>', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>')

-- treesj用のキーマップ
vim.keymap.set('n', '<leader>m', require('treesj').toggle, { desc = 'Treesj: トグル' })

-- telescope用のキーマップ
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>fb", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")
-- ファイル検索
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
-- テキスト検索
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
-- freequency検索
vim.keymap.set("n", "<leader>fe", ':Telescope frecency workspace=CWD<CR>', {})
vim.keymap.set("n", "<C-p>", ':Telescope frecency workspace=CWD<CR>', {})
-- レジスタ
vim.keymap.set("n", "<leader>fr", builtin.registers, {})
-- バッファ
vim.keymap.set("n", "<C-b>", builtin.buffers, {})
-- TODO
vim.keymap.set("n", "<leader>ft", ':TodoTelescope<CR>', {})
-- memolist
vim.keymap.set("n", "<leader>ml", ':Telescope memo list<CR>', {})
vim.keymap.set("n", "<leader>mg", ':Telescope memo live_grep<CR>', {})

-- barbar用のキーマップ
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>j', '<Cmd>BufferPrevious<CR>', opts)--Ctrl+jで前のBufferに移動
vim.keymap.set('n', '<leader>k', '<Cmd>BufferNext<CR>', opts)--Ctrl+kで次のBufferに移動
vim.keymap.set('n', '<leader>p',   '<Cmd>BufferPick<CR>', opts)
vim.keymap.set('n', '<leader>to', '<Cmd>BufferOrderByName<CR>', opts)
vim.keymap.set('n', '<leader>q', '<Cmd>BufferClose<CR>', opts)
vim.keymap.set('n', '<leader>tq', '<C-w>o<Cmd>BufferCloseAllButCurrent<CR>', opts)

-- lsp用のキーマップ
-- ホバー
vim.keymap.set("n", "K",  "<cmd>Lspsaga hover_doc<CR>")
vim.keymap.set("n", "ge", "<cmd>Lspsaga show_line_diagnostics<CR>")
vim.keymap.set("n", "ga", "<cmd>Lspsaga code_action<CR>")
vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>")
vim.keymap.set('n', 'gr', '<cmd>Lspsaga lsp_finder<CR>')
vim.keymap.set('n', 'gf', '<cmd>Lspsaga goto_definition<CR>')
vim.keymap.set('n', 'gs',  "<Cmd>Lspsaga finder<CR>",  { desc = 'Telescope: live grep args', })
vim.keymap.set('n', '<leader>ol', '<cmd>Lspsaga outline<CR>') -- lsp outline

-- dap用のキーマップ
-- options.luaに記述

-- toggleTerm用のキーマップ
-- open/close
vim.keymap.set('', '<C-t>', '<Cmd>ToggleTerm<CR>')
local Terminal  = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
	cmd = "lazygit",
	hidden = true,
	dir="%:p:h",
})

function _lazygit_toggle()
    lazygit:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})

local w3m = Terminal:new({
    cmd = "w3m google.com",
    hidden = true,
    dir="%:p:h",
})
function _w3m_toggle()
    w3m:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>ww", "<cmd>lua _w3m_toggle()<CR>", {noremap = true, silent = true})

--  天気予報
local wttr = Terminal:new({cmd = "curl wttr.in",hidden = true})
function _wttr_toggle()
    wttr:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>wttr", "<cmd>lua _wttr_toggle()<CR>", {noremap = true, silent = true})

-- ccusage
local ccusage = Terminal:new({cmd = "npx ccusage@latest",hidden=true})
function _ccusage_toggle()
    ccusage:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>cu", "<cmd>lua _ccusage_toggle()<CR>", {noremap = true, silent = true})

-- Suda.vim 用の キーマップ
vim.keymap.set('n', '<Leader>sw', ':SudaWrite<CR>')
vim.keymap.set('n', '<Leader>sr', ':SudaRead<CR>')

-- diffview用のキーマップ - トグル機能
-- @param なし
-- @return なし
-- @side_effect DiffviewのOpenとCloseを切り替える
local function toggle_diffview()
  local diffview = require('diffview')
  local lib = require('diffview.lib')
  local view = lib.get_current_view()
  
  if view then
    -- Diffviewが開いている場合はクローズ
    vim.cmd('DiffviewClose')
  else
    -- Diffviewが閉じている場合はオープン
    vim.cmd('DiffviewOpen')
  end
end
vim.keymap.set('n', '<leader>dv', toggle_diffview, { desc = 'Diffview: トグル' })

-- winresizer用のキーマップ
vim.keymap.set('n', '<C-w>r', '<Cmd>WinResizerStartResize<CR>')
