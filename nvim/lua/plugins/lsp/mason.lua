return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      -- Tools (formatters/linters/debuggers); LSP servers are installed by mason-lspconfig (see lsp.lua).
      ensure_installed = {
        "lua-language-server",
        "rust-analyzer",
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "clangd",
        "prettier",
        "codelldb", -- Rust debugger
        "js-debug-adapter", -- JS/TS debugger
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- re-trigger FileType so a freshly installed server attaches without restarting
          require("lazy.core.handler.event").trigger({ event = "FileType", buf = vim.api.nvim_get_current_buf() })
        end, 100)
      end)
      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local ok, pkg = pcall(mr.get_package, tool)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },
}
