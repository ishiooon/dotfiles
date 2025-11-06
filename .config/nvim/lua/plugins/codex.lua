return{
  {
    "rhart92/codex.nvim",
    config = function()
      -- シンプルに：codex のウィンドウを右に寄せるヘルパ
      local function move_codex_right()
        local old = vim.api.nvim_get_current_win()
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          local b = vim.api.nvim_win_get_buf(w)
          local ft = (vim.bo[b] and vim.bo[b].filetype) or ""
          local name = (vim.api.nvim_buf_get_name(b) or ""):lower()
          if ft:match("codex") or name:match("codex") then
            pcall(vim.api.nvim_set_current_win, w)
            pcall(vim.cmd, "wincmd L")
            pcall(vim.cmd, "vertical resize 35")
          end
        end
        if old and vim.api.nvim_win_is_valid(old) then
          pcall(vim.api.nvim_set_current_win, old)
        end
      end

      local ok, codex = pcall(require, "codex")
      if not ok or type(codex) ~= "table" then return end

      -- ラッパー: 実行後に右寄せをスケジュール
      local function wrap_right(fn)
        if type(fn) ~= "function" then return nil end
        return function(...)
          local out = { pcall(fn, ...) }
          vim.schedule(move_codex_right)
          local _unpack = table.unpack or unpack
          return _unpack(out)
        end
      end

      -- toggle をラップ
      codex.toggle = wrap_right(codex.toggle) or codex.toggle

      -- 視覚モード(<leader>cs)での送信も右に出す
      if codex.actions and type(codex.actions) == "table" then
        codex.actions.send_selection = wrap_right(codex.actions.send_selection) or codex.actions.send_selection
      end

      -- 入力画面から素早く抜けるキー(バッファローカル)
      vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
        callback = function(args)
          local b = args.buf
          if not b or not vim.api.nvim_buf_is_valid(b) then return end
          local ft = (vim.bo[b] and vim.bo[b].filetype) or ""
          local name = (vim.api.nvim_buf_get_name(b) or ""):lower()
          if not (ft:match("codex") or name:match("codex")) then return end

          local bt = (vim.bo[b] and vim.bo[b].buftype) or ""
          local opts = { buffer = b, silent = true, nowait = true }

          -- どの codex バッファでも 'q' で閉じる
          pcall(vim.keymap.set, 'n', 'q', '<Cmd>close<CR>', opts)

          -- 入力っぽいバッファでは <Esc>/<C-c> で抜けて閉じる
          if bt == 'prompt' or bt == 'nofile' then
            pcall(vim.keymap.set, 'i', '<Esc>', '<Esc><Cmd>close<CR>', opts)
            pcall(vim.keymap.set, 'n', '<Esc>', '<Cmd>close<CR>', opts)
            pcall(vim.keymap.set, 'i', '<C-c>', '<Esc><Cmd>close<CR>', opts)
            pcall(vim.keymap.set, 'n', '<C-c>', '<Cmd>close<CR>', opts)
          end
        end,
      })
    end,
  }
}
