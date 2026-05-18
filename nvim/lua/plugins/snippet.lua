return {
	-- 1. The Snippet Engine
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		dependencies = { "rafamadriz/friendly-snippets" }, -- 2. The Library of Snippets
		config = function()
			-- This line tells LuaSnip to load the Bash snippets from friendly-snippets
			require("luasnip.loaders.from_vscode").lazy_load()

			-- Keymaps to expand and jump through the snippet
			local ls = require("luasnip")
			vim.keymap.set({ "i", "s" }, "<Tab>", function()
				if ls.expand_or_jumpable() then
					ls.expand_or_jump()
				else
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
				end
			end, { silent = true })
			vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
				if ls.jumpable(-1) then
					ls.jump(-1)
				end
			end, { silent = true })
		end,
	},
}
