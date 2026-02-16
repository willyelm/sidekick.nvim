local config = require("sidekick.config")
local comments = require("sidekick.comments")
local runner = require("sidekick.runner")
local hints = require("sidekick.hints")

local M = {}

local function select_and_run(prompt, file_path, line_num)
  local tools = runner.get_tool_names()
  if #tools == 1 then
    runner.run_ai_tool(tools[1], prompt, file_path, line_num)
  else
    vim.ui.select(tools, { prompt = "Select AI:" }, function(tool)
      if tool then
        runner.run_ai_tool(tool, prompt, file_path, line_num)
      end
    end)
  end
end

function M.run_ai()
  local bufnr = vim.api.nvim_get_current_buf()
  local line_num = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local file_path = vim.fn.expand("%:p")

  if hints.has_keyword(line) then
    local comment_block, start_line = comments.get_comment_block(bufnr, line_num)
    select_and_run(comment_block, file_path, start_line)
  else
    select_and_run(nil, file_path, line_num)
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
