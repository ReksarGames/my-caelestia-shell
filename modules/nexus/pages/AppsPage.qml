pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Apps")

    // Apps opened by the special-workspace hotkeys (Super+D etc.) live in caelestia CLI's cli.json → toggles.
    // CLI built-in defaults (caelestia/subcommands/toggle.py); they must be disabled explicitly to be replaced.
    readonly property var toggleDefaults: ({
            communication: ["discord", "whatsapp"],
            music: ["spotify", "feishin"],
            sysmon: ["btop"],
            todo: ["todoist"]
        })
    property var cliConfig: ({})

    // Narrow the app picker per hotkey by .desktop Categories (plus a name fallback for apps with vague categories)
    function hasCat(app: DesktopEntry, cats: list<string>): bool {
        return cats.some(c => app.categories.includes(c));
    }
    readonly property var toggleFilters: ({
            communication: a => hasCat(a, ["InstantMessaging", "Chat", "Telephony", "VideoConference", "IRCClient", "Email"]),
            music: a => a.categories.includes("Music") || (a.categories.includes("Audio") && a.categories.includes("Player")),
            todo: a => hasCat(a, ["ProjectManagement", "Calendar"]) || /todo|task|notion|obsidian|productiv/i.test(a.name + " " + a.id),
            sysmon: a => (a.categories.includes("System") && a.categories.includes("Monitor")) || /system monitor|btop|htop|resources|mission center/i.test(a.name)
        })

    function toggleStatus(ws: string): string {
        const entries = cliConfig.toggles?.[ws] ?? {};
        const names = [...new Set([...toggleDefaults[ws], ...Object.keys(entries)])].filter(k => entries[k]?.enable ?? toggleDefaults[ws].includes(k));
        return names.map(k => {
            const cmd = entries[k]?.command ?? [];
            return DesktopEntries.byId(cmd[0] === "gtk-launch" ? cmd[1] : k)?.name ?? k;
        }).join(", ") || "Не задано";
    }

    function setToggleApp(ws: string, app: DesktopEntry): void {
        const cfg = cliConfig;
        if (!cfg.toggles)
            cfg.toggles = {};
        const old = cfg.toggles[ws] ?? {};
        const next = {};
        for (const k of [...toggleDefaults[ws], ...Object.keys(old)])
            next[k] = Object.assign({}, old[k], { enable: false });
        next[app.id] = {
            enable: true,
            match: [{ class: app.startupClass || app.id }],
            command: ["gtk-launch", app.id],
            move: true
        };
        cfg.toggles[ws] = next;
        cliFile.setText(JSON.stringify(cfg, null, 2) + "\n");
        cliConfig = Object.assign({}, cfg);
    }

    property FileView cliFile: FileView {
        path: `${Paths.config}/cli.json`
        onLoaded: {
            try {
                root.cliConfig = JSON.parse(text());
            } catch (e) {
                console.warn("AppsPage: cannot parse", path, e); // leave cliConfig empty → rows only show defaults
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Default applications
        SectionHeader {
            first: true
            text: Tr.tr("Default applications")
        }

        DefaultRow {
            first: true
            icon: "terminal"
            label: Tr.trCtx("Terminal", "default app category")
            status: GlobalConfig.general.apps.terminal.join(" ")
            onSelected: app => GlobalConfig.general.apps.terminal = app.command
        }

        DefaultRow {
            icon: "volume_up"
            label: Tr.trCtx("Audio", "default app category")
            status: GlobalConfig.general.apps.audio.join(" ")
            onSelected: app => GlobalConfig.general.apps.audio = app.command
        }

        DefaultRow {
            icon: "play_circle"
            label: Tr.trCtx("Media playback", "default app category")
            status: GlobalConfig.general.apps.playback.join(" ")
            onSelected: app => GlobalConfig.general.apps.playback = app.command
        }

        DefaultRow {
            last: true
            icon: "folder"
            label: Tr.trCtx("File manager", "default app category")
            status: GlobalConfig.general.apps.explorer.join(" ")
            onSelected: app => GlobalConfig.general.apps.explorer = app.command
        }

        // Special-workspace hotkeys
        SectionHeader {
            text: "Горячие клавиши приложений"
        }

        DefaultRow {
            first: true
            icon: "forum"
            label: "Общение · Super+D"
            status: root.toggleStatus("communication")
            appFilter: root.toggleFilters.communication
            onSelected: app => root.setToggleApp("communication", app)
        }

        DefaultRow {
            icon: "music_note"
            label: "Музыка · Super+M"
            status: root.toggleStatus("music")
            appFilter: root.toggleFilters.music
            onSelected: app => root.setToggleApp("music", app)
        }

        DefaultRow {
            icon: "checklist"
            label: "Задачи · Super+R"
            status: root.toggleStatus("todo")
            appFilter: root.toggleFilters.todo
            onSelected: app => root.setToggleApp("todo", app)
        }

        DefaultRow {
            last: true
            icon: "monitor_heart"
            label: "Системный монитор · Ctrl+Shift+Esc"
            status: root.toggleStatus("sysmon")
            appFilter: root.toggleFilters.sysmon
            onSelected: app => root.setToggleApp("sysmon", app)
        }

        // Library
        SectionHeader {
            text: Tr.trCtx("Library", "app library")
        }

        NavRow {
            first: true
            last: true
            icon: "apps"
            text: Tr.tr("All apps")
            subtext: Tr.tr("Browse installed apps, set favourites and hidden")
            onClicked: root.nState.openSubPage(1)
        }
    }

    component DefaultRow: PopupRow {
        id: row

        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - Tokens.padding.large - Tokens.padding.extraExtraLarge

        property var appFilter: null // fn(DesktopEntry) → bool; null = all apps

        signal selected(app: DesktopEntry)

        keepPopupAsChild: {
            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p?.opacity < 1;
        }
        popup.topMovement: Math.max(Tokens.sizes.nexus.minPopupHeight - popupHeight, Tokens.padding.large)

        Loader {
            anchors.centerIn: parent
            active: row.popup.animDriver > 0

            sourceComponent: VerticalFadeListView {
                id: list

                implicitWidth: Tokens.sizes.nexus.popupWidth
                implicitHeight: CUtils.clamp(row.popupHeight, Tokens.sizes.nexus.minPopupHeight, Tokens.sizes.nexus.maxPopupHeight)

                model: {
                    const all = [...DesktopEntries.applications.values];
                    const filtered = row.appFilter ? all.filter(a => row.appFilter(a)) : all;
                    const apps = filtered.length ? filtered : all; // nothing matched → don't leave the picker empty
                    const favourited = new Set(apps.filter(a => Strings.testRegexList(GlobalConfig.launcher.favouriteApps, a.id)));
                    return apps.sort((a, b) => (favourited.has(b) - favourited.has(a)) || a.name.localeCompare(b.name));
                }

                delegate: StateLayer {
                    id: appItem

                    required property DesktopEntry modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: list.contentItem.left
                    anchors.right: list.contentItem.right
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                    radius: Tokens.rounding.small

                    onClicked: {
                        row.popup.open = false;
                        row.selected(modelData);
                    }

                    RowLayout {
                        id: itemLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        IconImage {
                            asynchronous: true
                            implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.8)
                            source: Quickshell.iconPath(appItem.modelData.icon, "image-missing")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: appItem.modelData.name
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text
                                text: (appItem.modelData.comment || appItem.modelData.genericName) ?? ""
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            visible: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appItem.modelData.id)
                            text: "favorite"
                            fill: 1
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }
    }
}
