# Neovim config

Plain Neovim + [lazy.nvim](https://github.com/folke/lazy.nvim). No distribution: every option, keymap,
autocmd and plugin spec is in this repo.

```
init.lua                  options -> autocmds -> plugin manager -> keymaps (on VeryLazy)
lua/config/
  options.lua             all vim options + <leader>
  keymaps/                global keymaps by area: editing navigation terminal code toggles git
  autocmds/               general filetypes terminal python
  icons.lua               icon tables (diagnostics, git, dap, completion kinds)
  lazy.lua                lazy.nvim bootstrap + `LazyFile` event
lua/util/                 small helpers shared by config/ and plugins/
  format.lua root.lua buffers.lua explorer.lua theme.lua python_env.lua lualine.lua
lua/features/             self-contained subsystems
  terminal.lua            numbered persistent terminals
  md_image.lua            inline images in markdown (iTerm2 protocol)
lua/plugins/
  editor/                 which-key, flash, gitsigns, grug-far, mini.ai/pairs, ts-comments, todo-comments, ...
  lsp/                    lspconfig (+ servers), mason, conform, blink.cmp, treesitter, lazydev, rust
  tools/                  dap, neotest, neo-tree, aerial, persistence, dooing
  ui/                     snacks, lualine, bufferline, colorscheme, icons, focus/vimade
```

- Explorer backend: `lua/util/explorer.lua` (`use_snacks`). Theme: `<leader>st`.
- Format on save: `<leader>uf` (global) / `<leader>uF` (buffer); `<leader>cf` formats now; `:Format`.
- Add an LSP server: add it to `servers` in `lua/plugins/lsp/lsp.lua` (mason installs it).
- Add a formatter: `formatters_by_ft` in `lua/plugins/lsp/conform.lua`.
