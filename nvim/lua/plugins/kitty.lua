return {
	"knubie/vim-kitty-navigator",
	lazy = false,
	init = function()
		-- Disable default plugin mappings
		vim.g.kitty_navigator_no_mappings = 1
	end,
	config = function()
		-- Map standard vim window keys to the kitty-aware navigation commands
		vim.keymap.set("n", "<C-w>h", ":KittyNavigateLeft<CR>", { silent = true })
		vim.keymap.set("n", "<C-w>j", ":KittyNavigateDown<CR>", { silent = true })
		vim.keymap.set("n", "<C-w>k", ":KittyNavigateUp<CR>", { silent = true })
		vim.keymap.set("n", "<C-w>l", ":KittyNavigateRight<CR>", { silent = true })
	end,
}
