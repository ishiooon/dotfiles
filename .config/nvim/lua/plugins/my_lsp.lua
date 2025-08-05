local lsp_servers = {
    "lua_ls",
    "Intelephense",
    "eslint-lsp",
    "php-debug-adapter",
    "blade-formatter",
    "html-lsp"
}

return{
	-- mason / mason-lspconfig / lspconfig
	{ "williamboman/mason.nvim", opts = { ensure_installed = lsp_servers } },
	{
		"williamboman/mason-lspconfig.nvim",
	    	dependencies = {
	    		"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
	    	},
		opts =  {
			automatic_installation = true,
			-- automatic_enable は削除（存在しないオプション）
		},
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Intelephense設定
			require('lspconfig').intelephense.setup({
				root_dir = require('lspconfig').util.root_pattern('.vscode', 'composer.json', '.git'),
				init_options = {
					licenceKey = vim.fn.expand('~/intelephense-licence.txt'),
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
							"pdo_ibm",
							"pdo_mysql",
							"pdo_pgsql",
							"pdo_sqlite",
							"pgsql",
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
						},
						environment = {
							includePaths = {
								"vendor/",
								"_ide_helper.php",
								"bootstrap/cache/",
							},
						},
						files = {
							associations = {
								"*.php",
								"*.blade.php",
							},
							exclude = {
								"**/.git/**",
								"**/.svn/**",
								"**/.hg/**",
								"**/CVS/**",
								"**/.DS_Store/**",
								"**/node_modules/**",
								"**/bower_components/**",
								"**/vendor/**/{Test,test,Tests,tests}/**",
							},
						},
						diagnostics = {
							enable = true,
							undefinedTypes = false,
							undefinedFunctions = false,
							undefinedConstants = false,
							undefinedClassConstants = false,
							undefinedMethods = false,
							undefinedProperties = false,
							undefinedVariables = true,
						},
					}
				},
				on_attach = function(client, bufnr)
					-- プロジェクトタイプに応じて診断を制御
					local root_dir = vim.fn.getcwd()
					if root_dir:match("wordpress") then
						-- WordPress関数の未定義エラーを無効化
						client.server_capabilities.diagnosticsProvider = false
					end
				end,
			})
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
        },
        opts = {}
    },
	-- lspsaga
	{
	    	"nvimdev/lspsaga.nvim",
		opts  = {
		    symbol_in_winbar = {
			separator = "  ",
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
}
