return {
  'akinsho/bufferline.nvim',
  dependencies = {
    'moll/vim-bbye',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('bufferline').setup {
      options = {
        -- Display Settings
        mode = 'buffers',
        themable = true,
        numbers = 'none',

        -- Buffer Closure
        close_command = 'Bdelete! %d',
        buffer_close_icon = '✗',
        close_icon = '✗',

        -- Aesthetics and Formatting
        path_components = 1,
        modified_icon = '●',
        left_trunc_marker = '',
        right_trunc_marker = '',
        max_name_length = 30,
        max_prefix_length = 30,
        tab_size = 21,

        -- Diagnostics and Features
        diagnostics = false,
        diagnostics_update_in_insert = false,

        -- Interface Elements
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        persist_buffer_sort = true,
        separator_style = { '│', '│' },
        enforce_regular_tabs = true,
        always_show_bufferline = true,
        show_tab_indicators = false,
        indicator = {
          style = 'none',
        },
        icon_pinned = '󰐃',

        -- Padding and Length
        minimum_padding = 1,
        maximum_padding = 5,
        maximum_length = 15,

        -- Sorting Behavior
        sort_by = 'insert_at_end',

        -- Custom Filtering
        custom_filter = function(buf_number, buf_numbers)
          -- Hide terminal buffers from the bufferline
          if vim.bo[buf_number].buftype == 'terminal' then
            return false
          end
          return true
        end,
      },
      highlights = {
        separator = {
          fg = '#434C5E',
        },
        buffer_selected = {
          bold = true,
          italic = false,
        },
      },
    }
  end,
}
