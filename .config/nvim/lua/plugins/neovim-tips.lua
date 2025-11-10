return{
  {
    "saxon1964/neovim-tips",
    version = "*", -- Only update on tagged releases
    lazy = true,  -- Load lazily
    -- Load plugin when any of these commands are invoked
    cmd = {
      "NeovimTips",
      "NeovimTipsRandom",
      "NeovimTipsEdit",
      "NeovimTipsAdd",
      "NeovimTipsPdf",
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- OPTIONAL: Choose your preferred markdown renderer (or omit for raw markdown)
      "MeanderingProgrammer/render-markdown.nvim", -- Clean rendering
      -- OR: "OXY2DEV/markview.nvim", -- Rich rendering with advanced features
    },
    opts = {
      -- IMPORTANT: Daily tip DOES NOT WORK with lazy = true
      -- Reason: lazy = true loads plugin only when keybinds are triggered,
      --         but daily_tip needs plugin loaded at startup
      -- Solution: Keep daily_tip = 0 here, or use Option 2 below for daily tips
      daily_tip = 0,  -- 0 = off, 1 = once per day, 2 = every startup
      -- Other optional settings...
      bookmark_symbol = "🌟 ",
    },
  }
}
