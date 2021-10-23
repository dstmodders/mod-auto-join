project = "Auto-Join"
title = "DST Mod Auto-Join | LDoc"
description = "dst-mod-auto-join"
full_description = [[Mod for the game [Don\'t Starve Together](https://www.klei.com/games/dont-starve-together) to auto-join the selected server.]] .. "\n\n" ..
    [[- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)]] .. "\n" ..
    [[- **Steam Workshop:** [https://steamcommunity.com/sharedfiles/filedetails/?id=1903101575](https://steamcommunity.com/sharedfiles/filedetails/?id=1903101575)]]

file = {
    "./scripts/",
    exclude = {
        "./scripts/autojoin/sdk/",
    },
}

dir = "docs"
format = "markdown"
sort_modules = true
style = "./docs/ldoc/"
use_markdown_titles = true
