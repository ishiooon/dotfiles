-- このプラグインはインデント行を強調表示し、現在のカーソル位置に応じてコード チャンクを強調表示できます。
return{
	{
		"shellRaining/hlchunk.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("hlchunk").setup({
				chunk = {
					enable = true
				},
				indent = {
					enable = true
				},
				line_num = {
					enable = true
				},
				blank = {
					enable = true
				}
			})
		end
	},
}
