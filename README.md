# Tile Markers

A RuneScape plugin for marking ground tiles.

## Use

- Manage defaults and presets from the tilemarkers settings.
- Hold your configured keybind (default: **Ctrl+Shift**) and right-click any tile to mark it or edit its marker.
- Right-click the world map button to access bulk actions on visible markers.

## Nearby tile grid

Enable **Show all nearby tiles** in the settings to display a ground grid within
30 tiles of your character on the current floor. The grid follows you as you move,
including in instanced areas; it does not appear on the world map interface.

The grid is off by default. Its separate colour picker includes an opacity slider
(default: white at 35% opacity), and its outline thickness ranges from 0.5 to 10
(default: 1). It uses complete outlines without fills or labels and follows the
existing **Draw over scenery** setting.

Marked tiles and hover previews take priority over the grid. Grid tiles are only
a visual guide: they are never saved as markers or included in presets, exports,
or bulk marker actions.
