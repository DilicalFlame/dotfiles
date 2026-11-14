-- One numbered list of persistent terminals (Snacks), however they were opened.
--
--   * Every terminal has a slot number: 1, 2, 3 ... A new terminal takes the LOWEST FREE number,
--     so if 2 is killed the next one becomes 2 again. The number is all you need to remember.
--   * Keys decide where a NEW terminal opens (root of the project / folder of the current file, below / right);
--     pressing one again finds the existing terminal for that place instead of making another.
--   * A count picks the number:  3<leader>tt  = "go to terminal 3 if it exists (hide it if you're in it),
--     otherwise create it as number 3, in the project root". The same for tT / tc / tC / tn.
--   * <leader>tn (no count) always makes a fresh one in the next free number.
--   * <C-.> / <C-,> cycle the list. <c-/> hides / restores.
-- Hiding keeps the shell alive; `exit` removes it (see TermClose in config/autocmds/terminal.lua).
local M = {}

local MRU_MAX = 20
M.mru = {} ---@type number[] terminal buffers, most recently used first

-- ── helpers ─────────────────────────────────────────────────────────────────

local function info(buf)
  return vim.b[buf].snacks_terminal or {}
end

---@param buf number
---@return number? slot the terminal's number (Snacks calls it `id`)
function M.slot(buf)
  return info(buf).id
end

--- All live terminals, ordered by slot number.
---@return snacks.win[]
function M.list()
  local ts = Snacks.terminal.list()
  table.sort(ts, function(a, b)
    return (M.slot(a.buf) or 0) < (M.slot(b.buf) or 0)
  end)
  return ts
end

--- The terminal in the current window, if any.
local function current()
  local buf = vim.api.nvim_get_current_buf()
  for _, t in ipairs(M.list()) do
    if t.buf == buf then
      return t
    end
  end
end

--- Show `t` and focus it. Hides the focused terminal first, so terminals swap instead of stacking.
local function show(t)
  local cur = current()
  if cur and cur ~= t then
    cur:hide()
  end
  t:show():focus()
end

local function index_of(buf)
  for i, t in ipairs(M.list()) do
    if t.buf == buf then
      return i
    end
  end
end

--- The live terminal with slot number `n`, if any.
local function by_slot(n)
  for _, t in ipairs(M.list()) do
    if M.slot(t.buf) == n then
      return t
    end
  end
end

--- Lowest slot number not used by a live terminal.
local function free_slot()
  local used = {}
  for _, t in ipairs(M.list()) do
    used[M.slot(t.buf)] = true
  end
  local n = 1
  while used[n] do
    n = n + 1
  end
  return n
end

local function same_dir(a, b)
  if not a or not b then
    return false
  end
  a, b = vim.fs.normalize(a), vim.fs.normalize(b)
  if vim.fn.has("win32") == 1 then
    a, b = a:lower(), b:lower()
  end
  return a == b
end

local function is_right(env)
  return env and env.NVIM_TERM_SIDE == "right" or false
end

--- Existing terminal opened for this kind/dir/side (the lowest-numbered one if there are several).
local function find(kind, dir, vertical)
  for _, t in ipairs(M.list()) do
    local i = info(t.buf)
    local env = i.env or {}
    if env.NVIM_TERM_KIND == kind and is_right(env) == vertical and same_dir(i.cwd, dir) then
      return t
    end
  end
end

--- Create a terminal in slot `slot` (default: the next free one) and focus it.
local function spawn(kind, dir, vertical, slot)
  local cur = current()
  if cur then
    cur:hide() -- swap instead of stacking
  end
  Snacks.terminal.focus(nil, {
    count = slot or free_slot(), -- becomes the terminal's number
    cwd = dir,
    env = { NVIM_TERM_KIND = kind, NVIM_TERM_SIDE = vertical and "right" or nil },
    win = {
      position = vertical and "right" or "bottom",
      wo = { winbar = "%{%v:lua.require'features.terminal'.winbar()%}" },
    },
  })
end

--- "proj", "src", "proj→" (→ = opened on the right side)
function M.label(buf)
  local i = info(buf)
  local dir = i.cwd and vim.fs.basename(vim.fs.normalize(i.cwd)) or "?"
  return dir .. (is_right(i.env) and "→" or "")
end

-- ── actions ─────────────────────────────────────────────────────────────────

--- <leader>tt/tT/tc/tC. kind: "root" (git root) | "file" (folder of the current file). vertical = right side.
--- Opens the terminal for that place, or hides it if you are already in one of that kind/side.
--- With a count N: terminal N if it exists (hides it if you are in it), else a new terminal numbered N.
function M.toggle(kind, vertical)
  vertical = vertical == true
  local cur = current()
  local n = vim.v.count
  if n > 0 then
    local t = by_slot(n)
    if t then
      return cur == t and cur:hide() or show(t)
    end
    return spawn(kind, kind == "root" and require("util.root").git() or M.buf_dir(), vertical, n)
  end
  -- Checked first: inside a terminal there is no "current file", so the folder below would be wrong.
  if cur then
    local env = info(cur.buf).env or {}
    if env.NVIM_TERM_KIND == kind and is_right(env) == vertical then
      return cur:hide()
    end
  end
  local dir = kind == "root" and require("util.root").git() or M.buf_dir()
  local t = find(kind, dir, vertical)
  if t then
    return show(t)
  end
  spawn(kind, dir, vertical)
end

--- <leader>tn: always a fresh terminal. Inside a terminal it copies that one's folder and side;
--- otherwise it opens in the current file's folder. With a count N: terminal N if it exists, else a new number N.
function M.new()
  local cur = current()
  local n = vim.v.count
  local existing = n > 0 and by_slot(n) or nil
  if existing then
    return cur == existing and cur:hide() or show(existing)
  end
  local i = cur and info(cur.buf) or {}
  local env = i.env or {}
  spawn(env.NVIM_TERM_KIND or "file", i.cwd or M.buf_dir(), is_right(env), n > 0 and n or nil)
end

--- <c-/>: hide the terminal you're in. Otherwise bring back the most recently used one that still exists.
--- Only opens a new terminal when none exist at all.
function M.toggle_last()
  local cur = current()
  if cur then
    return cur:hide()
  end
  local ts = M.list()
  for _, buf in ipairs(M.mru) do
    for _, t in ipairs(ts) do
      if t.buf == buf then
        return show(t)
      end
    end
  end
  if ts[1] then
    return show(ts[1]) -- survivors that were never focused (e.g. restored): lowest number
  end
  M.toggle("root")
end

--- <C-.> / <C-,>: next (1) / previous (-1) terminal by number, wrapping around.
function M.cycle(step)
  local ts = M.list()
  if #ts == 0 then
    return vim.notify("No terminals open (<leader>tt opens one)", vim.log.levels.INFO)
  end
  local i = index_of(vim.api.nvim_get_current_buf()) or index_of(M.mru[1]) or (step > 0 and 0 or #ts + 1)
  show(ts[(i - 1 + step) % #ts + 1])
end

--- <leader>tl: fuzzy list of all terminals.
function M.pick()
  local ts = M.list()
  if #ts == 0 then
    return vim.notify("No terminals open (<leader>tt opens one)", vim.log.levels.INFO)
  end
  vim.ui.select(ts, {
    prompt = "Terminals",
    format_item = function(t)
      return ("%s %d  %s"):format(t:win_valid() and "●" or "○", M.slot(t.buf), M.label(t.buf))
    end,
  }, function(t)
    if t then
      show(t)
    end
  end)
end

-- ── UI ──────────────────────────────────────────────────────────────────────

--- Tab strip for the terminal window's winbar: "1 proj │ 2 src │ 4 proj→", the one in this window highlighted.
function M.winbar()
  local win = vim.g.statusline_winid
  local cur = win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) or nil
  local parts = {}
  for _, t in ipairs(M.list()) do
    local label = M.label(t.buf):gsub("%%", "%%%%")
    parts[#parts + 1] = ("%%#%s# %d %s "):format(t.buf == cur and "TabLineSel" or "TabLine", M.slot(t.buf), label)
  end
  return table.concat(parts, "%#TabLineFill#│") .. "%#TabLineFill#"
end

--- Statusline item: " 3 (4)" = terminal number you're in / last used, and how many exist.
function M.status()
  local buf = index_of(vim.api.nvim_get_current_buf()) and vim.api.nvim_get_current_buf() or M.mru[1]
  return ("%s %s (%d)"):format(vim.fn.nr2char(0xf489), buf and M.slot(buf) or "-", #M.list())
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("TerminalMru", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= "snacks_terminal" then
      return
    end
    M.mru = vim.tbl_filter(function(b)
      return b ~= ev.buf and vim.api.nvim_buf_is_valid(b)
    end, M.mru)
    table.insert(M.mru, 1, ev.buf)
    M.mru[MRU_MAX + 1] = nil
  end,
})

-- ── misc ────────────────────────────────────────────────────────────────────

local file_dir -- folder of the last real file you were in

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("TerminalFileDir", { clear = true }),
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if vim.bo[ev.buf].buftype == "" and name ~= "" then
      file_dir = vim.fs.dirname(name)
    end
  end,
})

-- Folder of the current file. From a terminal / picker / unnamed buffer (no file), the folder of the last file
-- you were editing; the cwd only if there has been none.
function M.buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and name ~= "" then
    local dir = vim.fs.dirname(name)
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  if file_dir and vim.fn.isdirectory(file_dir) == 1 then
    return file_dir
  end
  return vim.fn.getcwd()
end

-- Spawn a new WezTerm tab in `dir` (only works inside WezTerm).
function M.wezterm_tab(dir)
  if not vim.env.WEZTERM_PANE then
    return vim.notify("Not running inside a WezTerm session!", vim.log.levels.WARN)
  end
  vim.fn.jobstart({ "wezterm.exe", "cli", "spawn", "--cwd", dir }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Opened new WezTerm tab in: " .. dir)
        else
          vim.notify("Failed to open tab. Exit code: " .. code, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
