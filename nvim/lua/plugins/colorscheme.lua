return {
  {
    "xero/miasma.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("core.theme").load()
    end,
  },

  { "folke/tokyonight.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "rebelot/kanagawa.nvim" },
  { "EdenEast/nightfox.nvim" },
  { "navarasu/onedark.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "sainnhe/everforest" },
  { "rose-pine/neovim", name = "rose-pine" },
}
