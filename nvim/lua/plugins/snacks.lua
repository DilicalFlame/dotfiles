return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        enabled = true,
        -- 'row' sets the starting line from the top. Changing this from nil (center) to 4 adds a little top padding!
        row = 4,
        preset = {
          header = [[
         ▄▄                ▄▄   ▄▄ ▄▄                      
    █▄    ██                ██ ██   ██                     
    ██ ▀▀ ██ ▀▀             ██▄██▄  ██       ▄             
 ▄████ ██ ██ ██ ▄███▀ ▄▀▀█▄ ██ ██   ██ ▄▀▀█▄ ███▄███▄ ▄█▀█▄
 ██ ██ ██ ██ ██ ██    ▄█▀██ ██ ██   ██ ▄█▀██ ██ ██ ██ ██▄█▀
▄█▀███▄██▄██▄██▄▀███▄▄▀█▄██▄██▄██  ▄██▄▀█▄██▄██ ██ ▀█▄▀█▄▄▄
                               ██                          
                              ▀▀                           
]],
        },
        formats = {
          -- This just gives a little nice alignment to the startup footer
          footer = { "%s", align = "center" },
          header = { "%s", align = "center" },
        },
        sections = {
          { section = "header", padding = 1 },
          -- 'gap = 0' removes the extra blank lines between the key hints!
          { section = "keys", gap = 0, padding = 1 },
          { section = "startup" },
        },
      },
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            layout = {
              layout = {
                width = 30,
                min_width = 30,
              },
            },
          },
        },
      },
    },
  },
}
