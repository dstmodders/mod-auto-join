# dst-mod-auto-join

## Overview

Mod for the game [Don't Starve Together][] which is available through the
[Steam Workshop][]. It was made for those who are tired of pressing the "Join"
button over and over again in an attempt to join the full server while "hunting"
for the free slot.

It adds an "Auto-Join" button next to the original "Join" to continuously
reconnect to the selected server until joining. Now you can finally stop
"zombie-clicking" and focus on the more important stuff!

## Configuration

| Configuration             | Options   | Default | Description                                |
|---------------------------|-----------|---------|--------------------------------------------|
| **Waiting time**          | _5s - 1m_ | _15s_   | The time between the reconnection attempts |
| **Debug**                 | _Yes/No_  | _No_    | Enables/Disables the debug mode            |

## Roadmap

Below are the features/improvements yet to be implemented:

- [ ] Console commands to start/stop auto-joining to the server similar to `c_connect()`
- [ ] Global button/indicator to show the current auto-joining state in other screens

## License

Released under the [Unlicense](https://unlicense.org/).

[don't starve together]: https://www.klei.com/games/dont-starve-together
[steam workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=1903101575
