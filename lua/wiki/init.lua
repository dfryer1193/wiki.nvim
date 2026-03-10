local config = require("wiki.config")
local index = require("wiki.index")
local search = require("wiki.search")
local fs = require("wiki.fs")

local M = {}

function M.setup(user_config)
	config.setup(user_config or {})
end

function M.open_index()
	fs.ensure()
	vim.cmd("edit " .. config.index_file)

	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].syntax = "markdown"

	local function open_link()
		local line = vim.api.nvim_get_current_line()
		local path, anchor = string.match(line, "%((.-)#([^)]+)%)")
		if not path then
			path = string.match(line, "%((.-)%)")
		end
		if path then
			if anchor then
				vim.cmd("edit " .. path)
				local tag_name = anchor:gsub("%-", " ")
				vim.cmd("tag " .. vim.fn.escape(tag_name, " "))
			else
				vim.cmd("edit " .. path)
			end
		end
	end

	vim.keymap.set("n", "<CR>", open_link, { noremap = true, silent = true, buffer = buf })
	vim.keymap.set("n", "g<C-]>", "<C-]>", { noremap = true, silent = true, buffer = buf })
	vim.keymap.set("n", "g<C-t>", "<C-t>", { noremap = true, silent = true, buffer = buf })
end

function M.setup_buffer()
	local buf = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(buf)
	if bufname:sub(1, #config.pages_dir) == config.pages_dir then
		vim.bo[buf].filetype = "markdown"
		vim.keymap.set("n", "<CR>", function()
			local line = vim.api.nvim_get_current_line()
			local path, anchor = string.match(line, "%((.-)#([^)]+)%)")
			if not path then
				path = string.match(line, "%((.-)%)")
			end
			if path then
				if anchor then
					vim.cmd("edit " .. path)
					local tag_name = anchor:gsub("%-", " ")
					vim.cmd("tag " .. vim.fn.escape(tag_name, " "))
				else
					vim.cmd("edit " .. path)
				end
				local newbuf = vim.api.nvim_get_current_buf()
				vim.bo[newbuf].modifiable = true
				vim.bo[newbuf].readonly = false
			end
		end, { noremap = true, silent = true, buffer = buf })
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
