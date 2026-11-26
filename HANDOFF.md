<!--
SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
SPDX-License-Identifier: GPL-2.0-or-later
-->

# HANDOFF — builder notes

User-facing installation and usage instructions are in `README.md`.

## Project identity

- Project: Useless Launcher
- GitHub: https://github.com/Wasib-2005/Useless-Launcher
- Package ID: `io.github.wasib2005.uselesslauncher`
- Fork source: [Slick Launcher by Brock](https://codeberg.org/imbrock/slick-launcher)
- Licence: GPL-2.0-or-later
- Contributors: Waslla / Wasib, Brock, and Antigravity (Google DeepMind)

## Architecture & Visual System

- **Future Slick Visual Themes**: Configured via `visualTheme` (0 = Spatial Liquid Glass, 1 = Crystalline HUD, 2 = Cyber-Tech Neo-Minimal, 3 = Classic Adaptive).
- **Future Core Panel Icon**: Panel button mode with responsive orbital arcs (0° idle, 15° hover, 90° open) wired to `root.expanded && !root.closingLauncher`.
- **Cinematic 3-Phase Animation**:
  - Phase 1 (0.00-0.40): Shell background expansion + avatar rise.
  - Phase 2 (0.08-0.68): Top/left ribbons scroll in from behind avatar, search bar rises from bottom.
  - Phase 3 (0.50-1.00): Content area fade-in.
- **HUD Telemetry Strip**: Real-time polling via `hudProbe` querying `/proc/stat` and `/proc/meminfo`.

## Layout

- `package/` — Plasma widget metadata, configuration, and QML interface.
- `assets/` — launcher icon source and rendered sizes.
- `po/`, `Messages.sh` — translation extraction and compilation workflow.

## Deploy and test

For a first local installation:

```sh
kpackagetool6 --type Plasma/Applet --install package
systemctl --user restart plasma-plasmashell
```

For subsequent updates:

```sh
kpackagetool6 --type Plasma/Applet --upgrade package
```

Check QML diagnostics with:

```sh
journalctl --user -b -g uselesslauncher
```

## Release & KDE Store Packaging

1. Update `Version` in `package/metadata.json`.
2. Run the build script to generate the `.plasmoid` package:

   ```sh
   ./build-plasmoid.sh
   ```

   This produces `io.github.wasib2005.uselesslauncher-<version>.plasmoid`.
3. **KDE Store (store.kde.org) Submission**:
   - Go to https://store.kde.org/product/add (or OpenDesktop).
   - Category MUST be: **Plasma 6 Applets** (ensures it appears in Plasma 6's *Get New Widgets*).
   - Under **Files**, upload the generated `.plasmoid` file.
   - Tag the release on GitHub (e.g. `v0.9.2`) to trigger automatic GitHub Release asset upload.

## Known gotchas

- Controls that are siblings or children of `contentArea` may not render in the
  Plasma popup. Put floating controls inside each page's layout instead.
- Keep strings passed to `i18n()` literal so the extraction tools can find
  them. Preserve numbered placeholders such as `%1` when editing translations.
- The built-in Plasma About page cannot be removed; the custom configuration
  category is named **Help & Diagnostics** to distinguish it.
