-- LuaLS setup for editing this Neovim config (vim.*, Snacks, lazy.nvim, lspconfig types).
return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "lazy" } },
        { path = "nvim-lspconfig", words = { "lspconfig.settings" } },
      },
    },
  },
}
