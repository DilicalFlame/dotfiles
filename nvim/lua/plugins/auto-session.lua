return {
  'rmagatti/auto-session',
  config = function()
    require('auto-session').setup {
      log_level = 'error',
      auto_session_suppress_dirs = { '~/', '~/Downloads', '/' },
      auto_restore_enabled = true,
      auto_save_enabled = true,
      pre_save_cmds = {
        function()
          pcall(vim.cmd, 'Neotree close')
        end,
      },
    }
  end,
}
