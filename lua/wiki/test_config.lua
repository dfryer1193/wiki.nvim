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

local function run_tests()
  package.path = "./lua/?.lua;" .. package.path

  package.loaded["wiki.config"] = nil
  local config = require("wiki.config")

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

  local function assert_contains(haystack, needle, msg)
    if haystack and needle and string.find(haystack, needle, 1, true) then
      passed = passed + 1
      print("PASS: " .. msg)
    else
      failed = failed + 1
      print("FAIL: " .. msg .. " - expected to contain: " .. tostring(needle))
    end
  end

  print("=== Testing Config Module ===\n")

  print("--- Default configuration ---")
  assert_eq(type(config.root), "string", "root is a string")
  assert_eq(type(config.pages_dir), "string", "pages_dir is a string")
  assert_eq(type(config.index_file), "string", "index_file is a string")

  print("\n--- Configuration relationships ---")
  assert_contains(config.pages_dir, "/pages", "pages_dir contains /pages")
  assert_contains(config.index_file, "index.md", "index_file contains index.md")

  print("\n--- Setup function exists ---")
  assert_eq(type(config.setup), "function", "setup is a function")

  print("\n--- Setup modifies config ---")
  config.setup({ root = "/test/wiki" })
  assert_eq(config.root, "/test/wiki", "root updated after setup")
  assert_eq(config.pages_dir, "/test/wiki/pages", "pages_dir updated after setup")
  assert_eq(config.index_file, "/test/wiki/index.md", "index_file updated after setup")

  config.setup({ root = "~/my-wiki" })
  assert_eq(config.root, "~/my-wiki", "root updated with tilde path")
  assert_eq(config.pages_dir, "~/my-wiki/pages", "pages_dir updated with tilde path")

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
