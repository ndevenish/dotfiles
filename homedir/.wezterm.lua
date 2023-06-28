-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- local solr = wezterm.color.get_builtin_schemes()["Builtin Solarized Light"]
local solr = wezterm.color.get_builtin_schemes()["Solarized (light) (terminal.sexy)"]
solr.foreground = "#073642"
solr.scrollbar_thumb = "#7a7a7a"
config.color_schemes = {["My Solarized"] = solr}
-- config.colors = {scrollbar_thumb = '#7a7a7a'}

config.color_scheme = "My Solarized"

-- On Diamond systems, cannot change default shell to zsh
config.default_prog = {"zsh", "-l"}

config.enable_scroll_bar = true

config.font = wezterm.font("SF Mono", {weight = "Medium"})
config.font_size = 13

config.window_padding = {left = 5, right = 0, top = 2, bottom = 0}

config.quit_when_all_windows_are_closed = false

-- Create this here so we can later extend
config.keys = {}

-- if wezterm.target_triple == "x86_64-apple-darwin" or wezterm.target_triple == "aarch64-apple-darwin" then
if string.find(wezterm.target_triple, "apple") then
    -- Match my iTerm2 configuration for now - if we didn't change the general scheme
    if config.color_scheme == "Builtin Light" then
        config.colors = {
            ansi = {
                "#000000",
                "#990200",
                "#00a600",
                "#999900",
                "#0601ff",
                "#b200b2",
                "#01a6b2",
                "#bfbfbf",
            },
            brights = {
                "#686868",
                "#e60300",
                "#00d900",
                "#e5e500",
                "#0601ff",
                "#e600e6",
                "#01e6e6",
                "#ffffff",
            },
            scrollbar_thumb = "#7a7a7a",
        }
    end
    COMMAND = "CMD"
    config.send_composed_key_when_left_alt_is_pressed = true
    table.insert(config.keys, {
        key = "LeftArrow",
        mods = "OPT",
        action = wezterm.action.SendKey {key = "b", mods = "ALT"},
    })
    table.insert(config.keys, {
        key = "RightArrow",
        mods = "OPT",
        action = wezterm.action.SendKey {key = "f", mods = "ALT"},
    })
else
    COMMAND = "CTRL"
end

table.insert(config.keys, {
    key = "LeftArrow",
    mods = COMMAND .. "|SHIFT",
    action = wezterm.action.ActivateTabRelative(-1),
})
table.insert(config.keys, {
    key = "RightArrow",
    mods = COMMAND .. "|SHIFT",
    action = wezterm.action.ActivateTabRelative(1),
})
table.insert(config.keys, {
    key = "k",
    mods = "SUPER",
    action = wezterm.action.ClearScrollback "ScrollbackAndViewport",
})

-- config.use_ime = true
config.hide_tab_bar_if_only_one_tab = true

-- and finally, return the configuration to wezterm
return config

