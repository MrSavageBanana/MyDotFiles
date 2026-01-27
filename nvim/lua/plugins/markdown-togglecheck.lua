-- created with Claude. Account: Milobowler
-- ~/.config/nvim/lua/plugins/markdown-togglecheck.lua
return {
	"tadmccorkle/markdown.nvim",
	ft = "markdown",
	config = function()
		require("markdown").setup({
			-- configuration here or empty for defaults
		})
	end,
	keys = {
		{ "<leader>x", "<cmd>MDTaskToggle<cr>", desc = "Toggle Checkmark", ft = "markdown" },
	},
}
