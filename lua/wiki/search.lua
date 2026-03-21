local config = require 'wiki.config'

local M = {}

function M.live_grep()
  local success, telescope = pcall(require, "telescope")
  if not success then
    print("Error: telescope.nvim is required for search. Install with your package manager.")
    return
  end

  local success_builtin, builtin = pcall(require, "telescope.builtin")
  if not success_builtin then
    print("Error: telescope.builtin is required for search. Install with your package manager.")
    return
  end

  builtin.live_grep {
    prompt_title = 'Wiki Search',
    search_dirs = { config.root },
  }
end

return M
