local lsp_servers = {
    "lua_ls",
    "intelephense",
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
			-- Intelephenseライセンスキー読み込み関数
			local function get_intelephense_license()
				local license_path = vim.fn.expand('~/intelephense-licence.txt')
				local f = io.open(license_path, 'r')
				if f then
					local license_key = f:read('*a'):gsub('^%s+', ''):gsub('%s+$', '') -- trim whitespace
					f:close()
					return license_key
				end
				return nil
			end

			-- プロジェクトルートから絶対パスを取得する関数
			local function get_wordpress_paths()
				local root_dir = vim.fn.getcwd()
				local paths = {}
				
				-- WordPressプロジェクトの場合
				if vim.fn.isdirectory(root_dir .. "/wp-includes") == 1 then
					table.insert(paths, root_dir)
					table.insert(paths, root_dir .. "/wp-includes")
					table.insert(paths, root_dir .. "/wp-admin")
					table.insert(paths, root_dir .. "/wp-content")
				end
				
				-- vendor ディレクトリ
				if vim.fn.isdirectory(root_dir .. "/vendor") == 1 then
					table.insert(paths, root_dir .. "/vendor")
				end
				
				return paths
			end

			-- Intelephense設定
			require('lspconfig').intelephense.setup({
				root_dir = require('lspconfig').util.root_pattern('wp-config.php', 'composer.json', '.git'),
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
							includePaths = get_wordpress_paths(),
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
							maxSize = 1000000,
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
						telemetry = {
							enabled = false,
						},
						maxMemory = 256,
						completion = {
							insertUseDeclaration = true,
							fullyQualifyGlobalConstantsAndFunctions = false,
							triggerParameterHints = true,
							maxItems = 100,
						},
					}
				}
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
