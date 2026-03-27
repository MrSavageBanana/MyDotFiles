return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local status_ok, configs = pcall(require, "nvim-treesitter.configs")
			if not status_ok then
				return
			end

			configs.setup({
				ensure_installed = {
					"bash",
					"lua",
					"vim",
					"vimdoc",
					"javascript",
					"typescript",
					"html",
					"css",
					"python",
					"rust",
					"json",
					"yaml",
					"toml",
					"markdown",
					"markdown_inline",
				},
				sync_install = false,
				highlight = {
					enable = true,
				},
				indent = { enable = true },
			})
		end,
	},
}
