local function group(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end
local au = vim.api.nvim_create_autocmd

-- Close helper windows with q
au("FileType", {
  group = group("close_with_q"),
  pattern = {
    "PlenaryTestPopup", "checkhealth", "dap-float", "dbout", "gitsigns-blame", "grug-far", "help", "lspinfo",
    "neotest-output", "neotest-output-panel", "neotest-summary", "notify", "qf", "spectre_panel", "startuptime",
    "tsplayground",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
      end, { buffer = ev.buf, silent = true, desc = "Quit buffer" })
    end)
  end,
})

au("FileType", {
  group = group("man_unlisted"),
  pattern = "man",
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
  end,
})

-- Prose filetypes: wrap + spellcheck
au("FileType", {
  group = group("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

au("FileType", {
  group = group("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})
