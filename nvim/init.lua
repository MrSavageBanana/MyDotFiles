vim.opt.termguicolors = true
vim.opt.number = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.relativenumber = true
vim.opt.signcolumn = "number"
vim.opt.wrap = false
-- System clipboard copy
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+yy', { desc = "Copy line to system clipboard" })
-- Folds
vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.keymap.set("n", "zk", function()
	local winid = require("ufo").peekFoldedLinesUnderCursor()
	if not winid then
		vim.lsp.buf.hover()
	end
end, { desc = "Peek Fold" })
-- End of Folds
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})
vim.cmd("cabbrev yazi Yazi")
require("config.lazy")
vim.opt.showmode = false
vim.diagnostic.config({
	virtual_text = false,
	float = { border = "rounded" },
})

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

local _conceal_counter = 0

vim.api.nvim_create_user_command("Conceal", function(opts)
	local literal = opts.args

	-- Auto-enable concealing if currently off, but don't override a custom level
	if vim.wo.conceallevel == 0 then
		vim.wo.conceallevel = 2
	end

	_conceal_counter = _conceal_counter + 1
	local group = "UserConceal" .. _conceal_counter

	-- Escape for \V (very nomagic) mode:
	--   \ → \\ (only special char in \V)
	--   / → \/ (escape our regex delimiter)
	local escaped = literal:gsub("\\", "\\\\"):gsub("/", "\\/")

	-- Pattern explanation:
	--   \m      → switch to magic mode for the .* anchors
	--   .*      → match any leading characters on the line
	--   \V      → switch to very nomagic; everything after is treated as literal
	--   escaped → the user's literal string
	--   \m.*    → back to magic for trailing characters, consuming the rest of the line
	local pattern

	if opts.range == 2 then
		-- Visual/range selection: add line boundary assertions before the match
		-- \%>Nl means "after line N" (exclusive), \%<Nl means "before line N" (exclusive)
		-- So \%>(line1-1)l and \%<(line2+1)l together = exactly [line1, line2] inclusive
		pattern = string.format("\\m\\%%>%dl\\%%<%dl.*\\V%s\\m.*", opts.line1 - 1, opts.line2 + 1, escaped)
	else
		pattern = string.format("\\m.*\\V%s\\m.*", escaped)
	end

	vim.cmd(string.format("syntax match %s /%s/ conceal", group, pattern))
end, {
	nargs = 1,
	range = true,
	desc = "Conceal lines containing literal text. Supports visual ranges.",
})
vim.api.nvim_create_user_command("ConcealClear", function()
	for i = 1, _conceal_counter do
		pcall(vim.cmd, "syntax clear UserConceal" .. i)
	end
	_conceal_counter = 0
end, { desc = "Clear all rules created by :Conceal" })
local _conceal_counter = 0
local _conceal_rules = {} -- tracks pattern -> group name

vim.api.nvim_create_user_command("Conceal", function(opts)
	local literal = opts.args

	if vim.wo.conceallevel == 0 then
		vim.wo.conceallevel = 2
	end

	_conceal_counter = _conceal_counter + 1
	local group = "UserConceal" .. _conceal_counter
	_conceal_rules[literal] = group -- store it

	local escaped = literal:gsub("\\", "\\\\"):gsub("/", "\\/")
	local pattern

	if opts.range == 2 then
		pattern = string.format("\\m\\%%>%dl\\%%<%dl.*\\V%s\\m.*", opts.line1 - 1, opts.line2 + 1, escaped)
	else
		pattern = string.format("\\m.*\\V%s\\m.*", escaped)
	end

	vim.cmd(string.format("syntax match %s /%s/ conceal", group, pattern))
end, {
	nargs = 1,
	range = true,
	desc = "Conceal lines containing literal text.",
})

vim.api.nvim_create_user_command("Unconceal", function(opts)
	local literal = opts.args
	local group = _conceal_rules[literal]

	if group then
		vim.cmd("syntax clear " .. group)
		_conceal_rules[literal] = nil
	else
		vim.notify("No conceal rule found for: " .. literal, vim.log.levels.WARN)
	end
end, {
	nargs = 1,
	desc = "Remove a single conceal rule by its original argument.",
})

vim.api.nvim_create_user_command("ConcealClear", function()
	for _, group in pairs(_conceal_rules) do
		pcall(vim.cmd, "syntax clear " .. group)
	end
	_conceal_rules = {}
	_conceal_counter = 0
end, { desc = "Clear all rules created by :Conceal" })
