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
			table.insert(tree.files, entry.name)
		end
	end

	return tree
end

local function render_tree(tree, lines, depth, relpath)
	relpath = relpath or ""

	for dir_name, subtree in pairs(tree.dirs) do
		if depth < 5 then
			table.insert(lines, "")
			table.insert(lines, string.rep("#", depth + 2) .. " " .. dir_name)
			table.insert(lines, "")
		else
			local indent = string.rep("\t", depth - 5)
			table.insert(lines, indent .. "- **" .. dir_name .. "**")
			table.insert(lines, "")
		end

		render_tree(subtree, lines, depth + 1, relpath .. dir_name .. "/")
	end

	if #tree.files > 0 then
		local file_indent = ""
		if depth >= 5 then
			file_indent = string.rep("\t", depth - 5)
		end

		for _, file in ipairs(tree.files) do
			local name = file:gsub("%.md$", "")
			table.insert(lines, string.format("%s- [%s](%s%s)", file_indent, name, relpath, file))
		end
	end
end

function M.generate()
	local root = config.pages_dir
	local tree = build_tree(root)

	local lines = { "# Wiki", "" }

	render_tree(tree, lines, 0, "pages/")

	vim.fn.writefile(lines, config.index_file)
end

return M
