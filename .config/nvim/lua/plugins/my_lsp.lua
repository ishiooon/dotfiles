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
		},
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


