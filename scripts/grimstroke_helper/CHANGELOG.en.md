# Update 1.4.2

- The helper window uses the new interface version: the font matches the Umbrella menu, buttons light up in the accent colour on hover.
- The header chevron sits on the side of the screen edge the window is closer to.
- The dock button works from anywhere on the screen: the window moves to the nearest edge by itself.
- The docked tab is larger and as tall as the header.

# Update 1.4.1

- Dark Portrait filter: the built-in combo no longer casts Dark Portrait on an unmarked enemy after the combo key is released and pressed again.
- Dark Portrait filter: Dark Portrait is also allowed on an enemy bound by Soulbind to a marked enemy.
- Dark Portrait filter: if the enemy under the cursor changes while the combo key is held, Dark Portrait is cast only when both the first target and the new one are allowed.
- Ink Swell: the ally-to-enemy distance now works in every mode, including "Allowed ally closest to enemies".
- Fixed Lua errors when an illusion or its target disappears.

# Update 1.4.0

- The helper window looks like Umbrella's own panels (Illusion Controller, Wards): colours come from the cheat menu, the header has the switch and filters on the left, the title in the middle and a red chevron on the right.
- One window instead of the ally panel and a separate filters window: the filters button in the header switches the page, the filters key opens it directly.
- The header switch pauses the automation. Hide the window from the menu or with the panel key.
- Drag the window to the left or right screen edge to dock it there: only a small tab with a chevron and the automation switch stays.
- Window size is set in the gear next to Enable.
- Icons of a list that is not in use are dimmed: allies when Ink Swell picks any ally, enemies when their filter is off.

# Update 1.3.0

- New on-screen panel: Ink Swell allies are shown as icons, click an icon to allow or forbid Ink Swell. A green dot means an enemy is near that ally.
- The panel header has a pause switch, a fold button and a close button.
- "Combo Filters" window with both lists (Dark Portrait and solo Soulbind): enemy icons and a switch for each list. Changes sync with the menu.
- New keys: show or hide the panel and open or close the filters window.
- All panel text is in English and Russian, hero names come from the game.
- Menu lists are compact and no longer overlap while there are no enemies.
- Debug log (gear next to Enable): logs panel clicks and key presses.
- Optimization: Dark Portrait and Ink Swell are checked less often, drawing no longer creates extra objects every frame.

# Update 1.2.0

- Reworked menu: four groups in two columns (helper, Ink Swell, Dark Portrait illusion, built-in combo), with an icon and a tooltip on every item. Items grey out when their switch is off.
- The menu is translated into English and Russian and follows the cheat language. The translation library is embedded in the file, nothing else to install.
- Helper settings reset to defaults once because the menu items were renamed. Heroes checked in the whitelists are kept.

# Update 1.1.0

- Dark Portrait whitelist: the built-in combo casts Dark Portrait only on checked enemies. On other enemies it skips Dark Portrait and uses the other abilities as usual.
- Soulbind whitelist: with the level 15 talent, the combo Soulbinds a checked enemy even when no second enemy is nearby. Other enemies keep the original logic: Soulbind is cast only when a second enemy is in link range.
- Both lists work on the built-in combo key. Settings: Heroes → Grimstroke → Helper → Combo Whitelists.

# Update 1.0.0

- Initial release of the Grimstroke Ink Swell and Dark Portrait helper.
