return {
  -- Cargo.toml: crate versions, completion, code actions
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = { crates = { enabled = true } },
      lsp = { enabled = true, actions = true, completion = true, hover = true },
    },
  },

  {
    "mrcjkb/rustaceanvim",
    ft = { "rust" },
    opts = {
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>cR", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "Code Action", buffer = bufnr })
          vim.keymap.set("n", "<leader>dr", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })
        end,
        default_settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true, loadOutDirsFromCheck = true, buildScripts = { enable = true } },
            checkOnSave = true, -- clippy lints
            diagnostics = { enable = true },
            procMacro = { enable = true },
            files = {
              exclude = { ".direnv", ".git", ".jj", ".github", ".gitlab", "bin", "node_modules", "target", "venv", ".venv" },
              -- avoids "Roots Scanned" hanging, see rust-lang/rust-analyzer#12613
              watcher = "client",
            },
          },
        },
      },
    },
    config = function(_, opts)
      -- debugger adapter (codelldb comes from mason)
      local ext = vim.fn.has("win32") == 1 and ".dll" or (vim.fn.has("mac") == 1 and ".dylib" or ".so")
      opts.dap = {
        adapter = require("rustaceanvim.config").get_codelldb_adapter(
          vim.fn.exepath("codelldb"),
          vim.fn.expand("$MASON/opt/lldb/lib/liblldb" .. ext)
        ),
      }
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts)
      if vim.fn.executable("rust-analyzer") == 0 then
        vim.notify("rust-analyzer not found in PATH (:Mason -> rust-analyzer)", vim.log.levels.ERROR)
      end
    end,
  },
}
