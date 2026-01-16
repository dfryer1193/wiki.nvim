local M = {}

M.root = vim.fn.expand '~/wiki'
M.pages_dir = M.root .. '/pages'
M.index_file = M.root .. '/index.md'

return M
