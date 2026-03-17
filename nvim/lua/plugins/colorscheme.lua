return {
  {
    -- Global Interface Theme
    'xero/miasma.nvim',
    lazy = false,
    priority = 1000, -- Initialize strictly before other UI components
    config = function()
      local theme_path = vim.fn.stdpath 'data' .. '/active_theme.txt'
      local f = io.open(theme_path, 'r')
      if f then
        local theme = f:read '*l'
        f:close()
        if theme and theme ~= '' then
          pcall(vim.cmd, 'colorscheme ' .. theme)
          return
        end
      end
      -- Fallback if no valid theme is saved
      pcall(vim.cmd, 'colorscheme miasma')
    end,
  },
  -- Popular Theme Alternatives for testing:
  { 'folke/tokyonight.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'rebelot/kanagawa.nvim' },
  { 'EdenEast/nightfox.nvim' },
  { 'navarasu/onedark.nvim' },
  { 'ellisonleao/gruvbox.nvim' },
  { 'sainnhe/everforest' },
  { 'rose-pine/neovim', name = 'rose-pine' },
}
