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

## Release

1. Update `Version` in `package/metadata.json`.
2. From the repository root, create a Plasma package containing the contents
   of `package/`:

   ```sh
   cd package
   zip -r ../io.github.wasib2005.uselesslauncher-<version>.plasmoid .
   ```

3. Upload the `.plasmoid` to a GitHub Release for this project.

## Known gotchas

- Controls that are siblings or children of `contentArea` may not render in the
  Plasma popup. Put floating controls inside each page's layout instead.
- Keep strings passed to `i18n()` literal so the extraction tools can find
  them. Preserve numbered placeholders such as `%1` when editing translations.
- The built-in Plasma About page cannot be removed; the custom configuration
  category is named **Help & Diagnostics** to distinguish it.
