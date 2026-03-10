local config = require("wiki.config")
vim.opt.tags:append(config.root .. "/tags")

vim.api.nvim_create_user_command("WikiIndex", function()
	require("wiki").open_index()
end, {})

vim.api.nvim_create_user_command("WikiSearch", function()
	require("wiki").search()
end, {})

vim.api.nvim_create_user_command("WikiGenerate", function()
	require("wiki.index").generate()
end, {})

vim.api.nvim_create_user_command("WikiNewPage", function()
	local path = vim.fn.input("New wiki page path: ")
	if path ~= "" then
		require("wiki.page").new_page(path)
	end
end, {})

vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function(args)
		local bufname = vim.api.nvim_buf_get_name(args.buf)
		local pages_dir = vim.loop.fs_realpath(require("wiki.config").pages_dir)

		if bufname:sub(1, #pages_dir) == pages_dir then
			require("wiki.index").generate()
		end
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			local fs = require("wiki.fs")
			fs.ensure()
			require("wiki.index").generate()
			vim.cmd.edit(require("wiki.config").index_file)
			local buf = vim.api.nvim_get_current_buf()
			vim.bo[buf].modifiable = false
			vim.bo[buf].readonly = true
			vim.bo[buf].filetype = "markdown"
			vim.bo[buf].syntax = "markdown"
		end
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		require("wiki").setup_buffer()
	end,
})
