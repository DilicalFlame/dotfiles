-- Test runner (<leader>T*). Rust adapter comes from rustaceanvim.
return {
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim", "mrcjkb/rustaceanvim" },
    opts = {
      adapters = { ["rustaceanvim.neotest"] = {} },
      status = { virtual_text = true },
      output = { open_on_run = true },
      quickfix = {
        open = function()
          vim.cmd("copen")
        end,
      },
    },
    config = function(_, opts)
      -- compact one-line diagnostics from tests
      vim.diagnostic.config({
        virtual_text = {
          format = function(d)
            return (d.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", ""))
          end,
        },
      }, vim.api.nvim_create_namespace("neotest"))

      -- adapters given as { name = config }: require and (optionally) configure each
      local adapters = {}
      for name, config in pairs(opts.adapters) do
        if config ~= false then
          local adapter = require(name)
          if type(config) == "table" and not vim.tbl_isempty(config) then
            local meta = getmetatable(adapter)
            if adapter.setup then
              adapter.setup(config)
            elseif adapter.adapter then
              adapter.adapter(config)
              adapter = adapter.adapter
            elseif meta and meta.__call then
              adapter = adapter(config)
            else
              error("Adapter " .. name .. " does not support setup")
            end
          end
          adapters[#adapters + 1] = adapter
        end
      end
      opts.adapters = adapters

      require("neotest").setup(opts)
    end,
    -- stylua: ignore
    keys = {
      { "<leader>Ta", function() require("neotest").run.attach() end, desc = "Attach to Test" },
      { "<leader>Tr", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
      { "<leader>Tl", function() require("neotest").run.run_last() end, desc = "Run Last Test" },
      { "<leader>TR", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run Test File" },
      { "<leader>TA", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files" },
      { "<leader>Tm", function() require("neotest").summary.toggle() end, desc = "Toggle Test Summary" },
      { "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Test Output" },
      { "<leader>TO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Test Output Panel" },
      { "<leader>Tx", function() require("neotest").run.stop() end, desc = "Stop Test" },
      { "<leader>Tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Test Watch" },
      { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug Nearest Test" },
    },
  },
}
