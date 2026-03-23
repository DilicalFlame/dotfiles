-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    require("persistence").save()
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.cmd("silent! !printf '\\e[?1049l\\e[?25h'")
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    print("Neovim exiting cleanly...")
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  callback = function()
    -- Keep restored layout exactly as it was saved.
  end,
})

-- stay in terminal mode when entering
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(ev)
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.spell = false
    vim.opt_local.list = false
    vim.opt_local.wrap = false
    vim.opt_local.winfixwidth = false
    vim.opt_local.winfixheight = false

    -- Avoid expensive statusline updates in terminal buffers where input latency matters.
    pcall(vim.api.nvim_set_option_value, "statuscolumn", "", { scope = "local", win = vim.fn.bufwinid(ev.buf) })

    vim.cmd("startinsert")
  end,
})

