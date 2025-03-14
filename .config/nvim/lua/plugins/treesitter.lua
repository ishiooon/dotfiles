return {
    {
	"nvim-treesitter/nvim-treesitter",
	build = ':TSUpdate',
	opts = {
	  ensure_installed = { 'bash', 'c', 'html', 'lua', 'markdown', 'vim', 'vimdoc', 'tsx', 'typescript' },
	  auto_install = true,
	  highlight = {
	    enable = true,
	    -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
	    --  If you are experiencing weird indenting issues, add the language to
	    --  the list of additional_vim_regex_highlighting and disabled languages for indent.
	    additional_vim_regex_highlighting = { 'ruby', 'markdown' },
	  },
	  indent = { enable = true, disable = { 'ruby' } },
	},
	config = function(_, opts)
	  require('nvim-treesitter.configs').setup(opts)
	end,
    },
    --Treesitterを使用して、引数の定義と使用法を非同期的に強調表示する
    {
        "m-demare/hlargs.nvim",
        opts = {}
    },
    -- bladeのsyntaxを追加(~/.config/nvim/after/queries/bladeにhighlights.scf・injections.scmを配置)
    config = function(plug, config)
        local treesiter = require("nvim-treesitter.configs")
        local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
        parser_config.blade = {
            install_info = {
                url = "https://github.com/EmranMR/tree-sitter-blade",
                files = { "src/parser.c" },
                branch = "main",
            },
            filetype = "blade"
        }

        vim.filetype.add({
            pattern = {
                ['.*%.blade%.php'] = 'blade',
            }
        })
        local bladeGrp
        vim.api.nvim_create_augroup("BladeFiltypeRelated", { clear = true })
        vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
            pattern = "*.blade.php",
            group = bladeGrp,
            callback = function()
                vim.opt.filetype = "blade"
            end,
        })
    end,
}
