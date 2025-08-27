-- Claude Code status component for lualine
return {
  {
    dir = vim.fn.expand('~/dev_plugin/claudecode-lualine.nvim'),
    dependencies = {
      'nvim-lualine/lualine.nvim',
      'coder/claudecode.nvim',
    },
    config = function()
      -- ローカルディレクトリが存在しない場合は GitHubから取得
      local plugin_dir = vim.fn.expand('~/dev_plugin/claudecode-lualine.nvim')
      if vim.fn.isdirectory(plugin_dir) == 0 then
        vim.notify('claudecode-lualine.nvim not found locally, cloning from GitHub...', vim.log.levels.INFO)
        vim.fn.system({
          'git', 'clone', 'https://github.com/ishiooon/claudecode-lualine.nvim',
          plugin_dir
        })
      end
      
      -- The component will be added to lualine in the lualine.lua config
      -- This just ensures the plugin is loaded
    end,
  },
}