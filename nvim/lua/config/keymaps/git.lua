-- Git.
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local root = require("util.root")
-- ── Git ─────────────────────────────────────────────────────────────────────
if vim.fn.executable("lazygit") == 1 then
  map("n", "<leader>gg", function()
    Snacks.lazygit({ cwd = root.git() })
  end, { desc = "Lazygit (Root Dir)" })
  map("n", "<leader>gG", function()
    Snacks.lazygit()
  end, { desc = "Lazygit (cwd)" })
end
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, { desc = "Git Log (cwd)" })
map("n", "<leader>gb", function()
  Snacks.picker.git_log_line()
end, { desc = "Git Blame Line" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git Current File History" })
map("n", "<leader>gl", function()
  Snacks.picker.git_log({ cwd = root.git() })
end, { desc = "Git Log" })
map({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })
