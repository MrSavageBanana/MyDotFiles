-- created with Claude. Account: Milobowler
--- @since 25.5.31

local AVAILABLE_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789."

local changed = ya.sync(function(st, new)
	local b = st.last ~= new
	st.last = new
	return b or not cx.active.finder
end)

local escape = function(s) return s == "." and "\\." or s end

return {
	entry = function()
		local cands = {}
		for i = 1, #AVAILABLE_CHARS do
			cands[#cands + 1] = { on = AVAILABLE_CHARS:sub(i, i) }
		end

		local idx = ya.which { cands = cands, silent = true }
		if not idx then
			return
		end

		local kw = escape(cands[idx].on)
		if changed(kw) then
			-- Case insensitive search: match both uppercase and lowercase
			local lower = kw:lower()
			local upper = kw:upper()
			local pattern = lower ~= upper and "^[" .. lower .. upper .. "]" or "^" .. kw
			ya.emit("find_do", { pattern })
		else
			ya.emit("find_arrow", {})
		end
		
		-- Stop the finder after use
		ya.emit("find_do", { "" })
	end,
}
