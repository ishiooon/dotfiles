return {
  {
    "r7sqtr/wyw.nvim",
    cmd = { "Wyw", "WywToggle" },
    keys = {
      { "<leader>wn", "<cmd>WywToggle<cr>", desc = "Toggle News Reader" },
    },
    config = function()
      require("wyw").setup({
        -- Your configuration here
      })
    end,
  }
}
