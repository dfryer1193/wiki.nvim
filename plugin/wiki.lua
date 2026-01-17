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
		local pages_dir = require("wiki.config").pages_dir

		if bufname:sub(1, #pages_dir) == pages_dir then
			require("wiki.index").generate()
		end
	end,
})
