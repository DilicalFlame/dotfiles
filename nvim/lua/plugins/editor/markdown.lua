-- Markdown preview, inside the buffer. Preview is for reading, source is for editing:
--   * text:   render-markdown.nvim (headings, lists, tables, code, checkboxes, links), rendered in ALL modes and on
--             the cursor line too.
--   * images: features/md_image.lua draws them inline under their ![](...) line, via WezTerm's iTerm2 image protocol
--             (snacks.image's kitty protocol doesn't reach WezTerm on Windows).
--   * width:  no-neck-pain.nvim centers the text in a comfortable reading column (plugins/editor/reading-width.lua).
--   <leader>um flips the buffer between preview and source. Markdown files open as preview.

--- Wrapped tables, drawn on the rows the source lines already occupy.
--- Stock render-markdown hides every wrapped table row (`conceal_lines`) and piles all their virtual lines above the next
--- visible line: ONE block as tall as the whole table, which Neovim can't scroll through (the view jumps over it).
--- Here every row stays a real, visible line instead. Its text is concealed, but Neovim still reserves the screen rows
--- that text would wrap onto (3-4 for a 250-character table row). Those rows are used: the wrapped lines are drawn onto
--- them (one overlay per screen row), spare rows get the row's side borders so the table stays continuous, and any
--- lines beyond the reserved rows hang just below. A table becomes many small row-sized blocks that scroll natively,
--- and the caret steps through the table row by row. Guarded: if the plugin's internals change, stock behaviour stays.
local function anchor_table_rows()
  local ok, Marks = pcall(require, "render-markdown.lib.marks")
  if not (ok and type(Marks.replace) == "function" and type(Marks.insert) == "function") then
    return
  end

  -- border-only line (a frame or the header separator) vs a line with cell text (some chunk has a non-string highlight)
  local function is_border(line)
    for _, chunk in ipairs(line) do
      if type(chunk[2]) ~= "string" or not chunk[2]:find("RenderMarkdownTable", 1, true) then
        return false
      end
    end
    return true
  end

  -- a copy of a content line with its cell text blanked and its borders kept: an empty row inside the table
  local function blank_like(line)
    local out = {}
    for _, chunk in ipairs(line) do
      local border = type(chunk[2]) == "string" and chunk[2]:find("RenderMarkdownTable", 1, true)
      out[#out + 1] = { border and chunk[1] or string.rep(" ", vim.fn.strdisplaywidth(chunk[1])), chunk[2] }
    end
    return out
  end

  -- Columns (1-based) whose cell holds nothing but images. md_image.lua draws those images with their caption, so
  -- the "icon + alt" text render-markdown would print in the cell is blanked.
  local function image_cols(text)
    if not text:find("!%[") then
      return nil
    end
    local inner = text:gsub("^%s*|", ""):gsub("|%s*$", "")
    local cols, n = {}, 0
    for cell in (inner .. "|"):gmatch("(.-)|") do
      n = n + 1
      local rest = cell:gsub("!%b[]%b()", "")
      if cell:find("!%[") and rest:match("^%s*$") then
        cols[n] = true
      end
    end
    return next(cols) and cols or nil
  end

  local function count(s, needle)
    return select(2, s:gsub(needle, ""))
  end

  -- content line of each rendered row, keyed "buf:row". A border-only row (the header separator) borrows the header
  -- row right above it. This used to be ONE shared "last line seen", so a separator could pick up the borders of
  -- whichever OTHER table had rendered last: stray vertical lines at the wrong column.
  local templates = {} ---@type table<string, table>
  local template

  ---@param self table render.md.Marks
  Marks.replace = function(self, config, node, lines)
    local ctx = self.context
    local win, buf, row, col = ctx.win, ctx.buf, node.start_row, node.start_col

    -- Screen rows the (concealed) source line still occupies.
    local rows = 1
    local ok_h, h = pcall(vim.api.nvim_win_text_height, win, { start_row = row, end_row = row })
    if ok_h then
      rows = math.max(1, h.all - (h.fill or 0))
    end
    local info = vim.fn.getwininfo(win)[1]
    local width = info.width - info.textoff
    local text = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
    local total_w = math.max(vim.fn.strdisplaywidth(text), 1)

    local cols = image_cols(text)
    if cols then
      lines = vim.tbl_map(function(line)
        if is_border(line) then
          return line
        end
        local out, col = {}, 0 -- col: how many vertical borders were passed = the cell the next chunk is in
        for _, chunk in ipairs(line) do
          local t = chunk[1]
          local borders = count(t, "│") + count(t, "┃")
          if borders > 0 then
            col = col + borders
          elseif cols[col] then
            -- everything else inside an image cell (the icon, the alt text, whatever highlight it has): blank, same width
            t = string.rep(" ", vim.fn.strdisplaywidth(t))
          end
          out[#out + 1] = { t, chunk[2] }
        end
        return out
      end, lines)
    end

    -- Split the lines into leading frame, cell content, trailing frame; pad the content with blank rows to fill `rows`.
    local head, body, tail = {}, {}, {}
    local i = 1
    while lines[i] and is_border(lines[i]) and #lines > 1 do
      head[#head + 1] = lines[i]
      i = i + 1
    end
    while lines[i] and not (is_border(lines[i]) and #body > 0) do
      body[#body + 1] = lines[i]
      i = i + 1
    end
    while lines[i] do
      tail[#tail + 1] = lines[i]
      i = i + 1
    end
    if #body == 0 and #head > 0 then -- border-only row (the header separator): keep it as the body
      body, head = head, {}
    end
    local key = buf .. ":" .. row
    if #body > 0 and not is_border(body[#body]) then
      templates[key] = body[#body]
    end
    template = templates[key] or templates[buf .. ":" .. (row - 1)]
    local filler = template and blank_like(template) or nil
    local drawn = {}
    vim.list_extend(drawn, head)
    vim.list_extend(drawn, body)
    local spare = rows - (#head + #body + #tail)
    for _ = 1, filler and spare or 0 do
      drawn[#drawn + 1] = filler
    end
    vim.list_extend(drawn, tail)

    -- 1) conceal the source text
    self:insert(config, {
      conceal = true,
      start_row = row,
      start_col = col,
      opts = { end_row = node.end_row, end_col = node.end_col, conceal = "" },
    })
    -- 2) one overlay per reserved screen row. Row j starts about (j-1)*width columns into the concealed text, so a
    --    mark in the middle of that stretch is on screen row j whatever 'linebreak' does at the edges.
    for j = 1, math.min(rows, #drawn) do
      local mark_col = col
      if j > 1 then
        local vcol = math.min((j - 1) * width + math.floor(width / 2), total_w)
        mark_col = math.max(math.min(vim.fn.virtcol2col(win, row + 1, vcol) - 1, #text - 1), 0)
      end
      self:insert(config, {
        conceal = true,
        start_row = row,
        start_col = mark_col,
        opts = { virt_text = drawn[j], virt_text_pos = "overlay", virt_text_win_col = 0 },
      })
    end
    -- 3) lines that don't fit the reserved rows hang right below the row
    if #drawn > rows then
      self:insert(config, {
        conceal = true,
        start_row = row,
        start_col = col,
        opts = { virt_lines = vim.list_slice(drawn, rows + 1) },
      })
    end
  end
end

--- Center the text in a reading column (on) or give the window its full width back (off).
local function center(on)
  local ok, nnp = pcall(require, "no-neck-pain")
  if not ok then
    return
  end
  local state = _G.NoNeckPain and _G.NoNeckPain.state
  local active = false
  if state then
    pcall(function()
      active = state.enabled and state:is_active_tab_registered() or false
    end)
  end
  if on and not active then
    nnp.enable()
  elseif not on and active then
    nnp.disable()
  end
end

--- The preview hides some real lines (a table's source rows: they are drawn as virtual rows elsewhere). A hidden line
--- has zero height, but the cursor still steps onto it, so scrolling or j/k crawls through the whole block one line at a
--- time while nothing on screen moves. If the cursor lands on a hidden line, jump past the entire hidden block at once,
--- in the direction the view is moving.
local last_line = {} ---@type table<number, number>
local function skip_hidden()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cur = vim.api.nvim_win_get_cursor(win)
  local before = last_line[win] or cur[1]
  last_line[win] = cur[1]
  if vim.bo[buf].filetype ~= "markdown" or vim.b[buf].md_preview == false or vim.fn.mode():sub(1, 1) == "i" then
    return
  end
  local count = vim.api.nvim_buf_line_count(buf)
  local function hidden(l)
    return vim.api.nvim_win_text_height(win, { start_row = l - 1, end_row = l - 1 }).all == 0
  end
  if not hidden(cur[1]) then
    return
  end
  -- Direction = the way the CURSOR just moved (k onto a hidden line means keep going up, not back down).
  local up = cur[1] < before
  for _, step in ipairs(up and { -1, 1 } or { 1, -1 }) do -- prefer the direction of travel, else the other way
    local l = cur[1] + step
    while l >= 1 and l <= count and hidden(l) do
      l = l + step
    end
    if l >= 1 and l <= count then
      last_line[win] = l
      return vim.api.nvim_win_set_cursor(win, { l, cur[2] })
    end
  end
end

local function toggle()
  local buf = vim.api.nvim_get_current_buf()
  local on = vim.b[buf].md_preview == false -- nil/true = preview, so flipping from "source" turns preview on
  vim.b[buf].md_preview = on
  center(on) -- first, so images are sized for the final window width
  require("render-markdown").set_buf(on)
  require("features.md_image").set(buf, on)
  vim.notify("Markdown: " .. (on and "preview" or "source"))
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    init = function()
      local group = vim.api.nvim_create_augroup("MarkdownPreview", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function(ev)
          require("features.md_image").attach(ev.buf)
        end,
      })
      vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved" }, {
        group = group,
        callback = function()
          if vim.bo.filetype == "markdown" then
            skip_hidden()
          end
        end,
      })
      -- The reading column follows the buffer: on for markdown in preview, off for any other normal file.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(ev)
          local ft = vim.bo[ev.buf].filetype
          if ft == "no-neck-pain" or vim.bo[ev.buf].buftype ~= "" then
            return -- the side windows themselves, terminals, pickers...: leave the layout alone
          end
          local preview = ft == "markdown" and vim.b[ev.buf].md_preview ~= false
          vim.schedule(function()
            center(preview)
          end)
        end,
      })
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      anchor_table_rows()
    end,
    ---@module 'render-markdown'
    opts = {
      file_types = { "markdown" },
      render_modes = true, -- every mode, including insert/visual
      anti_conceal = { enabled = false }, -- the cursor line is rendered like every other line
      win_options = {
        concealcursor = { rendered = "nvic" }, -- keep markers hidden on the cursor line in every mode
      },
      -- Wide tables are wrapped to fit the window (anchored per row, see anchor_table_rows above).
      pipe_table = { wrap = true },
      code = { sign = false, width = "block", right_pad = 1 },
      heading = { sign = false },
      checkbox = { enabled = true },
    },
    keys = {
      { "<leader>um", toggle, ft = "markdown", desc = "Toggle markdown preview / source" },
    },
  },
}
