local wezterm = require("wezterm")
local mux = wezterm.mux
local config = wezterm.config_builder()

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():set_position(150, 125)
	window:gui_window():maximize()
end)

config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" }
config.default_cwd = "P:\\"
config.status_update_interval = 500
config.enable_kitty_graphics = true

config.keys = {
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	-- Neovim: <C-,> / <C-.> cycle terminals. Sent as "CSI u" sequences, which a plain terminal cannot express.
	{ key = ",", mods = "CTRL", action = wezterm.action.SendString("\x1b[44;5u") },
	{ key = ".", mods = "CTRL", action = wezterm.action.SendString("\x1b[46;5u") },
}

config.initial_cols = 100
config.initial_rows = 20

config.window_frame = {
	font_size = 11,
}

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- Whole cells never fill the window exactly. Split the leftover pixels evenly around the grid
-- so it works at any font size (zoom included). Idempotent: gap = window - grid, so re-running is stable.
local function center_grid(window)
	local win = window:get_dimensions()
	local pane = window:active_pane():get_dimensions()
	-- Leftover is the sub-cell remainder only, computed from window size and cell size, never from the
	-- pane (the pane shrinks by the padding itself, which would feed back and lock the padding in).
	local cell_w = pane.pixel_width / pane.cols
	local cell_h = pane.pixel_height / pane.viewport_rows
	local tab_h = window:effective_config().enable_tab_bar and cell_h or 0
	local gx = math.floor(win.pixel_width % cell_w + 0.5)
	local gy = math.floor((win.pixel_height - tab_h) % cell_h + 0.5)
	local function px(n)
		return string.format("%dpx", math.floor(n))
	end
	local pad = {
		left = px(gx / 2),
		right = px(gx - math.floor(gx / 2)),
		top = px(gy / 2),
		bottom = px(gy - math.floor(gy / 2)),
	}
	local o = window:get_config_overrides() or {}
	local old = o.window_padding or {}
	if old.left ~= pad.left or old.right ~= pad.right or old.top ~= pad.top or old.bottom ~= pad.bottom then
		o.window_padding = pad
		window:set_config_overrides(o)
	end
end
-- ponytail: tab bar height assumed = one cell row; adjust tab_h if a gap remains at the top/bottom.

-- Vertical fit: the tab bar is one row, so (rows + 1) * cell_h should equal the window height.
-- Pick a nearby integer cell_h that divides it, then steer line_height (cell_h = ceil(natural * lh)) there.
local BASE_LH = 1.04 -- must equal config.line_height below
local fit = {} -- window_id -> { h = window height, nat = natural cell height estimate, t = target cell height }
local function fit_height(window)
	local win_h = window:get_dimensions().pixel_height
	local pane = window:active_pane():get_dimensions()
	local cell_h = math.floor(pane.pixel_height / pane.viewport_rows + 0.5)
	local o = window:get_config_overrides() or {}
	local lh = o.line_height or BASE_LH
	-- Natural row height at BASE_LH, recovered from the current (possibly adjusted) one: no drift across zooms.
	local nat = (cell_h - 0.5) / lh * BASE_LH
	local id = window:window_id()
	local st = fit[id]
	if not (st and st.h == win_h and math.abs(nat - st.nat) <= 2) then
		local c0 = math.floor(nat + 0.5)
		local t, best = c0, math.huge
		for c = c0 - 2, c0 + 2 do -- nearest size wins ties; zoom stays roughly where the user put it
			local rem = win_h % c
			if rem < best or (rem == best and math.abs(c - c0) < math.abs(t - c0)) then
				t, best = c, rem
			end
		end
		st = { h = win_h, nat = nat, t = t, tries = 0 }
		fit[id] = st
	end
	if cell_h == st.t then
		st.tries = 0
		return false
	end
	if st.tries >= 6 then
		return false
	end
	st.tries = st.tries + 1
	o.line_height = lh * (st.t - 0.5) / (cell_h - 0.5)
	window:set_config_overrides(o)
	return true
end

local function on_layout(window)
	if not fit_height(window) then
		center_grid(window)
	end
end
wezterm.on("window-resized", on_layout)
wezterm.on("window-config-reloaded", on_layout)
-- Zoom (Ctrl +/-) changes the cell size without resizing the window, so no resize event fires; poll instead.
wezterm.on("update-status", on_layout)

config.colors = {
	tab_bar = {
		background = "#1e1e1e",
	},
}
-- Match nvim's carbonfox Normal bg (#161616) and make cell backgrounds share the window opacity,
-- otherwise the leftover pixels around the grid show as a different shade than nvim/TUI cells.
config.colors.background = "#161616"
config.text_background_opacity = 0.92
config.use_resize_increments = true

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.integrated_title_button_style = "Gnome"
config.integrated_title_buttons = { "Close" }
config.tab_max_width = 25
config.hide_tab_bar_if_only_one_tab = false
config.enable_tab_bar = true
config.window_background_opacity = 0.92
config.win32_system_backdrop = "Acrylic"

config.font = wezterm.font("JetBrainsMono Nerd Font Mono", { weight = "Regular" })
config.font_size = 14
config.line_height = BASE_LH
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0

config.window_close_confirmation = "NeverPrompt"

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = ""

	local cwd_uri = tab.active_pane.current_working_dir

	if cwd_uri then
		local cwd = ""

		if type(cwd_uri) == "userdata" then
			cwd = cwd_uri.file_path or ""
		elseif type(cwd_uri) == "string" then
			cwd = cwd_uri
		end

		if cwd ~= "" then
			title = cwd:match("([^/\\]+)[/\\]*$") or cwd
		end
	end

	-- fallback
	if title == "" then
		title = tab.active_pane.title
	end

	-- truncate
	local max_len = max_width - 6
	if #title > max_len then
		title = title:sub(1, max_len) .. "…"
	end

	local is_active = tab.is_active

	local bg = "#1e1e1e"
	local active_bg = "#3a3a3a"
	local hover_bg = "#2f2f2f"

	local fg = "#8a8a8a"
	local active_fg = "#ffffff"

	if is_active then
		bg = active_bg
		fg = active_fg
	elseif hover then
		bg = hover_bg
		fg = "#dddddd"
	end

	return {
		{ Text = " " },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = "  " .. title .. "   " },
		{ Background = { Color = "#1e1e1e" } },
		{ Text = " " },
	}
end)

return config
