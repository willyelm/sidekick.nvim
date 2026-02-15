vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if not vim.g.ai_hints_setup_done then
      require("ai-hints").setup()
      vim.g.ai_hints_setup_done = true
    end
  end,
})
