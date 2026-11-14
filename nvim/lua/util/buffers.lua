local M = {}

function M.delete()
  Snacks.bufdelete({ force = true })
end

-- Context-aware close: floats/pickers/explorers close themselves,
-- real buffers are deleted (layout kept), anything else closes its window.
function M.smart_close()
  local win = vim.api.nvim_get_current_win()
  local ft, bt = vim.bo.filetype, vim.bo.buftype

  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return vim.cmd("close")
  end

  if ft:match("^snacks_picker") then
    local pickers = Snacks.picker.get({ tab = true })
    if #pickers > 0 then
      return pickers[#pickers]:close()
    end
    return vim.cmd("close")
  end

  if ft == "neo-tree" then
    return vim.cmd("Neotree close")
  end
  if ft == "snacks_explorer" then
    return require("util.explorer").toggle()
  end

  -- Toggled terminals are hidden, not killed (the shell keeps running; reopen with the same key).
  if ft == "snacks_terminal" then
    return vim.cmd("hide")
  end

  if bt == "" or bt == "terminal" then
    return M.delete()
  end

  local normal = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))

  if #normal > 1 then
    vim.cmd("close")
  else
    vim.cmd("enew")
  end
end

return M
