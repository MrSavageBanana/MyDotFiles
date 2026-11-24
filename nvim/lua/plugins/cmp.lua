return {
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")

      -- LazyVim includes standard sources by default (nvim_lsp, buffer, path, luasnip).
      -- You can explicitly adjust or append sources here if needed:
      opts.sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- PowerShell cmdlets & LSP diagnostics
        { name = "buffer" }, -- Words from open buffers
        { name = "path" }, -- File paths
      })
    end,
  },
}
