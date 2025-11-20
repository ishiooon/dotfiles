-- .config/nvim/lua/plugins/triforce.lua
-- /home/dev_local/.config/nvim/lua/plugins//triforce.lua
return{
  {
    "gisketch/triforce.nvim",
    dependencies = {
      "nvzone/volt",
    },
    config = function()
      require("triforce").setup({
        -- Optional: Add your configuration here
        keymap = {
          show_profile = "<leader>tp", -- Open profile with <leader>tp
        },
      })
    end,
  }
}
