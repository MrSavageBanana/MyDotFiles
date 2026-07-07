-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- created with Claude. Account: Burhan Ra'if Kouri
-- This file loads on VeryLazy, immediately after LazyVim's own
-- lazyvim/config/keymaps.lua has already set its defaults (same M.load
-- call) -- so every del() below targets a bind that already exists.

local function del(modes, lhs)
  local ok, err = pcall(vim.keymap.del, modes, lhs)
  if not ok then
    vim.notify("keymaps.lua: couldn't delete '" .. lhs .. "': " .. tostring(err), vim.log.levels.WARN)
  end
end

-- movement
del({ "n", "x" }, "j")
del({ "n", "x" }, "<Down>")
del({ "n", "x" }, "k")
del({ "n", "x" }, "<Up>")

-- window nav / resize
del("n", "<C-h>")
del("n", "<C-j>")
del("n", "<C-k>")
del("n", "<C-l>")
del("n", "<C-Up>")
del("n", "<C-Down>")
del("n", "<C-Left>")
del("n", "<C-Right>")

-- move lines
del({ "n", "i", "v" }, "<A-j>")
del({ "n", "i", "v" }, "<A-k>")

-- buffers
del("n", "<S-h>")
del("n", "<S-l>")
del("n", "[b")
del("n", "]b")
del("n", "<leader>bb")
del("n", "<leader>`")
del("n", "<leader>bd")
del("n", "<leader>bo")
del("n", "<leader>bi")
del("n", "<leader>bD")

-- esc / search / save
del({ "i", "n", "s" }, "<esc>")
del("n", "<leader>ur")
del({ "n", "x", "o" }, "n")
del({ "n", "x", "o" }, "N")
del("i", ",")
del("i", ".")
del("i", ";")
del({ "i", "x", "n", "s" }, "<C-s>")
del("n", "<leader>K")

-- indent / comment
del("x", "<")
del("x", ">")
del("n", "gco")
del("n", "gcO")

-- misc
del("n", "<leader>l")
del("n", "<leader>fn")
del("n", "<leader>xl")
del("n", "<leader>xq")
del("n", "[q")
del("n", "]q")

-- format / diagnostics
del({ "n", "x" }, "<leader>cf")
del("n", "<leader>cd")
del("n", "]d")
del("n", "[d")
del("n", "]e")
del("n", "[e")
del("n", "]w")
del("n", "[w")

-- UI toggles
for _, k in ipairs({ "uf", "uF", "us", "uw", "uL", "ud", "ul", "uc", "uA", "uT", "ub", "uh" }) do
  del("n", "<leader>" .. k)
end

-- quit / inspect / changelog
del("n", "<leader>qq")
del("n", "<leader>ui")
del("n", "<leader>uI")
del("n", "<leader>L")

-- windows
del("n", "<leader>-")
del("n", "<leader>|")
del("n", "<leader>wd")

-- tabs
for _, k in ipairs({ "l", "o", "f", "<tab>", "]", "d", "[" }) do
  del("n", "<leader><tab>" .. k)
end

-- run current line as lua
del({ "n", "x" }, "<localleader>r")

-- your own keymaps
require("config.mykeys")
