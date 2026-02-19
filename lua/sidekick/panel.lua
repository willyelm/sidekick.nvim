local config = require("sidekick.config")

local M = {}
local PANEL_WIN_VAR = "sidekick_panel"

local function open_split()
	local split_config = config.options.split
	if split_config.direction == "vertical" then
		vim.cmd(string.format("vsplit | vertical resize %d", split_config.size))
	else
		vim.cmd(string.format("split | resize %d", split_config.size))
	end
	return vim.api.nvim_get_current_win()
end

local function clamp_ratio(value, fallback)
	if type(value) ~= "number" then
		return fallback
	end
	if value <= 0 then
		return fallback
	end
	if value > 1 then
		return 1
	end
	return value
end

local function find_existing_panel_win()
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		local ok, val = pcall(vim.api.nvim_win_get_var, winid, PANEL_WIN_VAR)
		if ok and val == true then
			return winid
		end
	end
	return nil
end

local function apply_float_window_style(win)
	vim.api.nvim_set_option_value("number", false, { win = win })
	vim.api.nvim_set_option_value("relativenumber", false, { win = win })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
	vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
	vim.api.nvim_set_option_value("statuscolumn", "", { win = win })
	vim.api.nvim_set_option_value("winbar", "", { win = win })

	local current_winhl = vim.api.nvim_get_option_value("winhl", { win = win })
	if current_winhl == "" then
		vim.api.nvim_set_option_value("winhl", "FloatTitle:Comment", { win = win })
	elseif not current_winhl:match("FloatTitle:") then
		vim.api.nvim_set_option_value("winhl", current_winhl .. ",FloatTitle:Comment", { win = win })
	end
end

local function maybe_close_on_blur(win, close_on_blur)
	if close_on_blur == false then
		return
	end
	vim.api.nvim_create_autocmd("WinLeave", {
		once = true,
		callback = function(args)
			if tonumber(args.match) ~= win then
				return
			end
			if vim.api.nvim_win_is_valid(win) then
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_win_close(win, true)
					end
				end)
			end
		end,
	})
end

local function build_cursor_config(total_rows, total_cols, width, height, border, title)
	local cursor_gap = 1
	local base_win = vim.api.nvim_get_current_win()
	local win_pos = vim.api.nvim_win_get_position(base_win)
	local cursor_screen_row = win_pos[1] + vim.fn.winline() - 1
	local cursor_screen_col = win_pos[2] + vim.fn.wincol() - 1
	local below_space = total_rows - cursor_screen_row - 1

	local row
	if below_space >= (height + cursor_gap) then
		row = cursor_screen_row + 1 + cursor_gap
	else
		row = math.max(0, cursor_screen_row - height - cursor_gap)
	end
	local col = math.min(cursor_screen_col, math.max(0, total_cols - width))

	return {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = border,
		title = title,
		title_pos = "center",
	}
end

local function build_center_config(total_rows, total_cols, width, height, border, title)
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((total_rows - height) / 2),
		col = math.floor((total_cols - width) / 2),
		style = "minimal",
		border = border,
		title = title,
		title_pos = "center",
	}
end

local function open_float(opts)
	opts = opts or {}
	local window_opts = config.options.window or {}
	local float_opts = window_opts.float or {}
	local width_ratio = math.min(clamp_ratio(float_opts.width, 0.2), 0.5)
	local height_ratio = math.min(clamp_ratio(float_opts.height, 0.2), 0.5)

	local ui = vim.api.nvim_list_uis()[1] or {}
	local total_cols = ui.width or vim.o.columns
	local total_rows = ui.height or vim.o.lines
	local width = math.max(math.floor(total_cols * width_ratio), 20)
	local height = math.max(math.floor(total_rows * height_ratio), 5)
	local border = float_opts.border or "rounded"
	local position = float_opts.position or "cursor"

	local cfg
	if position == "center" then
		cfg = build_center_config(total_rows, total_cols, width, height, border, opts.title)
	else
		cfg = build_cursor_config(total_rows, total_cols, width, height, border, opts.title)
	end

	local existing = find_existing_panel_win()
	if existing and vim.api.nvim_win_is_valid(existing) then
		vim.api.nvim_win_set_config(existing, cfg)
		vim.api.nvim_set_current_win(existing)
		apply_float_window_style(existing)
		return existing
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, cfg)
	vim.api.nvim_win_set_var(win, PANEL_WIN_VAR, true)
	apply_float_window_style(win)
	maybe_close_on_blur(win, float_opts.close_on_blur)
	return win
end

function M.open_window(opts)
	local mode = ((config.options.window or {}).mode) or "float"
	if mode == "split" then
		return open_split()
	end
	return open_float(opts)
end

return M
