pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Loader {
                id: wallpaper

                asynchronous: true

                anchors.fill: parent
                active: Config.background.wallpaperEnabled

                sourceComponent: Wallpaper {}
            }

            Visualiser {
                anchors.fill: parent
                visible: !StickyNotes.hidden
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        Loader {
            id: clockLoader

            asynchronous: true
            active: Config.background.desktopClock.enabled
            visible: !StickyNotes.hidden

            anchors.margins: Tokens.padding.extraLargeIncreased
            anchors.leftMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

            state: Config.background.desktopClock.position
            states: [
                State {
                    name: "top-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "top-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "top-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "middle-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "middle-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "middle-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "bottom-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "bottom-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "bottom-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }

        Item {
            id: notesLayer

            // Only keep clear of the bar and the border frame; the edge swipe strip is handled by
            // cutting our rects out of the drawers input mask (StickyNotes.hitRects → drawers/Regions.qml)
            readonly property real inset: Config.border.thickness
            readonly property real leftInset: Tokens.sizes.bar.innerWidth + Config.border.thickness

            anchors.fill: parent
            visible: !StickyNotes.hidden && StickyNotes.enabled

            Repeater {
                model: StickyNotes.notes

                StickyNote {
                    screenName: win.modelData.name
                    onEditRequested: noteEditor.createObject(win, { screen: win.modelData, note: modelData })
                }
            }

            IconButton {
                id: addBtn

                readonly property string pos: StickyNotes.buttonPosition
                readonly property real presetX: pos.endsWith("left") ? notesLayer.leftInset + Tokens.padding.large : pos.endsWith("right") ? parent.width - width - notesLayer.inset - Tokens.padding.large : (parent.width - width) / 2
                readonly property real presetY: pos.startsWith("top") ? notesLayer.inset + Tokens.padding.large : pos.startsWith("bottom") ? parent.height - height - notesLayer.inset - Tokens.padding.large : (parent.height - height) / 2
                readonly property real restX: StickyNotes.buttonX >= 0 ? StickyNotes.buttonX : presetX
                readonly property real restY: StickyNotes.buttonY >= 0 ? StickyNotes.buttonY : presetY
                property real dragX
                property real dragY

                function clampX(v: real): real {
                    return Math.max(notesLayer.leftInset, Math.min(v, parent.width - width - notesLayer.inset));
                }
                function clampY(v: real): real {
                    return Math.max(notesLayer.inset, Math.min(v, parent.height - height - notesLayer.inset));
                }

                // Free position (dragged) wins over the preset; target: null keeps x/y bindings intact
                x: clampX(dragHandler.active ? dragX : restX)
                y: clampY(dragHandler.active ? dragY : restY)
                icon: "note_add"
                type: IconButton.Tonal
                isRound: true
                font: Tokens.font.icon.size(StickyNotes.buttonSize).build()
                padding: StickyNotes.buttonSize * 0.6
                onClicked: noteEditor.createObject(win, { screen: win.modelData })

                readonly property var hitRect: notesLayer.visible ? { x: x, y: y, w: width, h: height } : null
                onHitRectChanged: StickyNotes.setHitRect(win.modelData.name, "add", hitRect)
                Component.onDestruction: StickyNotes.setHitRect(win.modelData.name, "add", null)

                DragHandler {
                    id: dragHandler

                    target: null
                    cursorShape: Qt.ClosedHandCursor
                    onActiveChanged: {
                        if (active) {
                            addBtn.dragX = addBtn.x;
                            addBtn.dragY = addBtn.y;
                        } else {
                            StickyNotes.buttonX = Math.round(addBtn.clampX(addBtn.dragX));
                            StickyNotes.buttonY = Math.round(addBtn.clampY(addBtn.dragY));
                        }
                    }
                    onTranslationChanged: {
                        if (active) {
                            addBtn.dragX = addBtn.restX + translation.x;
                            addBtn.dragY = addBtn.restY + translation.y;
                        }
                    }
                }
            }
        }

        Component {
            id: noteEditor

            NoteEditor {}
        }
    }
}
