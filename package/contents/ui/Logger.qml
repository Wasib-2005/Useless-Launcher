// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Lightweight diagnostics logger for Useless Launcher.
//
// Three sinks, by design:
//   1. console.*  — lands in journald with a "uselesslauncher" category, so
//      `journalctl --user -b -g uselesslauncher` always works (KDE-standard).
//   2. an in-memory ring buffer (`entries`) for a live view inside the app.
//   3. a size-capped cache file so the config "About & Help" page — which
//      runs in a different process and can't see the ring buffer — can show
//      recent problems without the user ever touching journalctl.
//
// Lines are base64-encoded before hitting the shell so arbitrary message
// text (quotes, newlines, $…) can never break the append command.
QtObject {
    id: logger

    // live ring buffer (newest last); capped to keep memory flat
    property ListModel entries: ListModel {}
    readonly property int maxEntries: 200

    // ~64 KB of persisted history is plenty for a bug report
    readonly property string logDir: "$HOME/.cache/uselesslauncher"
    readonly property string logFile: logDir + "/diagnostics.log"
    readonly property int maxFileBytes: 65536

    property P5Support.DataSource _io: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: sourceName => disconnectSource(sourceName)
    }

    function _stamp() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")
    }

    function _persist(line) {
        // base64 round-trip keeps any character in the message safe through
        // the shell (the executable engine already runs via /bin/sh); the
        // tail trim afterwards bounds the file size
        const b64 = Qt.btoa(line + "\n")
        _io.connectSource(
            "mkdir -p " + logDir
            + " && printf %s '" + b64 + "' | base64 -d >> " + logFile
            + " && if [ $(wc -c < " + logFile + ") -gt " + maxFileBytes + " ]; then"
            + " tail -c " + maxFileBytes + " " + logFile + " > " + logFile + ".tmp"
            + " && mv " + logFile + ".tmp " + logFile + "; fi")
    }

    function log(level, msg) {
        const text = String(msg)
        const line = _stamp() + "  [" + level + "]  " + text

        entries.append({ level: level, text: text, stamp: _stamp() })
        while (entries.count > maxEntries) {
            entries.remove(0)
        }

        if (level === "WARN" || level === "ERROR") {
            console.warn("uselesslauncher: " + text)
            _persist(line)   // only warnings/errors are worth persisting
        } else {
            console.log("uselesslauncher: " + text)
        }
    }

    function info(msg)  { log("INFO", msg) }
    function warn(msg)  { log("WARN", msg) }
    function error(msg) { log("ERROR", msg) }

    function clearPersisted() {
        _io.connectSource(": > " + logFile + " 2>/dev/null || true")
    }
}
