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
	comment_patterns = {
		lua = "^%s*%-%-",
		python = "^%s*#",
		javascript = "^%s*//",
		typescript = "^%s*//",
		typescriptreact = "^%s*//",
		javascriptreact = "^%s*//",
		rust = "^%s*//",
		go = "^%s*//",
		c = "^%s*//",
		cpp = "^%s*//",
		java = "^%s*//",
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
