import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> positions: [
        MenuItem { text: "Сверху слева"; value: "top-left" },
        MenuItem { text: "Сверху по центру"; value: "top-center" },
        MenuItem { text: "Сверху справа"; value: "top-right" },
        MenuItem { text: "По центру слева"; value: "middle-left" },
        MenuItem { text: "По центру"; value: "middle-center" },
        MenuItem { text: "По центру справа"; value: "middle-right" },
        MenuItem { text: "Снизу слева"; value: "bottom-left" },
        MenuItem { text: "Снизу по центру"; value: "bottom-center" },
        MenuItem { text: "Снизу справа"; value: "bottom-right" }
    ]

    title: "Часы"
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: "Показывать часы"
            subtext: "Часы на рабочем столе"
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SelectRow {
            label: "Положение"
            subtext: "Где на экране стоят часы"
            menuItems: root.positions
            active: root.positions.find(i => i.value === Config.background.desktopClock.position) ?? null
            onSelected: item => GlobalConfig.background.desktopClock.position = item.value
        }

        ToggleRow {
            text: "Подложка"
            subtext: "Фон за часами"
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        ToggleRow {
            last: true
            text: "Инвертировать цвета"
            checked: Config.background.desktopClock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }
    }
}
