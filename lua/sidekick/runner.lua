local config = require("sidekick.config")

local M = {}
local sessions = {}

local function safe_set_buf_name(buf, preferred)
	local ok = pcall(vim.api.nvim_buf_set_name, buf, preferred)
	if ok then
		return
	end
	pcall(vim.api.nvim_buf_set_name, buf, string.format("%s %d", preferred, buf))
end

function M.get_tool_names()
	local tools = {}
	for tool_name, _ in pairs(config.options.tools) do
		table.insert(tools, tool_name)
	end
	table.sort(tools)
	return tools
end

local function session_is_alive(session)
	if not session then
		return false
	end
	if not vim.api.nvim_buf_is_valid(session.buf) then
		return false
	end
	local ok, _ = pcall(vim.fn.jobpid, session.job_id)
	return ok
end

local function find_win_for_buf(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			return win
		end
	end
	return nil
end

local function open_result_window()
	local split_config = config.options.split
	if split_config.direction == "vertical" then
		vim.cmd(string.format("vsplit | vertical resize %d", split_config.size))
	else
		vim.cmd(string.format("split | resize %d", split_config.size))
	end
	return vim.api.nvim_get_current_win()
end

local function focus_session(session)
	local win = find_win_for_buf(session.buf)
	if not win then
		win = open_result_window()
		vim.api.nvim_win_set_buf(win, session.buf)
	end
	vim.api.nvim_set_current_win(win)
	return win
end

local function create_session(tool_name, cmd, win)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_win_set_buf(win, buf)
	safe_set_buf_name(buf, string.format("[Sidekick %s]", tool_name))

	local job_id = vim.fn.termopen(cmd, {
		on_exit = function()
			sessions[tool_name] = nil
		end,
	})

	vim.api.nvim_create_autocmd("WinResized", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				local ok, _ = pcall(vim.fn.jobpid, job_id)
				if ok then
					local w = find_win_for_buf(buf)
					if w then
						vim.fn.jobresize(job_id, vim.api.nvim_win_get_width(w), vim.api.nvim_win_get_height(w))
					end
				end
			end
		end,
	})

	vim.keymap.set("t", "<Esc>", function()
		local current_win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_is_valid(current_win) then
			vim.api.nvim_win_close(current_win, true)
		end
	end, { buffer = buf, noremap = true, silent = true })

	vim.keymap.set("n", "<Esc>", function()
		local current_win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_is_valid(current_win) then
			vim.api.nvim_win_close(current_win, true)
		end
	end, { buffer = buf, noremap = true, silent = true })

	local session = { buf = buf, job_id = job_id }
	sessions[tool_name] = session
	return session
end

local function build_prompt_text(entry, prompt)
	return "Context Files: " .. entry .. " " .. prompt
end

local function start_new_session(tool_name, cmd, entry, prompt)
	local win = open_result_window()
	local session = create_session(tool_name, cmd, win)

	vim.schedule(function()
		if not (session and session_is_alive(session)) then
			return
		end
		if prompt and prompt ~= "" then
			vim.api.nvim_chan_send(session.job_id, build_prompt_text(entry, prompt) .. "\r")
		else
			vim.api.nvim_chan_send(session.job_id, entry .. " ")
		end
	end)
	vim.cmd("startinsert")
end

function M.run_ai_tool(tool_name, prompt, file_path, line_num)
	local tool = config.options.tools[tool_name]
	if type(tool) == "function" then
		tool(file_path, line_num, prompt)
		return
	end

	local entry = string.format("%s:%d", file_path, line_num or 1)
	local session = sessions[tool_name]

	if session_is_alive(session) then
		focus_session(session)
		if prompt and prompt ~= "" then
			vim.api.nvim_chan_send(session.job_id, build_prompt_text(entry, prompt) .. "\r")
		else
			vim.api.nvim_chan_send(session.job_id, entry .. " ")
		end
		vim.cmd("startinsert")
		return
	end

	start_new_session(tool_name, tool, entry, prompt)
end

return M
