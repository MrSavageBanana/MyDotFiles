return {
	-- The "Recommended" Mason setup
	{
		"williamboman/mason.nvim",
		opts = {}, -- This replaces the need for a config function
	},

	-- The Tool Installer (To actually get ruff, prettier, etc.)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"ruff", -- For Python linting/formatting
					"stylua", -- For Lua formatting
					"eslint_d", -- For JS linting
					"prettier", -- For JS formatting
				},
			})
		end,
	},
}
