-- Triforce を初期化し、従来のキー操作からプロフィールを表示できるようにする。
return {
  {
    "gisketch/triforce.nvim",
    dependencies = {
      "nvzone/volt",
    },
    config = function()
      local triforce = require("triforce")
      triforce.setup()
      -- 非推奨の keymap オプションを使わず、公開関数をノーマルモードへ直接割り当てる。
      vim.keymap.set("n", "<leader>tp", triforce.show_profile, { desc = "Triforce: プロフィールを表示" })
    end,
  }
}
