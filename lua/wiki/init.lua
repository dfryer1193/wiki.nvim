local config = require("wiki.config")
local index = require("wiki.index")
local search = require("wiki.search")
local fs = require("wiki.fs")

local M = {}

function M.setup(user_config)
	config.setup(user_config or {})
end

function M.open_index()
	fs.ensure()
	vim.cmd.edit(config.index_file)
end

function M.generate_index()
	index.generate()
end

function M.search()
	fs.ensure()
	search.live_grep()
end

return M
