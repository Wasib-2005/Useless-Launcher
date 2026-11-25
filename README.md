<!--
SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
SPDX-License-Identifier: GPL-2.0-or-later
-->

# Useless Launcher

Useless Launcher is an application launcher widget for KDE Plasma 6. It offers
an alternative to the default application menu, with a phone-style home screen:
favourites across the top, navigation tabs at the side, and search at the
bottom.

> **Fork notice:** Useless Launcher is a fork of
> [Slick Launcher by Brock](https://codeberg.org/imbrock/slick-launcher).
> It builds on that project and retains its GPL-2.0-or-later licence.

## Features

- A favourites carousel. Drag to reorder favourites or drop apps onto it to
  pin them.
- Navigation for all apps, recent apps, documents, places, web links, and quick
  actions.
- KRunner-powered search for apps, files, calculations, conversions, spelling,
  definitions, open windows, shell commands, and session actions.
- Quick actions for common system tasks, including a system-update action that
  detects supported package managers or accepts a custom command.
- Custom web links displayed in an icon grid with favicons.
- Keyboard navigation, type-ahead search, and Meta-key activation.
- Customisable layouts, colours, themes, animations, icons, labels, and panel
  button styles.
- **Future Slick Visual Theme Suite**: Choose between Spatial Liquid Glass (translucent glass depths, specular rim lighting), Crystalline HUD (precision sci-fi accents, angular brackets), Cyber-Tech Neo-Minimal (chamfered edges, hairline micro-grids), or Classic Adaptive.
- **Future Core Panel Icon**: Panel button mode with reactive dual orbital arcs (0° horizontal when idle, 15° gentle tilt on hover, 90° vertical rotation on menu open).
- **Cinematic 3-Phase Entrance Animation**: Synchronised choreography featuring avatar rise & backdrop expansion, ribbon and search bar scroll-in, and content fade-in.
- **HUD Telemetry Strip**: Optional real-time CPU & RAM utilisation badges alongside distribution and user identity badges.
- Optional status information while open, including distribution, CPU, and memory, plus drive capacity in Places.

## Requirements

- KDE Plasma 6.0 or newer
- Qt 6 and KDE Frameworks 6
- `kpackagetool6` to install from source

## Install from GitHub

Clone the repository and install the Plasma widget:

```sh
git clone https://github.com/Wasib-2005/Useless-Launcher.git
cd Useless-Launcher
kpackagetool6 --type Plasma/Applet --install package
```

If you already have this widget installed, update it with:

```sh
kpackagetool6 --type Plasma/Applet --upgrade package
```

Reload Plasma Shell to make the widget available. On systems with the
`plasma-plasmashell` user service, run:

```sh
systemctl --user restart plasma-plasmashell
```

Otherwise, log out and back in. Then open the panel or desktop's edit mode,
choose **Add Widgets**, search for **Useless Launcher**, and add it.

This fork uses the package ID `io.github.wasib2005.uselesslauncher`. It installs
under its own identity. Use the `--upgrade` command above for future updates
to Useless Launcher.

## Use and configure

Open the widget to browse apps, favourites, recent apps, documents, places, web
links, and quick actions. Start typing to search. Use the Appearance settings
to customise its layout and visual style, and configure web links or a custom
system-update command there.

Right-click the widget and choose **Configure Useless Launcher…** to open its
settings. The Help & Diagnostics page shows the version, licence, project
links, and recent errors that you can copy when reporting a problem.

## Troubleshooting

Check **Help & Diagnostics** for recent errors. The full launcher log can be
viewed with:

```sh
journalctl --user -b -g uselesslauncher
```

## Translations

User-facing strings use `i18n()`. See [`po/README.md`](po/README.md) for
instructions on extracting and translating strings.

## Credits and licence

Useless Launcher is based on [Slick Launcher by Brock](https://codeberg.org/imbrock/slick-launcher).
The original project and its contributors retain their respective copyrights.
This fork is distributed under the GPL-2.0-or-later licence; see [`LICENSE`](LICENSE).

### Contributors & Enhancements
- **Waslla / Wasib**: Project maintainer, UX architecture, and Future Slick design direction.
- **Antigravity (Google DeepMind)**: Implementation of the Future Slick design suite (Spatial Liquid Glass, Crystalline HUD, Cyber-Tech Neo-Minimal), Future Core orbital arc mechanics, 3-phase cinematic entrance choreography, and real-time CPU/RAM HUD telemetry.
