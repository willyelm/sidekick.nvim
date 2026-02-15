local config = require("ai-hints.config")

local M = {}

local function get_multiline_comment_block(lines, line_num)
  local start_line = line_num
  while start_line > 1 do
    if lines[start_line]:match("/%*") then
      break
    end
    start_line = start_line - 1
  end

  local end_line = line_num
  while end_line <= #lines do
    if lines[end_line]:match("%*/") then
      break
    end
    end_line = end_line + 1
  end

  local comment_text = {}
  for i = start_line, end_line do
    local text = lines[i]
    text = text:gsub("/%*+", "")
    text = text:gsub("%*+/", "")
    text = text:gsub("^%s*%*%s?", "")
    text = text:gsub("^%s+", "")
    if text ~= "" then
      table.insert(comment_text, text)
    end
  end

  return table.concat(comment_text, "\n"), start_line
end

function M.get_comment_block(bufnr, line_num)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ft = vim.bo[bufnr].filetype
  local current_line = lines[line_num]

  if current_line:match("/%*") or current_line:match("%*/") or current_line:match("^%s*%*") then
    return get_multiline_comment_block(lines, line_num)
  end

  local pattern = config.options.comment_patterns[ft] or "^%s*//"

  local start_line = line_num
  while start_line > 1 and lines[start_line - 1]:match(pattern) do
    start_line = start_line - 1
  end

  local end_line = line_num
  while end_line < #lines and lines[end_line + 1]:match(pattern) do
    end_line = end_line + 1
  end

  local comment_text = {}
  for i = start_line, end_line do
    local text = lines[i]:gsub(pattern, ""):gsub("^%s+", "")
    table.insert(comment_text, text)
  end

  return table.concat(comment_text, "\n"), start_line
end

return M
