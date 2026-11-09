# Forever client checks

**Basic 1.0.1 behavior reported working on 9 November 2026** after the sentinel
fix. The exact running build and comprehensive checklist results were not
recorded. Version 1.0.2 adds
original artwork and author/version presentation; those cosmetic changes still
need a native visual check. Version 1.0.0 failed the user's native test in
both Blizzard's bags and Facet Bags. The screenshot diagnostic identified a
normal `GetBagItem` quote with `price = 3000` and `maxPrice = -1`; 1.0.0 wrongly
skipped that valid negative sentinel. Version 1.0.1 accepts the native
single-price rule, including `maxPrice = -1`.

The updated **94 behavioral checks** pass offline. The unchanged UI previously
passed **18 smoke checks**. Record the addon's version and the output of
`GetBuildInfo()` when running these checks. Offline tests do not establish
native rendering, saved-variable persistence, combat behavior or compatibility
with another bag addon.

1. Install the **1.0.2 ZIP**, restart Forever and enable Simple Sell Price.
   Turn off **Show unit and stack prices together** and disable other
   price-tooltip addons. Select a sellable stack containing more than one item
   in the default bags. Confirm the original Sell Price row shows one item's
   vendor value, with no duplicate row. Recheck the original failing stack;
   if retaining the chat diagnostic, confirm its `GetBagItem` quote with
   `maxPrice = -1` now follows the unit-price path. Try a single item and an
   item with no vendor value too.
2. Keep the mouse stationary over the stack. Press and release **left Shift**,
   then **right Shift**. The same row must switch promptly between unit and
   actual stack values. Hold both Shifts and release one; the stack value
   should remain until both are released. Repeat hovering while Shift is
   already down.
3. Split or combine stacks and hover the changed slot. Confirm the quantity
   used is its current stack size. Move between two stacks of the same item
   with different sizes; each Shift value must match the hovered stack.
4. Click the minimap coin. Tick **Show unit and stack prices together**. Hover
   a stack and confirm one Sell Price row contains the unit value labelled
   `each` and the full value labelled `stack`, with the right count. Shift must
   not remove either value. A single item should retain one price. Untick it
   and repeat the Shift check.
5. Open a merchant and repeat the bag checks. Compare the stack's total with
   the vendor's actual quote. Other merchant tooltips should keep their normal
   display. Repeat the bag checks with the player's usual bag addon if it
   uses native `SetBagItem` tooltips.
6. Click and drag the minimap button. A drag should move it around the minimap
   without opening settings. A click should toggle settings. Move the window
   by its title; its close button and Escape should dismiss it normally.
   Confirm the original coin icon loads and the settings footer says
   `meinyrdi | v1.0.2`.
7. Hide the minimap button in settings. Reopen the window with `/ssp` and with
   `/simplesellprice`, then show the button again. Change both settings and
   move the button, run `/reload`, and confirm they persist. Repeat after a
   complete logout/login and on another character on the same account.
8. Enter and leave combat with bags open. Check normal hover, stationary Shift,
   both-price mode and the minimap/settings controls without blocked-action
   warnings or Lua errors. After combat, repeat normal bag interactions,
   including Shift-click to split a stack.
