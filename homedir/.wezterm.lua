-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- config.color_scheme = 'Solarized (light) (terminal.sexy)'
config.color_scheme = 'Builtin Light'

-- On Diamond systems, cannot change default shell to zsh
config.default_prog = { 'zsh', '-l'}


config.enable_scroll_bar = true

config.font = wezterm.font("SF Mono", { weight = "Medium" })
-- config.font = wezterm.font "Menlo"
-- config.font = wezterm.font "Fira Code"
config.font_size = 13.3
-- config.freetype_load_target = "Normal"
-- config.freetype_render_target = "Normal"

-- config.font = wezterm.font "JetBrains Mono"
-- config.font_size = 13

config.window_padding = {
    left = 5,
    right = 0,
    top = 2,
    bottom = 0,
}

config.quit_when_all_windows_are_closed = false

if wezterm.target_triple == "x86_64-apple-darwin" or wezterm.target_triple == "aarch64-apple-darwin" then
    -- Match my iTerm2 configuration for now
    config.colors = {
        ansi = {
            '#000000',
            '#990200',
            '#00a600',
            '#999900',
            '#0601ff',
            '#b200b2',
            '#01a6b2',
            '#bfbfbf'
        },
        brights = {
            '#686868',
            '#e60300',
            '#00d900',
            '#e5e500',
            '#0601ff',
            '#e600e6',
            '#01e6e6',
            '#ffffff'
        },
        scrollbar_thumb = '#7a7a7a'
    }
    COMMAND = "CMD"
    config.send_composed_key_when_left_alt_is_pressed = true
else
    COMMAND = "CTRL"
end

config.keys = {
    {
        key = 'LeftArrow',
        mods = COMMAND .. '|SHIFT',
        action = wezterm.action.ActivateTabRelative(-1)
    },
    {
        key = 'RightArrow',
        mods = COMMAND .. '|SHIFT',
        action = wezterm.action.ActivateTabRelative(1)
    },
    {
        key = 'k',
        mods = 'SUPER',
        action = wezterm.action.ClearScrollback 'ScrollbackAndViewport'
    }
}

config.use_ime = true

-- and finally, return the configuration to wezterm
return config

