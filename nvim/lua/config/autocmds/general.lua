local function group(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

require("util.format") -- registers format-on-save

-- Clear the screen on exit (WezTerm leaves artifacts otherwise)
au("VimLeave", {
  group = group("clear_on_exit"),
  callback = function()
    io.stdout:write("\x1b[2J\x1b[H")
    io.stdout:flush()
  end,
})

-- Reload files changed outside nvim
au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

au("TextYankPost", {
  group = group("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Keep splits equal when the terminal is resized
au("VimResized", {
  group = group("resize_splits"),
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. tab)
  end,
})

-- Jump to the last known cursor position
au("BufReadPost", {
  group = group("last_loc"),
  callback = function(ev)
    local buf = ev.buf
    if vim.bo[buf].filetype == "gitcommit" or vim.b[buf].last_loc_done then
      return
    end
    vim.b[buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
-- Create missing parent directories on save
au("BufWritePre", {
  group = group("auto_create_dir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
