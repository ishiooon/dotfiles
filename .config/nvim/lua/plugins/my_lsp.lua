-- LSPサーバー名（mason-lspconfig用）
local lsp_servers = {
    "lua_ls",
    "intelephense",
    "eslint",
    "html"
}

-- Masonツール名（LSP以外のツール）
local mason_tools = {
    "php-debug-adapter",
    "blade-formatter"
}

return {
	-- mason / mason-lspconfig / lspconfig
	{ "williamboman/mason.nvim", config = function()
		require("mason").setup()
	end },
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			-- lsp自動補完設定
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- Intelephenseライセンスキー読み込み関数
			local function get_intelephense_license()
				local license_path = vim.fn.expand('~/intelephense-licence.txt')
				local f = io.open(license_path, 'r')
				if f then
					local license_key = f:read('*a'):gsub('^%s+', ''):gsub('%s+$', '')
					f:close()
					return license_key
				end
				return nil
			end
			-- lspの設定
			vim.opt.completeopt = "menu,menuone,noselect"
			-- lsp_linesを使用するためデフォルトのvirtual_textを無効にする
			vim.diagnostic.config({
        -- -- 右側にエラーコードを表示しないためコメントアウト
				-- virtual_text = {
				-- 	format = function(diagnostic)
				-- 		return string.format("(%s: %s)",diagnostic.source, diagnostic.code)
				-- 	end,
				-- },
				virtual_lines = false,
			})
			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup({
				automatic_installation = false, -- 自動インストールを無効化
				automatic_enable = false, -- 自動的なLSP有効化を無効にする（重複起動を防ぐ）
				ensure_installed = lsp_servers,
			})
			-- 各LSPサーバーの手動設定（Neovim 0.11+ API）
			-- Intelephenseの設定
			vim.lsp.config('intelephense', {
				capabilities = capabilities,
				init_options = {
					licenceKey = get_intelephense_license(),
				},
				settings = {
					intelephense = {
						stubs = {
							"apache",
							"bcmath",
							"bz2",
							"calendar",
							"com_dotnet",
							"Core",
							"ctype",
							"curl",
							"date",
							"dba",
							"dom",
							"enchant",
							"exif",
							"FFI",
							"fileinfo",
							"filter",
							"fpm",
							"ftp",
							"gd",
							"gettext",
							"gmp",
							"hash",
							"iconv",
							"imap",
							"intl",
							"json",
							"ldap",
							"libxml",
							"mbstring",
							"meta",
							"mysqli",
							"oci8",
							"odbc",
							"openssl",
							"pcntl",
							"pcre",
							"PDO",
							"pdo_mysql",
							"Phar",
							"posix",
							"pspell",
							"readline",
							"Reflection",
							"session",
							"shmop",
							"SimpleXML",
							"snmp",
							"soap",
							"sockets",
							"sodium",
							"SPL",
							"sqlite3",
							"standard",
							"superglobals",
							"sysvmsg",
							"sysvsem",
							"sysvshm",
							"tidy",
							"tokenizer",
							"xml",
							"xmlreader",
							"xmlrpc",
							"xmlwriter",
							"xsl",
							"Zend OPcache",
							"zip",
							"zlib",
							"wordpress",
							"WordPress"
						},
						files = {
							maxSize = 5000000
						},
						diagnostics = {
							enable = true,
							undefinedFunctions = false
						}
					}
				}
			})
			-- その他のLSPサーバーの設定
			vim.lsp.config('lua_ls', { capabilities = capabilities })
			vim.lsp.config('eslint', { capabilities = capabilities })
			vim.lsp.config('html', { capabilities = capabilities })

			-- 設定したサーバーを有効化（ファイルタイプに応じて起動）
			vim.lsp.enable('intelephense')
			vim.lsp.enable('lua_ls')
			vim.lsp.enable('eslint')
			vim.lsp.enable('html')
		end,
	},
	-- nvim-cmp 自動補完
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			local cmp = require"cmp"
			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "render-markdown" }
				}, {
					{ name = "buffer" },
				})
			})
		end,
	},
	-- lspsaga
	{
		"nvimdev/lspsaga.nvim",
		opts  = {
			symbol_in_winbar = {
        enable = false,
				-- separator = " ",
        -- hide_keyword = true,
        -- show_file = false,
			},
			finder = {
				max_height = 0.6,
				-- これは必須です / REQUIRED
				default = 'tyd+ref+imp+def',
				-- ここは任意でお好きなキーバインドにしてください / optional
				keys = {
					toggle_or_open = '<CR>',
					vsplit = 'v',
					split = 's',
					tabnew = 't',
					tab = 'T',
					quit = 'q',
					close = '<Esc>',
				},
				-- これは必須です / REQUIRED
				methods = {
					tyd = 'textDocument/typeDefinition',
				}
			},
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		event = { "BufRead", "BufNewFile" },
	},
  {
      "rachartier/tiny-inline-diagnostic.nvim",
      event = "VeryLazy",
      priority = 1000,
      opts = {
      -- preset = "powerline",
    options = {
        multilines = {
            enabled = true,
        },
        show_source = {
            enabled = true,
        },
        add_messages = {
            -- display_count = true,
        },
    },
    },
  }
}
