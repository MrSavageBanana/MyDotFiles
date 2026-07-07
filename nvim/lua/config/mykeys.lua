local map = vim.keymap.set

-- from your old init.lua
map("v", "<leader>y", '"+y', { desc = "Copy to system clipboard" })
map("n", "<leader>Y", '"+yy', { desc = "Copy line to system clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "actually delete text" })
map("n", "zk", function()
  local winid = require("ufo").peekFoldedLinesUnderCursor()
  if not winid then
    vim.lsp.buf.hover()
  end
end, { desc = "Peek Fold" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- add binds for new plugins here as you install/configure them
