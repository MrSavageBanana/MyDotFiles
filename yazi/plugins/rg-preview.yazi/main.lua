---@diagnostic disable: undefined-global
local M = {}

-- 1. Sync state to share the search term between the UI and Preview threads
local save_term = ya.sync(function(state, term)
	state.my_rg_term = term
end)

local get_term = ya.sync(function(state)
	return state.my_rg_term
end)

-- 2. The entry point when you press your search keybind
function M:entry()
	local value, event = ya.input({
		title = "Search files via rg:",
		pos = { "top-center", y = 3, w = 40 },
	})

	-- Exit if the user hits Escape
	if event ~= 1 then
		return
	end

	-- If empty search, clear the state and cancel
	if value == "" then
		save_term(nil)
		ya.emit("escape", { search = true })
		return
	end

	-- Save the term globally, then trigger Yazi's native ripgrep search directly.
	-- Note: we use "search_do" here, not "search" — "search" always pops its own
	-- interactive input prompt regardless of any value passed to it, which is
	-- where the second "Search via rg" prompt was coming from. "search_do" is
	-- the non-interactive variant that just executes with the keyword given.
	save_term(value)
	ya.emit("search_do", { value, via = "rg" })
end

-- 3. The Previewer hook
function M:peek(job)
	local term = get_term()
	local child

	-- Use job.file.path, not job.file.url — inside search results the url carries
	-- a "search://" scheme (with the search term embedded) rather than a plain
	-- filesystem path, and external commands like rg/bat can't read that directly.
	local real_path = tostring(job.file.path)

	if term and term ~= "" then
		-- If we are actively searching, use rg to read the file and highlight matches.
		-- We clear rg's default match style (match:none) and set it with an explicit
		-- truecolor RGB value. rg's default colors use named ANSI codes (e.g. "red"),
		-- which your terminal is free to remap (pywal does exactly this in kitty).
		-- 38;2;r;g;b truecolor escapes are absolute RGB and bypass that remapping —
		-- it's the same reason bat's syntax highlighting isn't affected by pywal.
		child = Command("rg")
			:arg({
				"--color=always",
				"--colors",
				"match:none",
				"--colors",
				"match:fg:255,85,85",
				"--colors",
				"match:style:bold",
				"--passthru",
				"-e",
				term,
				real_path,
			})
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:spawn()
	else
		-- Fallback to `bat` if we are just normally browsing directories
		child = Command("bat")
			:arg({ "--color=always", "--style=plain", real_path })
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:spawn()
	end

	-- Failsafe: drop to the built-in code previewer if commands fail
	if not child then
		return require("code").peek(job)
	end

	-- Read the output chunk by chunk
	local limit = job.area.h
	local i, lines = 0, ""
	repeat
		local next, event = child:read_line()
		if event == 1 then
			-- stderr output (e.g. rg/bat error) — fall back to the code previewer
			return require("code").peek(job)
		elseif event ~= 0 then
			-- 2 = no more data
			break
		end

		i = i + 1
		if i > job.skip then
			lines = lines .. next
		end
	until i >= job.skip + limit

	child:start_kill()

	-- Pagination logic for scrolling with Shift J/K
	if job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", {
			tostring(math.max(0, i - limit)),
			only_if = job.file.url,
			upper_bound = true,
		})
	else
		-- Render ANSI codes into Yazi's UI
		lines = lines:gsub("\t", string.rep(" ", 4))
		ya.preview_widget(job, ui.Text.parse(lines):area(job.area):wrap(ui.Wrap.YES))
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end

	ya.emit("peek", {
		math.max(0, cx.active.preview.skip + job.units),
		only_if = job.file.url,
	})
end

return M
