# Changelog

## 1.0.2 — 9 November 2026

- Added an original addon icon and matching project artwork.
- Credited **meinyrdi** in the addon metadata and settings window.
- Added version and author information to settings.
- Prepared the public repository, documentation and automated package checks.
- Retained the unit, Shift and both-price behavior from 1.0.1.

## 1.0.1 — 9 November 2026

- Fixed bag tooltips keeping the stack price when the game's quote used
  `maxPrice = -1`. The addon now follows Blizzard's single-price rule for a
  missing maximum or an accessible finite maximum below 1.
- Added regression coverage for the negative sentinel and range boundaries.

## 1.0.0 — 9 November 2026

- Initial standalone addon for WoW Forever.
- Unit vendor price by default; hold Shift for the hovered stack's total.
- Optional simultaneous unit and stack prices on the existing Sell Price line.
- Small settings window, movable minimap button and `/ssp` command.
- Account-wide settings and saved minimap position.
