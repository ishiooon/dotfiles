return {
  {
    "piersolenski/plugin-addict.nvim",
    opts = {
      plugins_path = vim.fn.stdpath("config") .. "/lua/plugins/",
    },
    keys = {
      {
        "<leader>np",
        function()
          require("plugin-addict").new()
        end,
        desc = "New plugin config",
      },
    },
  }
}
