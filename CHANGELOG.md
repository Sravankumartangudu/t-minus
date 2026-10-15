# Changelog

## 1.6.1 - 2026-10-15

- **Sharper small icons.** At 16–64 px the app icon's drop shadow filled the whole image, leaving a faint grey
  square behind it in Finder lists, Spotlight and the menu. Every size is now shrunk from the full-size drawing,
  so the shadow keeps its proportions and the corners stay clear. The icon itself is unchanged.

## 1.6.0 - 2026-10-15

- The menu is tidier: every preference now lives under one **⚙ Settings** submenu, grouped into **Alerts** (Alert style, Alert colors, Alert lead time, Sound, Voice), **What to alert for** (video links only, Reminders) and **App** (Appearance, Launch at login). Saved preferences are unchanged.
- Clearer names: the color picker is now **Alert colors** (it was "Theme", easy to confuse with Appearance), and Appearance says it covers the menu and dialogs.
- The meeting name on the alerts is easier to read: bigger and bolder, with a dark shadow behind it and brighter detail lines. The dark alert look is unchanged.
- README now has screenshots. A hidden `--shot=<file.png>` option (with `--demo-<style>`) captures them.

## 1.5.0 - 2026-10-15

- New **Appearance** setting in the menu: System (default), Light or Dark for the menu and dialogs. The alert overlays are pinned to their dark look and are unchanged in every mode.
