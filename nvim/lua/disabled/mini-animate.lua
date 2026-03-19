return {
  {
    "nvim-mini/mini.animate",
    opts = function(_, opts)
      -- LazyVim already defines some options, we just want to override the timing values
      -- to make the animations faster by modifying the duration.
      local animate = require("mini.animate")

      -- Default duration is usually around 150-250 for scroll, we'll make it 50
      opts.scroll = opts.scroll or {}
      opts.scroll.timing = animate.gen_timing.linear({ duration = 50, unit = "total" })

      -- Default duration is usually around 80-100 for cursor, make it 30
      opts.cursor = opts.cursor or {}
      opts.cursor.timing = animate.gen_timing.linear({ duration = 30, unit = "total" })

      -- Make resize animations faster too
      opts.resize = opts.resize or {}
      opts.resize.timing = animate.gen_timing.linear({ duration = 30, unit = "total" })
    end,
  },
}
