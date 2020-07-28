# dst-mod-auto-join

[![GitHub Workflow CI Status][]](https://github.com/victorpopkov/dst-mod-auto-join/actions?query=workflow%3ACI)
[![GitHub Workflow Documentation Status][]](https://github.com/victorpopkov/dst-mod-auto-join/actions?query=workflow%3ADocumentation)
[![Codecov][]](https://codecov.io/gh/victorpopkov/dst-mod-auto-join)

[![Auto-Join](preview.gif)](https://steamcommunity.com/sharedfiles/filedetails/?id=1903101575)

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

| Configuration          | Default     | Description                                            |
| ---------------------- | ----------- | ------------------------------------------------------ |
| **Waiting time**       | _15s_       | The time between reconnection attempts                 |
| **Indicator**          | _Yes_       | Should the corner indicator be visible?                |
| **Indicator position** | _Top Right_ | Indicator position on the screen                       |
| **Indicator padding**  | _10_        | Indicator padding from the screen edges                |
| **Indicator scale**    | _1.3_       | Indicator scale on the screen                          |
| **Hide changelog**     | _Yes_       | Should the changelog in the mod description be hidden? |
| **Debug**              | _No_        | Should the debug mode be enabled?                      |

## Documentation

The [LDoc][] documentation generator has been used for generating documentation,
and the most recent version can be found here:
http://github.victorpopkov.com/dst-mod-auto-join/

- [Installation][]
- [Development][]

## Roadmap

You can always find and track the current states of the upcoming features/fixes
on the following [Trello][] board:
https://trello.com/b/csl4Sgtm/dst-mod-auto-join

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).

[codecov]: https://img.shields.io/codecov/c/github/victorpopkov/dst-mod-auto-join.svg
[development]: readme/02-development.md
[don't starve together]: https://www.klei.com/games/dont-starve-together
[github workflow ci status]: https://img.shields.io/github/workflow/status/victorpopkov/dst-mod-auto-join/CI?label=CI
[github workflow documentation status]: https://img.shields.io/github/workflow/status/victorpopkov/dst-mod-auto-join/Documentation?label=Documentation
[installation]: readme/01-installation.md
[ldoc]: https://stevedonovan.github.io/ldoc/
[steam workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=1903101575
[trello]: https://trello.com/
