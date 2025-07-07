return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("claudecode").setup({})
      
      -- character.md管理用の関数
      local function manage_character_md()
        local dotfiles_dir = vim.fn.expand("~/dotfiles")
        local character_md = dotfiles_dir .. "/.claude/character.md"
        local character_log_dir = dotfiles_dir .. "/.claude/character_log"
        local current_date = os.date("%Y年%m月%d日 %H:%M")
        local current_month = os.date("%Y-%m")
        
        -- 過去月の記録を移動
        local function move_past_month_records()
          -- character_logディレクトリが存在しない場合は作成
          vim.fn.mkdir(character_log_dir, "p")
          
          -- character.mdが存在しない場合は終了
          if vim.fn.filereadable(character_md) == 0 then
            return
          end
          
          -- bashスクリプトを呼び出す
          vim.fn.system("bash ~/.bin/claude-code-wrapper --move-past-months-only")
        end
        
        -- セッション開始時に過去月の記録を移動
        move_past_month_records()
      end
      
      -- ClaudeCode起動時に実行
      vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "ClaudeCodeStart",
        callback = manage_character_md,
      })
      
      -- Neovim終了時に記録を追加（ClaudeCodeが使用された場合）
      local claude_used = false
      vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "ClaudeCode*",
        callback = function()
          claude_used = true
        end,
      })
      
      vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
        callback = function()
          if claude_used then
            -- 記録追加とGitコミット
            vim.fn.system("bash ~/.bin/claude-code-wrapper --add-record-only")
          end
        end,
      })
    end,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>at", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  }
}
