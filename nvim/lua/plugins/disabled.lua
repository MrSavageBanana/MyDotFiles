-- created with Claude. Account: Burhan Ra'if Kouri
return {
  -- Safe to fully disable: LazyVim's core config never references these directly.
  { "lewis6991/gitsigns.nvim", enabled = false },
  { "MagicDuck/grug-far.nvim", enabled = false }, -- I assumed this is what you meant by "grub-far,vnIM"
  { "folke/trouble.nvim", enabled = false },
  { "folke/todo-comments.nvim", enabled = false },

  -- Cannot use enabled = false: LazyVim's core config/keymaps.lua calls
  -- Snacks.toggle...() unconditionally at load time. If Snacks doesn't
  -- exist, that file errors out partway through and silently drops every
  -- keymap defined after the error (quit-all, tabs, window splits — things
  -- you didn't ask to remove). So: kept installed, every visible feature
  -- gutted instead. The actual keybinds get deleted separately below in
  -- config/keymaps.lua.
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>e", false },
      { "<leader>E", false },
    },
    opts = {
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      notifier = { enabled = false },
      picker = { enabled = false },
      quickfile = { enabled = false },
      scope = { enabled = false },
      scroll = { enabled = true },
      statuscolumn = { enabled = false },
      words = { enabled = false },
      bigfile = { enabled = false },
    },
  },
}
