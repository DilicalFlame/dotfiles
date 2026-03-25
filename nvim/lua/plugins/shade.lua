return {
  {
    "nvim-focus/focus.nvim",
    version = false,
    opts = {
      autoresize = {
        enable = true,
      },
      ui = {
        number = false,
        relativenumber = false,
        hybridnumber = false,
        cursorline = false,
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
