-- Claude Code status component for lualine
local dev_path = vim.fn.expand('~/dev_plugin/claudecode-lualine.nvim')
local use_dev = vim.fn.isdirectory(dev_path) == 1

local config = {
  dependencies = {
    'nvim-lualine/lualine.nvim',
    'coder/claudecode.nvim',
  },
}

if use_dev then
  config.dir = dev_path
  config[1] = 'claudecode-lualine.nvim'
else
  config[1] = 'ishiooon/claudecode-lualine.nvim'
end

return { config }
