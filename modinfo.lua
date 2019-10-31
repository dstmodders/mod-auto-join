name = "Auto-Join"
version = "0.1.0"
description = [[Version: ]] .. version .. "\n\n" ..
    [[Adds an Auto-Join button to the server listing screen to continue reconnecting to the same server until joining.]]
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

local boolean = {
    { description = "Yes", data = true },
    { description = "No", data = false },
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

local function AddConfig(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

configuration_options = {
    AddConfig("Waiting time", "waiting_time", waiting_time, 15, "The time between the reconnection attempts"),
    AddConfig("Debug", "debug", boolean, false, "Enables/Disables the debug mode"),
}
