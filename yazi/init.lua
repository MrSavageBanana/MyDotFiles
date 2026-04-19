require("recycle-bin"):setup()

require("kdeconnect-send"):setup({
	auto_select_single = false,
})
require("relative-motions"):setup({
	show_numbers = "relative_absolute",
	show_motion = false,
	line_numbers_styles = {
		hovered = ui.Style():bold():fg("#bcc3cd"):reverse(true),
		normal = ui.Style():fg("#66717d"),
	},
})
--		hovered = ui.Style():bold():fg("#555c66"):reverse(true),
--		normal = ui.Style():fg("#474747"),

-- This is the old config for the old relative motions
-- require("relative-motions"):setup({
--   show_numbers = "relative_absolute",
--   show_motion  = true,
--   enter_mode   = "first"
-- })
-- require("simple-tag"):setup({
--   ui_mode = "icon",
--   hints_disabled = false,
--   linemode_order = 1000,
--
--   tag_order = { "r", "o", "y", "g", "b", "p" },  -- Add this line!
--
--   colors = {
--     ["r"] = "#F85B52",
--     ["o"] = "#F6A137",
--     ["y"] = "#F5CE35",
--     ["g"] = "#4ECF64",
--     ["b"] = "#378CF8",
--     ["p"] = "#B46FD4",
--   },
--
--   icons = {
--     default = "●",
--     ["r"] = "●",
--     ["o"] = "●",
--     ["y"] = "●",
--     ["g"] = "●",
--     ["b"] = "●",
--     ["p"] = "●",
--   },
-- })
-- Status:children_add(function(self)
-- 	local h = self._current.hovered
-- 	if h and h.link_to then
-- 		return " -> " .. tostring(h.link_to)
-- 	else
-- 		return ""
-- 	end
-- end, 3300, Status.LEFT)
-- Add this to your ~/.config/yazi/init.lua file # Claude Pics. title: Yazi Pllugin for file line numbers

-- Cache for line counts and binary status to avoid re-running commands
local linecount_cache = {}
local binary_cache = {}

-- Check if file is binary
local function is_binary(path)
	-- Check cache first
	if binary_cache[path] ~= nil then
		return binary_cache[path]
	end

	-- Run file command to check mime type
	local cmd = string.format("file --brief --mime %s 2>/dev/null | grep -q binary", ya.quote(path))
	local result = os.execute(cmd)

	-- In Lua, os.execute returns 0 for success (grep found "binary")
	local is_bin = (result == 0 or result == true)
	binary_cache[path] = is_bin

	return is_bin
end

function Linemode:linecount()
	local path = tostring(self._file.url)

	-- Check if it's a binary file first
	if is_binary(path) then
		return ui.Line(string.format("%6s", "-"))
	end

	-- Check cache for line count
	if linecount_cache[path] then
		return ui.Line(string.format("%6s", linecount_cache[path]))
	end

	-- Only calculate for the hovered file to reduce load
	local hovered = cx.active.current.hovered
	if not hovered or tostring(hovered.url) ~= path then
		-- Not hovered, show placeholder
		return ui.Line(string.format("%6s", ""))
	end

	-- Run wc -l only on hovered file
	local handle = io.popen("wc -l < " .. ya.quote(path) .. " 2>/dev/null")
	if not handle then
		linecount_cache[path] = "ERR"
		return ui.Line(string.format("%6s", "ERR"))
	end

	local result = handle:read("*a")
	handle:close()

	-- Parse the number
	local count = tonumber(result:match("%d+"))
	if count and count > 0 then
		linecount_cache[path] = tostring(count)
		return ui.Line(string.format("%6s", tostring(count)))
	end

	-- If wc -l fails or is 0, show a dash
	linecount_cache[path] = "-"
	return ui.Line(string.format("%6s", "-"))
end

-- created with Claude. Account: Milobowler
-- MD5 Hash Linemode - shows MD5 hash for all files in directory (skips folders, non-recursive)
local md5_cache = {}

function Linemode:md5hash()
	local file = self._file
	local path = tostring(file.url)

	-- Skip folders
	if file.cha.is_dir then
		return ui.Line(string.format("%8s", "-"))
	end

	-- Check cache for MD5 hash
	if md5_cache[path] then
		return ui.Line(string.format("%8s", md5_cache[path]))
	end

	-- Run md5sum for this file
	local handle = io.popen("md5sum " .. ya.quote(path) .. " 2>/dev/null")
	if not handle then
		md5_cache[path] = "ERR"
		return ui.Line(string.format("%8s", "ERR"))
	end

	local result = handle:read("*a")
	handle:close()

	-- Parse the hash (first part before space)
	local hash = result:match("^(%x+)")
	if hash then
		-- Truncate hash to first 8 characters for display
		local short_hash = hash:sub(1, 8)
		md5_cache[path] = short_hash
		return ui.Line(string.format("%8s", short_hash))
	end

	-- If md5sum fails, show a dash
	md5_cache[path] = "-"
	return ui.Line(string.format("%8s", "-"))
end
-- created with Claude. Account: Milobowler
-- SHA256 Hash Linemode - shows SHA256 hash for all files in directory (skips folders, non-recursive)
local sha256_cache = {}

function Linemode:sha256hash()
	local file = self._file
	local path = tostring(file.url)

	-- Skip folders
	if file.cha.is_dir then
		return ui.Line(string.format("%8s", "-"))
	end

	-- Check cache for SHA256 hash
	if sha256_cache[path] then
		return ui.Line(string.format("%8s", sha256_cache[path]))
	end

	-- Run sha256sum for this file
	local handle = io.popen("sha256sum " .. ya.quote(path) .. " 2>/dev/null")
	if not handle then
		sha256_cache[path] = "ERR"
		return ui.Line(string.format("%8s", "ERR"))
	end

	local result = handle:read("*a")
	handle:close()

	-- Parse the hash (first part before space)
	local hash = result:match("^(%x+)")
	if hash then
		-- Truncate hash to first 8 characters for display
		local short_hash = hash:sub(1, 32)
		sha256_cache[path] = short_hash
		return ui.Line(string.format("%8s", short_hash))
	end

	-- If sha256sum fails, show a dash
	sha256_cache[path] = "-"
	return ui.Line(string.format("%8s", "-"))
end
local pagecount_cache = {}

function Linemode:pagecount()
	local file = self._file
	local path = tostring(file.url)

	-- Skip directories
	if file.cha.is_dir then
		return ui.Line(string.format("%6s", "-"))
	end

	-- Only process PDF files (case-insensitive extension check)
	if not path:lower():match("%.pdf$") then
		return ui.Line(string.format("%6s", "-"))
	end

	-- Check cache
	if pagecount_cache[path] then
		return ui.Line(string.format("%6s", pagecount_cache[path]))
	end

	-- Only calculate for the hovered file to reduce load
	local hovered = cx.active.current.hovered
	if not hovered or tostring(hovered.url) ~= path then
		return ui.Line(string.format("%6s", ""))
	end

	-- pdfinfo takes a filename argument; pipe to grep+awk inside the shell string
	local handle = io.popen("pdfinfo " .. ya.quote(path) .. " 2>/dev/null | grep '^Pages:' | awk '{print $2}'")
	if not handle then
		pagecount_cache[path] = "ERR"
		return ui.Line(string.format("%6s", "ERR"))
	end

	local result = handle:read("*a")
	handle:close()

	local count = tonumber(result:match("%d+"))
	if count and count > 0 then
		pagecount_cache[path] = tostring(count)
		return ui.Line(string.format("%6s", tostring(count)))
	end

	pagecount_cache[path] = "-"
	return ui.Line(string.format("%6s", "-"))
end
