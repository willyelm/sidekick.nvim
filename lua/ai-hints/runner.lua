local config = require("ai-hints.config")

local M = {}

function M.get_tool_names()
  local tools = {}
  for tool_name, _ in pairs(config.options.tools) do
    table.insert(tools, tool_name)
  end
  table.sort(tools)
  return tools
end

local function run_command(tool_name, cmd, prompt, file_path, line_num)
  local full_prompt = string.format(
    "Context Files:\n%s\nLine: %d\n\nTask:\n%s",
    file_path,
    line_num or 1,
    prompt
  )

  local tmp_file = os.tmpname()
  local f = io.open(tmp_file, 'w')
  f:write(full_prompt)
  f:close()

  local split_config = config.options.split
  if split_config.direction == "vertical" then
    vim.cmd(string.format('vsplit | vertical resize %d', split_config.size))
  else
    vim.cmd(string.format('split | resize %d', split_config.size))
  end

  local buf = vim.api.nvim_create_buf(true, false)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_name(buf, string.format("[AI %s] %s", tool_name, prompt:sub(1, 30)))

  local shell_cmd = string.format('cat %s | %s', tmp_file, cmd)

  local job_id = vim.fn.termopen(shell_cmd, {
    on_exit = function()
      os.remove(tmp_file)
    end
  })

  vim.api.nvim_create_autocmd("WinResized", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) and job_id then
        local new_width = vim.api.nvim_win_get_width(win)
        local new_height = vim.api.nvim_win_get_height(win)
        vim.fn.jobresize(job_id, new_width, new_height)
      end
    end,
  })

  vim.cmd('startinsert')
end

function M.run_ai_tool(tool_name, prompt, file_path, line_num)
  local tool = config.options.tools[tool_name]

  if type(tool) == "function" then
    tool(file_path, line_num, prompt)
  else
    run_command(tool_name, tool, prompt, file_path, line_num)
  end
end

return M
