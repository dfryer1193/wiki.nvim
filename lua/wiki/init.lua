local config = require("wiki.config")
local index = require("wiki.index")
local search = require("wiki.search")
local fs = require("wiki.fs")

local M = {}

vim.api.nvim_set_hl(0, "WikiTitle", { bold = true, fg = "#61afef" })
vim.api.nvim_set_hl(0, "WikiHeading0", { bold = true, fg = "#e5c07b" })
vim.api.nvim_set_hl(0, "WikiHeading1", { bold = true, fg = "#e06c75" })
vim.api.nvim_set_hl(0, "WikiHeading2", { bold = true, fg = "#c678dd" })
vim.api.nvim_set_hl(0, "WikiHeading3", { bold = true, fg = "#98c379" })
vim.api.nvim_set_hl(0, "WikiHeading4", { bold = true, fg = "#56b6c2" })
vim.api.nvim_set_hl(0, "WikiHeading5", { bold = true, fg = "#d19a66" })
vim.api.nvim_set_hl(0, "WikiLinkText", { fg = "#61afef" })
vim.api.nvim_set_hl(0, "WikiLinkPath", { fg = "#5c6370", italic = true })

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

	local lines, link_store = index.get_index_data()
	if not lines or #lines == 0 then
		lines = { "# Empty Wiki!" }
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
	vim.api.nvim_buf_set_name(buf, "wiki-index")

	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
	vim.bo[buf].filetype = "wiki"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].modified = false

	local ns = vim.api.nvim_create_namespace("wiki_index")

	local src_id = vim.api.nvim_buf_add_highlight(buf, ns, "WikiTitle", 0, 0, -1)
	for i = 1, #lines - 1 do
		local link_data = link_store[i]
		if link_data then
			if link_data.is_title then
				vim.api.nvim_buf_add_highlight(buf, src_id, "WikiTitle", i, 0, -1)
			elseif link_data.is_heading then
				local hl_group = "WikiHeading" .. link_data.depth
				vim.api.nvim_buf_add_highlight(buf, src_id, hl_group, i, 0, -1)
			elseif link_data.text and link_data.path then
				vim.api.nvim_buf_add_highlight(buf, src_id, "WikiLinkText", i, 0, -1)
			end
		end
	end

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = vim.o.columns,
		height = vim.o.lines,
		row = 0,
		col = 0,
		style = "minimal",
	})

	vim.wo[win].wrap = false
	vim.wo[win].cursorline = true

	vim.api.nvim_buf_set_var(buf, "wiki_link_store", link_store)
	vim.api.nvim_buf_set_var(buf, "wiki_ns", ns)

	local links_by_line = {}
	for line_idx, data in pairs(link_store) do
		if data.path then
			links_by_line[line_idx] = data
		end
	end
	vim.api.nvim_buf_set_var(buf, "wiki_links", links_by_line)

	local group = vim.api.nvim_create_augroup("wiki_index", { clear = true })
	local last_line = nil
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		group = group,
		callback = function()
			local cursor_line = vim.api.nvim_win_get_cursor(win)
			local line_idx = cursor_line[1]
			local links = vim.api.nvim_buf_get_var(buf, "wiki_links")

			vim.bo[buf].modifiable = true

			if last_line and last_line ~= line_idx and links[last_line] then
				local link_data = links[last_line]
				vim.api.nvim_buf_set_lines(buf, last_line - 1, last_line, true, { link_data.short })
			end

			if links[line_idx] then
				local link_data = links[line_idx]
				local display_line = "- [" .. link_data.text .. "](" .. link_data.path .. ")"
				vim.api.nvim_buf_set_lines(buf, line_idx - 1, line_idx, true, { display_line })
			end

			vim.bo[buf].modifiable = false

			last_line = line_idx
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		buffer = buf,
		group = group,
		callback = function()
			local valid_bufs = 0
			for _, b in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted then
					valid_bufs = valid_bufs + 1
				end
			end
			if valid_bufs == 0 then
				vim.cmd("qa!")
			end
		end,
	})

	vim.keymap.set("n", "q", function()
		vim.cmd("bd! " .. buf)
	end, { noremap = true, silent = true, buffer = buf })

	vim.keymap.set("n", "<CR>", function()
		local cursor_line = vim.api.nvim_win_get_cursor(win)
		local line_idx = cursor_line[1]
		local links = vim.api.nvim_buf_get_var(buf, "wiki_links")
		if links[line_idx] then
			local link_data = links[line_idx]
			local tag_name = link_data.tag
			vim.cmd("tag! " .. tag_name)
			local newbuf = vim.api.nvim_get_current_buf()
			vim.bo[newbuf].filetype = "markdown"
			vim.bo[newbuf].modifiable = true
			vim.bo[newbuf].readonly = false
		end
	end, { noremap = true, silent = true, buffer = buf })

	vim.keymap.set("n", "<C-]>", function()
		local cursor_line = vim.api.nvim_win_get_cursor(win)
		local line_idx = cursor_line[1]
		local links = vim.api.nvim_buf_get_var(buf, "wiki_links")
		if links[line_idx] then
			local link_data = links[line_idx]
			local tag_name = link_data.tag
			vim.cmd("tag! " .. tag_name)
			local newbuf = vim.api.nvim_get_current_buf()
			vim.bo[newbuf].filetype = "markdown"
			vim.bo[newbuf].modifiable = true
			vim.bo[newbuf].readonly = false
		end
	end, { noremap = true, silent = true, buffer = buf })
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
