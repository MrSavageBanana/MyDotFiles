--- @sync entry

-- pdfunite.yazi plugin
-- Combines multiple PDF files into one

local function entry(_, job)
	-- SYNC CONTEXT: Get data from cx, then switch to async

	-- Get the selected files
	-- cx.active.selected contains Url objects directly, not File objects!
	local selected_files = {}
	for _, url in pairs(cx.active.selected) do
		-- url is already a Url object, just convert to string
		table.insert(selected_files, tostring(url))
	end

	-- Check if we have at least 2 files selected
	if #selected_files < 2 then
		ya.notify({
			title = "PDF Unite",
			content = "Please select at least 2 PDF files to unite",
			level = "error",
			timeout = 3,
		})
		return
	end

	-- Verify all selected files are PDFs
	local pdf_files = {}
	for _, file_path in ipairs(selected_files) do
		if file_path:match("%.pdf$") or file_path:match("%.PDF$") then
			table.insert(pdf_files, file_path)
		else
			ya.notify({
				title = "PDF Unite",
				content = string.format("File '%s' is not a PDF", file_path),
				level = "warn",
				timeout = 3,
			})
		end
	end

	if #pdf_files < 2 then
		ya.notify({
			title = "PDF Unite",
			content = "At least 2 PDF files required",
			level = "error",
			timeout = 3,
		})
		return
	end

	-- Get the current directory (as a string for passing to async)
	local cwd = tostring(cx.active.current.cwd)

	-- SWITCH TO ASYNC CONTEXT: Do everything else here
	ya.async(function()
		-- Prompt for output filename
		local output_name, event = ya.input({
			title = "Output PDF filename:",
			pos = { "top-center", y = 3, w = 40 },
			value = "united.pdf",
		})

		-- User cancelled or error
		if event ~= 1 then
			return
		end

		-- Ensure the output filename has .pdf extension
		if not output_name:match("%.pdf$") and not output_name:match("%.PDF$") then
			output_name = output_name .. ".pdf"
		end

		local output_path = string.format("%s/%s", cwd, output_name)

		-- Check if output file already exists
		local output_url = Url(output_path)
		local cha, _ = fs.cha(output_url, false)
		if cha then
			-- Ask for confirmation to overwrite
			local confirm = ya.confirm({
				title = "File Exists",
				content = string.format("'%s' already exists. Overwrite?", output_name),
				pos = { "top-center", y = 3, w = 40 },
			})
			if not confirm then
				return
			end
		end

		-- Build the pdfunite command
		ya.notify({
			title = "PDF Unite",
			content = string.format("Uniting %d PDF files...", #pdf_files),
			level = "info",
			timeout = 3,
		})

		-- Create command with all input files
		local cmd = Command("pdfunite")
		for _, pdf_path in ipairs(pdf_files) do
			cmd = cmd:arg(pdf_path)
		end
		cmd = cmd:arg(output_path):stdout(Command.PIPED):stderr(Command.PIPED)

		-- Execute the command
		local child, spawn_err = cmd:spawn()

		if not child then
			ya.notify({
				title = "PDF Unite",
				content = string.format("Failed to spawn pdfunite: %s", spawn_err),
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
				title = "PDF Unite",
				content = string.format("pdfunite failed: %s", error_msg),
				level = "error",
				timeout = 5,
			})
			return
		end

		-- Success!
		ya.notify({
			title = "PDF Unite",
			content = string.format("Successfully created: %s", output_name),
			level = "info",
			timeout = 5,
		})
	end)
end

return { entry = entry }
