local wezterm = require("wezterm")

local config = wezterm.config_builder()
config.automatically_reload_config = true

config.color_scheme = "Tokyo Night"
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}

return config
