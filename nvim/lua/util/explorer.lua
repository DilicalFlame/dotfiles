local M = {}

-- true = snacks explorer, false = Neo-tree
M.use_snacks = false

function M.toggle()
  if M.use_snacks then
    Snacks.explorer()
  else
    vim.cmd("Neotree toggle")
  end
end

return M
