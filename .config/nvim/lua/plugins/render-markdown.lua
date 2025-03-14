return{
    {
        "MeanderingProgrammer/markdown.nvim",
        main = "render-markdown",
        opts = {
            enabled = true,
            renderer = "html",
            filetypes = { "markdown", "md", "txt" },
            template = "default",
        },
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    }
}
