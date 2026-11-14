return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
    init = function()
      -- Keep lualine/snacks statusline control intact.
      vim.g.VM_set_statusline = 0
      -- Reduce noisy messages when leaving multi-cursor mode.
      vim.g.VM_silent_exit = 1
      -- Keep mouse support when adding/removing cursors.
      vim.g.VM_mouse_mappings = 1
      -- Preserve plugin defaults: <C-n>, \\A, q/n/N/[/] etc.
      vim.g.VM_default_mappings = 1
    end,
  },
}
