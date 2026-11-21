import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: "Управление жестами"
    isSubPage: true

    property string loadState
    property string activeState
    property string errorText
    property string bindingsError
    property string hand: "left"
    property var bindings: null
    readonly property string gestureCommand: Quickshell.env("HOME") + "/.local/bin/gesture-caelestia"
    readonly property list<string> serviceCommand: ["systemctl", "--user"]
    readonly property string unit: "gesture-caelestia.service"
    readonly property bool busy: action.running || activeState === "activating" || activeState === "deactivating"

    readonly property list<MenuItem> hands: [
        MenuItem {
            text: "Левая"
            value: "left"
        },
        MenuItem {
            text: "Правая"
            value: "right"
        }
    ]
    readonly property list<MenuItem> actions: [
        MenuItem {
            text: "Не назначено"
            value: "none"
        },
        MenuItem {
            text: "Рабочие столы"
            value: "workspace"
        },
        MenuItem {
            text: "Курсор"
            value: "pointer"
        },
        MenuItem {
            text: "ЛКМ / перетаскивание"
            value: "left"
        },
        MenuItem {
            text: "Правый клик"
            value: "right"
        },
        MenuItem {
            text: "Прокрутка"
            value: "scroll"
        },
        MenuItem {
            text: "Диктовка"
            value: "dictation"
        }
    ]
    readonly property var poses: [
        {
            key: "palm",
            label: "Открытая ладонь"
        },
        {
            key: "index-pinky",
            label: "Указательный + мизинец"
        },
        {
            key: "thumb-index",
            label: "Большой + указательный"
        },
        {
            key: "thumb-ring",
            label: "Большой + безымянный",
            hint: "Указательный и средний прямые"
        },
        {
            key: "v-sign",
            label: "Знак V",
            hint: "Указательный и средний прямые, остальные согнуты"
        },
        {
            key: "thumb-pinky",
            label: "Большой + мизинец",
            hint: "Остальные три пальца прямые"
        }
    ]

    function bind(pose: string, value: string): void {
        if (bindingProcess.running || bindings?.[hand]?.[pose] === value)
            return;
        bindingsError = "";
        bindingProcess.command = [gestureCommand, "bind", hand, pose, value];
        bindingProcess.running = true;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            last: true
            text: "Камера для жестов"
            subtext: root.busy ? "Переключение…" : root.loadState === "loaded" ? (checked ? "Распознавание включено" : "Распознавание выключено") : (root.loadState ? "Служба недоступна" : "Проверка службы…")
            checked: root.activeState === "active"
            disabled: root.loadState !== "loaded" || root.busy
            onToggled: {
                action.command = [...root.serviceCommand, checked ? "start" : "stop", root.unit];
                action.running = true;
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.errorText
            wrapMode: Text.WordWrap
            font: Tokens.font.body.small
        }

        SectionHeader {
            text: "Назначения жестов"
        }

        SelectRow {
            first: true
            last: true
            Layout.bottomMargin: Tokens.spacing.small
            label: "Рука"
            subtext: "Обе руки можно использовать одновременно"
            menuItems: root.hands
            active: root.hands.find(item => item.value === root.hand) ?? null
            onSelected: item => root.hand = item.value
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            Layout.bottomMargin: Tokens.spacing.small
            visible: text.length > 0
            text: root.bindingsError
            wrapMode: Text.WordWrap
            font: Tokens.font.body.small
        }

        Repeater {
            model: root.poses

            SelectRow {
                id: row

                required property int index
                required property var modelData
                readonly property string selectedAction: root.bindings?.[root.hand]?.[modelData.key] ?? ""

                first: index === 0
                last: index === root.poses.length - 1
                enabled: root.bindings !== null && !bindingProcess.running
                menuOnTop: index >= 3
                label: modelData.label
                fallbackText: "—"
                fallbackIcon: ""
                subtext: {
                    if (selectedAction === "workspace")
                        return "Смахни влево для следующего стола, вправо для предыдущего";
                    if (modelData.key === "thumb-index" && selectedAction === "left")
                        return "Тап средним — клик. Удержание — перетаскивание";
                    if (selectedAction === "dictation")
                        return modelData.hint ? modelData.hint + " · Super+Shift+D" : "Super+Shift+D";
                    return modelData.hint ?? "";
                }
                menuItems: root.actions
                active: root.actions.find(item => item.value === row.selectedAction) ?? null
                onSelected: item => root.bind(modelData.key, item.value)
            }
        }

        Timer {
            running: root.visible
            triggeredOnStart: true
            repeat: true
            interval: 1200
            onTriggered: query.running = true
        }

        Process {
            id: query

            command: [...root.serviceCommand, "show", "-p", "LoadState", "-p", "ActiveState", "-p", "StatusText", root.unit]
            stdout: StdioCollector {
                onStreamFinished: {
                    const values = {};
                    for (const line of text.trim().split("\n")) {
                        const i = line.indexOf("=");
                        if (i > 0)
                            values[line.slice(0, i)] = line.slice(i + 1);
                    }
                    root.loadState = values.LoadState ?? "unavailable";
                    root.activeState = values.ActiveState ?? "";
                    root.errorText = root.activeState === "failed" ? (values.StatusText || "Служба остановилась с ошибкой") : "";
                }
            }
        }

        Process {
            id: action

            onExited: (exitCode, exitStatus) => {
                if (exitCode !== 0)
                    root.errorText = "Не удалось переключить службу жестов";
                query.running = true;
            }
        }

        Process {
            id: bindingProcess

            command: [root.gestureCommand, "bindings"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    if (text.trim())
                        root.bindings = JSON.parse(text);
                }
            }

            onExited: exitCode => {
                if (exitCode !== 0)
                    root.bindingsError = "Не удалось загрузить или сохранить назначения жестов";
            }
        }
    }
}
