vim = {
  fn = {
    expand = function(s)
      if s == "~/wiki" then
        return os.getenv("HOME") .. "/wiki"
      end
      return s
    end,
    isdirectory = function(path)
      return 0
    end,
    mkdir = function(path, flags)
      return 1
    end,
    filereadable = function(path)
      return 0
    end,
    fnamemodify = function(path, modifier)
      if modifier == ":h" then
        local dir = path:match("(.*)/")
        return dir or ""
      end
      if modifier == ":t" then
        return path:match("([^/]+)$") or path
      end
      return path
    end,
    input = function(opts)
      return ""
    end,
  },
  loop = {
    fs_realpath = function(path)
      return path
    end,
  },
  api = {
    nvim_get_current_buf = function()
      return 1
    end,
  },
  cmd = {
    edit = function(path)
      print("vim.cmd.edit called with: " .. tostring(path))
    end,
  },
}

package.path = "./lua/?.lua;" .. package.path

-- Mock modules before requiring
package.loaded["wiki.config"] = {
  pages_dir = "/tmp/wiki/pages"
}

-- Mock io for testing
local io_open_called = false
local io_write_content = ""
local filereadable_results = {}
local io_open_results = {}

vim.fn.filereadable = function(path)
  return filereadable_results[path] or 0
end

_G.io = {
  open = function(path, mode)
    if io_open_results[path] == false then
      return nil
    end
    io_open_called = true
    return {
      write = function(self, content)
        io_write_content = content
        print("write called with: " .. tostring(content))
      end,
      close = function(self) end,
    }
  end,
}

local passed = 0
local failed = 0

local function assert_eq(actual, expected, msg)
  if actual == expected then
    passed = passed + 1
    print("PASS: " .. msg)
  else
    failed = failed + 1
    print("FAIL: " .. msg .. " - expected: " .. tostring(expected) .. ", got: " .. tostring(actual))
  end
end

local function assert_true(val, msg)
  if val == true then
    passed = passed + 1
    print("PASS: " .. msg)
  else
    failed = failed + 1
    print("FAIL: " .. msg .. " - expected true, got: " .. tostring(val))
  end
end

print("=== Testing Page Module ===\n")

print("--- Module loads ---")
local page
local success, result = pcall(function()
  page = require("wiki.page")
end)
assert_true(success, "page module loads without error")

print("\n--- Module exports ---")
assert_eq(type(page), "table", "page is a table")
assert_eq(type(page.new_page), "function", "page.new_page is a function")

print("\n--- new_page function ---")
page.new_page("test.md")
assert_true(io_open_called, "new_page opens file for writing")
assert_eq(io_write_content, "# test.md\n\n", "new_page writes correct content")

print("\n--- new_page existing ---")
filereadable_results["/tmp/wiki/pages/existing.md"] = 1
page.new_page("existing.md")

print("\n--- new_page error ---")
io_open_results["/tmp/wiki/pages/error.md"] = false
page.new_page("error.md")

print("\n=== Test Summary ===")
print("Passed: " .. passed)
print("Failed: " .. failed)

if failed > 0 then
  print("\nTESTS FAILED")
  os.exit(1)
else
  print("\nALL TESTS PASSED")
end
