# Level Lens
Level Lens is a RuneScape plugin that adds configurable level-progress indicators directly to the native Skills interface. It shows progress toward the next level on each skill tile.

## Screenshots

![Level Lens](assets/level-lens.png)

**Settings**

![Level Lens settings](assets/options.png)

**Rarity background**

![Rarity-coloured background progress indicators](assets/skillmenu-rarity-background.png)

**Solid green background**

![Solid green background progress indicators](assets/skillmenu-green-background.png)

**Solid green bottom bar**

![Solid green bottom progress indicators](assets/skillmenu-green-bottom.png)


## Features

- Three indicator styles: Background bar, Bottom bar, and Left bar
- Configurable thickness for the Bottom and Left bars
- Rarity-style progress colours or solid green
- Includes Invention's elite-skill XP curve
- Optional True Virtual Level integration (API 1.1+), including native elite Invention progress and independent 120/126 virtual-level cap calculations
- A virtual level cap setting: follow TVL, cap at 120, or extend to 126
- Settings saved between sessions
- Indicators that follow the native Skills interface when it resizes

Rarity colours show progress as follows:

- 0–20%: light/white
- 20–40%: green
- 40–60%: blue
- 60–80%: purple
- 80–100%: gold

## Settings

Choose the indicator style, set the thickness for Bottom or Left bars, and select rarity colours or solid green.

**Virtual level cap:** Follow True Virtual Level (default), cap at 120, or extend to 126. With TVL API 1.1+, Level Lens requests the selected cap per calculation; it never changes TVL's saved preference. Native elite Invention uses its level-150 progression regardless of the standard cap. If TVL is unavailable, Level Lens retains its native progression fallback; 120/126 overrides require TVL 1.1+.

## Development

This plugin is built for the official RuneScape Plugin API.
