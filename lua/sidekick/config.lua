local M = {}

M.defaults = {
	tools = {
		Claude = "claude --permission-mode bypassPermissions",
	},
	hints = {
		enabled = true,
		keywords = { "TODO", "FIXME", "HACK", "NOTE", "XXX", "BUG" },
		tip = "Implement with AI",
	},
	split = {
		direction = "vertical",
		size = 50,
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
