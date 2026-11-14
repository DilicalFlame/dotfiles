for _, m in ipairs({ "general", "filetypes", "terminal", "python" }) do
  require("config.autocmds." .. m)
end
