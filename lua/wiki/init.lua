local config = require 'wiki.config'
local index = require 'wiki.index'
--local search = require("wiki.search")

local M = {}

function M.open_index()
  vim.cmd('edit ' .. config.index_file)
end

function M.generate_index()
  index.generate()
end

--function M.search()
--  search.live_grep()
--end

return M
