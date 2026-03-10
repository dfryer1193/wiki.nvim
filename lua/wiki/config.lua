local M = {}

M.root = vim.fn.expand("~/wiki")
M.pages_dir = M.root .. "/pages"
M.index_file = M.root .. "/index.md"

function M.setup(opts)
	opts = opts or {}

	if opts.root then
		M.root = opts.root
		M.pages_dir = M.root .. "/pages"
		M.index_file = M.root .. "/index.md"
	end
end

return M
