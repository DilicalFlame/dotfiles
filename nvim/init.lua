-- Entry point. Everything is explicit: options -> autocmds -> plugin manager -> keymaps.
require("config.options") -- also sets <leader>, must precede plugins
require("config.autocmds")
require("config.lazy")

-- Keymaps load after plugins so mine override plugin defaults.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("config.keymaps")
  end,
})
