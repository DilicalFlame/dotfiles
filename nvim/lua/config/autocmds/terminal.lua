local function group(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

-- Terminal buffers: clean look, start in insert mode
au("TermOpen", {
  group = group("term_open"),
  callback = function(ev)
    -- Plain terminals die with their window. Snacks terminals must survive hiding (they are toggled).
    if vim.bo[ev.buf].filetype ~= "snacks_terminal" then
      vim.bo[ev.buf].bufhidden = "wipe"
    end
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
    -- Avoid expensive statuscolumn updates where input latency matters.
    pcall(vim.api.nvim_set_option_value, "statuscolumn", "", { scope = "local", win = vim.fn.bufwinid(ev.buf) })
    vim.cmd("startinsert")
  end,
})

au("TermClose", {
  group = group("term_close"),
  desc = "Auto-close terminal window and wipe buffer on successful exit",
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
    -- vimade doesn't see this window change; without a nudge the editor stays faded until its next poll
    vim.schedule(function()
      if vim.fn.exists(":VimadeRedraw") == 2 then
        vim.cmd("VimadeRedraw")
      end
    end)
  end,
})
