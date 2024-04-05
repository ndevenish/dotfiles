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
local solr_light =
    wezterm.color.get_builtin_schemes()["Solarized (light) (terminal.sexy)"]
solr_light.foreground = "#073642"
solr_light.scrollbar_thumb = "#7a7a7a"
-- config.colors = {scrollbar_thumb = '#7a7a7a'}

local solr_dark =
    wezterm.color.get_builtin_schemes()["Solarized (dark) (terminal.sexy)"]
solr_dark.scrollbar_thumb = "#657b83"

config.color_schemes = {
    ["My Solarized Light"] = solr_light,
    ["My Solarized Dark"] = solr_dark,
}

function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return "Dark"
end

function scheme_for_appearance(appearance)
    if appearance:find "Dark" then
        -- return "Solarized (dark) (terminal.sexy)"
        return "My Solarized Dark"
    else
        return "My Solarized Light"
    end
end

-- config.color_scheme = "My Solarized"
config.color_scheme = scheme_for_appearance(get_appearance())

-- On Diamond systems, cannot change default shell to zsh
config.default_prog = {"zsh", "-l"}
config.default_cwd = "~"

config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
config.scrollback_lines = 10000
config.font_size = 13

config.window_padding = {left = 5, right = 0, top = 2, bottom = 0}

config.quit_when_all_windows_are_closed = false

-- Create this here so we can later extend
config.keys = {}

-- if wezterm.target_triple == "x86_64-apple-darwin" or wezterm.target_triple == "aarch64-apple-darwin" then
if string.find(wezterm.target_triple, "apple") then
    config.font = wezterm.font("SF Mono", {weight = "Medium"})
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
table.insert(config.keys, {
    key = "a",
    mods = "CMD",
    action = wezterm.action_callback(function(window, pane)
        local dims = pane:get_dimensions()
        local txt = pane:get_text_from_region(0, dims.scrollback_top, 0,
                                              dims.scrollback_top + dims.scrollback_rows)
        window:copy_to_clipboard(txt:match("^%s*(.-)%s*$")) -- trim leading and trailing whitespace
    end),
})

-- config.use_ime = true
config.hide_tab_bar_if_only_one_tab = true

config.initial_cols = 120
config.initial_rows = 35
config.window_frame = {
    font_size = 13,
    active_titlebar_bg = "#7a7a7a",
    --    active_titlebar_bg = '#d2d2d2',
    --    inactive_titlebar_bg = '#cc0000'
}

config.skip_close_confirmation_for_processes_named = {
    "bash",
    "sh",
    "zsh",
    "tmux",
    "ssh",
}

-- config.keys = {
--  -- CMD-y starts `top` in a new tab
--  {
--    key = 't',
--    mods = 'CMD',
--    action = wezterm.action.SpawnCommandInNewTab {
--      cwd = wezterm.home_dir,
--    },
--  },
-- }

-- and finally, return the configuration to wezterm
return config

