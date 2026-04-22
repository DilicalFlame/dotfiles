local function should_attach(bufnr, bufname)
  if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
    return false
  end

  local name = bufname or vim.api.nvim_buf_get_name(bufnr)
  local lower = name:lower()

  -- Keep Copilot away from common secret/config files.
  if lower:match("%.env") or lower:match("secrets?") or lower:match("credentials?") then
    return false
  end
  -- Skip very large files to reduce latency and noise.
  local stat = vim.uv.fs_stat(name)
  if stat and stat.size and stat.size > 512 * 1024 then
    return false
  end

  return true
end

local function toggle_inline_completions()
  if vim.g.copilot_inline_completions_enabled == nil then
    vim.g.copilot_inline_completions_enabled = true
  end

  vim.g.copilot_inline_completions_enabled = not vim.g.copilot_inline_completions_enabled
  local enabled = vim.g.copilot_inline_completions_enabled

  if enabled then
    vim.cmd("Copilot enable")
  else
    pcall(vim.cmd, "Copilot suggestion dismiss")
    vim.cmd("Copilot disable")
  end

  vim.notify("Copilot inline completions: " .. (enabled and "ON" or "OFF"), vim.log.levels.INFO)
end

return {
  "zbirenbaum/copilot.lua",
  event = { "InsertEnter", "VeryLazy" },
  cmd = "Copilot",
  keys = {
    { "<leader>aa", "<cmd>Copilot auth<cr>", desc = "Copilot Auth" },
    { "<leader>as", "<cmd>Copilot status<cr>", desc = "Copilot Status" },
    { "<leader>ap", "<cmd>Copilot panel toggle<cr>", desc = "Copilot Panel Toggle" },
    { "<leader>at", "<cmd>Copilot suggestion toggle_auto_trigger<cr>", desc = "Copilot Toggle Auto Trigger" },
    { "<leader>ai", toggle_inline_completions, desc = "Copilot Toggle Inline Completions" },
    { "<leader>am", "<cmd>Copilot model select<cr>", desc = "Copilot Model Select" },
    { "<leader>aw", "<cmd>Copilot workspace add .<cr>", desc = "Copilot Add Workspace" },
  },
  opts = function()
    local ai_cmp = vim.g.ai_cmp

    return {
      panel = {
        enabled = false,
        auto_refresh = true,
        layout = {
          position = "right",
          ratio = 0.35,
        },
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = ai_cmp,
        debounce = 25,
        trigger_on_accept = true,
        keymap = {
          accept = "<Tab>",
          accept_word = false,
          accept_line = false,
          next = false,
          prev = false,
          dismiss = "<C-]>",
        },
      },
      filetypes = {
        markdown = true,
        help = true,
        gitcommit = true,
        yaml = true,
      },
      should_attach = should_attach,
      logger = {
        file = vim.fn.stdpath("log") .. "/copilot-lua.log",
        file_log_level = vim.log.levels.OFF,
        print_log_level = vim.log.levels.WARN,
        trace_lsp = "off",
        trace_lsp_progress = false,
        log_lsp_messages = false,
      },
      server = {
        type = "nodejs",
      },
      server_opts_overrides = {
        settings = {
          advanced = {
            listCount = 10,
            inlineSuggestCount = 3,
          },
        },
      },
      workspace_folders = {
        vim.fn.getcwd(),
      },
      disable_limit_reached_message = false,
    }
  end,
}
