local config = require("wiki.config")

local M = {}

local function ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

function M.ensure()
	ensure_dir(config.root)
	ensure_dir(config.pages_dir)

	if vim.fn.filereadable(config.index_file) == 0 then
		vim.fn.writefile({ "# Empty Wiki!" }, config.index_file)
	end
end

return M
