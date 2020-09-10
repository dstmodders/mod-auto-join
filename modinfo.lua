name = "Auto-Join"
version = "0.6.0-alpha"
description = [[Version: ]] .. version .. "\n\n" ..
    [[Adds an Auto-Join button to the server listing screen to continuously reconnect to the selected server until joining.]] .. "\n\n" ..
    [[v]] .. version .. [[:]] .. "\n" ..
    [[- Added button states animations]] .. "\n" ..
    [[- Added support for "Rejoin" main screen button]] .. "\n" ..
    [[- Added support for rejoin configurations]] .. "\n" ..
    [[- Added support for the "Dev Tools" mod submenu]]
author = "Demonblink"
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
-- Helpers
--

local function AddConfig(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

local function AddSection(title)
    return AddConfig(title, "", { { description = "", data = 0 } }, 0)
end

local function CreateKeyList()
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

    return list
end

--
-- Configuration
--

local key_list = CreateKeyList()

local boolean = {
    { description = "Yes", data = true },
    { description = "No", data = false },
}

local indicator_padding = {
    { description = "5", data = 5 },
    { description = "10", data = 10 },
    { description = "15", data = 15 },
    { description = "20", data = 20 },
}

local indicator_position = {
    { description = "Top Left", data = "tl" },
    { description = "Top Right", data = "tr" },
    { description = "Bottom Right", data = "br" },
    { description = "Bottom Left", data = "bl" },
}

local indicator_scale = {
    { description = "1", data = 1 },
    { description = "1.1", data = 1.1 },
    { description = "1.2", data = 1.2 },
    { description = "1.3", data = 1.3 },
    { description = "1.4", data = 1.4 },
    { description = "1.5", data = 1.5 },
}

local waiting_time = {
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
}

local rejoin_initial_wait = {
    { description = "1s", data = 1 },
    { description = "2s", data = 2 },
    { description = "3s", data = 3 },
    { description = "5s", data = 5 },
    { description = "10s", data = 10 },
}

configuration_options = {
    AddSection("General"),
    AddConfig("Waiting time", "waiting_time", waiting_time, 15, "The time between reconnection attempts"),

    AddSection("Indicator"),
    AddConfig("Indicator", "indicator", boolean, true, "Should the corner indicator be visible?"),
    AddConfig("Indicator position", "indicator_position", indicator_position, "tr", "Indicator position on the screen"),
    AddConfig("Indicator padding", "indicator_padding", indicator_padding, 10, "Indicator padding from the screen edges"),
    AddConfig("Indicator scale", "indicator_scale", indicator_scale, 1.3, "Indicator scale on the screen"),

    AddSection("Rejoin"),
    AddConfig("Rejoin key", "key_rejoin", key_list, "KEY_CTRL", "Key used for toggling rejoin functionality.\nAvailable on the main screen"),
    AddConfig("Rejoin initial wait", "rejoin_initial_wait", rejoin_initial_wait, 3, "Initial wait in seconds before rejoining to retrieve the list of servers.\nChange based on your network speed"),
    AddConfig("Main screen button", "main_screen_button", boolean, true, "Should the main screen button be enabled?"),

    AddSection("Other"),
    AddConfig("Hide changelog", "hide_changelog", boolean, true, "Should the changelog in the mod description be hidden?\nMods should be reloaded to take effect"),
    AddConfig("Debug", "debug", boolean, false, "Should the debug mode be enabled?"),
}
