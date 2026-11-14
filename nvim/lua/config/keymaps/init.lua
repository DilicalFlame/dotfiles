-- Loaded on VeryLazy (after plugins, so these override plugin defaults).
-- Logic lives in lua/util and lua/features; plugin-specific keys live next to each plugin spec.
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })
for _, m in ipairs({ "editing", "navigation", "terminal", "code", "toggles", "git" }) do
  require("config.keymaps." .. m)
end
