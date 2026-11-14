-- Bootstrap lazy.nvim (the plugin manager).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- `event = "LazyFile"`: fires when a real file is opened (BufReadPre-ish), not on the dashboard.
local Event = require("lazy.core.handler.event")
Event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPost", "BufNewFile", "BufWritePre" } }
Event.mappings["User LazyFile"] = Event.mappings.LazyFile

require("lazy").setup({
  spec = {
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.tools" },
    { import = "plugins.ui" },
  },
  defaults = {
    lazy = false, -- specs without event/cmd/keys/ft load at startup
    version = false,
  },
  install = { colorscheme = { "miasma", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})

-- All plugins are on the runtimepath now, so the saved theme resolves.
require("util.theme").load()
