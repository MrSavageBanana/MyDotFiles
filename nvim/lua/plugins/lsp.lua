return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Tell servers what autocomplete features cmp supports
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls", -- Lua
					"ts_ls", -- JavaScript + TypeScript
					"pyright", -- Python
					"bashls", -- Bash
					"jsonls", -- JSON
					"yamlls", -- YAML
					"taplo", -- TOML
					"cssls", -- CSS + SCSS
					"html", -- HTML
					"marksman", -- Markdown
					"rust_analyzer", -- Rust
				},
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end,
				},
			})
		end,
	},
	{ "williamboman/mason-lspconfig.nvim" },
}
