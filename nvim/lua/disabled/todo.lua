local M = {}

local todo_file = vim.fn.stdpath("data") .. "/todo.md"

-- Ensure file exists
local function ensure_file()
  if vim.fn.filereadable(todo_file) == 0 then
    vim.fn.writefile({ "# TODOs", "" }, todo_file)
  end
end

-- Open floating window
function M.open()
  ensure_file()

  local buf = vim.fn.bufadd(todo_file)
  vim.fn.bufload(buf)

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.6)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
  })

  vim.bo[buf].filetype = "markdown"

  local opts = { buffer = buf, silent = true }

  -- Close
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, opts)

  -- Toggle checkbox
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()

    if line:match("%- %[ %]") then
      line = line:gsub("%- %[ %]", "- [x]")
    elseif line:match("%- %[x%]") then
      line = line:gsub("%- %[x%]", "- [ ]")
    end

    vim.api.nvim_set_current_line(line)
  end, opts)

  vim.keymap.set("n", "a", function()
    local text = "- [ ] "
    vim.api.nvim_put({ text }, "l", true, true)
    vim.cmd("normal! $")
    vim.cmd("startinsert!")
  end, opts)

  -- Delete task
  vim.keymap.set("n", "dd", function()
    vim.cmd("normal! dd")
  end, opts)
end

-- Toggle (open/close)
function M.toggle()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf) == todo_file then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  M.open()
end

return M
