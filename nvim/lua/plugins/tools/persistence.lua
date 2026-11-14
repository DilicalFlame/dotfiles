-- Sessions are saved automatically on exit (per folder + git branch).
return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    dir = vim.fn.stdpath("state") .. "/sessions/",
    need = 1,
    branch = true,
  },
  -- stylua: ignore
  keys = {
    { "<leader>pr", function() require("persistence").load(); vim.cmd("redraw!") end, desc = "Restore session (cwd)" },
    { "<leader>pl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>ps", function() require("persistence").select() end, desc = "Select session" },
    { "<leader>pd", function() require("persistence").stop() end, desc = "Don't save this session" },
  },
}
