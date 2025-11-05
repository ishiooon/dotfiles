return{
  {
    "rhart92/codex.nvim",
    config = function()
      -- Codex: toggle 実行時に開かれたウィンドウを右側へ移動
      local ok, codex = pcall(require, "codex")
      if not ok or type(codex) ~= "table" then return end

      local orig_toggle = codex.toggle
      if type(orig_toggle) == "function" then
        codex.toggle = function(...)
          local before = {}
          for _, w in ipairs(vim.api.nvim_list_wins()) do before[w] = true end

          local out = { pcall(orig_toggle, ...) }

          vim.schedule(function()
            -- 新規ウィンドウを検出
            local target
            for _, w in ipairs(vim.api.nvim_list_wins()) do
              if not before[w] then
                target = w
                break
              end
            end

            -- 見つかった場合は右側へ移動、見つからなければ codex らしいバッファを探す
            local function move_right(win)
              local old = vim.api.nvim_get_current_win()
              pcall(vim.api.nvim_set_current_win, win)
              pcall(vim.cmd, "wincmd L")
              -- 幅を固定したい場合は次行のコメントを外してください
              pcall(vim.cmd, "vertical resize 35")
              if old and vim.api.nvim_win_is_valid(old) then
                pcall(vim.api.nvim_set_current_win, old)
              end
            end

            if target and vim.api.nvim_win_is_valid(target) then
              move_right(target)
            else
              for _, w in ipairs(vim.api.nvim_list_wins()) do
                local b = vim.api.nvim_win_get_buf(w)
                local ft = (vim.bo[b] and vim.bo[b].filetype) or ""
                local name = (vim.api.nvim_buf_get_name(b) or ""):lower()
                if ft:match("codex") or name:match("codex") then
                  move_right(w)
                  break
                end
              end
            end
          end)

          -- Lua 5.1 uses global `unpack`, 5.2+ uses `table.unpack`.
          local _unpack = table.unpack or unpack
          return _unpack(out)
        end
      end
    end,
  }
}
