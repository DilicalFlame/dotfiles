-- Format-on-save via conform.nvim (falls back to LSP formatting).
-- Toggle: vim.g.autoformat (global) / vim.b.autoformat (buffer); <leader>uf / <leader>uF.
local M = {}

function M.enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local b = vim.b[buf].autoformat
  if b ~= nil then
    return b
  end
  return vim.g.autoformat == nil or vim.g.autoformat
end

function M.enable(enable, buf_local)
  if buf_local then
    vim.b.autoformat = enable
  else
    vim.g.autoformat = enable
    vim.b.autoformat = nil
  end
  vim.notify(("Autoformat %s (%s)"):format(enable and "on" or "off", buf_local and "buffer" or "global"))
end

---@param opts? {force?: boolean, buf?: number}
function M.format(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  if not (opts.force or M.enabled(buf)) then
    return
  end
  require("conform").format({ bufnr = buf, timeout_ms = 3000, lsp_format = "fallback" })
end

function M.snacks_toggle(buf_local)
  return Snacks.toggle({
    name = "Auto Format (" .. (buf_local and "Buffer" or "Global") .. ")",
    get = function()
      return buf_local and M.enabled() or (vim.g.autoformat == nil or vim.g.autoformat)
    end,
    set = function(state)
      M.enable(state, buf_local)
    end,
  })
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("AutoFormat", { clear = true }),
  callback = function(ev)
    M.format({ buf = ev.buf })
  end,
})
vim.api.nvim_create_user_command("Format", function()
  M.format({ force = true })
end, { desc = "Format buffer" })

return M
