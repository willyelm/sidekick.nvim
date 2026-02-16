vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if not vim.g.sidekick_setup_done then
      require("sidekick").setup()
      vim.g.sidekick_setup_done = true
    end
  end,
})
