local function group(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

-- Project Python venv: activate from cwd and from file buffers
local python_env = require("util.python_env")
local python_group = group("python_env")

au({ "VimEnter", "DirChanged" }, {
  group = python_group,
  desc = "Auto-detect and activate project Python virtualenv from cwd",
  callback = function()
    python_env.activate(vim.fn.getcwd())
  end,
})

au("BufEnter", {
  group = python_group,
  desc = "Auto-detect and activate project Python virtualenv from file buffers",
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then
      return
    end
    local path = vim.api.nvim_buf_get_name(ev.buf)
    if path ~= "" then
      python_env.activate(path)
    end
  end,
})
