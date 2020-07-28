name = "Auto-Join"
version = "0.5.0-alpha"
description = [[Version: ]] .. version .. "\n\n" ..
    [[Adds an Auto-Join button to the server listing screen to continuously reconnect to the selected server until joining.]] .. "\n\n" ..
    [[v]] .. version .. [[:]] .. "\n" ..
    [[- Added support for the hide changelog configuration]] .. "\n" ..
    [[- Added tests and documentation]] .. "\n" ..
    [[- Changed configuration to be divided into sections]]  .. "\n" ..
    [[- Refactored and restructured most of the existing code]]
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

--
-- Configuration
--

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

configuration_options = {
    AddSection("General"),
    AddConfig("Waiting time", "waiting_time", waiting_time, 15, "The time between reconnection attempts"),

    AddSection("Indicator"),
    AddConfig("Indicator", "indicator", boolean, true, "Should the corner indicator be visible?"),
    AddConfig("Indicator position", "indicator_position", indicator_position, "tr", "Indicator position on the screen"),
    AddConfig("Indicator padding", "indicator_padding", indicator_padding, 10, "Indicator padding from the screen edges"),
    AddConfig("Indicator scale", "indicator_scale", indicator_scale, 1.3, "Indicator scale on the screen"),

    AddSection("Other"),
    AddConfig("Hide changelog", "hide_changelog", boolean, true, "Should the changelog in the mod description be hidden?\nMods should be reloaded to take effect"),
    AddConfig("Debug", "debug", boolean, false, "Should the debug mode be enabled?"),
}
