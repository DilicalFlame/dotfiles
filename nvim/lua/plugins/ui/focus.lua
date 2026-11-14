return {
  {
    "nvim-focus/focus.nvim",
    version = false,
    config = function(_, opts)
      require("focus").setup(opts)
      -- Sidebars/pickers must never be auto-resized.
      local skip = vim.list_extend({ "notify", "snacks_picker_list", "snacks_picker_input" }, opts.autoresize.exclude_filetypes)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("FocusDisable", { clear = true }),
        callback = function()
          vim.b.focus_disable = vim.tbl_contains(skip, vim.bo.filetype)
        end,
      })
    end,
    opts = {
      autoresize = {
        enable = true,
        exclude_filetypes = { "neo-tree", "neo-tree-popup", "neo-tree-filter", "aerial", "aerial-nav" },
      },
    },
  },
  {
    "tadaa/vimade",
    event = "UIEnter",
    opts = {
      recipe = { "duo", { animate = false } },
      fadelevel = 0.5,
      ncmode = "windows",
      checkinterval = 250, -- ms; default 1000 makes missed window changes linger
    },
  },
}
