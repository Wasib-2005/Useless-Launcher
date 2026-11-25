#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# KDE-standard message extraction for Useless Launcher.
# Produces po/plasma_applet_io.github.wasib2005.uselesslauncher.pot from every i18n()/i18nc()
# call in the QML/JS sources plus the .kcfg config entries.
#
# Run from the project root with the KDE i18n tools installed:
#   (Fedora/Nobara) sudo dnf install gettext ki18n-devel
#   mkdir -p po && ./Messages.sh

$EXTRACTRC $(find . -name '*.kcfg') >> rc.cpp 2>/dev/null
$XGETTEXT $(find . -name '*.qml' -o -name '*.js') rc.cpp \
    -o po/plasma_applet_io.github.wasib2005.uselesslauncher.pot
rm -f rc.cpp
