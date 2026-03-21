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
    writefile = function(lines, path)
      return 1
    end,
    readfile = function(path)
      return {}
    end,
    esc = function(s)
      return s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', "%%%1")
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
    esc = function(s)
      return s
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
  },
  opt = {
    tags = {
      append = function() end,
    },
  },
  cmd = function() end,
  BO = {
    filetypes = {},
  },
}

local function run_tests()
  package.path = "./lua/?.lua;" .. package.path

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

  print("=== Testing FS Module ===\n")

  print("--- Module loads ---")
  local fs
  local success, result = pcall(function()
    fs = require("wiki.fs")
  end)
  assert_true(success, "fs module loads without error")

print("\n--- Module exports ---")
assert_eq(type(fs), "table", "fs is a table")
assert_eq(type(fs.ensure), "function", "fs.ensure is a function")

print("\n--- ensure function ---")
local success = pcall(function()
  fs.ensure()
end)
assert_true(success, "ensure runs without error")

  print("\n=== Test Summary ===")
  print("Passed: " .. passed)
  print("Failed: " .. failed)

  if failed > 0 then
    print("\nTESTS FAILED")
    os.exit(1)
  else
    print("\nALL TESTS PASSED")
  end
end

run_tests()
