local wezterm = require("wezterm")

local config = wezterm.config_builder()
config.automatically_reload_config = true

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"Noto Sans Mono CJK JP",
})

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }
local act = wezterm.action
config.keys = {
	{
		key = "C",
		mods = "SUPER",
		action = wezterm.action.CopyTo("Clipboard"),
	},
	{
		key = "V",
		mods = "SUPER",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
	{
		key = "\\",
		mods = "LEADER",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = "LEADER",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "z",
		mods = "LEADER",
		action = act.TogglePaneZoomState,
	},
	{
		key = "h",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "c",
		mods = "LEADER",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{ key = "q", mods = "LEADER", action = wezterm.action.QuickSelect },
	{
		key = "Space",
		mods = "LEADER",
		action = wezterm.action.ActivateCopyMode,
	},
}

for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

config.color_scheme = "Tokyo Night"
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}

return config
