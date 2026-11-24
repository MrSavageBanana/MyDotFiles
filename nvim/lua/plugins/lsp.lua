-- created with Claude. Account: Burhan Ra'if Kouri
return {
  {
    "neovim/nvim-lspconfig",
    config = function() end,
    opts = {
      servers = {
        powershell_es = {
          bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
          settings = {
            powershell = {
              codeFormatting = {
                Preset = "Custom",
              },
            },
          },
        },
        -- AWK configuration
        awk_ls = {},
        ["*"] = {
          keys = {
            { "<leader>ca", false },
            { "<leader>cc", false },
            { "<leader>cC", false },
            { "<leader>cR", false },
            { "<leader>rn", false },
          },
        },
      },
    },
  },
}
