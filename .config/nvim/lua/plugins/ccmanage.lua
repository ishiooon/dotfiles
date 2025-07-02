return{
  {
  "ishiooon/ccmanager.nvim",
  branch = "fix/issue-18-paste-character-loss",
  dependencies = {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true
  },
  config = function()
    require("ccmanager").setup({
      keymap = "<leader>cm",
      window = {
        size = 0.3,
        position = "right",
      },
      command = "npx ccmanager",
      terminal_keymaps = {
        normal_mode = "<C-q>",
        window_nav = "<C-w>",
        paste = "<C-S-v>",
      },
      wsl_optimization = {
        enabled = true,
        check_clipboard = false,  -- options.luaで設定済みなのでチェックは不要
        fix_paste = true,
      },
    })
  end,
 }
}
