local wezterm = require("wezterm")
local mux = wezterm.mux
local config = wezterm.config_builder()

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():set_position(150, 125)
	window:gui_window():maximize()
end)

config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" }
config.default_cwd = "D:\\"
config.status_update_interval = 500

config.keys = {
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
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

config.colors = {
	tab_bar = {
		background = "#1e1e1e",
	},
}
config.colors.background = "#1e1e1e"
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
config.font_size = 13.5
config.line_height = 1
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
