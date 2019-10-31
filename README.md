# dst-mod-auto-join

## Overview

Mod for the game [Don't Starve Together][] which adds an Auto-Join button to the
server listing screen to continue reconnecting to the same server until joining.

## Configuration

| Configuration             | Options   | Default | Description                                |
|---------------------------|-----------|---------|--------------------------------------------|
| **Waiting time**          | _5s - 1m_ | _15s_   | The time between the reconnection attempts |
| **Debug**                 | _Yes/No_  | _No_    | Enables/Disables the debug mode            |

## Roadmap

Below are the features/improvements yet to be implemented:

- [ ] Console commands to start/stop auto-joining to the server similar to `c_connect()`
- [ ] Global button/indicator to show the current auto-joining state in other screens
- [ ] Highlight the auto-joining server in the server listing screen

## License

Released under the [Unlicense](https://unlicense.org/).

[don't starve together]: https://www.klei.com/games/dont-starve-together
