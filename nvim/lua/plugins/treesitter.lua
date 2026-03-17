return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate', 
  opts = {
    -- Supported languages for syntax parsing
    ensure_installed = {
      'lua',
      'python',
      'javascript',
      'typescript',
      'vimdoc',
      'vim',
      'regex',
      'terraform',
      'sql',
      'dockerfile',
      'toml',
      'json',
      'java',
      'groovy',
      'go',
      'gitignore',
      'graphql',
      'yaml',
      'make',
      'cmake',
      'markdown',
      'markdown_inline',
      'bash',
      'tsx',
      'css',
      'html',
    },
    auto_install = true,

    -- Syntax Highlighting Configuration
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'ruby' },
    },

    -- Automatic Indentation Configuration
    indent = {
      enable = true,
      disable = { 'ruby' },
    },
  },
}
