# CurseForge listing

## Project fields

| Field | Value |
| --- | --- |
| Name | Simple Sell Price |
| Author | meinyrdi |
| Game | World of Warcraft |
| Game flavor | WoW Forever |
| Supported game version | 1.60.1 |
| Primary category | Tooltip |
| Additional category | Bags & Inventory |
| License | MIT |
| Source | https://github.com/marxnus/simple-sell-price |
| Issues | https://github.com/marxnus/simple-sell-price/issues |
| Project icon | `art/curseforge-icon.png` |
| Banner | `art/banner.png` |
| Feature image | `art/feature-preview.png` — illustrative example |

## Summary

Show unit vendor prices in WoW Forever bag tooltips. Hold Shift for the stack
total, or display both on the same Sell Price line. Includes a small minimap
settings button.

## Description

**Unit sell prices at a glance. Hold Shift for the stack.**

Simple Sell Price is a small standalone addon for **World of Warcraft: Forever**
by **meinyrdi**. It changes the existing **Sell Price** line in bag tooltips so
you can see what one item is worth without doing the division yourself.

### How it works

- **Normal hover:** vendor sell value of one item.
- **Hold Shift:** vendor sell value of the entire hovered stack.
- **Show both prices:** unit and stack values together on the same Sell Price
  line, labelled `each` and `stack`, with the stack count.

Single items keep one price. Values come from the actual stack's vendor quote
and quantity.

### Two simple settings

Click the small minimap button or type **`/ssp`** to open settings. Choose
whether to show both prices and whether to show the minimap button. Drag the
button around the minimap to move it. Settings are shared across characters
on the same account. **`/simplesellprice`** also opens the window.

### Compatibility

For **WoW Forever 1.60.1 / Camelot**, interface **16001**. Uses Blizzard's bag
tooltips and supports compatible bag addons that follow the native item-tooltip
path. Other tooltip contexts keep their normal prices.

No dependencies, bag replacement or auction scan required. These are **vendor
sell prices**, not auction-house estimates.

### Install

Install the Forever file through CurseForge, or extract its ZIP into your
Forever installation's **Interface/AddOns** folder. Enable **Simple Sell Price**
in the game's AddOns list.

Made by **meinyrdi**. Open source under the **MIT license**.

[Source code](https://github.com/marxnus/simple-sell-price) ·
[Report an issue](https://github.com/marxnus/simple-sell-price/issues)

## File release notes — 1.0.2

Original addon icon and project artwork, with **meinyrdi** author credit and
version information in settings. Includes the 1.0.1 fix for normal Forever bag
quotes using `maxPrice = -1`. Unit price by default, Shift for stack price, and
the optional both-price display retain the same behavior.

Upload `dist/SimpleSellPrice-1.0.2-Camelot.zip` as a release for **WoW Forever
1.60.1**. Gallery captions must identify `art/feature-preview.png` as an
illustrative example, not an in-game screenshot.
