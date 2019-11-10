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

Don't like the default behaviour? Choose your own configuration to match your
needs:

| Configuration          | Options     | Default     | Description                                     |
|------------------------|-------------|-------------|-------------------------------------------------|
| **Waiting time**       | _5s - 1m_   | _15s_       | The time between the reconnection attempts      |
| **Indicator**          | _Yes/No_    | _No_        | Enables/Disables the indicator on other screens |
| **Indicator position** | _[corners]_ | _Top Right_ | The indicator position on the screen            |
| **Indicator padding**  | _5 - 20_    | _10_        | The indicator padding from the screen edges     |
| **Indicator scale**    | _1 - 1.5_   | _1.3_       | The indicator size on the screen                |
| **Debug**              | _Yes/No_    | _No_        | Enables/Disables the debug mode                 |

## Roadmap

Below are the features/improvements yet to be implemented:

- [ ] Console commands to start/stop auto-joining to the server similar to `c_connect()`

## License

Released under the [Unlicense](https://unlicense.org/).

[don't starve together]: https://www.klei.com/games/dont-starve-together
[steam workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=1903101575
