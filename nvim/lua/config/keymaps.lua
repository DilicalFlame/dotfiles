-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local opts = { noremap = true, silent = true }

-- deleting some lazyvim made keymaps:
pcall(vim.keymap.del, "n", "<leader>qd")
pcall(vim.keymap.del, "n", "<leader>qs")
pcall(vim.keymap.del, "n", "<leader>qS")
pcall(vim.keymap.del, "n", "<leader>ql")
pcall(vim.keymap.del, "n", "<leader>st")
pcall(vim.keymap.del, "n", "<leader>e")

-- Disable default spacebar mapping to enable leader functionality
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Insert Mode
vim.keymap.set("i", "jj", "<Esc>", opts) -- Quickly exit insert mode

-- Terminal Mode
vim.keymap.set("t", "<C-]>", "<C-\\><C-n>", opts) -- Fast exit terminal mode without timeout side effects
vim.keymap.set("n", "<leader>tt", "<cmd>split | terminal<CR>", { desc = "Open terminal below" })
vim.keymap.set("n", "<leader>tv", "<cmd>vsplit | terminal<CR>", { desc = "Open terminal vertical" })

-- File Operations
vim.keymap.set("n", "<C-s>", "<cmd> w <CR>", opts) -- Save file
vim.keymap.set("n", "<leader>sn", "<cmd>noautocmd w <CR>", opts) -- Save file without auto-formatting
vim.keymap.set("n", "<C-q>", "<cmd> qa <CR>", opts) -- Quit completely (closes all windows)
vim.keymap.set("n", "<leader>qq", "<cmd> qa <CR>", opts) -- Quit completely (closes all windows)

-- Editing and Registers
vim.keymap.set("n", "x", '"_x', opts) -- Delete single character without copying to register
vim.keymap.set("v", "p", '"_dP', opts) -- Retain register content when pasting over visual selection

-- Visual Indentation
vim.keymap.set("v", "<", "<gv", opts) -- Stay in indent mode when unindenting
vim.keymap.set("v", ">", ">gv", opts) -- Stay in indent mode when indenting

-- Navigation and Search
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts) -- Vertical scroll down and center cursor
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts) -- Vertical scroll up and center cursor
vim.keymap.set("n", "n", "nzzzv", opts) -- Next search result and center cursor
vim.keymap.set("n", "N", "Nzzzv", opts) -- Previous search result and center cursor

-- Window Resizing
vim.keymap.set("n", "<Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<Left>", ":vertical resize +2<CR>", opts)
vim.keymap.set("n", "<Right>", ":vertical resize -2<CR>", opts)

-- Buffer Management
vim.keymap.set("n", "<Tab>", ":bnext<CR>", opts) -- Go to next buffer
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", opts) -- Go to previous buffer
vim.keymap.set("n", "<leader>x", ":bdelete!<CR>", opts) -- Close current buffer forcefully
vim.keymap.set("n", "<leader>b", "<cmd> enew <CR>", opts) -- Create new buffer

-- Window Split Management
vim.keymap.set("n", "<leader>v", "<C-w>v", opts) -- Split window vertically
vim.keymap.set("n", "<leader>h", "<C-w>s", opts) -- Split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", opts) -- Equalize split window dimensions
vim.keymap.set("n", "<leader>sx", ":close<CR>", opts) -- Close current split window
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Explorer NeoTree", silent = true })

local function navigate_split(direction)
  local mode = vim.api.nvim_get_mode().mode
  local started_in_insert = mode:sub(1, 1) == "i" or mode:sub(1, 1) == "t"

  if mode == "c" then
    local esc = vim.api.nvim_replace_termcodes("<C-c>", true, false, true)
    vim.api.nvim_feedkeys(esc, "n", false)
    vim.schedule(function()
      vim.cmd("wincmd " .. direction)
    end)
    return
  end

  if started_in_insert then
    vim.cmd("stopinsert")
    vim.cmd("wincmd " .. direction)
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
    return
  end

  vim.cmd("wincmd " .. direction)
end

vim.keymap.set({ "n", "i" }, "<C-h>", function()
  navigate_split("h")
end, { desc = "Go to left split", silent = true })
vim.keymap.set({ "n", "i" }, "<C-j>", function()
  navigate_split("j")
end, { desc = "Go to lower split", silent = true })
vim.keymap.set({ "n", "i" }, "<C-k>", function()
  navigate_split("k")
end, { desc = "Go to upper split", silent = true })
vim.keymap.set({ "n", "i" }, "<C-l>", function()
  navigate_split("l")
end, { desc = "Go to right split", silent = true })

vim.keymap.set({ "n", "i", "c" }, "<M-Left>", function()
  navigate_split("h")
end, { desc = "Go to left split", silent = true })
vim.keymap.set({ "n", "i", "c" }, "<M-Down>", function()
  navigate_split("j")
end, { desc = "Go to lower split", silent = true })
vim.keymap.set({ "n", "i", "c" }, "<M-Up>", function()
  navigate_split("k")
end, { desc = "Go to upper split", silent = true })
vim.keymap.set({ "n", "i", "c" }, "<M-Right>", function()
  navigate_split("l")
end, { desc = "Go to right split", silent = true })

-- Tab (Buffer) Management
vim.keymap.set("n", "<leader>to", "<cmd> enew <CR>", opts) -- Open new tab (buffer)
vim.keymap.set("n", "<leader>tx", "<cmd> Bdelete! <CR>", opts) -- Close current tab (buffer) safely without killing window
vim.keymap.set("n", "<leader>tn", ":bnext<CR>", opts) -- Go to next tab (buffer)
vim.keymap.set("n", "<leader>tp", ":bprevious<CR>", opts) -- Go to previous tab (buffer)

-- Utilities
vim.keymap.set("n", "<leader>lw", "<cmd>set wrap!<CR>", opts) -- Toggle line wrapping

local function toggle_vimade()
  if vim.fn.exists(":VimadeToggle") == 2 then
    vim.cmd("VimadeToggle")
    return
  end

  local can_enable = vim.fn.exists(":VimadeEnable") == 2
  local can_disable = vim.fn.exists(":VimadeDisable") == 2

  if not (can_enable and can_disable) then
    vim.notify("Vimade toggle command is unavailable", vim.log.levels.WARN)
    return
  end

  if vim.g.vimade_enabled == nil then
    vim.g.vimade_enabled = true
  end

  if vim.g.vimade_enabled then
    vim.cmd("VimadeDisable")
    vim.g.vimade_enabled = false
    vim.notify("Vimade: OFF", vim.log.levels.INFO)
  else
    vim.cmd("VimadeEnable")
    vim.g.vimade_enabled = true
    vim.notify("Vimade: ON", vim.log.levels.INFO)
  end
end

vim.keymap.set("n", "<leader>uv", toggle_vimade, { desc = "Toggle Vimade" })

-- Smart Universal Close (`<leader>q`)
local function smart_close()
  local api = vim.api

  local win = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()

  local buftype = vim.bo[buf].buftype
  local filetype = vim.bo[buf].filetype
  local bufname = api.nvim_buf_get_name(buf)

  local wins = api.nvim_tabpage_list_wins(0)
  local win_cfg = api.nvim_win_get_config(win)

  -- 1. Floating windows
  if win_cfg.relative and win_cfg.relative ~= "" then
    vim.cmd("close")
    return
  end

  -- 2. Special UI
  if filetype:match("^snacks_picker") then
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks and snacks.picker and snacks.picker.get then
      local pickers = snacks.picker.get({ tab = true })
      if type(pickers) == "table" and #pickers > 0 then
        local picker = pickers[#pickers]
        if picker and picker.close then
          picker:close()
          return
        end
      end
    end
    vim.cmd("close")
    return
  end

  if filetype == "neo-tree" then
    vim.cmd("Neotree close")
    return
  end

  local listed_buffers = vim.fn.getbufinfo({ buflisted = 1 })
  if #listed_buffers > 1 then
    vim.cmd("bdelete!")
    return
  end

  -- 4. Terminal
  if buftype == "terminal" then
    vim.cmd("bdelete!")
    return
  end

  -- 5. Safe window close
  local normal_wins = {}
  for _, w in ipairs(wins) do
    local cfg = api.nvim_win_get_config(w)
    if not (cfg.relative and cfg.relative ~= "") then
      table.insert(normal_wins, w)
    end
  end

  if #normal_wins > 1 then
    vim.cmd("close")
    return
  end

  -- 6. Final exit
  if bufname == "" or buftype ~= "" then
    vim.cmd("qa")
    return
  end

  vim.cmd("qa!")
end

vim.keymap.set("n", "<leader>q", smart_close, {
  desc = "Smart close",
  noremap = true,
  silent = true,
})

-- Diagnostic Navigation
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Navigate to previous diagnostic message" })

vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Navigate to next diagnostic message" })

vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Inspect diagnostic details in floating window" })
vim.keymap.set("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Populate quickfix list with diagnostics" })

vim.keymap.set("n", "<leader>sr", function()
  require("persistence").load()
  vim.cmd("redraw!")
end, { desc = "Restore session safely" })

vim.keymap.set("n", "<leader>st", function()
  local ok, theme = pcall(require, "core.theme")
  if not ok or type(theme.telescope_picker) ~= "function" then
    package.loaded["core.theme"] = nil
    ok, theme = pcall(require, "core.theme")
  end

  if ok and type(theme.telescope_picker) == "function" then
    theme.telescope_picker()
    return
  end

  vim.notify("Theme picker is unavailable; reload config and try again.", vim.log.levels.WARN)
end, { desc = "Switch Theme" })

-- vim.keymap.set("n", "<leader>td", function()
--   require("core.todo").toggle()
-- end, { desc = "Toggle TODO" })

-- Terminals
local term = require("core.terminal")

vim.keymap.set("n", "<leader>tf", function()
  require("core.terminal").float()
end, { desc = "Floating terminal" })

vim.keymap.set("n", "<leader>tF", function()
  term.fullscreen()
end, { desc = "Fullscreen terminal" })
