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
    vim.bo[ev.buf].bufhidden = "wipe"

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

vim.api.nvim_create_autocmd("TermClose", {
  callback = function(ev)
    if type(vim.v.event) == "table" and vim.v.event.status and vim.v.event.status ~= 0 then
      return
    end

    local buf = ev.buf
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      pcall(vim.api.nvim_win_close, win, true)
    end

    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end,
  desc = "Auto-close terminal window and wipe terminal buffer on successful exit",
})

local ignore_filetypes = {
  "neo-tree",
  "neo-tree-popup",
  "neo-tree-filter",
  "notify",
  "TelescopePrompt",
  "snacks_picker_list",
  "snacks_picker_input",
}

local augroup = vim.api.nvim_create_augroup("FocusDisable", { clear = true })


vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(_)
    if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
      vim.b.focus_disable = true
    else
      vim.b.focus_disable = false
    end
  end,
  desc = "Disable focus autoresize for FileType",
})

local python_env = require("core.python_env")
local python_env_group = vim.api.nvim_create_augroup("ProjectPythonEnv", { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  group = python_env_group,
  callback = function()
    python_env.activate(vim.fn.getcwd())
  end,
  desc = "Auto-detect and activate project Python virtualenv from cwd",
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = python_env_group,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then
      return
    end

    local path = vim.api.nvim_buf_get_name(ev.buf)
    if path == "" then
      return
    end

    python_env.activate(path)
  end,
  desc = "Auto-detect and activate project Python virtualenv from file buffers",
})