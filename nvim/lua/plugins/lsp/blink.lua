-- Completion. Keys: <CR> accept, <C-y> accept, <Tab> next snippet field, <C-space> menu, <C-e> hide.
local icons = require("config.icons")

-- Native snippet expansion that tolerates nested placeholders some LSP servers send.
local function snippet_preview(snippet)
  local ok, parsed = pcall(function()
    return vim.lsp._snippet_grammar.parse(snippet)
  end)
  return ok and tostring(parsed) or snippet:gsub("%$%b{}", function(m)
    local _, text = m:match("^%${(%d+):(.+)}$")
    return text and snippet_preview(text) or m
  end):gsub("%$0", "")
end

local function snippet_fix(snippet)
  local texts = {}
  return snippet:gsub("%$%b{}", function(m)
    local n, text = m:match("^%${(%d+):(.+)}$")
    if not n then
      return m
    end
    texts[n] = texts[n] or snippet_preview(text)
    return "${" .. n .. ":" .. texts[n] .. "}"
  end)
end

local function expand(snippet)
  -- Native sessions don't support nesting: always keep the top-level session.
  local session = vim.snippet.active() and vim.snippet._session or nil
  local ok, err = pcall(vim.snippet.expand, snippet)
  if not ok then
    ok = pcall(vim.snippet.expand, snippet_fix(snippet))
    vim.notify(ok and "Failed to parse snippet, but fixed it automatically." or ("Failed to parse snippet.\n" .. err),
      ok and vim.log.levels.WARN or vim.log.levels.ERROR, { title = "vim.snippet" })
  end
  if session then
    vim.snippet._session = session
  end
end

local function snippet_forward()
  if vim.snippet.active({ direction = 1 }) then
    vim.schedule(function()
      vim.snippet.jump(1)
    end)
    return true
  end
end

return {
  {
    "saghen/blink.cmp",
    version = "*", -- release tags ship a prebuilt fuzzy-matcher binary
    dependencies = { "rafamadriz/friendly-snippets" },
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      snippets = { preset = "default", expand = expand },
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
        kind_icons = icons.kinds,
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = { draw = { treesitter = { "lsp" } } },
        documentation = { auto_show = false },
        ghost_text = { enabled = true },
      },
      signature = { enabled = false, window = { show_documentation = false } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline", ["<Right>"] = false, ["<Left>"] = false },
        completion = {
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function()
              return vim.fn.getcmdtype() == ":"
            end,
          },
          ghost_text = { enabled = true },
        },
        -- `:!` completion scans every PATH dir synchronously and stalls typing, so skip it there.
        sources = function()
          local t = vim.fn.getcmdtype()
          if t == "/" or t == "?" then
            return { "buffer" }
          end
          if t == ":" and not vim.fn.getcmdline():match("^%s*!") then
            return { "buffer", "cmdline" }
          end
          return {}
        end,
      },
      keymap = {
        preset = "enter",
        ["<C-y>"] = { "select_and_accept" },
        ["<Tab>"] = { snippet_forward, "fallback" },
      },
    },
  },
}
