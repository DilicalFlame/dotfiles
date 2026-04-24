return {
  -- Style blink.cmp for a cleaner, balanced completion UI.
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts = opts or {}
      opts.completion = opts.completion or {}
      opts.completion.list = opts.completion.list or {}
      opts.completion.list.selection = vim.tbl_deep_extend("force", opts.completion.list.selection or {}, {
        preselect = true,
        auto_insert = false,
      })

      opts.completion.menu = vim.tbl_deep_extend("force", opts.completion.menu or {}, {
        min_width = 28,
        max_height = 12,
        border = "rounded",
        winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        draw = {
          columns = {
            { "kind_icon" },
            { "label", "label_description", gap = 1 },
          },
        },
      })

      opts.completion.documentation = vim.tbl_deep_extend("force", opts.completion.documentation or {}, {
        auto_show = false,
        auto_show_delay_ms = 300,
        update_delay_ms = 120,
        treesitter_highlighting = true,
        window = {
          min_width = 20,
          max_width = 52,
          max_height = 8,
          border = "rounded",
          scrollbar = true,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
          direction_priority = {
            menu_north = { "e", "w", "n", "s" },
            menu_south = { "e", "w", "s", "n" },
          },
        },
      })
      opts.completion.documentation.auto_show = false

      opts.completion.ghost_text = vim.tbl_deep_extend("force", opts.completion.ghost_text or {}, {
        enabled = false,
      })

      opts.signature = vim.tbl_deep_extend("force", opts.signature or {}, {
        enabled = true,
        window = {
          max_width = 60,
          max_height = 5,
          border = "rounded",
          show_documentation = false,
        },
      })

      opts.keymap = opts.keymap or {}
      opts.keymap["<C-u>"] = { "scroll_documentation_up", "fallback" }
      opts.keymap["<C-d>"] = { "scroll_documentation_down", "fallback" }

      return opts
    end,
  },
}
