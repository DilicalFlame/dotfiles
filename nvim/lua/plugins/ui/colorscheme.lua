-- Theme plugins. The active theme is persisted by util/theme.lua (<leader>st to switch);
-- config/lazy.lua loads it once all plugins are on the runtimepath.
local function theme(spec)
  return vim.tbl_extend("keep", spec, { lazy = false, priority = 1000 })
end

return {
  theme({ "xero/miasma.nvim" }),
  theme({ "folke/tokyonight.nvim", opts = { style = "moon" } }),
  theme({
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      lsp_styles = {
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
      integrations = {
        aerial = true,
        blink_cmp = true,
        flash = true,
        gitsigns = true,
        grug_far = true,
        mason = true,
        mini = true,
        neotest = true,
        neotree = true,
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
  }),
  theme({ "rebelot/kanagawa.nvim" }),
  theme({ "EdenEast/nightfox.nvim" }),
  theme({ "navarasu/onedark.nvim" }),
  theme({ "ellisonleao/gruvbox.nvim" }),
  theme({ "sainnhe/everforest" }),
  theme({ "rose-pine/neovim", name = "rose-pine" }),

  -- Make bufferline match catppuccin when it is the active theme.
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      if (vim.g.colors_name or ""):find("catppuccin") then
        opts.highlights = require("catppuccin.special.bufferline").get_theme()
      end
    end,
  },
}
