local M = {}

local function get_comment_node(bufnr, line_num)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return nil
	end
	local tree = parser:parse()[1]
	if not tree then
		return nil
	end
	local root = tree:root()
	local row = line_num - 1
	local node = root:named_descendant_for_range(row, 0, row, 0)
	while node do
		if node:type():match("comment") then
			return node
		end
		node = node:parent()
	end
	return nil
end

local function strip_comment_markers(text, bufnr)
	local cs = vim.bo[bufnr].commentstring or ""
	local prefix, suffix = cs:match("^(.-)%%s(.-)$")
	if not prefix then
		return text
	end
	prefix = vim.trim(prefix)
	suffix = vim.trim(suffix)
	local lines = vim.split(text, "\n")
	local result = {}
	for _, line in ipairs(lines) do
		local stripped = line
		if prefix ~= "" then
			local esc = prefix:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
			stripped = stripped:gsub("%s*" .. esc .. "%s?", "", 1)
		end
		if suffix ~= "" then
			local esc = suffix:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
			stripped = stripped:gsub("%s?" .. esc .. "%s*$", "")
		end
		stripped = stripped:gsub("^%s*%*%s?", "")
		stripped = vim.trim(stripped)
		if stripped ~= "" then
			table.insert(result, stripped)
		end
	end
	return table.concat(result, "\n")
end

function M.get_comment_block(bufnr, line_num)
	local node = get_comment_node(bufnr, line_num)
	if node then
		local start_row = node:start()
		local text = vim.treesitter.get_node_text(node, bufnr)
		local stripped = strip_comment_markers(text, bufnr)
		return stripped, start_row + 1
	end
	local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1] or ""
	return vim.trim(line), line_num
end

return M
