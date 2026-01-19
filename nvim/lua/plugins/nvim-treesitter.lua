return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Use pcall to avoid the 'module not found' crash
      local status_ok, configs = pcall(require, "nvim-treesitter.configs")
      if not status_ok then 
        return 
      end

      configs.setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript", "html" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
