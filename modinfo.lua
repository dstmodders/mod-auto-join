name = "Auto-Join"
version = "0.9.0-alpha"
description = [[Version: ]] .. version .. "\n\n" ..

    [[Adds "Auto-Join" and "Rejoin" buttons.]] .. "\n\n" ..

    [[The first one allows continuous reconnections to the selected server until joining, and ]] ..
    [[the second - rejoin the last server.]] .. "\n\n" ..

    [[v]] .. version .. [[:]] .. "\n" ..
    [[- Added support for "banned" and "kicked" statuses]] .. "\n" ..
    [[- Fixed issue with syncing rejoin button state]] .. "\n" ..
    [[- Improved some existing status icons]] .. "\n" ..
    [[- Improved the "Dev Tools" mod submenu]] .. "\n" ..
    [[- Refactored modinfo]]
author = "Depressed DST Modders"
api_version = 10
forumthread = ""

priority = 0

icon = "modicon.tex"
icon_atlas = "modicon.xml"

all_clients_require_mod = false
client_only_mod = true
dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = false
shipwrecked_compatible = false

folder_name = folder_name or "dst-mod-auto-join"
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
end

--
-- Configuration
--

local function AddConfig(name, label, hover, options, default)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

local function AddBooleanConfig(name, label, hover, default)
    default = default == nil and true or default
    return AddConfig(name, label, hover, {
        { description = "Enabled", data = true },
        { description = "Disabled", data = false },
    }, default)
end

local function AddKeyListConfig(name, label, hover, default)
    if default == nil then
        default = false
    end

    -- helpers
    local function AddDisabled(t)
        t[#t + 1] = { description = "Disabled", data = false }
    end

    local function AddKey(t, key)
        t[#t + 1] = { description = key, data = "KEY_" .. key:gsub(" ", ""):upper() }
    end

    local function AddKeysByName(t, names)
        for i = 1, #names do
            AddKey(t, names[i])
        end
    end

    local function AddAlphabetKeys(t)
        local string = ""
        for i = 1, 26 do
            AddKey(t, string.char(64 + i))
        end
    end

    local function AddTypewriterNumberKeys(t)
        for i = 1, 10 do
            AddKey(t, "" .. (i % 10))
        end
    end

    local function AddTypewriterModifierKeys(t)
        AddKeysByName(t, { "Alt", "Ctrl", "Shift" })
    end

    local function AddTypewriterKeys(t)
        AddAlphabetKeys(t)
        AddKeysByName(t, {
            "Slash",
            "Backslash",
            "Period",
            "Semicolon",
            "Left Bracket",
            "Right Bracket",
        })
        AddKeysByName(t, { "Space", "Tab", "Backspace", "Enter" })
        AddTypewriterModifierKeys(t)
        AddKeysByName(t, { "Tilde" })
        AddTypewriterNumberKeys(t)
        AddKeysByName(t, { "Minus", "Equals" })
    end

    local function AddFunctionKeys(t)
        for i = 1, 12 do
            AddKey(t, "F" .. i)
        end
    end

    local function AddArrowKeys(t)
        AddKeysByName(t, { "Up", "Down", "Left", "Right" })
    end

    local function AddNavigationKeys(t)
        AddKeysByName(t, { "Insert", "Delete", "Home", "End", "Page Up", "Page Down" })
    end

    -- key list
    local list = {}

    AddDisabled(list)
    AddArrowKeys(list)
    AddFunctionKeys(list)
    AddTypewriterKeys(list)
    AddNavigationKeys(list)
    AddKeysByName(list, { "Escape", "Pause", "Print" })

    return AddConfig(name, label, hover, list, default)
end

local function AddSection(title)
    return AddConfig("", title, nil, { { description = "", data = 0 } }, 0)
end

configuration_options = {
    --
    -- General
    --

    AddSection("General"),

    AddBooleanConfig(
        "disable_music",
        "Disable music",
        "When enabled, disables music while attempting to join"
    ),

    AddConfig(
        "notification_sound",
        "Notification sound",
        "Plays the following sound if connection succeeds",
        {
            { description = "Disabled", data = false },
            { description = "Beefalo Horn", data = "dontstarve/common/Horn_beefalo" },
            { description = "Splumonkey Taunt", data = "dontstarve/creatures/monkey/taunt" },
            { description = "Batilisk Taunt", data = "dontstarve/creatures/bat/taunt" },
        },
        false
    ),

    AddConfig(
        "waiting_time",
        "Waiting time",
        "The time between reconnection attempts",
        {
            { description = "5s", data = 5 },
            { description = "10s", data = 10 },
            { description = "15s", data = 15 },
            { description = "20s", data = 20 },
            { description = "25s", data = 25 },
            { description = "30s", data = 30 },
            { description = "35s", data = 35 },
            { description = "40s", data = 40 },
            { description = "45s", data = 45 },
            { description = "50s", data = 50 },
            { description = "55s", data = 55 },
            { description = "1m", data = 60 },
        },
        15
    ),

    --
    -- Indicator
    --

    AddSection("Indicator"),

    AddBooleanConfig(
        "indicator",
        "Indicator",
        "When enabled, adds a corner indicator on the supported screens"
    ),

    AddConfig(
        "indicator_position",
        "Indicator position",
        "Indicator position on the screen",
        {
            { description = "Top Left", data = 1 },
            { description = "Top Right", data = 2 },
            { description = "Bottom Right", data = 3 },
            { description = "Bottom Left", data = 4 },
        },
        2
    ),

    AddConfig(
        "indicator_padding",
        "Indicator padding",
        "Indicator padding from the screen edges",
        {
            { description = "5", data = 5 },
            { description = "10", data = 10 },
            { description = "15", data = 15 },
            { description = "20", data = 20 },
        },
        10
    ),

    AddConfig(
        "indicator_scale",
        "Indicator scale",
        "Indicator scale on the screen",
        {
            { description = "1", data = 1 },
            { description = "1.1", data = 1.1 },
            { description = "1.2", data = 1.2 },
            { description = "1.3", data = 1.3 },
            { description = "1.4", data = 1.4 },
            { description = "1.5", data = 1.5 },
        },
        1.3
    ),

    --
    -- Rejoin
    --

    AddSection("Rejoin"),

    AddKeyListConfig(
        "key_rejoin",
        "Rejoin key",
        "Key used for toggling the rejoin functionality.\nAvailable on the main and pause screens",
        "KEY_CTRL"
    ),

    AddConfig(
        "rejoin_initial_wait",
        "Rejoin initial wait",
        [[Initial wait in seconds to retrieve a list of servers before rejoining.]] .. "\n" ..
            [[Change based on your network speed]],
        {
            { description = "1s", data = 1 },
            { description = "2s", data = 2 },
            { description = "3s", data = 3 },
            { description = "5s", data = 5 },
            { description = "10s", data = 10 },
        },
        3
    ),

    AddBooleanConfig(
        "rejoin_main_screen_button",
        "Rejoin main screen button",
        [[When enabled, adds "Rejoin" button in the multiplayer main screen.]] .. "\n" ..
            [[On Windows, replaces the last "Games" button']]
    ),

    AddBooleanConfig(
        "rejoin_pause_screen_button",
        "Rejoin pause screen button",
        [[When enabled, adds "Rejoin" button in the pause screen.]] .. "\n" ..
            [[Replaces "Disconnect" while holding the rejoin key]]
    ),

    --
    -- Other
    --

    AddSection("Other"),

    AddBooleanConfig(
        "hide_changelog",
        "Hide changelog",
        [[When enabled, hides the changelog in the mod description.]] .. "\n" ..
            [[Mods should be reloaded to take effect]]
    ),

    AddBooleanConfig(
        "debug",
        "Debug",
        "When enabled, displays debug data in the console.\nUsed mainly for development",
        false
    ),
}
