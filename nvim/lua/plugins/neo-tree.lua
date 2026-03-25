return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "antosha417/nvim-lsp-file-operations",
    },
    cmd = "Neotree",
    opts = {
      enable_git_status = false,
      enable_diagnostics = false,
      close_if_last_window = true,
      popup_border_style = "rounded",
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
        search_limit = 40,
        find_by_full_path_words = false,
        filtered_items = {
          visible = false,
          hide_gitignored = true,
          hide_dotfiles = false,
          hide_by_name = {
            -- ".github",
            -- ".gitignore",
            -- "package-lock.json",
            -- ".changeset",
            -- ".prettierrc.json",
          },
          never_show = { ".git" },
        },
        hijack_netrw_behavior = "open_current",
        use_libuv_file_watcher = false,
      },
      window = {
        position = "left",
        width = 30,
        mappings = {
          ["/"] = "filter_on_submit",
          ["<esc>"] = "clear_filter",
        },
      },
    },
  },
}
