// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import Qt.labs.platform as Platform

KCM.SimpleKCM {
    id: aboutRoot

    // Kept in step with metadata.json by hand — bump both on release.
    readonly property string appName: i18n("Useless Launcher")
    readonly property string appVersion: "0.9.2"
    readonly property string appLicense: "GPL-2.0-or-later"
    readonly property string repoUrl: "https://github.com/Wasib-2005/Useless-Launcher"
    readonly property string issuesUrl: "https://github.com/Wasib-2005/Useless-Launcher/issues"

    // the running launcher writes diagnostics here (see Logger.qml); read it
    // back with a plain file read so this page needs no extra QML modules
    readonly property string logUrl:
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.GenericCacheLocation)
        + "/uselesslauncher/diagnostics.log"

    property string diagnosticsText: ""
    property string distroName: i18n("unknown")

    function readFile(url, cb) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // local file reads report status 0 on success
                cb(xhr.status === 0 || xhr.status === 200 ? (xhr.responseText || "") : "")
            }
        }
        try { xhr.open("GET", url); xhr.send() } catch (e) { cb("") }
    }

    function refresh() {
        readFile(logUrl, t => {
            const s = t.trim()
            aboutRoot.diagnosticsText = s.length > 0 ? s : i18n("No problems recorded. 🎉")
        })
        readFile("file:///etc/os-release", t => {
            const m = t.match(/PRETTY_NAME="?([^"\n]+)"?/)
            aboutRoot.distroName = m ? m[1] : i18n("unknown")
        })
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // ---- intro (identity/version/licence live on the built-in About page) ----
        QQC2.Label {
            text: i18n("Need a hand, or found a bug? Start here. Version, authors and licence are on the built-in About page.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            RowLayout {
                Kirigami.FormData.label: i18n("Links:")
                QQC2.Button {
                    text: i18n("Source code")
                    icon.name: "git"
                    onClicked: Qt.openUrlExternally(aboutRoot.repoUrl)
                }
                QQC2.Button {
                    text: i18n("Report a bug")
                    icon.name: "tools-report-bug"
                    onClicked: Qt.openUrlExternally(aboutRoot.issuesUrl)
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ---- diagnostics ----
        Kirigami.Heading {
            text: i18n("Diagnostics")
            level: 3
        }
        QQC2.Label {
            text: i18n("Recent problems the launcher ran into. Attach this to a bug report — it stays on your machine until you share it.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 10

            QQC2.TextArea {
                id: diagView
                readOnly: true
                wrapMode: TextEdit.NoWrap
                font.family: "monospace"
                text: aboutRoot.appName + " " + aboutRoot.appVersion
                    + "\n" + i18n("Distro: %1", aboutRoot.distroName)
                    + "\n\n" + aboutRoot.diagnosticsText
            }
        }

        RowLayout {
            QQC2.Button {
                text: i18n("Copy diagnostics")
                icon.name: "edit-copy"
                onClicked: { diagView.selectAll(); diagView.copy(); diagView.deselect() }
            }
            QQC2.Button {
                text: i18n("Refresh")
                icon.name: "view-refresh"
                onClicked: aboutRoot.refresh()
            }
            QQC2.Button {
                text: i18n("Clear log")
                icon.name: "edit-clear-history"
                onClicked: {
                    // best-effort truncate via a local-file write
                    const xhr = new XMLHttpRequest()
                    try { xhr.open("PUT", aboutRoot.logUrl); xhr.send("") } catch (e) {}
                    aboutRoot.diagnosticsText = i18n("No problems recorded. 🎉")
                }
            }
        }

        QQC2.Label {
            text: i18n("Full logs: journalctl --user -b -g uselesslauncher")
            font.family: "monospace"
            opacity: 0.6
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
        }
    }
}
