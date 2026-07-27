-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- created with Claude. Account: Burhan Ra'if Kouri
local function del(modes, lhs)
  local ok, err = pcall(vim.keymap.del, modes, lhs)
  if not ok then
    vim.notify("keymaps.lua: couldn't delete '" .. lhs .. "': " .. tostring(err), vim.log.levels.WARN)
  end
end
-- Disable Mouse
-- Mouse: scroll wheel scrolls, left-click/drag/double-click do nothing
vim.keymap.set({ "n", "i", "v" }, "<ScrollWheelDown>", "<C-e>")
vim.keymap.set({ "n", "i", "v" }, "<ScrollWheelUp>", "<C-y>")
for _, mode in ipairs({ "n", "v", "i" }) do
  vim.keymap.set(mode, "<LeftMouse>", "<Nop>")
  vim.keymap.set(mode, "<LeftDrag>", "<Nop>")
  vim.keymap.set(mode, "<2-LeftMouse>", "<Nop>") -- disables double click
end
-- non-leader binds (unaffected by the allowlist wipe below, deleted by hand)
del({ "n", "x" }, "j")
del({ "n", "x" }, "<Down>")
del({ "n", "x" }, "k")
del({ "n", "x" }, "<Up>")
del("n", "<C-h>")
del("n", "<C-j>")
del("n", "<C-k>")
del("n", "<C-l>")
del("n", "<C-Up>")
del("n", "<C-Down>")
del("n", "<C-Left>")
del("n", "<C-Right>")
del({ "n", "i", "v" }, "<A-j>")
del({ "n", "i", "v" }, "<A-k>")
del("n", "<S-h>")
del("n", "<S-l>")
del("n", "[b")
del("n", "]b")
del({ "i", "n", "s" }, "<esc>")
del({ "n", "x", "o" }, "n")
del({ "n", "x", "o" }, "N")
del("i", ",")
del("i", ".")
del("i", ";")
del({ "i", "x", "n", "s" }, "<C-s>")
del("x", "<")
del("x", ">")
del("n", "gco")
del("n", "gcO")
del("n", "[q")
del("n", "]q")
del("n", "]d")
del("n", "[d")
del("n", "]e")
del("n", "[e")
del("n", "]w")
del("n", "[w")

-- your own keymaps (must load before the wipe, so its binds are protected by the allowlist)
require("config.mykeys")

-- delete every remaining <leader>-prefixed keymap except this list
local leader_allowlist = {
  [" e"] = true,
  [" y"] = true,
  [" Y"] = true,
  [" d"] = true,
  [" -"] = true,
}

for _, mode in ipairs({ "n", "v", "o" }) do
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if map.lhs:sub(1, 1) == " " and not leader_allowlist[map.lhs] then
      pcall(vim.keymap.del, mode, map.lhs)
    end
  end
end
