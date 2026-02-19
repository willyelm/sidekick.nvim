local config = require("sidekick.config")
local comments = require("sidekick.comments")
local runner = require("sidekick.runner")
local hints = require("sidekick.hints")
local panel = require("sidekick.panel")

local M = {}

local state = {
	prompt_buf = nil,
	prompt_ctx = nil,
}

local function close_win(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function prompt_from_buf(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	while #lines > 0 and lines[#lines] == "" do
		table.remove(lines)
	end
	return table.concat(lines, "\n")
end

local function submit_prompt()
	local ctx = state.prompt_ctx
	if not ctx then
		return
	end
	if not state.prompt_buf or not vim.api.nvim_buf_is_valid(state.prompt_buf) then
		return
	end
	local prompt = prompt_from_buf(state.prompt_buf)
	if prompt == "" then
		return
	end
	local win = vim.fn.bufwinid(state.prompt_buf)
	if win ~= -1 then
		close_win(win)
	end
	local used_buf = state.prompt_buf
	state.prompt_buf = nil
	state.prompt_ctx = nil
	runner.run_ai_tool(ctx.tool, prompt, ctx.file_path, ctx.line_num)
	if used_buf and vim.api.nvim_buf_is_valid(used_buf) then
		vim.api.nvim_buf_delete(used_buf, { force = true })
	end
end

local function ensure_prompt_buffer()
	if state.prompt_buf and vim.api.nvim_buf_is_valid(state.prompt_buf) then
		return state.prompt_buf
	end

	local buf = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_option(buf, "buftype", "")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "buflisted", true)
	vim.api.nvim_buf_set_option(buf, "filetype", config.options.window.prompt_filetype or "lua")
	state.prompt_buf = buf

	vim.keymap.set("i", "<CR>", submit_prompt, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<CR>", submit_prompt, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("i", "<S-CR>", function()
		vim.api.nvim_paste("\n", true, -1)
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "q", function()
		close_win(vim.fn.bufwinid(buf))
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		close_win(vim.fn.bufwinid(buf))
	end, { buffer = buf, noremap = true, silent = true })

	return buf
end

local function open_prompt(tool, file_path, line_num)
	local win = panel.open_window({ title = " Prompt " })
	local buf = ensure_prompt_buffer()
	state.prompt_ctx = {
		tool = tool,
		file_path = file_path,
		line_num = line_num,
	}

	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_set_option_value("wrap", true, { win = win })
	vim.api.nvim_set_option_value("linebreak", true, { win = win })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
	vim.api.nvim_set_current_win(win)
	vim.api.nvim_win_set_cursor(win, { 1, 0 })
	vim.cmd("startinsert")
end

local function open_tool_picker(prompt, file_path, line_num)
	local tools = runner.get_tool_names()
	if #tools == 0 then
		vim.notify("Sidekick: no tools configured", vim.log.levels.WARN)
		return
	end

	if #tools == 1 then
		if prompt and prompt ~= "" then
			runner.run_ai_tool(tools[1], prompt, file_path, line_num)
		else
			open_prompt(tools[1], file_path, line_num)
		end
		return
	end

	local win = panel.open_window({ title = " Select Tool " })
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "prompt")
	vim.api.nvim_set_option_value("cursorline", true, { win = win })
	vim.api.nvim_set_option_value("cursorlineopt", "line", { win = win })
	local current_winhl = vim.api.nvim_get_option_value("winhl", { win = win })
	local new_winhl = current_winhl == "" and "CursorLine:Visual" or (current_winhl .. ",CursorLine:Visual")
	vim.api.nvim_set_option_value("winhl", new_winhl, { win = win })

	local idx = 1
	local function render()
		local lines = {}
		for _, tool in ipairs(tools) do
			table.insert(lines, "  " .. tool)
		end
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_win_set_cursor(win, { idx, 0 })
	end

	local function choose()
		local tool = tools[idx]
		if not tool then
			return
		end
		close_win(win)
		if prompt and prompt ~= "" then
			runner.run_ai_tool(tool, prompt, file_path, line_num)
		else
			open_prompt(tool, file_path, line_num)
		end
	end

	render()
	vim.keymap.set("n", "j", function()
		idx = math.min(idx + 1, #tools)
		render()
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "k", function()
		idx = math.max(idx - 1, 1)
		render()
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<Down>", function()
		idx = math.min(idx + 1, #tools)
		render()
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<Up>", function()
		idx = math.max(idx - 1, 1)
		render()
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<CR>", choose, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "q", function()
		close_win(win)
	end, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		close_win(win)
	end, { buffer = buf, noremap = true, silent = true })
end

function M.run_ai()
	local bufnr = vim.api.nvim_get_current_buf()
	local line_num = vim.fn.line(".")
	local line = vim.api.nvim_get_current_line()
	local file_path = vim.fn.expand("%:p")

	if hints.has_keyword(line) then
		local comment_block, start_line = comments.get_comment_block(bufnr, line_num)
		open_tool_picker(comment_block, file_path, start_line)
	else
		open_tool_picker(nil, file_path, line_num)
	end
end

function M.setup(opts)
	config.setup(opts)
	hints.setup_autocmds()

	vim.api.nvim_create_user_command("Sidekick", function()
		require("sidekick").run_ai()
	end, {})

	vim.schedule(function()
		hints.update()
	end)
end

return M
