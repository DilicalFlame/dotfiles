-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Line Numbers Display
vim.wo.number = true
vim.o.relativenumber = true

-- System Integration
vim.o.clipboard = "unnamedplus"
vim.o.mouse = "a"

-- Setup PowerShell as default shell
vim.o.shell = "pwsh"

-- Fix screen not clearing on exit
vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  callback = function()
    -- Explicitly flush the alternate screen buffer exit code
    io.stdout:write("\x1b[2J\x1b[H")
    io.stdout:flush()
  end,
})

-- Line Wrapping and Indentation
vim.o.wrap = false
vim.o.linebreak = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.breakindent = true

-- Search Configuration
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = false

-- Tab and Space Management
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true

-- Viewport and Display
vim.o.scrolloff = 10
vim.o.sidescrolloff = 8
vim.o.cursorline = true
vim.o.showmode = false
vim.opt.termguicolors = true
vim.o.numberwidth = 4
vim.o.showtabline = 2
vim.o.conceallevel = 0
vim.wo.signcolumn = "yes"
vim.o.cmdheight = 1

-- Configure listchars to show spaces as dots
-- vim.o.list = true
-- vim.opt.listchars:append({ space = "·", tab = "» ", trail = "·", nbsp = "␣" })

-- Window Splits
vim.o.splitbelow = true
vim.o.splitright = true

-- File Management and History
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false
vim.o.undofile = true
vim.o.fileencoding = "utf-8"

-- Timing and Event Delays
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Completion and Menu Settings
vim.o.pumheight = 10
vim.o.completeopt = "menuone,noselect"
vim.opt.shortmess:append("c")

-- Navigation and Editing
vim.o.whichwrap = "bs<>[]hl"
vim.o.backspace = "indent,eol,start"
vim.opt.iskeyword:append("-")

-- Auto-formatting Preferences
vim.opt.formatoptions:remove({ "c", "r", "o" })

-- Path Isolation
vim.opt.runtimepath:remove("/usr/share/vim/vimfiles")
