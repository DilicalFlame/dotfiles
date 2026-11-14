-- Images in markdown buffers, drawn with the iTerm2 inline-image protocol (OSC 1337).
--
-- Why not snacks.image: it only speaks the kitty graphics protocol, and WezTerm on Windows doesn't get those
-- sequences through the pseudo-console. The iTerm2 protocol does arrive (`wezterm imgcat` works). snacks.image
-- is still used for what it does well: finding images, downloading URLs, converting any format to PNG (cached).
--
-- Two modes (M.mode):
--   "inline": every image is shown in the text, right under its ![](...) line. Space is reserved with virtual
--             lines; each image is cut into one-cell-tall strips so a half-visible image shows exactly its visible
--             rows while scrolling. Strips are drawn after every scroll step and after layout changes.
--   "popup" : the image under the cursor appears in a floating window; moving away closes it.
local M = {}

M.mode = "inline" ---@type "inline"|"popup"

local ESC, BEL = "\27", "\7"
local MAX_BYTES = 1200 * 1024 -- popup mode: larger images are shrunk first so the escape sequence stays small
local CELL_W, CELL_H = 9, 18 -- assumed cell size in pixels, used only to size images in cells
local STRIP_W, STRIP_H = 18, 36 -- pixels per cell in the cut strips (2x the assumed cell: stays sharp on HiDPI)
local BLANK = "\226\128\135" -- U+2007 figure space: an invisible character, but not a plain " " to the terminal

-- ── shared helpers ──────────────────────────────────────────────────────────

local function be32(s, i)
  local a, b, c, d = s:byte(i, i + 3)
  return ((a * 256 + b) * 256 + c) * 256 + d
end

---@return number? width, number? height in pixels (PNG header)
local function png_size(file)
  local f = io.open(file, "rb")
  if not f then
    return
  end
  local head = f:read(24)
  f:close()
  if head and #head == 24 and head:sub(2, 4) == "PNG" then
    return be32(head, 17), be32(head, 21)
  end
end

--- Shrink big images (popup mode). Calls `cb(file)` with the file to draw.
local function shrink(file, cb)
  local stat = vim.uv.fs_stat(file)
  if not stat or stat.size <= MAX_BYTES or vim.fn.executable("magick") == 0 then
    return cb(file)
  end
  local small = file:gsub("%.png$", "") .. ".small.png"
  if vim.uv.fs_stat(small) then
    return cb(small)
  end
  vim.system({ "magick", file, "-resize", "1400x1400>", small }, {}, function(res)
    vim.schedule(function()
      cb(res.code == 0 and small or file)
    end)
  end)
end

--- src (path or URL) -> local PNG (downloads/converts through snacks, cached on disk). cb(file|nil)
local function to_png(src, cb)
  Snacks.image.convert
    .convert({
      src = src,
      on_done = function(conv)
        vim.schedule(function()
          cb(not conv:error() and conv.file or nil)
        end)
      end,
    })
    :run()
end

local VIDEO = { mp4 = 1, mkv = 1, webm = 1, mov = 1, avi = 1, m4v = 1, wmv = 1, flv = 1 }

---@param src string?
local function is_video(src)
  local ext = src and src:gsub("[?#].*$", ""):match("%.(%w+)$")
  return ext ~= nil and VIDEO[ext:lower()] ~= nil
end

--- gx: a markdown link/image whose target is a video is opened with the system player;
--- anything else goes to Neovim's normal gx target.
local function gx(buf)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local target, video, any
  for s, dest, e in line:gmatch("()%b[]%(([^)]-)%)()") do
    any = any or dest
    if col >= s and col < e then
      target = dest -- the link under the cursor
    elseif not video and is_video(dest) then
      video = dest -- else the first video on the line
    end
  end
  target = target or video
  if not target and line:match("^%s*!%[") then
    target = any -- cursor parked on a hidden image line: open its image
  end
  if target then
    target = target:match("^<(.*)>$") or target:gsub("%s+[\"'].*$", "") -- drop <> and a "title"
    return vim.ui.open(Snacks.image.doc.resolve(buf, target))
  end
  local urls = vim.ui._get_urls and vim.ui._get_urls() or { vim.fn.expand("<cfile>") }
  if urls[1] and urls[1] ~= "" then
    vim.ui.open(urls[1])
  end
end

local function send(seq)
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(seq)
  else
    io.stdout:write(seq)
  end
end

--- One OSC 1337 image at 0-based screen (row, col), fitted into a w x h cell box.
local function osc(b64, size, w, h, row, col, keep_aspect)
  return table.concat({
    ESC, "7", -- save cursor
    ESC, ("[%d;%dH"):format(row + 1, col + 1),
    -- doNotMoveCursor: WezTerm normally moves its cursor past the image. Windows' console layer (ConPTY) doesn't know
    -- that, so it would later send a relative cursor move from the WRONG place and the next image lands off to the side.
    ESC, "]1337;File=inline=1;doNotMoveCursor=1;width=", w, ";height=", h, ";preserveAspectRatio=",
    keep_aspect and 1 or 0, ";size=", size, ":", b64, BEL,
    ESC, "8", -- restore cursor
  })
end

local function debounced(ms, fn)
  local timer = assert(vim.uv.new_timer())
  return function()
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(fn))
  end
end

--- Overwrite screen rectangles with an invisible character, then let Neovim repaint them.
--- Neovim only rewrites cells whose content changed, so a blank cell that stays blank would keep an old image
--- on screen; writing a real character there first removes it.
---@param rects {row:number,col:number,w:number,h:number}[] 0-based screen rectangles
local function erase(rects)
  if #rects == 0 then
    return
  end
  local wins = {}
  for _, r in ipairs(rects) do
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = {}
    for i = 1, r.h do
      lines[i] = BLANK:rep(r.w)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local w = vim.api.nvim_open_win(buf, false, {
      relative = "editor", row = r.row, col = r.col, width = r.w, height = r.h,
      style = "minimal", focusable = false, zindex = 250, border = "none", noautocmd = true,
    })
    vim.wo[w].winhighlight = "NormalFloat:Normal"
    wins[#wins + 1] = { win = w, buf = buf }
  end
  vim.cmd("redraw") -- the invisible characters hit the terminal here, replacing the image cells
  for _, w in ipairs(wins) do
    pcall(vim.api.nvim_win_close, w.win, true)
    pcall(vim.api.nvim_buf_delete, w.buf, { force = true })
  end
  vim.cmd("redraw") -- and Neovim writes the real content back
end

-- ── popup mode ──────────────────────────────────────────────────────────────

local popup ---@type { win: number, buf: number, src: string, rect: table }?
local popup_token = 0 -- bumps whenever the wanted image changes, to drop stale async results

local function popup_close()
  if not popup then
    return
  end
  local rect = popup.rect
  pcall(vim.api.nvim_win_close, popup.win, true)
  pcall(vim.api.nvim_buf_delete, popup.buf, { force = true })
  popup = nil
  erase({ rect })
end

local function popup_show(file, src)
  local pw, ph = png_size(file)
  local f = io.open(file, "rb")
  if not (pw and ph and pw > 0 and ph > 0 and f) then
    return
  end
  local raw = f:read("*a")
  f:close()
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(win)
  local pos = vim.fn.screenpos(win, cur[1], cur[2] + 1) -- 1-based screen row/col of the cursor
  local lines, cols = vim.o.lines, vim.o.columns

  -- Room below / above the cursor line (the last row is the statusline). Use the roomier side.
  local below, above = lines - pos.row - 2, pos.row - 2
  local on_top = above > below
  local max_rows = math.max(2, math.min(on_top and above or below, 28))
  local max_cols = math.max(4, math.min(cols - 2, 90))
  local nw, nh = pw / CELL_W, ph / CELL_H
  local scale = math.min(1, max_cols / nw, max_rows / nh)
  local cw, ch = math.max(1, math.floor(nw * scale)), math.max(1, math.floor(nh * scale))
  local row = on_top and (pos.row - 1 - ch) or pos.row -- 0-based top row of the float
  local col = math.max(0, math.min(pos.col - 1, cols - cw))

  local buf = vim.api.nvim_create_buf(false, true)
  local blank = {}
  for i = 1, ch do
    blank[i] = ""
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, blank)
  local fw = vim.api.nvim_open_win(buf, false, {
    relative = "editor", row = row, col = col, width = cw, height = ch,
    style = "minimal", focusable = false, zindex = 60, border = "none", noautocmd = true,
  })
  vim.wo[fw].winhighlight = "Normal:NormalFloat"
  popup = { win = fw, buf = buf, src = src, rect = { row = row, col = col, w = cw, h = ch } }
  vim.cmd("redraw") -- the (blank) float must be on screen before the image goes on top of it
  send(osc(vim.base64.encode(raw), #raw, cw, ch, row, col, true))
end

local function popup_update()
  if vim.fn.mode() ~= "n" or vim.b.md_preview == false or vim.bo.filetype ~= "markdown" then
    return popup_close()
  end
  Snacks.image.doc.at_cursor(function(src)
    if not src then
      return popup_close()
    end
    if popup and popup.src == src then
      return
    end
    popup_close()
    popup_token = popup_token + 1
    local mine = popup_token
    to_png(src, function(file)
      if not file or mine ~= popup_token then
        return
      end
      shrink(file, function(small)
        if mine == popup_token then
          popup_show(small, src)
        end
      end)
    end)
  end)
end

-- ── inline mode ─────────────────────────────────────────────────────────────

local ns = vim.api.nvim_create_namespace("md_image_inline")
---@class md_image.item
---@field mark number extmark holding the reserved rows
---@field cw number width in cells
---@field ch number height in cells (= number of strips)
---@field strips {b64:string,size:number}[] one strip per cell row
local items = {} ---@type table<number, md_image.item[]>
local drawn = {} ---@type table<number, {row:number,col:number,w:number,h:number}[]> where images are on screen now
local gen = {} ---@type table<number, number> refresh generation per buffer (drops stale async work)

--- Take the images of `buf` off the screen (their cells are overwritten, then repainted).
local function wipe_drawn(buf)
  local rects = drawn[buf]
  drawn[buf] = nil
  if rects then
    erase(rects)
  end
end

local function inline_clear(buf)
  gen[buf] = (gen[buf] or 0) + 1
  local had = items[buf] ~= nil
  items[buf] = nil
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  if had or drawn[buf] then
    wipe_drawn(buf)
  end
end

-- ── layout: where an image may go, and how big it should be ───────────────────

local UPSCALE = 1 -- images never grow beyond their native size (more looks blurry)
local ROW_CHROME = 3 -- screen rows a table row takes besides its images (text, padding, border); an estimate
local geom = {} ---@type table<number, table<number, number[]>> per buffer: table start line -> border columns
local schedule_refresh ---@type fun(buf: number) (assigned below)

local function getline(buf, l)
  return vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1] or ""
end

local function is_table_line(line)
  return line:match("^%s*|") ~= nil
end

--- First and last line of the pipe table that contains `lnum`.
local function table_block(buf, lnum)
  local n = vim.api.nvim_buf_line_count(buf)
  local a, b = lnum, lnum
  while a > 1 and is_table_line(getline(buf, a - 1)) do
    a = a - 1
  end
  while b < n and is_table_line(getline(buf, b + 1)) do
    b = b + 1
  end
  return a, b
end

--- Read the table's real column borders off the screen: the `│` cells of any visible content row, as 0-based
--- offsets from the text start. (Reading the screen is the only reliable way: render-markdown conceals URLs and
--- pads cells, so the buffer text says nothing about where the columns end up.)
---@return number[]? borders
local function measure(win, buf, a, b)
  local info = vim.fn.getwininfo(win)[1]
  local first = info.wincol + info.textoff -- 1-based screen column where the text starts
  local last = info.wincol + info.width - 1
  for l = a, math.min(b, a + 300) do
    if not getline(buf, l):match("^%s*|[%s:|%-]+$") then -- skip the |---|---| delimiter row
      local row = vim.fn.screenpos(win, l, 1).row
      if row > 0 then
        local borders = {}
        for c = first, last do
          local ch = vim.fn.screenstring(row, c)
          if ch == "│" or ch == "┃" then
            borders[#borders + 1] = c - first
          end
        end
        if #borders >= 2 then
          return borders
        end
      end
    end
  end
end

--- Size in cells for an image that may use `avail_w` columns: grows a little, shrinks to fit, and when it would
--- be far taller than the screen it is cropped (top part shown) instead of becoming a thin sliver.
---@return number cw, number ch shown size; number fh full height (> ch when cropped); boolean cropped
---@param scale number? extra shrink factor (1 = as big as fits); tables use it to fit into one screen
local function fit(win, pw, ph, avail_w, in_table, scale)
  local info = vim.fn.getwininfo(win)[1]
  local max_rows = math.max(3, math.min(math.floor(info.height * 0.7), in_table and 16 or 24))
  local cw = math.max(1, math.floor(math.min(avail_w, pw / CELL_W * UPSCALE) * (scale or 1)))
  local hc = cw * ph / pw * (CELL_W / CELL_H)
  if hc <= max_rows then
    local h = math.max(1, math.floor(hc))
    return cw, h, h, false
  end
  if hc <= max_rows * 1.8 then -- a bit too tall: shrink to the height limit
    return math.max(1, math.floor(cw * max_rows / hc)), max_rows, max_rows, false
  end
  return cw, max_rows, math.ceil(hc), true -- very tall: keep the width, show the top
end

local strip_cache = {} ---@type table<string, {b64:string,size:number}[]>

--- Cut `file` into `ch` strips, each one cell tall (cached on disk and in memory). cb(strips|nil)
local function make_strips(file, cw, ch, fh, cb)
  local key = ("%s.%dx%d"):format((file:gsub("%.png$", "")), cw, ch) .. (fh > ch and (".c" .. fh) or "")
  if strip_cache[key] then
    return cb(strip_cache[key])
  end
  local function load()
    local list = {}
    for i = 0, ch - 1 do
      local f = io.open(("%s.%d.png"):format(key, i), "rb")
      if not f then
        return nil
      end
      local raw = f:read("*a")
      f:close()
      list[#list + 1] = { b64 = vim.base64.encode(raw), size = #raw }
    end
    strip_cache[key] = list
    return list
  end
  local cached = load() -- strips from an earlier session
  if cached then
    return cb(cached)
  end
  if vim.fn.executable("magick") == 0 then
    return cb(nil)
  end
  vim.system({
    "magick", file,
    "-resize", ("%dx%d!"):format(cw * STRIP_W, fh * STRIP_H), -- fh > ch: keep only the top ch strips
    "-crop", ("%dx%d"):format(cw * STRIP_W, STRIP_H), "+repage",
    key .. ".%d.png",
  }, {}, function(res)
    vim.schedule(function()
      cb(res.code == 0 and load() or nil)
    end)
  end)
end

--- One virtual line made of pieces at given columns (0-based, relative to the text start), spaces in between.
---@param parts {at:number,text:string,hl:string}[]
local function compose(parts)
  table.sort(parts, function(a, b)
    return a.at < b.at
  end)
  local chunks, cur = {}, 0
  for _, pt in ipairs(parts) do
    if pt.at >= cur and pt.text ~= "" then
      chunks[#chunks + 1] = { (" "):rep(pt.at - cur), "Normal" }
      chunks[#chunks + 1] = { pt.text, pt.hl }
      cur = pt.at + vim.fn.strdisplaywidth(pt.text)
    end
  end
  if #chunks == 0 then
    chunks[1] = { " ", "Normal" }
  end
  return chunks
end

--- Reserve the rows under each image line (virtual lines), now that every image is cut.
local function inline_apply(buf, list)
  wipe_drawn(buf) -- the layout is about to change: take the old pictures off the screen first
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  items[buf] = {}
  local hidden = {} ---@type table<number, boolean> image lines that are concealed
  local last = vim.api.nvim_buf_line_count(buf)
  local groups, order = {}, {} ---@type table<number, table[]>, number[] images per line, in slot order
  for _, it in ipairs(list) do
    if it.strips and it.lnum >= 1 and it.lnum <= last then
      if not groups[it.lnum] then
        groups[it.lnum] = {}
        order[#order + 1] = it.lnum
      end
      table.insert(groups[it.lnum], it)
    end
  end
  table.sort(order)

  for _, lnum in ipairs(order) do
    local g = groups[lnum]
    table.sort(g, function(a, b)
      return a.slot < b.slot
    end)
    local img_rows, has_alt = 0, false
    for _, it in ipairs(g) do
      img_rows = math.max(img_rows, it.ch)
      has_alt = has_alt or (it.alt ~= nil and it.alt ~= "")
    end
    -- Inside a table the reserved rows must carry the table's vertical borders too, or the lines break there.
    local borders = g[1].tbl and geom[buf] and geom[buf][g[1].tbl[1]] or nil
    local border_hl = (g[1].tbl and lnum == g[1].tbl[1]) and "RenderMarkdownTableHead" or "RenderMarkdownTableRow"
    local function border_parts()
      local parts = {}
      for _, b in ipairs(borders or {}) do
        parts[#parts + 1] = { at = b, text = "│", hl = border_hl }
      end
      return parts
    end
    local virt = {}
    for i = 1, img_rows do
      virt[i] = compose(border_parts())
    end
    local rows = img_rows
    if has_alt then -- one caption row; each alt is centered under its own image
      local parts = border_parts()
      for _, it in ipairs(g) do
        local alt = vim.fn.strcharpart(it.alt or "", 0, math.max(1, it.sw - 2))
        local w = vim.fn.strdisplaywidth(alt)
        parts[#parts + 1] = { at = it.off + math.max(0, math.floor((it.cw - w) / 2)), text = alt, hl = "Comment" }
      end
      virt[#virt + 1] = compose(parts)
      rows = rows + 1
    end
    -- Hide the "icon + alt" line itself (the alt shows under the image instead). Neovim drops virtual lines that
    -- hang on a concealed line, so they go on the line ABOVE it. That needs a visible line above and a line below.
    local text = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
    local in_table = text:match("^%s*|") ~= nil -- hiding would remove the whole table row
    local hide = not in_table and lnum > 1 and lnum < last and not hidden[lnum - 1]
    local shift = hide and 1 or 0
    if hide then
      hidden[lnum] = true
      vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, { conceal_lines = "" })
    end
    local mark = vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1 - shift, 0, { virt_lines = virt })
    for _, it in ipairs(g) do
      table.insert(items[buf], {
        mark = mark, shift = shift, cw = it.cw, ch = it.ch, rows = rows, off = it.off, strips = it.strips, tbl = it.tbl,
      })
    end
  end
end

--- Screen rows that held image pieces last time (`old`) but hold none now (`new`), as rectangles to erase.
--- Needed because Neovim repaints only changed cells: after a big jump (mouse wheel, <C-d>) the old pieces would
--- stay behind on rows that are now blank.
---@param old {row:number,col:number,w:number,h:number}[]
---@param new {row:number,col:number,w:number,h:number}[]
local function stale_rects(old, new)
  local covered = {} ---@type table<number, {col:number,w:number}>
  for _, r in ipairs(new) do
    for row = r.row, r.row + r.h - 1 do
      covered[row] = r
    end
  end
  local rows, spec = {}, {} ---@type number[], table<number, {col:number,w:number}>
  for _, r in ipairs(old) do
    for row = r.row, r.row + r.h - 1 do
      local c = covered[row]
      if not (c and c.col == r.col and c.w >= r.w) then
        rows[#rows + 1] = row
        spec[row] = r
      end
    end
  end
  table.sort(rows)
  local out = {}
  for _, row in ipairs(rows) do
    local last = out[#out]
    local r = spec[row]
    if last and last.row + last.h == row and last.col == r.col and last.w == r.w then
      last.h = last.h + 1
    else
      out[#out + 1] = { row = row, col = r.col, w = r.w, h = 1 }
    end
  end
  return out
end

--- Draw the visible rows of every image in the current window, strip by strip.
local function inline_draw()
  local buf = vim.api.nvim_get_current_buf()
  local list = items[buf]
  local mode = vim.fn.mode():sub(1, 1)
  if not list or #list == 0 or mode == "i" or mode == "c" then
    return
  end
  local win = vim.api.nvim_get_current_win()
  vim.cmd("redraw") -- Neovim must finish painting before the pictures go on top
  local info = vim.fn.getwininfo(win)[1]
  local top = info.winrow - 1 + info.winbar -- 0-based first / last screen row of the text area
  local bottom = top + info.height - 1
  local col = info.wincol - 1 + info.textoff
  local out, rects = {}, {}
  -- Tables: if the columns on screen are not where the images were laid out for, remeasure and lay out again.
  local checked = {}
  for _, it in ipairs(list) do
    if it.tbl and not checked[it.tbl[1]] then
      checked[it.tbl[1]] = true
      local now = measure(win, buf, it.tbl[1], it.tbl[2])
      geom[buf] = geom[buf] or {}
      if now and not vim.deep_equal(now, geom[buf][it.tbl[1]]) then
        geom[buf][it.tbl[1]] = now
        schedule_refresh(buf)
      end
    end
  end
  for _, it in ipairs(list) do
    local m = vim.api.nvim_buf_get_extmark_by_id(buf, ns, it.mark, {})
    if m[1] then
      local lnum = m[1] + 1 + it.shift -- the image's own line (the extmark sits one line higher when it is hidden)
      -- First reserved row (0-based). The reserved rows end right above the NEXT line, so anchoring on where
      -- that line starts stays exact however the image line wraps or conceals.
      local row
      local nxt = lnum < vim.api.nvim_buf_line_count(buf) and vim.fn.screenpos(win, lnum + 1, 1) or nil
      if nxt and nxt.row > 0 then
        row = nxt.row - it.rows - 1
      else
        local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
        local p = vim.fn.screenpos(win, lnum, math.max(#line, 1))
        row = p.row > 0 and p.row or nil
      end
      if row then
        local first, last = math.max(row, top), math.min(row + it.ch - 1, bottom)
        for r = first, last do
          local s = it.strips[r - row + 1]
          out[#out + 1] = osc(s.b64, s.size, it.cw, 1, r, col + it.off, false)
        end
        if last >= first then
          rects[#rects + 1] = { row = first, col = col + it.off, w = it.cw, h = last - first + 1 }
        end
      end
    end
  end
  local stale = stale_rects(drawn[buf] or {}, rects)
  drawn[buf] = rects
  if #stale > 0 then
    erase(stale) -- take last frame's leftovers off the screen before drawing this frame
  end
  if #out > 0 then
    send(table.concat(out))
  end
end

local drawing = false
local function draw_soon() -- at most once per event-loop tick: immediate during scrolling, no pile-up
  if drawing then
    return
  end
  drawing = true
  vim.schedule(function()
    drawing = false
    inline_draw()
  end)
end

--- Find every image in the buffer, load and cut them, reserve their rows, then draw.
local function inline_refresh(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
    return
  end
  if vim.b[buf].md_preview == false or vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
    return inline_clear(buf)
  end
  local win = vim.fn.win_findbuf(buf)[1]
  if not win then
    return
  end
  gen[buf] = (gen[buf] or 0) + 1
  local mine = gen[buf]
  Snacks.image.doc.find(buf, function(imgs)
    if gen[buf] ~= mine then
      return
    end
    if #imgs == 0 then
      return inline_clear(buf)
    end
    imgs = vim.tbl_filter(function(img)
      return not is_video(img.src) -- videos stay as plain links; `gx` opens them
    end, imgs)
    if #imgs == 0 then
      return inline_clear(buf)
    end
    local list, pending = {}, #imgs
    local function done()
      pending = pending - 1
      if pending == 0 and gen[buf] == mine then
        inline_apply(buf, list)
        draw_soon()
      end
    end
    -- Where each image may go. Images on one line are numbered left to right. In a pipe table every image belongs
    -- to a column and may use that cell; elsewhere the whole text width is the box. Images sharing a box split it.
    table.sort(imgs, function(a, b)
      local ra, rb = a.range or { 0, 0 }, b.range or { 0, 0 }
      return ra[1] < rb[1] or (ra[1] == rb[1] and ra[2] < rb[2])
    end)
    local info = vim.fn.getwininfo(win)[1]
    local text_w = math.max(4, math.min(info.width - info.textoff - 2, 100))
    local function line_of(img)
      return (img.range and (img.range[3] or img.range[1])) or 0
    end
    local seen, boxes = {}, {} ---@type table<number, number>, table<string, number> per line / per box counters
    local prep = {}
    for _, img in ipairs(imgs) do
      local lnum = line_of(img)
      seen[lnum] = (seen[lnum] or 0) + 1
      local line = getline(buf, lnum)
      local p = { img = img, lnum = lnum, slot = seen[lnum], line = line, in_table = is_table_line(line) }
      if p.in_table then
        local _, pipes = line:sub(1, (img.range and img.range[2]) or 0):gsub("|", "")
        p.col = math.max(0, pipes - (line:match("^%s*|") and 1 or 0)) -- 0-based column of the cell
        p.ta, p.tb = table_block(buf, lnum)
      end
      p.box = lnum .. ":" .. (p.col or 0)
      boxes[p.box] = (boxes[p.box] or 0) + 1
      p.sub = boxes[p.box]
      prep[#prep + 1] = p
    end

    for _, p in ipairs(prep) do
      local img = p.img
      local alt, n = "", 0
      for a in p.line:gmatch("!%[(.-)%]") do
        n = n + 1
        if n == p.slot then
          alt = a
        end
      end
      -- the box this image may use: x offset and width in columns, relative to the text start
      local bx, bw = 0, text_w
      if p.in_table then
        geom[buf] = geom[buf] or {}
        geom[buf][p.ta] = geom[buf][p.ta] or measure(win, buf, p.ta, p.tb)
        local borders = geom[buf][p.ta]
        local b1, b2 = borders and borders[p.col + 1], borders and borders[p.col + 2]
        if b1 and b2 then
          bx, bw = b1 + 2, math.max(4, b2 - b1 - 3) -- one column of padding inside each border
        else -- columns not measurable yet: equal split of the window (the first draw remeasures)
          local _, pipes = p.line:gsub("|", "")
          local cols = math.max(1, pipes - 1)
          bx, bw = math.floor(p.col * info.width / cols) + 2, math.max(4, math.floor(info.width / cols) - 4)
        end
      end
      local sw = math.floor(bw / boxes[p.box])
      p.bx, p.sw = bx, sw
      p.it = { lnum = p.lnum, alt = alt, slot = p.slot, sw = sw, tbl = p.in_table and { p.ta, p.tb } or nil }
      list[#list + 1] = p.it
    end

    -- Sizes are decided together, once every image is loaded: a table gets ONE shrink factor, the largest that
    -- still lets the whole table (rows, images, captions) fit into the window.
    local function layout()
      if gen[buf] ~= mine then
        return
      end
      local tables = {} ---@type table<number, table> table start line -> its images
      for _, p in ipairs(prep) do
        if p.pw and p.in_table then
          tables[p.ta] = tables[p.ta] or { b = p.tb, ps = {} }
          table.insert(tables[p.ta].ps, p)
        end
      end
      local scale = {} ---@type table<number, number>
      for ta, t in pairs(tables) do
        local s = 1
        while s > 0.3 do
          local per_line, lines = {}, 0
          for _, p in ipairs(t.ps) do
            local _, ch = fit(win, p.pw, p.ph, p.sw, true, s)
            local l = per_line[p.lnum]
            if not l then
              l = { rows = 0, alt = false }
              per_line[p.lnum] = l
              lines = lines + 1
            end
            l.rows = math.max(l.rows, ch)
            l.alt = l.alt or (p.it.alt ~= nil and p.it.alt ~= "")
          end
          local total = (t.b - ta + 1 - lines) + 2 -- rows without images, plus the table's top and bottom borders
          for _, l in pairs(per_line) do
            total = total + ROW_CHROME + l.rows + (l.alt and 1 or 0)
          end
          if total <= info.height - 1 then
            break
          end
          s = s - 0.05
        end
        scale[ta] = math.max(s, 0.3)
      end

      for _, p in ipairs(prep) do
        local it = p.it
        if not p.pw then
          done()
        else
          local fh, cropped
          it.cw, it.ch, fh, cropped = fit(win, p.pw, p.ph, p.sw, p.in_table, scale[p.ta])
          -- table cells: images are centered in their cell; elsewhere they stay left-aligned
          it.off = p.bx + (p.sub - 1) * p.sw + (p.in_table and math.floor((p.sw - it.cw) / 2) or 0)
          if cropped then
            it.alt = ((it.alt or "") ~= "" and (it.alt .. " ") or "") .. "⋯ gx opens full"
          end
          make_strips(p.file, it.cw, it.ch, fh, function(strips)
            it.strips = strips
            done()
          end)
        end
      end
    end

    local loading = #prep
    for _, p in ipairs(prep) do
      to_png(p.img.src, function(file)
        if file and gen[buf] == mine then
          p.file = file
          p.pw, p.ph = png_size(file)
          if not (p.pw and p.ph and p.pw > 0 and p.ph > 0) then
            p.pw, p.ph = nil, nil
          end
        end
        loading = loading - 1
        if loading == 0 then
          layout()
        end
      end)
    end
  end)
end

local refresh_soon = {} ---@type table<number, fun()>
schedule_refresh = function(buf)
  refresh_soon[buf] = refresh_soon[buf] or debounced(250, function()
    inline_refresh(buf)
  end)
  refresh_soon[buf]()
end

-- ── public ──────────────────────────────────────────────────────────────────

--- Turn images on/off for a buffer (the <leader>um toggle).
function M.set(buf, on)
  if M.mode == "popup" then
    if on then
      M.attach(buf)
      popup_update()
    else
      popup_token = popup_token + 1
      popup_close()
    end
  elseif on then
    M.attach(buf)
    schedule_refresh(buf)
  else
    inline_clear(buf)
  end
end

function M.attach(buf)
  if vim.b[buf].md_image_attached then
    return
  end
  vim.b[buf].md_image_attached = true
  vim.keymap.set("n", "gx", function()
    gx(buf)
  end, { buffer = buf, desc = "Open link (videos in system player)" })
  local group = vim.api.nvim_create_augroup("MdImage" .. buf, { clear = true })
  local function au(events, cb)
    vim.api.nvim_create_autocmd(events, { group = group, buffer = buf, callback = cb })
  end

  if M.mode == "popup" then
    local soon = debounced(120, popup_update)
    au("CursorMoved", soon)
    au({ "ModeChanged", "BufLeave" }, function()
      popup_token = popup_token + 1
      popup_close()
    end)
  else
    au({ "BufWinEnter", "TextChanged", "InsertLeave" }, function()
      schedule_refresh(buf)
    end)
    au("InsertEnter", function()
      vim.schedule(function()
        inline_clear(buf) -- editing: plain source, no reserved rows
      end)
    end)
    au({ "BufLeave", "WinLeave" }, function()
      vim.schedule(function()
        wipe_drawn(buf) -- leaving: don't leave pictures behind where the next buffer has blank cells
        gen[buf] = (gen[buf] or 0) + 1
      end)
    end)
  end
end

-- Events that move or repaint the screen, whichever buffer is showing.
vim.api.nvim_create_autocmd({ "WinScrolled", "VimResized", "WinResized", "FocusGained" }, {
  group = vim.api.nvim_create_augroup("MdImageGlobal", { clear = true }),
  callback = function(ev)
    if M.mode == "popup" then
      if popup then
        popup_token = popup_token + 1
        popup_close()
      end
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    if ev.event == "VimResized" or ev.event == "WinResized" then
      geom[buf] = nil -- column positions depend on the window width
      if items[buf] then
        schedule_refresh(buf) -- sizes depend on the window, so recompute the reserved rows
      end
    elseif items[buf] then
      draw_soon()
    end
  end,
})

return M
