pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> positions: [
        MenuItem { text: "Сверху слева"; value: "top-left" },
        MenuItem { text: "Сверху по центру"; value: "top-center" },
        MenuItem { text: "Сверху справа"; value: "top-right" },
        MenuItem { text: "По центру слева"; value: "middle-left" },
        MenuItem { text: "По центру справа"; value: "middle-right" },
        MenuItem { text: "Снизу слева"; value: "bottom-left" },
        MenuItem { text: "Снизу по центру"; value: "bottom-center" },
        MenuItem { text: "Снизу справа"; value: "bottom-right" }
    ]

    title: "Напоминалки"
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: "Показывать напоминалки"
            subtext: "Стикеры и кнопка «+» на рабочем столе"
            checked: StickyNotes.enabled
            onToggled: StickyNotes.enabled = checked
        }

        SelectRow {
            label: "Положение кнопки «+»"
            subtext: StickyNotes.buttonX >= 0 ? "Своё (перетащено мышью) — выберите, чтобы сбросить" : "Или просто перетащите кнопку мышью"
            menuItems: root.positions
            active: StickyNotes.buttonX >= 0 ? null : root.positions.find(i => i.value === StickyNotes.buttonPosition) ?? null
            fallbackText: "Своё"
            onSelected: item => {
                StickyNotes.buttonPosition = item.value;
                StickyNotes.buttonX = -1;
                StickyNotes.buttonY = -1;
            }
        }

        SliderRow {
            icon: "opacity"
            label: "Непрозрачность стикеров"
            valueLabel: `${Math.round(StickyNotes.noteOpacity * 100)}%`
            value: StickyNotes.noteOpacity
            onMoved: v => StickyNotes.noteOpacity = Math.round(v * 100) / 100
        }

        StepperRow {
            last: true
            label: "Размер кнопки «+»"
            value: StickyNotes.buttonSize
            from: 12
            to: 64
            stepSize: 2
            onMoved: v => StickyNotes.buttonSize = v
        }

        SectionHeader {
            text: "Заметки"
        }

        ConnectedRect {
            first: true
            last: StickyNotes.notes.length === 0
            Layout.fillWidth: true
            implicitHeight: addRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: addRow

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledTextField {
                    id: newNote

                    Layout.fillWidth: true
                    verticalPadding: Tokens.padding.small
                    placeholderText: "Новая заметка… (Enter — прикрепить)"
                    onAccepted: addNote()

                    function addNote(): void {
                        StickyNotes.add(text, "");
                        clear();
                    }
                }

                TextButton {
                    text: "Прикрепить"
                    onClicked: newNote.addNote()
                }
            }
        }

        Repeater {
            model: StickyNotes.notes

            ConnectedRect {
                id: noteRow

                required property var modelData
                required property int index

                last: index === StickyNotes.notes.length - 1
                Layout.fillWidth: true
                implicitHeight: noteLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: noteLayout

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "push_pin"
                        color: Colours.palette.m3primary
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        verticalPadding: Tokens.padding.small
                        text: noteRow.modelData.text
                        onEditingFinished: {
                            if (text.trim() && text !== noteRow.modelData.text)
                                StickyNotes.update(noteRow.modelData.id, { text: text.trim() });
                        }
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        onClicked: StickyNotes.remove(noteRow.modelData.id)
                    }
                }
            }
        }
    }
}
