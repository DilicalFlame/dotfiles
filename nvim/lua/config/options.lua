-- Leader must be set before plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- Globals read by my own config
vim.g.autoformat = true -- format on save (see util/format.lua)
vim.g.markdown_recommended_style = 0
vim.g.snacks_animate = false

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 4
opt.signcolumn = "yes"
opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]

-- System integration
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.confirm = true -- ask instead of failing on unsaved changes
opt.autowrite = true

-- PowerShell as shell (settings from :help shell-powershell; -NoProfile keeps :! and system() fast/clean)
if vim.fn.executable("pwsh") == 1 then
  opt.shell = "pwsh"
  opt.shellcmdflag = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -Command "
    .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    .. "$ProgressPreference='SilentlyContinue';$PSStyle.OutputRendering='PlainText';"
  opt.shellredir = "2>&1 | Out-File -Encoding utf8 %s; exit $LastExitCode"
  opt.shellpipe = "2>&1 | Out-File -Encoding utf8 %s; exit $LastExitCode"
  opt.shellquote = ""
  opt.shellxquote = ""
end

-- Wrapping and indentation
opt.wrap = false
opt.linebreak = true
opt.autoindent = true
opt.smartindent = true
opt.breakindent = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true
opt.shiftround = true
opt.formatoptions = "jqlnt" -- no auto comment continuation

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.inccommand = "nosplit"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Viewport and display
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.cursorline = true
opt.showmode = false
opt.showtabline = 2
opt.laststatus = 3 -- global statusline
opt.ruler = false
opt.cmdheight = 0 -- no reserved cmdline row: statusline sits at the very bottom, ://? overlay it while typing
opt.conceallevel = 0
opt.termguicolors = true
opt.pumheight = 10
opt.pumblend = 10
opt.smoothscroll = true
opt.list = true
opt.winminwidth = 5
opt.virtualedit = "block"
opt.jumpoptions = "view"
opt.guicursor =
  "n-v-c-sm:block-blinkwait0-blinkon0-blinkoff0,i-ci-ve:ver25-blinkwait0-blinkon0-blinkoff0,r-cr-o:hor20-blinkwait0-blinkon0-blinkoff0,t:block-blinkwait0-blinkon0-blinkoff0"
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- Folding (treesitter/LSP switch foldmethod to "expr" per buffer)
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = ""

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Files and history
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.undolevels = 10000
opt.fileencoding = "utf-8"
opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Timing
opt.updatetime = 250
opt.timeoutlen = 300
opt.ttimeoutlen = 10

-- Completion and command line
opt.completeopt = "menuone,noselect"
opt.wildmode = "longest:full,full"
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.spelllang = { "en" }

-- Navigation
opt.whichwrap = "bs<>[]hl"
opt.backspace = "indent,eol,start"
opt.iskeyword:append("-")

-- Format with conform (falls back to LSP)
opt.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Native message UI (experimental, 0.12+): messages collapse as "[+N]" instead of "Press ENTER" (use g< for the rest).
-- Pairs with cmdheight=0. If it ever misbehaves, delete this block.
pcall(function()
  require("vim._core.ui2").enable({})
end)
