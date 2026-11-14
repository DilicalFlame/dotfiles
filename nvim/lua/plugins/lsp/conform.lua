-- Formatters. Format-on-save is wired in util/format.lua; <leader>cf formats now.
local prettier_fts = {
  "css", "graphql", "handlebars", "html", "javascript", "javascriptreact", "json", "jsonc", "less", "markdown",
  "markdown.mdx", "scss", "typescript", "typescriptreact", "vue", "yaml", "svelte",
}

-- prettier can infer a parser for more filetypes than the list above; ask it once per file and cache.
local parser_cache = {}
local function has_parser(ctx)
  local ft = vim.bo[ctx.buf].filetype
  if vim.tbl_contains(prettier_fts, ft) then
    return true
  end
  if parser_cache[ctx.filename] == nil then
    local out = vim.fn.system({ "prettier", "--file-info", ctx.filename })
    local ok, info = pcall(vim.fn.json_decode, out)
    parser_cache[ctx.filename] = (ok and info.inferredParser and info.inferredParser ~= vim.NIL) or false
  end
  return parser_cache[ctx.filename]
end

return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason-org/mason.nvim" },
    lazy = true, -- loaded on first format
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "x" },
        desc = "Format Injected Langs",
      },
    },
    opts = function()
      local by_ft = { lua = { "stylua" }, fish = { "fish_indent" }, sh = { "shfmt" } }
      for _, ft in ipairs(prettier_fts) do
        by_ft[ft] = { "prettier" }
      end
      return {
        default_format_opts = { timeout_ms = 3000, async = false, quiet = false, lsp_format = "fallback" },
        formatters_by_ft = by_ft,
        formatters = {
          injected = { options = { ignore_errors = true } },
          prettier = {
            condition = function(_, ctx)
              return has_parser(ctx)
            end,
          },
        },
      }
    end,
  },
}
