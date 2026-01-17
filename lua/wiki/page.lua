local fs = require("wiki.fs")
local config = require("wiki.config")

local M = {}

local function ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

function M.new_page(relative_path)
	local fullpath = config.pages_dir .. "/" .. relative_path
	local dir = vim.fn.fnamemodify(fullpath, ":h")
	ensure_dir(dir)

	if vim.fn.filereadable(fullpath) == 1 then
		print("Page already exists: " .. fullpath)
	else
		local file = io.open(fullpath, "w")
		if file then
			file:write("# " .. vim.fn.fnamemodify(relative_path, ":t") .. "\n\n")
			file:close()
			print("New wiki page created: " .. fullpath)
			vim.cmd.edit(fullpath)
		else
			print("Error creating page: " .. fullpath)
		end
	end
end

return M
