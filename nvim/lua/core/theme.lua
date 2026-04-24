local M = {}

local theme_file = vim.fn.stdpath("state") .. "/active_theme.txt"

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and type(hl) == "table" then
    return hl
  end
  return {}
end

local function first(...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
  return nil
end

local function apply_completion_overrides()
  local normal = get_hl("Normal")
  local normal_float = get_hl("NormalFloat")
  local float_border = get_hl("FloatBorder")
  local pmenu = get_hl("Pmenu")
  local pmenu_sel = get_hl("PmenuSel")
  local comment = get_hl("Comment")

  local menu_bg = first(pmenu.bg, normal_float.bg, normal.bg)
  local menu_fg = first(pmenu.fg, normal_float.fg, normal.fg)
  local border_fg = first(float_border.fg, comment.fg, menu_fg)
  local select_bg = first(pmenu_sel.bg, menu_bg)
  local select_fg = first(pmenu_sel.fg, menu_fg)
  local muted_fg = first(comment.fg, menu_fg)

  vim.api.nvim_set_hl(0, "BlinkCmpMenu", { fg = menu_fg, bg = menu_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = border_fg, bg = menu_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { fg = select_fg, bg = select_bg, bold = true })
  vim.api.nvim_set_hl(0, "BlinkCmpDoc", { fg = menu_fg, bg = menu_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = border_fg, bg = menu_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpLabelDescription", { fg = muted_fg, bg = menu_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpSource", { fg = muted_fg, bg = menu_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { fg = muted_fg, italic = true })
end

local function apply_ui_overrides(theme)
  local separator_fg = "#5A6478"
  local separator_bg = "NONE"

  if theme == "carbonfox" then
    local ok, palette_mod = pcall(require, "nightfox.palette")
    if ok and palette_mod and palette_mod.load then
      local pal = palette_mod.load("carbonfox")
      if pal then
        separator_fg = pal.sel1 or pal.fg2 or separator_fg
      end
    end
  end

  vim.api.nvim_set_hl(0, "WinSeparator", { fg = separator_fg, bg = separator_bg, bold = true })
  vim.api.nvim_set_hl(0, "VertSplit", { fg = separator_fg, bg = separator_bg, bold = true })
  apply_completion_overrides()
end

local function read_theme()
  local f = io.open(theme_file, "r")
  if not f then
    return nil
  end

  local theme = f:read("*l")
  f:close()
  if theme and theme ~= "" then
    return theme
  end

  return nil
end

local function write_theme(theme)
  local f = io.open(theme_file, "w")
  if not f then
    return false
  end

  f:write(theme)
  f:close()
  return true
end

function M.load()
  local theme = read_theme()
  if theme and pcall(vim.cmd, "colorscheme " .. theme) then
    apply_ui_overrides(theme)
    return
  end

  pcall(vim.cmd, "colorscheme miasma")
  apply_ui_overrides("miasma")
end

function M.set(theme)
  if not theme or theme == "" then
    return
  end

  local ok = pcall(vim.cmd, "colorscheme " .. theme)
  if ok then
    write_theme(theme)
    apply_ui_overrides(theme)
    return
  end

  vim.notify("Failed to load colorscheme: " .. theme, vim.log.levels.WARN)
end

function M.telescope_picker()
  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  builtin.colorscheme({
    enable_preview = true,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local theme = entry and (entry.value or entry.ordinal or entry[1])
        if theme then
          M.set(theme)
        end
      end)

      return true
    end,
  })
end

return M
