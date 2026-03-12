local config = require("wiki.config")
local index = require("wiki.index")
local search = require("wiki.search")
local fs = require("wiki.fs")

local M = {}

function M.setup(user_config)
	config.setup(user_config or {})
end

local function resolve_path(path, current_buf)
	if not path:match("^/") and not path:match("^%a:") then
		local current_file = vim.api.nvim_buf_get_name(current_buf)
		local current_dir = current_file:match("^(.*)/")

		-- Check if we're in the pages directory or a subdirectory
		if current_dir and current_dir:sub(1, #config.pages_dir) == config.pages_dir then
			return current_dir .. "/" .. path
		end

		-- Check if path already includes pages/ prefix
		if path:sub(1, 6) == "pages/" then
			return config.pages_dir .. "/" .. path:sub(7)
		end

		-- Otherwise, resolve relative to pages directory
		return config.pages_dir .. "/" .. path
	end
	return path
end

local function open_link(is_index_buffer)
	local line = vim.api.nvim_get_current_line()
	local current_buf = vim.api.nvim_get_current_buf()

	if is_index_buffer then
		local path, anchor = string.match(line, "%(([^#)%)]+)#([^)]+)%)")
		if not path then
			path, anchor = string.match(line, "%(([^)]+)%)")
		end

		if path then
			local full_path = resolve_path(path, current_buf)
			full_path = full_path:gsub("%s+$", "")

			local rel_path = full_path:sub(#config.pages_dir + 2)
			local tag_name = rel_path:gsub("%.md$", ""):gsub("/", "-")

			if vim.fn.filereadable(full_path) == 1 then
				vim.cmd("tag! " .. tag_name)
				if anchor then
					local anchor_tag = anchor:gsub("%-", " ")
					vim.cmd("tag " .. vim.fn.escape(anchor_tag, " "))
				end
				local newbuf = vim.api.nvim_get_current_buf()
				vim.bo[newbuf].filetype = "markdown"
				vim.bo[newbuf].modifiable = true
				vim.bo[newbuf].readonly = false
			else
				print("File not found: " .. full_path)
			end
		end
	else
		local col = vim.fn.col(".") - 1
		local path, anchor = string.match(line, "%(([^#)%)]+)#([^)]+)%)")
		if not path then
			path, anchor = string.match(line, "%(([^)]+)%)")
		end

		if path and col >= 0 then
			local line_start = line:match("^%[.*%]%(")
			if line_start then
				local link_start = #line_start
				local link_end = line:find("%)$", link_start, true)
				if link_start and link_end and (col < link_start or col > link_end) then
					path = nil
				end
			end
		end

		if path then
			local full_path = resolve_path(path, current_buf)
			full_path = full_path:gsub("%s+$", "")

			local rel_path = full_path:sub(#config.pages_dir + 2)
			local tag_name = rel_path:gsub("%.md$", ""):gsub("/", "-")

			if vim.fn.filereadable(full_path) == 1 then
				vim.cmd("tag! " .. tag_name)
				if anchor then
					local anchor_tag = anchor:gsub("%-", " ")
					vim.cmd("tag " .. vim.fn.escape(anchor_tag, " "))
				end
				local newbuf = vim.api.nvim_get_current_buf()
				vim.bo[newbuf].filetype = "markdown"
				vim.bo[newbuf].modifiable = true
				vim.bo[newbuf].readonly = false
			else
				print("File not found: " .. full_path)
			end
		end
	end
end

function M.open_index()
	fs.ensure()
	index.generate()

	local lines = vim.fn.readfile(config.index_file)
	if not lines then
		lines = { "# Empty Wiki!" }
	end

	vim.cmd("enew")
	local buf = vim.api.nvim_get_current_buf()

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_name(buf, "wiki-index")

	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].syntax = "markdown"
	vim.bo[buf].modified = false

	vim.keymap.set("n", "<CR>", function() open_link(true) end, { noremap = true, silent = true, buffer = buf })
	vim.keymap.set("n", "<C-]>", function() open_link(true) end, { noremap = true, silent = true, buffer = buf })
end

function M.setup_buffer()
	local buf = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(buf)

	local is_index_named = bufname == "wiki-index"
	local is_in_pages = bufname:sub(1, #config.pages_dir) == config.pages_dir
	local is_index_file = bufname == config.index_file

	if is_index_named or is_in_pages then
		vim.bo[buf].filetype = "markdown"

		if is_index_named then
			vim.bo[buf].modifiable = false
			vim.bo[buf].readonly = true
			vim.keymap.set("n", "<CR>", function() open_link(true) end, { noremap = true, silent = true, buffer = buf })
			vim.keymap.set("n", "<C-]>", function() open_link(true) end, { noremap = true, silent = true, buffer = buf })
		else
			vim.bo[buf].modifiable = true
			vim.bo[buf].readonly = false
			vim.keymap.set("n", "<CR>", function() open_link(false) end, { noremap = true, silent = true, buffer = buf })
			vim.keymap.set("n", "<C-]>", function() open_link(false) end, { noremap = true, silent = true, buffer = buf })
		end
	end
end

function M.generate_index()
	index.generate()
end

function M.search()
	fs.ensure()
	search.live_grep()
end

return M
