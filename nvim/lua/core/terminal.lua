local M = {}

M.terminals = {}

local function create_terminal(opts)
  opts = opts or {}
  local name = opts.name or "default"

  if M.terminals[name] and vim.api.nvim_buf_is_valid(M.terminals[name]) then
    vim.cmd("buffer " .. M.terminals[name])
    return
  end

  vim.cmd("split")
  vim.cmd("terminal")

  local buf = vim.api.nvim_get_current_buf()
  M.terminals[name] = buf

  vim.bo[buf].buflisted = true
  vim.bo[buf].filetype = "terminal"

  vim.cmd("startinsert")
end

function M.open(name)
  create_terminal({ name = name })
end

function M.list()
  return M.terminals
end

function M.float()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
  })

  vim.fn.jobstart({ "pwsh", "-NoLogo" }, { term = true })

  vim.cmd("startinsert")

  -- manual close
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, silent = true })

  -- auto close on exit
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
end

function M.fullscreen()
  local name = "fullscreen"

  if M.terminals[name] and vim.api.nvim_buf_is_valid(M.terminals[name]) then
    vim.cmd("buffer " .. M.terminals[name])
    vim.cmd("only")
    vim.cmd("startinsert")
    return
  end

  vim.cmd("enew")
  vim.cmd("terminal")

  local buf = vim.api.nvim_get_current_buf()
  M.terminals[name] = buf

  vim.bo[buf].buflisted = true
  vim.bo[buf].filetype = "terminal"

  -- Keep the terminal as the only visible window in the current tab.
  vim.cmd("only")
  vim.cmd("startinsert")
end

return M
