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

local function read_first_h1(filepath)
	local lines = vim.fn.readfile(filepath)
	if not lines then
		return nil
	end
	for _, line in ipairs(lines) do
		local h1_text = line:match("^#%s+(.+)$")
		if h1_text then
			return h1_text
		end
	end
	return nil
end

local function get_link_text(filepath, filename)
  local h1 = read_first_h1(filepath)
  if h1 then
    return h1
  end
  local fallback = filename and filename:gsub("%.md$", "") or "unknown"
  return fallback
end

local function heading_to_block(heading, depth)
	local font_data = require("wiki.font")
	local font_height = math.max(1, 6 - depth)
	local font = font_data[font_height]
	local block_chars = {}

	local upper_heading = string.upper(heading)

	for i = 1, #upper_heading do
		local char = upper_heading:sub(i, i)
		if font[char] then
			table.insert(block_chars, font[char])
		end
	end

	if #block_chars == 0 then
		return {}
	end

	local result_lines = {}
	for row = 1, font_height do
		local line = ""
		for _, char_block in ipairs(block_chars) do
			line = line .. char_block[row]
		end
		table.insert(result_lines, line)
	end

	return result_lines
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

		local link_text = get_link_text(full_path, fname)
		local relative_path = full_path:sub(#config.pages_dir + 2)
		table.insert(lines, string.format("%s- [%s](%s)", file_indent, link_text, relative_path))
	end

	local has_dir_newline = false
	for dir_name, subtree in pairs(tree.dirs) do
		if depth < 5 then
			table.insert(lines, "")
			local block_lines = heading_to_block(dir_name, depth)
			for _, block_line in ipairs(block_lines) do
				table.insert(lines, block_line)
			end
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

local function find_files(path, files)
	files = files or {}
	for _, entry in ipairs(scandir(path)) do
		local full_path = path .. "/" .. entry.name
		if entry.type == "directory" then
			find_files(full_path, files)
		else
			if entry.name:match("%.md$") then
				table.insert(files, { name = entry.name, path = full_path })
			end
		end
	end
	return files
end

local function normalize_to_tag(text)
	return text:gsub("%s+", "-"):gsub("[^%w%-]", ""):lower()
end

local function read_all_headings(filepath)
	local lines = vim.fn.readfile(filepath)
	if not lines then
		return {}
	end

	local headings = {}
	for line_num, line in ipairs(lines) do
		local level, text = line:match("^(#+)%s+(.+)$")
		if level and text then
			local tag_name = normalize_to_tag(text)
			local pattern = "/^" .. vim.pesc(line) .. "$/"
			table.insert(headings, {
				tag = tag_name,
				pattern = pattern,
				line = line_num,
				text = text,
			})
		end
	end
	return headings
end

local function generate_tags()
	local files = find_files(config.pages_dir)
	local lines = { '!_TAG_FILE_FORMAT\t2\t/extended format; --format=1 will not append ;" to lines/' }

	for _, file in ipairs(files) do
		local rel_path = file.path:sub(#config.pages_dir + 2)
		local tag_name = rel_path:gsub("%.md$", ""):lower():gsub("/", "-")
		table.insert(lines, string.format("%s\t%s\t1", tag_name, file.path))

		local headings = read_all_headings(file.path)
		for _, heading in ipairs(headings) do
			table.insert(lines, string.format("%s\t%s\t%s", heading.tag, file.path, heading.pattern))
		end
	end

	vim.fn.writefile(lines, config.root .. "/tags")
end

function M.generate()
	local root = config.pages_dir
	local tree = build_tree(root)

	local lines = {}
	local wiki_block = heading_to_block("Wiki", 0)
	for _, line in ipairs(wiki_block) do
		table.insert(lines, line)
	end

	render_tree(tree, lines, 0, "pages/")

	vim.fn.writefile(lines, config.index_file)
	generate_tags()

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and same_file(buf, config.index_file) then
			vim.cmd("edit " .. config.index_file)
		end
	end

	print("Wiki index generated.")
end

return M
