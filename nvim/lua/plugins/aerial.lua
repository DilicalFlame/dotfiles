local symbol_text_highlights = {
  Array = "Type",
  Boolean = "Boolean",
  Class = "Type",
  Constant = "Constant",
  Constructor = "Special",
  Enum = "Type",
  EnumMember = "Constant",
  Event = "Special",
  Field = "@field",
  File = "Directory",
  Function = "Function",
  Interface = "Type",
  Key = "@property",
  Method = "Function",
  Module = "Include",
  Namespace = "Include",
  Number = "Number",
  Object = "Type",
  Operator = "Operator",
  Package = "Include",
  Property = "@property",
  String = "String",
  Struct = "Type",
  TypeParameter = "Type",
  Variable = "@variable",
}

local symbol_icon_highlights = {
  Class = "DiagnosticInfo",
  Constant = "DiagnosticWarn",
  Constructor = "Special",
  Enum = "DiagnosticInfo",
  EnumMember = "DiagnosticWarn",
  Field = "DiagnosticHint",
  Function = "DiagnosticOk",
  Interface = "DiagnosticInfo",
  Method = "DiagnosticOk",
  Module = "DiagnosticInfo",
  Namespace = "DiagnosticInfo",
  Property = "DiagnosticHint",
  Struct = "DiagnosticInfo",
  Variable = "DiagnosticHint",
}

return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    {
      "<leader>o",
      function()
        require("aerial").toggle()
      end,
      desc = "Aerial: Toggle",
    },
  },
  opts = {
    backends = { "lsp", "treesitter", "markdown", "asciidoc", "man" },
    -- Keep symbols panel on the right and track current window context.
    layout = {
      default_direction = "right",
      placement = "edge",
      min_width = 28,
      max_width = { 40, 0.25 },
      resize_to_content = true,
      win_opts = {
        cursorline = true,
      },
    },
    attach_mode = "global",
    open_automatic = false,
    close_automatic_events = {},
    close_on_select = true,
    filter_kind = false,
    show_guides = true,
    highlight_mode = "full_width",
    get_highlight = function(symbol, is_icon, is_collapsed)
      if is_icon then
        return symbol_icon_highlights[symbol.kind] or "Special"
      end

      return symbol_text_highlights[symbol.kind] or "Normal"
    end,
  },
}
