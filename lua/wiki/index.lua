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

	for fname, full_path in pairs(tree.files) do
		local file_indent = ""
		if depth >= 5 then
			file_indent = string.rep("  ", depth - 5)
		end

		local name = fname:gsub("%.md$", "")
		table.insert(lines, string.format("%s- [%s](%s%s)", file_indent, name, relpath, fname))
	end

	for dir_name, subtree in pairs(tree.dirs) do
		if depth < 5 then
			table.insert(lines, "")
			table.insert(lines, string.rep("#", depth + 2) .. " " .. dir_name)
		else
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

function M.generate()
	local root = config.pages_dir
	local tree = build_tree(root)

	local lines = { "# Wiki", "" }

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
