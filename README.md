# sidekick.nvim

Inline AI hints for TODO/FIXME comments in Neovim. A simple plugin that shows `> Implement with AI` hints above your TODO comments and lets you quickly send them to AI tools.

## Features

- Automatically detects TODO/FIXME/HACK/NOTE comments
- Shows `> Implement with AI` hint above comments (highlights when cursor is on the line)
- Single keymap to trigger AI on comment or custom task
- Fully configurable AI tools (Claude, Codex, GPT, etc.)
- Reads entire comment blocks (single-line `//` and multi-line `/* */`)
- Opens AI response in a vertical split terminal

## Installation

### Using lazy.nvim
```lua
{
  "willyelm/sidekick.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  config = function()
    require("sidekick").setup()
  end,
  keys = {
    { "<leader>gz", "<cmd>Sidekick<cr>", desc = "Start agent tool" },
  },
}
```

## Usage

1. Write a TODO comment:
```javascript
// TODO: Implement user authentication
// Need to add JWT token validation
```

2. You'll see: `> Implement with AI` above the comment

3. Move cursor to the comment line (hint becomes `> Implement with AI  <-`)

4. Press `<leader>gz`:
   - Prompts you to select a tool (Claude, Codex, etc.)
   - Sends the entire comment block to the AI
   - Opens response in a vertical split

5. Or press `<leader>gz` anywhere else:
   - Asks for a custom task
   - Prompts you to select a tool
   - Sends task with file context to AI

## Configuration
```lua
{
  "willyelm/sidekick.nvim",
  opts = {
    tools = {
      -- String: runs as a shell command in a split terminal
      Claude = "claude --permission-mode bypassPermissions",
      Codex = "codex",
      -- Function: full control over how the tool is invoked
      -- Receives (file_path, line_number, task) as arguments
      Gemini = function(file, line, task)
        vim.fn.jobstart({ "gemini", "--file", file, "--task", task })
      end,
    },
    keywords = { "TODO", "FIXME", "HACK", "NOTE", "XXX", "BUG" },
    hint_text = "Implement with AI",
    split = {
      direction = "vertical",
      size = 50,
    },
  }
}
```

## Supported Comment Styles

### Single-line comments
```javascript
// TODO: Fix this bug
```

### Multi-line comments
```javascript
/**
 * TODO: Refactor this function
 * It's getting too complex
 */
```

### Language-specific
- JavaScript/TypeScript: `//` and `/* */`
- Python: `#`
- Lua: `--`
- Rust/Go/C/C++/Java: `//`

## Requirements

- Neovim >= 0.10.0
- plenary.nvim
- AI CLI tools installed (claude, codex, etc.)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details
