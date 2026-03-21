vim = {
  fn = {
    expand = function(s)
      if s == "~/wiki" then
        return os.getenv("HOME") .. "/wiki"
      end
      return s
    end,
    readfile = function(path)
      return {}
    end,
    writefile = function(lines, path)
      return 1
    end,
    esc = function(s)
      return s
    end,
    pesc = function(s)
      return s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', "%%%1")
    end,
    isdirectory = function(path)
      return true
    end,
    mkdir = function(path, flags)
      return true
    end,
  },
  loop = {
    fs_scandir = function(path)
      return nil
    end,
    fs_scandir_next = function(handle)
      return nil
    end,
    fs_realpath = function(path)
      return path
    end,
  },
  api = {
    nvim_get_current_buf = function()
      return 1
    end,
    nvim_buf_get_name = function(buf)
      return ""
    end,
    nvim_buf_is_loaded = function(buf)
      return false
    end,
    nvim_list_bufs = function()
      return {}
    end,
    nvim_get_current_line = function()
      return "- [Link](file.md)"
    end,
  },
  opt = {
    tags = {
      append = function() end,
    },
  },
  cmd = function(cmd)
    -- mock
  end,
  bo = {
    [1] = {},
  },
  keymap = {
    set = function() end,
  },
}

package.path = "./lua/?.lua;" .. package.path

-- Mock modules before requiring init
local config_setup_called = false
package.loaded["wiki.config"] = {
  setup = function(cfg)
    config_setup_called = true
  end,
  root = "~/wiki",
  pages_dir = "~/wiki/pages",
  index_file = "~/wiki/index.md",
}

local index_generate_called = false
package.loaded["wiki.index"] = {
  generate = function()
    index_generate_called = true
  end
}

local fs_ensure_called = false
package.loaded["wiki.fs"] = {
  ensure = function()
    fs_ensure_called = true
  end
}

local search_live_grep_called = false
package.loaded["wiki.search"] = {
  live_grep = function()
    search_live_grep_called = true
  end
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

print("=== Testing Init Module ===\n")

print("--- Module loads ---")
local init
local success, result = pcall(function()
  init = require("wiki.init")
end)
assert_true(success, "init module loads without error")

print("\n--- Module exports ---")
assert_eq(type(init), "table", "init is a table")
assert_eq(type(init.setup), "function", "init.setup is a function")
assert_eq(type(init.open_index), "function", "init.open_index is a function")
assert_eq(type(init.setup_buffer), "function", "init.setup_buffer is a function")
assert_eq(type(init.generate_index), "function", "init.generate_index is a function")
assert_eq(type(init.search), "function", "init.search is a function")

print("\n--- Setup function ---")
init.setup({})
assert_true(config_setup_called, "setup calls config.setup")

print("\n--- Generate index function ---")
init.generate_index()
assert_true(index_generate_called, "generate_index calls index.generate")

print("\n--- Search function ---")
init.search()
assert_true(fs_ensure_called, "search calls fs.ensure")
assert_true(search_live_grep_called, "search calls search.live_grep")

print("\n--- open_index function ---")
init.open_index()

print("\n--- setup_buffer function ---")
init.setup_buffer()

print("\n=== Test Summary ===")
print("Passed: " .. passed)
print("Failed: " .. failed)

if failed > 0 then
  print("\nTESTS FAILED")
  os.exit(1)
else
  print("\nALL TESTS PASSED")
end