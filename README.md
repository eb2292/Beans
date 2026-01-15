# Beans

Beans is a lightweight World of Warcraft: Mists of Pandaria Classic addon that tracks how much gold your character has gained or lost for the current day and week. It provides a small, movable coin icon that shows a running total and a tooltip with both daily and weekly net values.

## Features

- Tracks gold earned or spent for the current day and week.
- Automatic day/week rollover based on your system date.
- Movable coin icon with a hover tooltip.
- Quick toggle between daily and weekly display.
- Simple slash commands for configuration.

## Installation

1. Download or clone this repository.
2. Copy the `Beans` folder into your World of Warcraft Classic addons directory:
   - **Windows:** `World of Warcraft\_classic_\Interface\AddOns\`
   - **macOS:** `World of Warcraft/_classic_/Interface/AddOns/`
3. Ensure the folder structure looks like this:
   ```text
   Interface/AddOns/Beans/Beans.toc
   Interface/AddOns/Beans/Beans.lua
   ```
4. Launch the game and enable **Beans** from the AddOns list at the character select screen.

## Usage

- A small coin icon appears on screen after login.
- **Hover** the icon to see the daily and weekly net totals.
- **Right-click** the icon to toggle the on-frame display between daily and weekly totals.
- **Drag** the icon to reposition it (unless locked).

## Slash Commands

Use `/beans` followed by one of the options below:

- `/beans lock` - Lock the icon in place.
- `/beans unlock` - Unlock the icon so it can be moved.
- `/beans show` - Show the icon.
- `/beans hide` - Hide the icon.
- `/beans reset day` - Reset the daily net total.
- `/beans reset week` - Reset the weekly net total.
- `/beans reset all` - Reset both daily and weekly totals.
- `/beans display daily` - Show the daily net total on the icon.
- `/beans display weekly` - Show the weekly net total on the icon.

## Notes

- Totals are tracked per character.
- Day and week boundaries are based on your system clock (local time).

## License

MIT
