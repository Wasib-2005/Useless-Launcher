<!--
SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
SPDX-License-Identifier: GPL-2.0-or-later
-->

# Translations

All user-facing strings in Useless Launcher are wrapped in `i18n()` / `i18nc()`,
so they can be extracted and translated without touching code.

## Translation domain

`plasma_applet_io.github.wasib2005.uselesslauncher`

Compiled catalogs are installed by `kpackagetool6` into
`contents/locale/<lang>/LC_MESSAGES/plasma_applet_io.github.wasib2005.uselesslauncher.mo`.

## Workflow

Needs `gettext` and the KDE i18n tools (`extractrc`, `xgettext`). On a KDE
desktop these come with `ki18n`.

```sh
# 1. Extract translatable strings into the .pot template
./Messages.sh

# 2. Start a new language (e.g. French) from the template
msginit --input=po/plasma_applet_io.github.wasib2005.uselesslauncher.pot \
        --locale=fr --output=po/fr.po

# 3. Translate po/fr.po (Lokalize, Poedit, or a text editor)

# 4. Compile + install into the package so Plasma picks it up
msgfmt po/fr.po \
  -o package/contents/locale/fr/LC_MESSAGES/plasma_applet_io.github.wasib2005.uselesslauncher.mo
```

After installing/upgrading the package, log out and back in (or restart
plasmashell) and switch the system language to test.

## Notes

- Keep `%1`, `%2` … placeholders intact and in a natural order for the target
  language — `i18n("%1 — %2", a, b)` lets translators reorder them.
- British spelling is intentional in the source strings (Favourites, Colour).
- When adding a new string, always wrap it in `i18n()` and re-run `Messages.sh`
  so the `.pot` stays current before pushing a release.
