return{
  {
  "ishiooon/ccmanager.nvim",
  dependencies = {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true
  },
  config = function()
    require("ccmanager").setup({
      window = {size = 0.3},
    })
  end,
 }
}
