return {
	entry = function()
		-- Safely get the hovered file using Yazi's global 'cx' context
		local hovered = cx.active.current.hovered
		if not hovered then
			return
		end

		-- Convert the URL to a string
		local url_str = tostring(hovered.url)

		-- Regex to strip 'search://...//' and leave the absolute path intact
		local clean_path = url_str:gsub("^search://.-//", "/")

		-- Send the cleaned path to your system clipboard
		ya.clipboard(clean_path)

		-- Show a brief notification confirming the real path was copied
		ya.notify({
			title = "Clipboard",
			content = "Copied real path: " .. clean_path,
			timeout = 1.5,
			level = "info",
		})
	end,
}
