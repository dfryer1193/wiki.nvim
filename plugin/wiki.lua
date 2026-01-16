vim.api.nvim_create_user_command("WikiIndex", function()
	require("wiki").open_index()
end, {})

vim.api.nvim_create_user_command("WikiSearch", function()
	require("wiki").search()
end, {})
