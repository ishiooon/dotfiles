-- 初期実行コマンド
--========================================================
-- カラースキームを設定
vim.cmd([[colorscheme gruvbox-material]])
-- ストローク表示をオン
vim.cmd([[ShowkeysToggle]])
--========================================================
-- 行番号を表示
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.ignorecase = true -- 検索時に大文字小文字を区別しない

-- タブとインデントの設定
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true -- タブをスペースに変換

-- vimdoc-ja.luaの設定
vim.opt.helplang = 'ja' -- ヘルプの言語を日本語に設定

-- memolist.luaのファイル保存先
vim.g.memolist_path = '~/.config/memolist'
vim.g.memo_dir = '~/.config/memolist'

-- local filetype_tabstop = {php = 4} -- filetype毎のインデント幅
-- local usrftcfg = vim.api.nvim_create_augroup("UserFileTypeConfig", { clear = true})
-- vim.api.nvim_create_autocmd("FileType", {
--   group = usrftcfg,
--   callback = function (args)
--     local ftts = filetype_tabstop[args.match]
--     if ftts then
--       vim.opt.tabstop = ftts
--       vim.opt.shiftwidth = ftts
--     end
--   end
-- })

if vim.fn.has("wsl") then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf"
    },
    paste = {
      ["+"] = "win32yank.exe -o --crlf",
      ["*"] = "win32yank.exe -o --crlf"
    },
    cache_enable = 0,
  }
end
-- クリップボードの設定
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.lsp.set_log_level("debug")

-- ウィンドウの不透明度
vim.opt.termguicolors = true
vim.opt.winblend = 3 -- ウィンドウの不透明度
vim.opt.pumblend = 3 -- ポップアップメニューの不透明度

-- lsp設定
local mason = require('mason')
local lspconfig = require('lspconfig')
local mason_lspconfig = require('mason-lspconfig')

mason.setup()
mason_lspconfig.setup()
mason_lspconfig.setup_handlers({
    function(server_name)
        lspconfig[server_name].setup({})
    end,
    -- laravelの「Route」で「undefinedTypes」エラーが出るため Intelephenseのdiagnostics.undefinedTypesをfalseにする
    ["intelephense"] = function()
        lspconfig.intelephense.setup({
            settings = {
                intelephense = {
                    diagnostics = {
                        undefinedTypes = false,
                    }
                }
            }
        })
    end
})

-- lsp自動補完設定
-- lspのハンドラーに設定
capabilities = require("cmp_nvim_lsp").default_capabilities()

-- lspの設定後に追加
vim.opt.completeopt = "menu,menuone,noselect"

-- lsp_linesを使用するためデフォルトのvirtual_textを無効にする
vim.diagnostic.config({
  virtual_text = false,
})

local cmp = require"cmp"
cmp.setup({
  -- snippet = {
  --   expand = function(args)
  --     require("luasnip").lsp_expand(args.body)
  --   end,
  -- },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "render-markdown" }
  }, {
    { name = "buffer" },
  })
})


-- tree-sitterの設定(4blade)
local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.blade = {
  install_info = {
    url = "https://github.com/EmranMR/tree-sitter-blade",
    files = {"src/parser.c"},
    branch = "main",
  },
  filetype = "blade"
}
vim.filetype.add({
  pattern = {
    ['.*%.blade%.php'] = 'blade',
  },
})

-- neotreeの透過
require('transparent').clear_prefix('NeoTree')
-- lualineの透過
-- require('transparent').clear_prefix('lualine')
--
-- pdfviewの設定
vim.api.nvim_create_autocmd("BufReadPost", {
   pattern = "*.pdf",
   callback = function()
     local file_path = vim.api.nvim_buf_get_name(0)
     require("pdfview").open(file_path)
   end,
})

-- mini.nvimの設定
require('mini.animate').setup() -- アニメーションの設定
require('mini.cursorword').setup()  -- カーソルの単語をハイライト

-- telescopeの設定
require("telescope").setup({
  defaults = {
    path_display = {
      filename_first = {
        reverse_directories = false,
      },
    },
  },
})

-- dap設定
require("mason").setup()
require("mason-nvim-dap").setup({
    ensure_installed = { "php-debug-adapter" },
    automatic_installation = true,
})
local dap = require("dap")
-- バグが出ているため一時的にコメントアウト
local dapui = require("dapui")
dapui.setup()
dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
end
-- PHP用アダプターの設定
dap.adapters.php = {
    type = 'executable',
    command = 'node',
    args = { os.getenv('HOME') .. '/vscode-php-debug/out/phpDebug.js' }
}
-- .vscode/launch.jsonの設定
-- require("dap.ext.vscode").load_launchjs(nil, { lldb = { "c", "cpp", "" } })

dap.set_log_level('TRACE')
-- ブレークポイントの設定
vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end, { desc = "Toggle Breakpoint" })
vim.keymap.set('n', '<Leader>B', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = "Set Conditional Breakpoint" })
vim.keymap.set('n', '<Leader>lp', function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, { desc = "Set Log Point" })

-- デバッグ操作
vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = "Start/Continue Debugging" })
vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = "Step Over" })
vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = "Step Into" })
vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = "Step Out" })

-- デバッグUI
---@diagnostic disable-next-line: redefined-local
vim.keymap.set('n', '<Leader>du', function() dapui.toggle() end, { desc = "Toggle Debug UI" })
-- vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end, { desc = "Open Debug REPL" })

-- 最後のデバッグセッションを再実行
vim.keymap.set('n', '<Leader>dl', function() dap.run_last() end, { desc = "Run Last Debug Session" })


