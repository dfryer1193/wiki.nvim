local function run_tests()
  package.path = "./lua/?.lua;" .. package.path
  local font = require("wiki.font")

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

  local function assert_table_eq(actual, expected, msg)
    local function deep_equal(a, b)
      if type(a) ~= type(b) then return false end
      if type(a) ~= "table" then return a == b end
      for k, v in pairs(a) do
        if not deep_equal(v, b[k]) then return false end
      end
      for k, v in pairs(b) do
        if not deep_equal(v, a[k]) then return false end
      end
      return true
    end

    if deep_equal(actual, expected) then
      passed = passed + 1
      print("PASS: " .. msg)
    else
      failed = failed + 1
      print("FAIL: " .. msg)
    end
  end

  print("=== Testing Font Module ===\n")

  print("--- Font height 6 (6-line block letters) ---")
  local expected_A = {
    " █████╗ ",
    "██╔══██╗",
    "███████║",
    "██╔══██║",
    "██║  ██║",
    "╚═╝  ╚═╝",
  }
  assert_table_eq(font[6]["A"], expected_A, "Font 6 - A (block letter)")

  local expected_W = {
    "██╗    ██╗",
    "██║    ██║",
    "██║ █╗ ██║",
    "██║███╗██║",
    "╚███╔███╔╝",
    " ╚══╝╚══╝ ",
  }
  assert_table_eq(font[6]["W"], expected_W, "Font 6 - W (block letter)")

  local expected_space = {
    "        ",
    "        ",
    "        ",
    "        ",
    "        ",
    "        ",
  }
  assert_table_eq(font[6][" "], expected_space, "Font 6 - space")

  local expected_0 = {
    " ██████╗ ",
    "██╔═══██╗",
    "██║   ██║",
    "██║   ██║",
    "╚██████╔╝",
    " ╚═════╝ ",
  }
  assert_table_eq(font[6][0], expected_0, "Font 6 - 0 (block digit)")

  local expected_1 = {
    " ██╗",
    "███║",
    "╚██║",
    " ██║",
    " ██║",
    " ╚═╝",
  }
  assert_table_eq(font[6][1], expected_1, "Font 6 - 1 (block digit)")

  local expected_2 = {
    "██████╗ ",
    "╚════██╗",
    " █████╔╝",
    "██╔═══╝ ",
    "███████╗",
    "╚══════╝",
  }
  assert_table_eq(font[6][2], expected_2, "Font 6 - 2 (block digit)")

  print("\n--- All font heights available ---")
  assert_eq(font[6] ~= nil, true, "Font height 6 exists")

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
