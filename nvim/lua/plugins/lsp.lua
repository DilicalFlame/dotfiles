local python_env = require("core.python_env")

return {
  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {
          settings = {
            python = {
              analysis = {
                -- Keep completions/hover/import intelligence but avoid strict typing noise.
                typeCheckingMode = "off",
                diagnosticMode = "openFilesOnly",
              },
            },
          },
          before_init = function(_, config)
            local root_dir = config.root_dir or vim.fn.getcwd()
            local python_path = python_env.python_for_root(root_dir)

            if not python_path then
              python_env.activate(root_dir)
              python_path = python_env.python_for_root(root_dir)
            end

            if python_path then
              config.settings = config.settings or {}
              config.settings.python = config.settings.python or {}
              config.settings.python.pythonPath = python_path
            end
          end,
        },
        -- Enables symbols for javascript/typescript files (including .cjs)
        ts_ls = {},
      },
    },
  },
}
