return{
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",  -- Required for Job and HTTP requests
    },
    -- Ensure hub will be ready at the earliest
    -- cmd = "MCPHub",  -- lazy load disabled for immediate availability
    build = "npm install -g mcp-hub@latest",  -- Installs required mcp-hub npm module
    -- uncomment this if you don't want mcp-hub to be available globally or can't use -g
    -- build = "bundled_build.lua",  -- Use this and set use_bundled_binary = true in opts  (see Advanced configuration)
    config = function()
      require("mcphub").setup({
        -- Enable auto approval for all server tools
        auto_approve = true,
        -- Start all servers automatically
        auto_start = true,
      })
    end,
  }
}
