import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Plugins")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            last: true
            icon: "widgets"
            text: "Виджеты"
            subtext: "Часы, напоминалки на рабочем столе"
            onClicked: root.nState.openSubPage(1)
        }
    }
}
