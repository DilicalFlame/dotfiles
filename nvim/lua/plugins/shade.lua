return {
  {
    "nvim-focus/focus.nvim",
    version = false,
    opts = {
      autoresize = {
        enable = true,
        exclude_filetypes = { "neo-tree", "neo-tree-popup", "neo-tree-filter" },
      },
    },
  },
  {
    "tadaa/vimade",
    event = "UIEnter",
    opts = {
      recipe = { "duo", { animate = false } },
      fadelevel = 0.5,
      ncmode = "windows",
    },
  },
}
