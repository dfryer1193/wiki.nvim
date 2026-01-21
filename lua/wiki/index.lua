local config = require("wiki.config")

local M = {}

local function scandir(path)
	local handle = vim.loop.fs_scandir(path)
	if not handle then
		return {}
	end

	local entries = {}
	while true do
		local name, type = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end
		table.insert(entries, { name = name, type = type })
	end

	table.sort(entries, function(a, b)
		return a.name < b.name
	end)

	return entries
end

local function build_tree(path)
	local tree = { dirs = {}, files = {} }

	for _, entry in ipairs(scandir(path)) do
		local full_path = path .. "/" .. entry.name

		if entry.type == "directory" then
			tree.dirs[entry.name] = build_tree(full_path)
		else
			tree.files[entry.name] = full_path
		end
	end

	return tree
end

local function render_tree(tree, lines, depth, relpath)
	relpath = relpath or ""

	local has_file_newline = false
	for fname, full_path in pairs(tree.files) do
		local file_indent = ""
		if depth >= 5 then
			file_indent = string.rep("  ", depth - 5)
		else
			if not has_file_newline then
				has_file_newline = true
				table.insert(lines, "")
			end
		end

		local name = fname:gsub("%.md$", "")
		table.insert(lines, string.format("%s- [%s](%s)", file_indent, name, full_path))
	end

	local has_dir_newline = false
	for dir_name, subtree in pairs(tree.dirs) do
		if depth < 5 then
			table.insert(lines, "")
			table.insert(lines, string.rep("#", depth + 2) .. " " .. dir_name)
		else
			if depth == 5 and not has_dir_newline then
				has_dir_newline = true
				table.insert(lines, "")
			end

			local indent = string.rep("  ", depth - 5)
			table.insert(lines, indent .. "- **" .. dir_name .. "**")
		end

		render_tree(subtree, lines, depth + 1, relpath .. dir_name .. "/")
	end
end

local function same_file(buf, path)
	local bufname = vim.api.nvim_buf_get_name(buf)
	if bufname == "" then
		return false
	end
	local realbuf = vim.loop.fs_realpath(bufname)
	local realpath = vim.loop.fs_realpath(path)
	return realbuf == realpath
end

local function heading_to_block(heading)
	local font_data = require("wiki.font")
	local font = font_data[6] -- Get the 6-line font
	local block_chars = {}

	-- Convert heading to uppercase to match font keys
	local upper_heading = string.upper(heading)

	-- Process each character in the heading
	for i = 1, #upper_heading do
		local char = upper_heading:sub(i, i)

		-- Check if the character exists in the font (letters A-Z and digits 0-9)
		if font[char] then
			table.insert(block_chars, font[char])
		end
	end

	-- If no valid characters were found, return empty
	if #block_chars == 0 then
		return {}
	end

	-- Combine the characters row by row
	local result_lines = {}
	for row = 1, 6 do -- Since each character is 6 lines tall
		local line = ""
		for _, char_block in ipairs(block_chars) do
			line = line .. char_block[row]
		end
		table.insert(result_lines, line)
	end

	return result_lines
end

function M.generate()
	local root = config.pages_dir
	local tree = build_tree(root)

	-- local lines = { heading_to_block("# Wiki") }
	local lines = { "# Wiki" }

	render_tree(tree, lines, 0, "pages/")

	vim.fn.writefile(lines, config.index_file)

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and same_file(buf, config.index_file) then
			vim.cmd.edit(config.index_file)
		end
	end

	print("Wiki index generated.")
end

return M
