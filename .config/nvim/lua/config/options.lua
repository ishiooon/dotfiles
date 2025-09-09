-- Denoのパス設定
vim.g.denops_deno = vim.fn.expand('~/.deno/bin/deno')
vim.g['denops#deno'] = vim.fn.expand('~/.deno/bin/deno')
-- 環境変数の設定 (副作用: 環境変数の変更)
vim.fn.setenv('PATH', vim.fn.expand('~/.local/bin') .. ':' .. vim.fn.expand('~/.deno/bin') .. ':' .. vim.fn.getenv('PATH'))


-- カラースキームを設定
vim.cmd([[colorscheme gruvbox-material]])
--========================================================
-- 行番号を表示
vim.opt.number = true
vim.opt.relativenumber = true

-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3

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

-- WSL2環境用のクリップボード設定
if vim.fn.has("wsl") == 1 then
  -- Dockerコンテナ内かどうかをチェック
  local is_in_docker = vim.fn.filereadable("/.dockerenv") == 1 or vim.fn.system("grep -q docker /proc/self/cgroup 2>/dev/null && echo 1 || echo 0"):gsub("%s+", "") == "1"
  if is_in_docker then
    -- WSL内のDockerコンテナでは手動でOSC 52シーケンスを送信
    local function osc52_copy(lines)
      local text = table.concat(lines, "\n")
      -- base64エンコード（改行を除去）
      local base64 = vim.fn.system({"base64", "-w", "0"}, text):gsub("\n", "")
      -- OSC 52シーケンスを構築
      local osc52
      if vim.env.TMUX then
        -- tmux環境ではDCSでラップ
        osc52 = string.format("\27Ptmux;\27\27]52;c;%s\7\27\\", base64)
      else
        -- 通常のOSC 52
        osc52 = string.format("\27]52;c;%s\7", base64)
      end
      -- ターミナルに直接書き込み
      vim.fn.chansend(vim.v.stderr, osc52)
    end
    vim.g.clipboard = {
      name = 'OSC52-Docker',
      copy = {
        ['+'] = osc52_copy,
        ['*'] = osc52_copy,
      },
      paste = {
        -- Dockerコンテナ内では貼り付けは通常通り
        ['+'] = function() return vim.split(vim.fn.getreg('+'), '\n') end,
        ['*'] = function() return vim.split(vim.fn.getreg('*'), '\n') end,
      },
    }
  else
    -- 通常のWSL環境では従来の設定を使用
    vim.g.clipboard = {
      name = 'WslClipboard',
      copy = {
        ['+'] = 'clip.exe',
        ['*'] = 'clip.exe',
      },
      paste = {
        ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
      cache_enabled = 0,
    }
  end
else
  -- macOS環境用のクリップボード設定
  vim.opt.clipboard = "unnamedplus"
end

-- vim.lsp.set_log_level("debug")  -- ログ肥大化防止のためコメントアウト

-- ウィンドウの不透明度
vim.opt.termguicolors = true
vim.opt.winblend = 3 -- ウィンドウの不透明度
vim.opt.pumblend = 3 -- ポップアップメニューの不透明度

-- lsp設定
-- すべてのLSP関連設定はmy_lsp.luaに移動済み


-- tree-sitterの設定はtreesitter.luaに移動済み

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
-- mason.setupはmy_lsp.luaで実行されるため、ここでは削除
-- require("mason").setup()
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

dap.configurations.php = {
    {
        type = "php",
        request = "launch",
        name = "Listen for Xdebug",
        port = 9003
    }
}
-- .vscode/launch.jsonの設定
-- require("dap.ext.vscode").load_launchjs(nil, { lldb = { "c", "cpp", "" } })


-- dap.set_log_level('TRACE')  -- ログ肥大化防止のためコメントアウト
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


