return {
    {
        'nvim-lualine/lualine.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'arkav/lualine-lsp-progress',
            'ishiooon/claudecode-lualine.nvim',
        },
        opts = {
            options = {
                icons_enabled = true,
                theme = 'auto',
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
                disabled_filetypes = {
                    statusline = {},
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = true,
                refresh = {
			      statusline = 100,  -- 100msごとに更新（より頻繁に）
			      tabline = 1000,
			      winbar = 1000,
			    }
			},
			sections = {
			    lualine_a = {'mode'},
			    lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {
            'filename',
            {
                function()
                    return require("dap").status()
                end,
                icon = { "", color = { fg = "#e7c664" } }, -- nerd icon.
                cond = function()
                  if not package.loaded.dap then
                    return false
                  end
                  local session = require("dap").session()
                  return session ~= nil
                end,
            },
            {
              function()
                return require("pomodoro").get_pomodoro_status("⏱❌","⏱","🛏")
              end,
            },
          },
			    lualine_x = {
            {
              'claudecode',
              icons = {
                idle = '○',
                busy = '●',
                wait = '◐',
                disconnected = '✕',
              },
              colors = {
                idle = nil,
                busy = 'DiagnosticInfo',
                wait = 'DiagnosticWarn',
                disconnected = 'DiagnosticError',
              },
              show_status_text = false,
            },
            'encoding', 'fileformat', 'filetype'},
			    lualine_y = {'progress'},
                -- 時計アイコンと時分を表示
                lualine_z = {
                    'location',
                    function()
                        return " " .. os.date("%H:%M")
                    end,
                },
			  },
			  inactive_sections = {
			    lualine_a = {},
			    lualine_b = {},
			    lualine_c = {'filename'},
			    lualine_x = {'location'},
			    lualine_y = {},
			    lualine_z = {}
			  },
			  tabline = {},
			  winbar = {},
			  inactive_winbar = {},
			  extensions = {}
		}
	}
}
