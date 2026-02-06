--- @sync entry

-- pdfseparate.yazi plugin
-- Extracts pages from a PDF file to a separate folder

local function entry(_, job)
	-- SYNC CONTEXT: Only get the file from cx, then switch to async immediately
	local file = cx.active.current.hovered
	if not file then
		ya.notify({
			title = "PDF Separate",
			content = "No file selected",
			level = "error",
			timeout = 3,
		})
		return
	end

	-- Get the file path as a string (this is sendable to async context)
	local pdf_path = tostring(file.url)

	-- Check if it's a PDF file
	if not pdf_path:match("%.pdf$") and not pdf_path:match("%.PDF$") then
		ya.notify({
			title = "PDF Separate",
			content = "Selected file is not a PDF",
			level = "error",
			timeout = 3,
		})
		return
	end

	-- SWITCH TO ASYNC CONTEXT: Do everything else here
	ya.async(function()
		-- Prompt for first page (ya.input works in async context)
		local first_page, event1 = ya.input({
			title = "First page to extract:",
			pos = { "top-center", y = 3, w = 40 },
		})

		-- User cancelled or error
		if event1 ~= 1 then
			return
		end

		-- Validate first page is a number
		first_page = tonumber(first_page)
		if not first_page or first_page < 1 then
			ya.notify({
				title = "PDF Separate",
				content = "Invalid first page number",
				level = "error",
				timeout = 3,
			})
			return
		end

		-- Prompt for last page
		local last_page, event2 = ya.input({
			title = "Last page to extract:",
			pos = { "top-center", y = 3, w = 40 },
		})

		-- User cancelled or error
		if event2 ~= 1 then
			return
		end

		-- Validate last page is a number
		last_page = tonumber(last_page)
		if not last_page or last_page < first_page then
			ya.notify({
				title = "PDF Separate",
				content = "Invalid last page number (must be >= first page)",
				level = "error",
				timeout = 3,
			})
			return
		end

		-- Create folder name from the PDF filename (without extension)
		local folder_name = pdf_path:match("(.+)%.pdf$") or pdf_path:match("(.+)%.PDF$")
		if not folder_name then
			folder_name = pdf_path .. "_separated"
		end

		-- Show notification that we're starting
		ya.notify({
			title = "PDF Separate",
			content = string.format("Extracting pages %d to %d...", first_page, last_page),
			level = "info",
			timeout = 3,
		})

		-- Create the output directory
		local folder_url = Url(folder_name)
		local ok, err = fs.create("dir", folder_url)
		if not ok then
			ya.notify({
				title = "PDF Separate",
				content = string.format("Failed to create directory: %s", err),
				level = "error",
				timeout = 5,
			})
			return
		end

		-- Build the output pattern
		-- pdfseparate expects: output/file-%d.pdf where %d is the page number
		local output_pattern = string.format("%s/page-%%d.pdf", folder_name)

		-- Build and execute the pdfseparate command
		local child, spawn_err = Command("pdfseparate")
			:arg("-f")
			:arg(tostring(first_page))
			:arg("-l")
			:arg(tostring(last_page))
			:arg(pdf_path)
			:arg(output_pattern)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:spawn()

		if not child then
			ya.notify({
				title = "PDF Separate",
				content = string.format("Failed to spawn pdfseparate: %s", spawn_err),
				level = "error",
				timeout = 5,
			})
			return
		end

		-- Wait for the command to finish
		local output, wait_err = child:wait_with_output()

		if not output or not output.status.success then
			local error_msg = output and output.stderr or tostring(wait_err)
			ya.notify({
				title = "PDF Separate",
				content = string.format("pdfseparate failed: %s", error_msg),
				level = "error",
				timeout = 5,
			})
			return
		end

		-- Success!
		ya.notify({
			title = "PDF Separate",
			content = "Successfully extracted pages",
			level = "info",
			timeout = 5,
		})
	end)
end

return { entry = entry }
