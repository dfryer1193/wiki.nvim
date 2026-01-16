local config = require 'wiki.config'

local M = {}

local function get_pages()
  local files = vim.fn.glob(config.pages_dir .. '/**/*.md', true, true)
  local pages = {}

  for _, file in ipairs(files) do
    local stat = vim.loop.fs_stat(file)
    if stat then
      table.insert(pages, {
        path = file,
        mtime = stat.mtime.sec,
      })
    end
  end

  table.sort(pages, function(a, b)
    return a.mtime > b.mtime
  end)

  return pages
end

local function ensure_dir(path)
  local stat = vim.loop.fs_stat(path)
  if not stat then
    vim.fn.mkdir(path, 493) -- 493 = 0755 in octal
  end
end

local function ensure_wiki()
  ensure_dir(config.root)
  ensure_dir(config.pages_dir)
end

function M.generate()
  ensure_wiki()

  local pages = get_pages()
  local lines = {}

  table.insert(lines, '# Wiki Index\n')
  for _, page in ipairs(pages) do
    local date = os.date('%Y-%m-%d', page.mtime)
    local rel_path = page.path:gsub('^' .. config.root .. '/', '')
    local title = vim.fn.fnamemodify(rel_path, ':t:r')

    table.insert(lines, string.format('- [%s](%s) - %s', title, rel_path, date))
  end

  vim.fn.writefile(lines, config.index_file)
  vim.notify('Wiki index generated at ' .. config.index_file, vim.log.levels.INFO)
end

return M
