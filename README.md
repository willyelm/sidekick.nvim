# sidekick.nvim

A Neovim plugin that detects TODO/FIXME comments and lets you send them to AI tools (Claude, Codex, etc.) with a single keymap.

## Install

```lua
-- lazy.nvim
{
  "willyelm/sidekick.nvim",
  opts = {},
  keys = {
    { "<leader>gz", "<cmd>Sidekick<cr>", desc = "Sidekick AI" },
  },
}
```

## Usage

1. Write a TODO comment in any file
2. Place your cursor on it and press `<leader>gz`
3. The comment is sent to your AI tool in a split terminal

Press `<leader>gz` on any other line to enter a custom prompt instead.

## Configuration

```lua
{
  "willyelm/sidekick.nvim",
  opts = {
    tools = {
      -- String: shell command opened in a split terminal
      Claude = "claude --permission-mode bypassPermissions",
      Codex = "codex",
      -- Function: full control (receives file_path, line_number, task)
      Custom = function(file, line, task)
        vim.fn.jobstart({ "my-tool", "--file", file, "--task", task })
      end,
    },
    hints = {
      enabled = true,                                          -- show inline hints
      keywords = { "TODO", "FIXME", "HACK", "NOTE", "XXX", "BUG" },
      tip = "Implement with AI",                               -- hint text
    },
    split = {
      direction = "vertical", -- "vertical" or "horizontal"
      size = 50,
    },
  },
}
```

## Requirements

- Neovim >= 0.10.0
- An AI CLI tool installed (e.g. `claude`, `codex`)

## License

MIT
