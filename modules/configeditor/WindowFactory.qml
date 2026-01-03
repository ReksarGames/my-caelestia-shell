import "."
import qs.services
import Quickshell
import QtQuick

Item {
    id: root

    // Keep a single config editor window instead of one per screen to avoid duplicate popups.
    property var window: null
    readonly property var defaultScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : undefined

    Component {
        id: windowComponent

        ConfigEditorWindow {}
    }

    Connections {
        target: ConfigEditor

        function onOpen(): void {
            if (!root.window) {
                root.window = windowComponent.createObject(root, { screen: root.defaultScreen });
            }
            root.window.visible = true;
        }

        function onClose(): void {
            if (root.window) {
                root.window.visible = false;
            }
        }
    }
}
