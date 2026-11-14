-- Debugging. <leader>d* keys. Adapters: codelldb (Rust, see lsp/rust.lua), js-debug-adapter (JS/TS, below).
local icons = require("config.icons")

-- prompt for program arguments before launching
local function get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  local args_str = type(args) == "table" and table.concat(args, " ") or args
  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str))
    if config.type and config.type == "java" then
      return new_args
    end
    return require("dap.utils").splitstr(new_args)
  end
  return config
end

local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
      "jay-babu/mason-nvim-dap.nvim",
    },
    -- stylua: ignore
    keys = {
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end, desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
      for name, sign in pairs(icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define("Dap" .. name, { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] })
      end

      -- launch.json support (allow comments)
      local json = require("plenary.json")
      require("dap.ext.vscode").json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end

      -- JS/TS via js-debug-adapter
      local dap = require("dap")
      for _, adapter_type in ipairs({ "node", "chrome", "msedge" }) do
        local pwa = "pwa-" .. adapter_type
        if not dap.adapters[pwa] then
          dap.adapters[pwa] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = { command = "js-debug-adapter", args = { "${port}" } },
          }
        end
        if not dap.adapters[adapter_type] then
          dap.adapters[adapter_type] = function(cb, config)
            local native = dap.adapters[pwa]
            config.type = pwa
            if type(native) == "function" then
              native(cb, config)
            else
              cb(native)
            end
          end
        end
      end

      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = js_filetypes
      vscode.type_to_filetypes["pwa-node"] = js_filetypes

      for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
          local runtime = language:find("typescript") and (vim.fn.executable("tsx") == 1 and "tsx" or "ts-node") or nil
          local common = {
            type = "pwa-node",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            runtimeExecutable = runtime,
            skipFiles = { "<node_internals>/**", "node_modules/**" },
            resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
          }
          dap.configurations[language] = {
            vim.tbl_extend("force", common, { request = "launch", name = "Launch file", program = "${file}" }),
            vim.tbl_extend("force", common, {
              request = "attach",
              name = "Attach",
              processId = require("dap.utils").pick_process,
            }),
          }
        end
      end
    end,
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
    opts = {},
    config = function(_, opts)
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },

  -- mason integration: installs/configures debug adapters
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason-org/mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      automatic_installation = { exclude = { "chrome" } }, -- chrome adapter is deprecated; js-debug-adapter replaces it
      handlers = {},
      ensure_installed = {},
    },
    config = function() end, -- set up by nvim-dap's config order; nothing to do here
  },
}
