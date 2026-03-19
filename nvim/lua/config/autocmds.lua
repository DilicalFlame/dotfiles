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
    -- normalize state after restore
    vim.cmd("silent! only") -- remove weird splits if any
  end,
})

-- stay in terminal mode when entering
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.cmd("startinsert")
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    require("persistence").save()
  end,
})
