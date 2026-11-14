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

-- Closing a full-width terminal split makes Neovim focus the LEFTMOST window of the row above. In a markdown preview
-- (no-neck-pain: pad | text | pad) that is the empty left pad, not your text. Remember the last real editing window
-- and go back to it when a terminal window closes (hide or exit).
local last_edit_win
local function is_edit_win(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.api.nvim_win_get_config(win).relative == ""
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].filetype ~= "no-neck-pain"
end
-- WinLeave too: the window you start in never fires WinEnter, so it would otherwise never be remembered.
au({ "WinEnter", "WinLeave" }, {
  group = group("term_return_track"),
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_edit_win(win) then
      last_edit_win = win
    end
  end,
})
--- If focus ended up on a no-neck-pain pad, move it to the editing window.
local function return_focus()
  local cur = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(cur)].filetype ~= "no-neck-pain" then
    return
  end
  local target = last_edit_win
  if not (target and vim.api.nvim_win_is_valid(target)) then
    target = vim.tbl_filter(is_edit_win, vim.api.nvim_tabpage_list_wins(0))[1]
  end
  if target then
    vim.api.nvim_set_current_win(target)
  end
end
-- hide (<c-/>, <leader>tt ...): the terminal window is closed by Snacks
au("WinClosed", {
  group = group("term_return"),
  callback = function(ev)
    local win = tonumber(ev.match)
    if win and vim.api.nvim_win_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then
      vim.schedule(return_focus)
    end
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
    -- exit: the window was closed right here (no WinClosed reaches the handler above)
    vim.schedule(return_focus)
    -- vimade doesn't see this window change; without a nudge the editor stays faded until its next poll
    vim.schedule(function()
      if vim.fn.exists(":VimadeRedraw") == 2 then
        vim.cmd("VimadeRedraw")
      end
    end)
  end,
})
