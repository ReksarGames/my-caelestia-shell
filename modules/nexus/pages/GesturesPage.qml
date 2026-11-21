import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.modules.nexus.common

PageBase {
    id: root

    title: "Управление жестами"
    isSubPage: true

    property string loadState
    property string activeState
    property string errorText
    readonly property list<string> serviceCommand: ["systemctl", "--user"]
    readonly property string unit: "gesture-caelestia.service"
    readonly property bool busy: action.running || activeState === "activating" || activeState === "deactivating"

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
            text: "Жесты"
        }

        InfoRow {
            first: true
            icon: "swipe"
            label: "Рабочие столы"
            subtext: "Открытая ладонь влево → следующий, вправо → предыдущий"
        }

        InfoRow {
            icon: "mouse"
            label: "Курсор"
            subtext: "Соедини указательный палец и мизинец и двигай кистью"
        }

        InfoRow {
            icon: "touch_app"
            label: "Левый клик и перетаскивание"
            subtext: "Большой к указательному. Коснись средним или удерживай"
        }

        InfoRow {
            icon: "ads_click"
            label: "Правый клик"
            subtext: "Большой к безымянному, указательный и средний прямые"
        }

        InfoRow {
            last: true
            icon: "swap_vert"
            label: "Прокрутка"
            subtext: "Разведи указательный и средний и двигай кистью по нужной оси"
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
    }
}
