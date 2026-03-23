return {
  {
    "nvim-focus/focus.nvim",
    version = false,
    opts = {
      autoresize = {
        enable = true,
      },
    },
  },
  {
  "tadaa/vimade",
  event = "UIEnter",
  opts = {
    recipe = {"duo", {animate = false}},
    fadelevel = 0.5,
    ncmode = "windows",
  }
}
}
