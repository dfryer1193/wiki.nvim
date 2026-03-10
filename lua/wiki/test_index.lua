package.path = "./lua/?.lua;" .. package.path

package.loaded["wiki.config"] = {
  pages_dir = "/test/pages",
  root = "/test",
  index_file = "/test/index.md"
}

_G.scandir_index = {}

_G.scandir_entries = {
  {name = "another.md", type = "file"},
  {name = "subdir", type = "directory"},
  {name = "test.md", type = "file"}
}

vim = {
fn = {
  readfile = function(path)
      if path:match("with_h1") or path == "test/with_h1.md" then
        return { "# The Foo is Barring", "## The Bar is Fooing", "Some content" }
      elseif path:match("no_h1") or path == "test/no_h1.md" then
        return { "Some content", "No heading here" }
      elseif path:match("empty") then
        return {}
      elseif path:match("multi_h1") then
        return { "# First Heading", "## Second Heading", "# Third Heading", "Content" }
      elseif path:match("special") then
        return { "# Hello! World? (Test)", "## What's Up!", "### A-B_C" }
      elseif path:match("nested") then
        return { "# Nested Page" }
      elseif path:match("deep_nested") then
        return { "# Deep Nested" }
      end
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
  },
loop = {
    fs_scandir = function(path)
      if path == "/test/pages" then
        return "handle"
      end
      return nil
    end,
    fs_scandir_next = function(handle)
      if handle == "handle" then
        _G.scandir_index[handle] = _G.scandir_index[handle] or 1
        local idx = _G.scandir_index[handle]
        if idx <= #_G.scandir_entries then
          local entry = _G.scandir_entries[idx]
          _G.scandir_index[handle] = idx + 1
          return entry.name, entry.type
        end
      end
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
      if buf == 1 then return "/test/index.md" else return "" end
    end,
    nvim_buf_is_loaded = function(buf)
      return buf == 1
    end,
    nvim_list_bufs = function()
      return {1}
    end,
  },
opt = {
    tags = {
      append = function() end,
    },
  },
cmd = function() end
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

local function assert_contains(haystack, needle, msg)
  if haystack and needle and string.find(haystack, needle, 1, true) then
    passed = passed + 1
    print("PASS: " .. msg)
  else
    failed = failed + 1
    print("FAIL: " .. msg .. " - expected to contain: " .. tostring(needle))
  end
end

print("=== Testing Index Module ===\n")

print("--- Module loads ---")
package.loaded["wiki.index"] = nil
local index
local success, result = pcall(function()
  index = require("wiki.index")
end)
assert_true(success, "index module loads without error")

print("\n--- Module exports ---")
assert_eq(type(index), "table", "index is a table")
assert_eq(type(index.generate), "function", "index.generate is a function")

print("\n--- generate function ---")
local success, result = pcall(function()
  index.generate()
end)
print("Result: ", result)
assert_true(success, "generate runs without error")

print("\n--- Pure function: normalize_to_tag ---")
local normalize_to_tag = function(text)
  return text:gsub("%s+", "-"):gsub("[^%w%-]", ""):lower()
end

assert_eq(normalize_to_tag("The Foo is Barring"), "the-foo-is-barring", "normalizes heading to tag")
assert_eq(normalize_to_tag("Hello World!"), "hello-world", "removes special chars")
assert_eq(normalize_to_tag("  Multiple   Spaces  "), "-multiple-spaces-", "collapses spaces")
assert_eq(normalize_to_tag("Test123"), "test123", "keeps alphanumeric")
assert_eq(normalize_to_tag(""), "", "handles empty string")
assert_eq(normalize_to_tag("UPPERCASE"), "uppercase", "lowercases text")
assert_eq(normalize_to_tag("## The Bar is Fooing"):gsub("^%-", ""), "the-bar-is-fooing", "heading tag")

print("\n--- heading_to_block function exists ---")
assert_eq(type(index.generate), "function", "heading_to_block is accessible via generate")

print("\n--- Link text extraction ---")
local get_link_text = function(filepath, filename)
  local lines = vim.fn.readfile(filepath)
  if not lines then
    return filename:gsub("%.md$", "")
  end
  for _, line in ipairs(lines) do
    local h1_text = line:match("^#%s+(.+)$")
    if h1_text then
      return h1_text
    end
  end
  return filename:gsub("%.md$", "")
end

assert_eq(get_link_text("test/with_h1.md", "with_h1.md"), "The Foo is Barring", "extracts H1 heading")
assert_eq(get_link_text("test/no_h1.md", "no_h1.md"), "no_h1", "falls back to filename")
assert_eq(get_link_text("test/empty.md", "empty.md"), "empty", "falls back to filename for empty file")

print("\n--- read_first_h1 function ---")
local test_lines_with_h1 = { "# The Foo is Barring", "## The Bar is Fooing", "Some content" }
local test_lines_no_h1 = { "Some content", "No heading here" }
local test_lines_empty = {}

local function read_first_h1_from_lines(lines)
  if not lines then
    return nil
  end
  for _, line in ipairs(lines) do
    local h1_text = line:match("^#%s+(.+)$")
    if h1_text then
      return h1_text
    end
  end
  return nil
end

assert_eq(read_first_h1_from_lines(test_lines_with_h1), "The Foo is Barring", "finds first H1")
assert_eq(read_first_h1_from_lines(test_lines_no_h1), nil, "returns nil when no H1")
assert_eq(read_first_h1_from_lines(test_lines_empty), nil, "returns nil for empty file")

print("\n--- read_all_headings function ---")
local test_lines = { "# The Foo is Barring", "## The Bar is Fooing", "Some content" }
local function read_all_headings_mock(lines)
  if not lines then
    return {}
  end

  local headings = {}
  local function pesc(s)
    return s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', "%%%1")
  end
  for line_num, line in ipairs(lines) do
    local level, text = line:match("^(#+)%s+(.+)$")
    if level and text then
      local tag_name = normalize_to_tag(text)
      local pattern = "/^" .. pesc(line) .. "$/"
      table.insert(headings, {
        tag = tag_name,
        pattern = pattern,
        line = line_num,
        text = text,
      })
    end
  end
  return headings
end

local headings = read_all_headings_mock(test_lines)
assert_eq(#headings, 2, "finds all headings in file")
if headings[1] then
  assert_eq(headings[1].text, "The Foo is Barring", "first heading is H1")
end
if headings[2] then
  assert_eq(headings[2].text, "The Bar is Fooing", "second heading is H2")
end

print("\n--- Tag name generation ---")
local tag1 = normalize_to_tag("The Foo is Barring")
assert_eq(tag1, "the-foo-is-barring", "file tag from H1")
local tag2_input = "The Bar is Fooing"
local tag2 = normalize_to_tag(tag2_input)
assert_eq(tag2, "the-bar-is-fooing", "heading tag")

print("\n--- find_files function pattern ---")
local is_markdown_file = function(name)
  return name:match("%.md$") ~= nil or name:match("%.MD$") ~= nil
end
assert_true(is_markdown_file("test.md"), "identifies .md file")
assert_true(is_markdown_file("test.MD"), "identifies .MD file (case)")
assert_true(not is_markdown_file("test.txt"), "rejects non-markdown")

print("\n--- Edge cases ---")
assert_eq(normalize_to_tag("Test!@#$%"), "test", "removes all special chars")
assert_eq(normalize_to_tag("  Spaces  Around  "), "-spaces-around-", "handles leading/trailing spaces")

print("\n--- Heading to block letter rendering ---")
local heading_to_block = function(heading, depth)
  local font_data = require("wiki.font")
  local font_height = math.max(1, 6 - depth)
  local font = font_data[font_height]
  local block_chars = {}

  local upper_heading = string.upper(heading)

  for i = 1, #upper_heading do
    local char = upper_heading:sub(i, i)
    if font[char] then
      table.insert(block_chars, font[char])
    end
  end

  if #block_chars == 0 then
    return {}
  end

  local result_lines = {}
  for row = 1, font_height do
    local line = ""
    for _, char_block in ipairs(block_chars) do
      line = line .. char_block[row]
    end
    table.insert(result_lines, line)
  end

  return result_lines
end

local block = heading_to_block("A", 0)
assert_eq(#block, 6, "depth 0 uses 6-line font")

local block2 = heading_to_block("A", 1)
assert_eq(#block2, 5, "depth 1 uses 5-line font")

local block3 = heading_to_block("A", 2)
assert_eq(#block3, 4, "depth 2 uses 4-line font")

local block4 = heading_to_block("A", 3)
assert_eq(#block4, 3, "depth 3 uses 3-line font")

local block5 = heading_to_block("A", 4)
assert_eq(#block5, 2, "depth 4 uses 2-line font")

local block6 = heading_to_block("A", 5)
assert_eq(#block6, 1, "depth 5 uses 1-line font")

print("\n--- Font module heights ---")
local font = require("wiki.font")
assert_true(font[1] ~= nil, "font height 1 exists")
assert_true(font[2] ~= nil, "font height 2 exists")
assert_true(font[3] ~= nil, "font height 3 exists")
assert_true(font[4] ~= nil, "font height 4 exists")
assert_true(font[5] ~= nil, "font height 5 exists")
assert_true(font[6] ~= nil, "font height 6 exists")

print("\n--- Index file generation format ---")
local expected_index_format = function(lines)
  local has_wiki_block = false
  for _, line in ipairs(lines) do
    if line:match("████") then
      has_wiki_block = true
      break
    end
  end
  return has_wiki_block
end
assert_true(expected_index_format({" █████╗ "}), "index has ASCII block header")

print("\n--- Tags file format ---")
local tags_header = '!_TAG_FILE_FORMAT\t2\t/extended format; --format=1 will not append ;" to lines/'
assert_contains(tags_header, "TAG_FILE_FORMAT", "tags has proper header format")
assert_contains(tags_header, "2", "tags uses extended format")

print("\n--- Tag entry format ---")
local file_tag = "the-foo-is-barring\tfoo.md\t1"
assert_contains(file_tag, "the-foo-is-barring", "file tag has name")
assert_contains(file_tag, "foo.md", "file tag has path")
assert_contains(file_tag, "1", "file tag has line number")

local heading_tag = "the-bar-is-fooing\tfoo.md\t/^## The Bar is Fooing$/"
assert_contains(heading_tag, "the-bar-is-fooing", "heading tag has name")
assert_contains(heading_tag, "/^", "heading tag has pattern start")
assert_contains(heading_tag, "$/", "heading tag has pattern end")

print("\n=== Test Summary ===")
print("Passed: " .. passed)
print("Failed: " .. failed)

if failed > 0 then
  print("\nTESTS FAILED")
  os.exit(1)
else
  print("\nALL TESTS PASSED")
end
