-- Format, diagnostics, hover, run Lua.
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ── Code: format, diagnostics, hover ────────────────────────────────────────
map({ "n", "x" }, "<leader>cf", function()
  require("util.format").format({ force = true })
end, { desc = "Format" })

local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

map("n", "K", function()
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/hover" }) > 0 then
    return vim.lsp.buf.hover()
  end
  if not pcall(vim.cmd, "normal! K") then
    vim.notify("No hover or help available.", vim.log.levels.WARN)
  end
end, { desc = "Hover / keyword help" })
-- ── Lua ─────────────────────────────────────────────────────────────────────
map({ "n", "x" }, "<localleader>r", function()
  Snacks.debug.run()
end, { desc = "Run Lua" })
