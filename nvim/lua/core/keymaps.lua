local opts = { noremap = true, silent = true }

-- General Keybindings
-- Disable default spacebar mapping to enable leader functionality
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Insert Mode
vim.keymap.set('i', 'jj', '<Esc>', opts) -- Quickly exit insert mode

-- Terminal Mode
vim.keymap.set('t', 'jj', '<C-\\><C-n>', opts) -- Quickly exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', opts) -- Exit terminal mode with Escape
vim.keymap.set('n', '<leader>tt', '<cmd>split | terminal<CR>A', { desc = 'Open terminal below' })
vim.keymap.set('n', '<leader>tv', '<cmd>vsplit | terminal<CR>A', { desc = 'Open terminal vertical' })

-- File Operations
vim.keymap.set('n', '<C-s>', '<cmd> w <CR>', opts) -- Save file
vim.keymap.set('n', '<leader>sn', '<cmd>noautocmd w <CR>', opts) -- Save file without auto-formatting
vim.keymap.set('n', '<C-q>', '<cmd> qa <CR>', opts) -- Quit completely (closes all windows)
vim.keymap.set('n', '<leader>qq', '<cmd> qa <CR>', opts) -- Quit completely (closes all windows)

-- Editing and Registers
vim.keymap.set('n', 'x', '"_x', opts) -- Delete single character without copying to register
vim.keymap.set('v', 'p', '"_dP', opts) -- Retain register content when pasting over visual selection

-- Visual Indentation
vim.keymap.set('v', '<', '<gv', opts) -- Stay in indent mode when unindenting
vim.keymap.set('v', '>', '>gv', opts) -- Stay in indent mode when indenting

-- Navigation and Search
vim.keymap.set('n', '<C-d>', '<C-d>zz', opts) -- Vertical scroll down and center cursor
vim.keymap.set('n', '<C-u>', '<C-u>zz', opts) -- Vertical scroll up and center cursor
vim.keymap.set('n', 'n', 'nzzzv', opts) -- Next search result and center cursor
vim.keymap.set('n', 'N', 'Nzzzv', opts) -- Previous search result and center cursor

-- Window Resizing
vim.keymap.set('n', '<Up>', ':resize -2<CR>', opts)
vim.keymap.set('n', '<Down>', ':resize +2<CR>', opts)
vim.keymap.set('n', '<Left>', ':vertical resize +2<CR>', opts)
vim.keymap.set('n', '<Right>', ':vertical resize -2<CR>', opts)

-- Buffer Management
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts) -- Go to next buffer
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts) -- Go to previous buffer
vim.keymap.set('n', '<leader>x', ':bdelete!<CR>', opts) -- Close current buffer forcefully
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- Create new buffer

-- Window Split Management
vim.keymap.set('n', '<leader>v', '<C-w>v', opts) -- Split window vertically
vim.keymap.set('n', '<leader>h', '<C-w>s', opts) -- Split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- Equalize split window dimensions
vim.keymap.set('n', '<leader>sx', ':close<CR>', opts) -- Close current split window

-- Split Navigation
vim.keymap.set('n', '<C-k>', ':wincmd k<CR>', opts)
vim.keymap.set('n', '<C-j>', ':wincmd j<CR>', opts)
vim.keymap.set('n', '<C-h>', ':wincmd h<CR>', opts)
vim.keymap.set('n', '<C-l>', ':wincmd l<CR>', opts)

-- Tab (Buffer) Management
vim.keymap.set('n', '<leader>to', '<cmd> enew <CR>', opts) -- Open new tab (buffer)
vim.keymap.set('n', '<leader>tx', '<cmd> Bdelete! <CR>', opts) -- Close current tab (buffer) safely without killing window
vim.keymap.set('n', '<leader>tn', ':bnext<CR>', opts) -- Go to next tab (buffer)
vim.keymap.set('n', '<leader>tp', ':bprevious<CR>', opts) -- Go to previous tab (buffer)

-- Utilities
vim.keymap.set('n', '<leader>lw', '<cmd>set wrap!<CR>', opts) -- Toggle line wrapping

-- Smart Universal Close (`<leader>q`)
vim.keymap.set('n', '<leader>q', function()
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype
  local win_count = #vim.api.nvim_tabpage_list_wins(0)

  if filetype == 'neo-tree' then
    pcall(vim.cmd, 'Neotree close')
  elseif buftype == 'terminal' then
    pcall(vim.cmd, 'bdelete!')
  elseif win_count > 1 then
    -- Try closing the split. If it fails (e.g. it's the last normal window but Neo-tree is open), just delete the buffer.
    local ok = pcall(vim.cmd, 'close')
    if not ok then
      pcall(vim.cmd, 'Bdelete!')
    end
  else
    pcall(vim.cmd, 'Bdelete!')
  end
end, { desc = 'Smart close (split/buffer/panel/terminal)', noremap = true, silent = true })

-- Diagnostic Navigation
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Navigate to previous diagnostic message' })

vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Navigate to next diagnostic message' })

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Inspect diagnostic details in floating window' })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Populate quickfix list with diagnostics' })
