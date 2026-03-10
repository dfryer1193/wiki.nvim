vim = {
  fn = {
    expand = function(s)
      if s == "~/wiki" then
        return os.getenv("HOME") .. "/wiki"
      end
      return s
    end,
  },
}

package.path = "./lua/?.lua;" .. package.path

package.loaded["telescope.builtin"] = {
  live_grep = function(opts) end
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

print("=== Testing Search Module ===\n")

print("--- Module loads ---")
local search
local success, result = pcall(function()
  search = require("wiki.search")
end)
assert_true(success, "search module loads without error")

print("\n--- Module exports ---")
assert_eq(type(search), "table", "search is a table")
assert_eq(type(search.live_grep), "function", "search.live_grep is a function")

print("\n--- live_grep function ---")
local success = pcall(function()
  search.live_grep()
end)
assert_true(success, "live_grep runs without error")

print("\n=== Test Summary ===")
print("Passed: " .. passed)
print("Failed: " .. failed)

if failed > 0 then
  print("\nTESTS FAILED")
  os.exit(1)
else
  print("\nALL TESTS PASSED")
end
