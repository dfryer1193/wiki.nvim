local config = require 'wiki.config'

local M = {}

function M.live_grep()
  require('telescope.builtin').live_grep {
    prompt_title = 'Wiki Search',
    search_dirs = { config.root },
  }
end

return M
