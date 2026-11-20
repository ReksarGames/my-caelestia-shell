import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: "Виджеты"
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            last: true
            text: "Скрыть виджеты рабочего стола"
            subtext: "Часы, визуализатор и стикеры · Super+Shift+R"
            checked: StickyNotes.hidden
            onToggled: StickyNotes.hidden = checked
        }

        SectionHeader {
            text: "Виджеты"
        }

        NavRow {
            first: true
            icon: "schedule"
            text: "Часы"
            subtext: Config.background.desktopClock.enabled ? "Включены" : "Выключены"
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            last: true
            icon: "sticky_note_2"
            text: "Напоминалки"
            subtext: !StickyNotes.enabled ? "Выключены" : StickyNotes.notes.length ? `Заметок: ${StickyNotes.notes.length}` : "Нет заметок"
            onClicked: root.nState.openSubPage(3)
        }
    }
}
