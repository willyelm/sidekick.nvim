local config = require("ai-hints.config")
local comments = require("ai-hints.comments")
local runner = require("ai-hints.runner")
local hints = require("ai-hints.hints")

local M = {}

function M.run_ai()
  local bufnr = vim.api.nvim_get_current_buf()
  local line_num = vim.fn.line(".")
  local line = vim.api.nvim_get_current_line()
  local file_path = vim.fn.expand("%:p")

  if hints.has_keyword(line) then
    local comment_block, start_line = comments.get_comment_block(bufnr, line_num)

    vim.ui.select(runner.get_tool_names(), {
      prompt = "Select AI:",
    }, function(tool)
      if tool then
        runner.run_ai_tool(tool, comment_block, file_path, start_line)
      end
    end)
  else
    vim.ui.input({ prompt = "Task: " }, function(task)
      if not task then return end

      vim.ui.select(runner.get_tool_names(), {
        prompt = "Select AI:",
      }, function(tool)
        if tool then
          runner.run_ai_tool(tool, task, file_path, nil)
        end
      end)
    end)
  end
end

function M.setup(opts)
  config.setup(opts)
  hints.setup_autocmds()

  vim.schedule(function()
    hints.update()
  end)
end

return M
