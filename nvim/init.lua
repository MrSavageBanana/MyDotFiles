vim.opt.termguicolors = true
vim.opt.number = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.relativenumber = true
vim.opt.signcolumn = "number"
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})
vim.cmd("cabbrev yazi Yazi")
require("config.lazy")
vim.opt.showmode = false

