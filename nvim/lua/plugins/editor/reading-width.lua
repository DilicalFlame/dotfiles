-- Reading width: markdown preview shows the text in a centered column instead of edge to edge.
-- (Wide lines are hard on the eye. Wiring: plugins/editor/markdown.lua)
return {
  {
    "shortcuts/no-neck-pain.nvim",
    cmd = { "NoNeckPain" },
    opts = {
      width = 100,
      autocmds = { enableOnVimEnter = false, enableOnTabEnter = false },
      mappings = { enabled = false },
      buffers = { scratchPad = { enabled = false }, bo = { filetype = "no-neck-pain" } },
    },
  },
}
