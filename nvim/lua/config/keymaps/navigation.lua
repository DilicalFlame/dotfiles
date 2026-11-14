-- Files, buffers, windows, tabs, explorer, lists.
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local buffers = require("util.buffers")
-- ── Files / quitting ────────────────────────────────────────────────────────
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<leader>fS", "<cmd>noautocmd w<CR>", { desc = "Save without formatting" })
map("n", "<C-q>", "<cmd>qa<CR>", opts)
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<leader>ff", function()
  Snacks.picker.files({ hidden = true, ignored = true, follow = true })
end, { desc = "Find files (incl. hidden/ignored)" })
map("n", "<leader>fp", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("data") .. "/lazy" })
end, { desc = "Find plugin file" })
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy (plugins)" })
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- ── Buffers ─────────────────────────────────────────────────────────────────
-- <S-h>/<S-l>/[b/]b and pin/close-others live in plugins/ui/bufferline.lua
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers (fuzzy find)" })
map("n", "<leader>bd", buffers.delete, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bi", function()
  Snacks.bufdelete.invisible()
end, { desc = "Delete Invisible Buffers" })
map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })
map("n", "<leader>q", buffers.smart_close, { desc = "Smart close" })

-- ── Windows ─────────────────────────────────────────────────────────────────
map("n", "<leader>v", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>h", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>we", "<C-w>=", { desc = "Equalize splits" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Split navigation that also works from insert/terminal/cmdline mode
local function navigate_split(dir)
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == "c" then
    vim.api.nvim_feedkeys(vim.keycode("<C-c>"), "n", false)
    return vim.schedule(function()
      vim.cmd("wincmd " .. dir)
    end)
  end
  local was_insert = mode == "i" or mode == "t"
  if was_insert then
    vim.cmd("stopinsert")
  end
  vim.cmd("wincmd " .. dir)
  if was_insert then
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  end
end

for key, dir in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
  map("n", "<C-" .. key .. ">", function()
    navigate_split(dir)
  end, { desc = "Go to split " .. dir, silent = true })
end
for key, dir in pairs({ Left = "h", Down = "j", Up = "k", Right = "l" }) do
  map({ "n", "i", "c" }, "<M-" .. key .. ">", function()
    navigate_split(dir)
  end, { desc = "Go to split " .. dir, silent = true })
end

-- ── Tabs ────────────────────────────────────────────────────────────────────
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
-- ── Explorer / theme ─────────────────────────────────────────────
map("n", "<leader>e", function()
  require("util.explorer").toggle()
end, { desc = "Explorer" })
map("n", "<leader>uC", function()
  require("util.theme").picker()
end, { desc = "Switch theme" })
map("n", "<leader>n", "<cmd>messages<cr>", { desc = "Messages" })

-- ── Lists ───────────────────────────────────────────────────────────────────
map("n", "<leader>xl", function()
  local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })
