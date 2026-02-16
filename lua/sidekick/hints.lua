local config = require("sidekick.config")

local M = {}

local ns_id = vim.api.nvim_create_namespace("sidekick")

function M.has_keyword(line)
  for _, keyword in ipairs(config.options.hints.keywords) do
    if line:match(keyword .. ":") then
      return true
    end
  end
  return false
end

function M.update(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  if not config.options.hints.enabled then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_line_num = vim.fn.line(".")

  for line_num, line in ipairs(lines) do
    if M.has_keyword(line) then
      local is_cursor_here = (line_num == current_line_num)
      local highlight = is_cursor_here and "DiagnosticInfo" or "PreProc"
      local indent = line:match("^%s*") or ""
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num - 1, 0, {
        virt_lines = {
          { { indent .. config.options.hints.tip, highlight } }
        },
        virt_lines_above = true,
      })
    end
  end
end

function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("Sidekick", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function()
      M.update()
    end,
  })
end

return M
