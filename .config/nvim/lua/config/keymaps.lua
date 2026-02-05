-- キーマップ: 開始キー順に整理（機能は変更なし）

-- 前提: 依存モジュール/共通オプション
local builtin = require("telescope.builtin")
local Terminal  = require('toggleterm.terminal').Terminal
local opts = { noremap = true, silent = true }

-- <C-b> で始まるキー
vim.keymap.set("n", "<C-b>", builtin.buffers, {})

-- <C-e> で始まるキー
vim.keymap.set('n', '<C-e>', '<Cmd>Neotree reveal toggle<CR>')

-- <C-f> で始まるキー
vim.keymap.set('n', '<C-f>', '<Cmd>lua require("spectre").toggle()<CR>')
vim.keymap.set('v', '<C-f>', '<Cmd>lua require("spectre").open_visual{select_word=true}<CR>')

-- <C-p> で始まるキー
vim.keymap.set("n", "<C-p>", ':Telescope frecency workspace=CWD<CR>', {})

-- <C-s> で始まるキー
vim.keymap.set('n', '<C-s>', '<cmd>lua require("spectre").open_file_search()<CR>')
vim.keymap.set('v', '<C-s>', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>')

-- <C-t> で始まるキー
vim.keymap.set('', '<C-t>', '<Cmd>ToggleTerm<CR>')

-- <C-w> で始まるキー
vim.keymap.set('n', '<C-w>r', '<Cmd>WinResizerStartResize<CR>')

-- K で始まるキー
vim.keymap.set("n", "K",  "<cmd>Lspsaga hover_doc<CR>")

-- g で始まるキー
vim.keymap.set("n", "ga", "<cmd>Lspsaga code_action<CR>", { desc = 'Lspsaga: コードアクション', })
vim.keymap.set('n', 'gd', '<cmd>Lspsaga peek_definition<CR>', { desc = 'Lspsaga: 定義を覗く', })
vim.keymap.set("n", "ge", "<cmd>Lspsaga show_line_diagnostics<CR>", { desc = 'Lspsaga: 行の診断を表示', })
vim.keymap.set('n', 'gf', '<cmd>Lspsaga goto_definition<CR>', { desc = 'Lspsaga: 定義へ移動', })
vim.keymap.set('n', 'gr', '<cmd>Lspsaga lsp_finder<CR>', { desc = 'Lspsaga: 参照を探す', })
vim.keymap.set('n', 'gs',  "<Cmd>Lspsaga finder<CR>",  { desc = 'Lspsaga: シンボルを探す', })

-- <leader> / <Leader> で始まるキー
-- 依存するローカル関数・ターミナルの定義
local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, dir = "%:p:h" })
function _lazygit_toggle() lazygit:toggle() end

local w3m = Terminal:new({ cmd = "w3m google.com", hidden = true, dir = "%:p:h" })
function _w3m_toggle() w3m:toggle() end

local wttr = Terminal:new({ cmd = "curl wttr.in", hidden = true })
function _wttr_toggle() wttr:toggle() end

-- Diffview トグル用のローカル関数
local function toggle_diffview()
  local diffview = require('diffview')
  local lib = require('diffview.lib')
  local view = lib.get_current_view()
  if view then
    vim.cmd('DiffviewClose')
  else
    vim.cmd('DiffviewOpen')
  end
end

-- Codexの既定キーマップはcodex.nvim側で設定するため、ここでは定義しない

-- キー: <leader>dv (diffview)
vim.keymap.set('n', '<leader>dv', toggle_diffview, { desc = 'Diffview: トグル' })

-- キー: <leader>dm (idle_dungeon_menu_toggle)
vim.keymap.set('n', '<leader>dm', '<Cmd>IdleDungeonMenu<CR>', { desc = 'IdleDungeonMenu: トグル' })

-- キー: <leader>e (neo-tree)
vim.keymap.set('n', '<leader>e', '<Cmd>Neotree reveal toggle<CR>', { desc = 'Neotree: トグル', })

-- キー: <leader>fb / <leader>ff / <leader>fe / <leader>fr / <leader>ft (telescope)
vim.keymap.set("n", "<leader>fb", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")
vim.keymap.set("n", "<leader>fe", ':Telescope frecency workspace=CWD<CR>', {})
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fr", builtin.registers, {})
vim.keymap.set("n", "<leader>ft", ':TodoTelescope<CR>', {})

-- キー: <leader>j / <leader>k / <leader>p / <leader>q / <leader>to / <leader>tq (barbar)
vim.keymap.set('n', '<leader>j', '<Cmd>BufferPrevious<CR>', opts)
vim.keymap.set('n', '<leader>k', '<Cmd>BufferNext<CR>', opts)
vim.keymap.set('n', '<leader>p', '<Cmd>BufferPick<CR>', opts)
vim.keymap.set('n', '<leader>q', '<Cmd>BufferClose<CR>', opts)
vim.keymap.set('n', '<leader>to', '<Cmd>BufferOrderByName<CR>', opts)
vim.keymap.set('n', '<leader>tq', '<C-w>o<Cmd>BufferCloseAllButCurrent<CR>', opts)

-- キー: <leader>lg / <leader>ww / <leader>wttr (toggleterm)
vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<leader>ww", "<cmd>lua _w3m_toggle()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<leader>wttr", "<cmd>lua _wttr_toggle()<CR>", {noremap = true, silent = true})

-- キー: <leader>ol (lsp outline)
vim.keymap.set('n', '<leader>ol', '<cmd>Lspsaga outline<CR>')

-- キー: <Leader>sr / <Leader>sw (suda)
vim.keymap.set('n', '<Leader>sr', ':SudaRead<CR>')
vim.keymap.set('n', '<Leader>sw', ':SudaWrite<CR>')


-- キー: <Leader>ut (undotree)
vim.keymap.set('n', '<Leader>ut', '<Cmd>Atone toggle<CR>' , { desc = 'Atone[Undotree]: トグル' })

-- キー: <leader>nt* (neovim-tips)
vim.keymap.set('n', '<leader>nto', '<Cmd>NeovimTips<CR>', { desc = 'Neovim tips' })
vim.keymap.set('n', '<leader>ntr', '<Cmd>NeovimTipsRandom<CR>', { desc = 'Show random tip' })
vim.keymap.set('n', '<leader>nte', '<Cmd>NeovimTipsEdit<CR>', { desc = 'Edit your tips' })
vim.keymap.set('n', '<leader>nta', '<Cmd>NeovimTipsAdd<CR>', { desc = 'Add your tip' })
vim.keymap.set('n', '<leader>ntp', '<Cmd>NeovimTipsPdf<CR>', { desc = 'Open tips PDF' })
