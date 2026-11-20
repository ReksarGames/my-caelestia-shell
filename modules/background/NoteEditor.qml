import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Small window to write or edit a sticky note (desktop layer can't take keyboard focus).
FloatingWindow {
    id: root

    property var note: null // null = new note

    function save(): void {
        if (note) {
            if (input.text.trim())
                StickyNotes.update(note.id, { text: input.text.trim() });
        } else {
            StickyNotes.add(input.text, screen?.name ?? "");
        }
        destroy();
    }

    title: note ? "Редактировать заметку" : "Новая заметка"
    color: Colours.tPalette.m3surface
    surfaceFormat.opaque: false
    implicitWidth: 420
    implicitHeight: 320

    contentItem.Config.screen: screen?.name ?? ""
    contentItem.Tokens.screen: screen?.name ?? ""

    onVisibleChanged: {
        if (!visible)
            destroy();
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.destroy()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainer

            Flickable {
                id: flick

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                clip: true
                contentHeight: input.height
                boundsBehavior: Flickable.StopAtBounds

                T.TextArea {
                    id: input

                    width: flick.width
                    // Templates.TextArea has no implicit size: without this only part of the first line was visible
                    implicitHeight: Math.max(contentHeight + topPadding + bottomPadding, flick.height)
                    topPadding: Tokens.padding.small
                    bottomPadding: Tokens.padding.small
                    renderType: TextEdit.NativeRendering
                    focus: true
                    text: root.note?.text ?? ""
                    placeholderText: "Что нужно не забыть?"
                    placeholderTextColor: Colours.palette.m3outline
                    wrapMode: TextEdit.Wrap
                    color: Colours.palette.m3onSurface
                    selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                    selectedTextColor: Colours.palette.m3onSurface
                    font: Tokens.font.body.large
                    Component.onCompleted: forceActiveFocus()
                    // Explicit newline handling: plain/Shift+Enter = new paragraph, Ctrl+Enter = save
                    Keys.onPressed: event => {
                        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
                            return;
                        if (event.modifiers & Qt.ControlModifier)
                            root.save();
                        else
                            input.insert(input.cursorPosition, "\n");
                        event.accepted = true;
                    }
                    onCursorRectangleChanged: {
                        if (cursorRectangle.y < flick.contentY)
                            flick.contentY = cursorRectangle.y;
                        else if (cursorRectangle.y + cursorRectangle.height > flick.contentY + flick.height)
                            flick.contentY = cursorRectangle.y + cursorRectangle.height - flick.height;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: "Ctrl+Enter — сохранить, Esc — отмена"
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            TextButton {
                text: "Отмена"
                type: TextButton.Text
                onClicked: root.destroy()
            }

            TextButton {
                text: root.note ? "Сохранить" : "Прикрепить"
                onClicked: root.save()
            }
        }
    }
}
