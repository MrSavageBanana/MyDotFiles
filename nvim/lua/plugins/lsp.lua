-- created with Claude. Account: Burhan Ra'if Kouri
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
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
