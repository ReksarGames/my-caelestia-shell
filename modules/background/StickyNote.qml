import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// One draggable note on the desktop. First line = title. Double-click or the pencil opens NoteEditor.
// Move: Super + left-drag. Resize: Super + right-drag. Collapse: chevron (shows only the title).
StyledRect {
    id: root

    required property var modelData
    required property string screenName

    readonly property int minW: 80
    readonly property int minH: 90
    readonly property string title: modelData.text.split("\n")[0]
    readonly property string body: modelData.text.split("\n").slice(1).join("\n").trim()
    readonly property bool collapsed: modelData.collapsed ?? false
    readonly property real savedH: modelData.h ?? 0 // 0 = grow with the text (up to 500px)
    readonly property real autoH: header.height + (body ? Tokens.spacing.small + bodyText.implicitHeight : 0) + Tokens.padding.large * 2

    // Window-like gestures (Hyprland passes Super+click to the desktop when no window is under the cursor;
    // Super state itself comes from StickyNotes.superHeld, since this layer never sees keyboard modifiers):
    //   Super + LMB drag = move, Super + RMB drag = resize from the corner nearest to the cursor.
    property int mode // 0 = idle, 1 = move, 2 = resize
    readonly property bool resizing: mode === 2
    property point gStart
    property real startX
    property real startY
    property real startW
    property real startH
    property bool fromLeft
    property bool fromTop
    property real liveX
    property real liveY
    property real liveW
    property real liveH

    signal editRequested

    function begin(newMode: int, p: point, local: point): void {
        gStart = p;
        startX = liveX = x;
        startY = liveY = y;
        startW = liveW = width;
        startH = liveH = height;
        fromLeft = local.x < width / 2;
        fromTop = local.y < height / 2;
        mode = newMode;
    }

    function track(p: point): void {
        const dx = p.x - gStart.x;
        const dy = p.y - gStart.y;
        const minX = parent?.leftInset ?? 0;
        const minY = parent?.inset ?? 0;
        const maxR = (parent?.width ?? 0) - (parent?.inset ?? 0);
        const maxB = (parent?.height ?? 0) - (parent?.inset ?? 0);
        if (mode === 1) {
            liveX = Math.max(minX, Math.min(startX + dx, maxR - startW));
            liveY = Math.max(minY, Math.min(startY + dy, maxB - startH));
            return;
        }
        if (fromLeft) {
            liveX = Math.max(minX, Math.min(startX + dx, startX + startW - minW));
            liveW = startX + startW - liveX;
        } else {
            liveW = Math.max(minW, Math.min(startW + dx, maxR - startX));
        }
        if (collapsed)
            return; // collapsed height is fixed to the title row
        if (fromTop) {
            liveY = Math.max(minY, Math.min(startY + dy, startY + startH - minH));
            liveH = startY + startH - liveY;
        } else {
            liveH = Math.max(minH, Math.min(startH + dy, maxB - startY));
        }
    }

    function finish(): void {
        const changes = { x: Math.round(liveX), y: Math.round(liveY) };
        if (mode === 2) {
            changes.w = Math.round(liveW);
            if (!collapsed)
                changes.h = Math.round(liveH);
        }
        mode = 0;
        if (changes.x !== modelData.x || changes.y !== modelData.y || changes.w !== undefined)
            StickyNotes.update(modelData.id, changes);
    }

    readonly property var hitRect: visible && (parent?.visible ?? false) ? { x: x, y: y, w: width, h: height } : null
    onHitRectChanged: StickyNotes.setHitRect(screenName, String(modelData.id), hitRect)
    Component.onDestruction: StickyNotes.setHitRect(screenName, String(modelData.id), null)

    // Show on its own screen; if that screen is gone, fall back to the first one
    visible: modelData.screen === screenName || (!Quickshell.screens.some(s => s.name === modelData.screen) && Quickshell.screens[0]?.name === screenName)

    x: mode ? liveX : Math.min(modelData.x, Math.max(0, (parent?.width ?? 0) - width))
    y: mode ? liveY : Math.min(modelData.y, Math.max(0, (parent?.height ?? 0) - height))
    width: resizing ? liveW : (modelData.w ?? 240)
    height: collapsed ? header.height + Tokens.padding.large * 2 : resizing ? liveH : savedH > 0 ? savedH : Math.min(autoH, 500)
    radius: Tokens.rounding.medium
    // Same surface colour as the shell's panels; opacity is set in Nexus → Plugins → Виджеты → Напоминалки
    color: Qt.alpha(Colours.palette.m3surfaceContainer, StickyNotes.noteOpacity)
    clip: true
    rotation: mode ? 0 : -1.5

    Behavior on rotation {
        Anim {}
    }

    MouseArea {
        id: drag

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.mode === 2 ? (root.fromLeft === root.fromTop ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor) : root.mode === 1 ? Qt.ClosedHandCursor : StickyNotes.superHeld ? Qt.OpenHandCursor : Qt.ArrowCursor

        onPressed: event => {
            if (StickyNotes.superHeld) {
                root.begin(event.button === Qt.RightButton ? 2 : 1, mapToItem(root.parent, event.x, event.y), Qt.point(event.x, event.y));
                return;
            }
            if (event.button === Qt.RightButton)
                event.accepted = false;
        }
        onPositionChanged: event => {
            if (root.mode)
                root.track(mapToItem(root.parent, event.x, event.y));
        }
        onReleased: {
            if (root.mode)
                root.finish();
        }
        onCanceled: {
            if (root.mode)
                root.finish();
        }
        onDoubleClicked: {
            if (!StickyNotes.superHeld)
                root.editRequested();
        }
    }

    HoverHandler {
        id: noteHover
    }

    // Long notes scroll with the mouse wheel
    WheelHandler {
        enabled: !root.collapsed
        onWheel: event => bodyFlick.contentY = Math.max(0, Math.min(bodyFlick.contentHeight - bodyFlick.height, bodyFlick.contentY - event.angleDelta.y / 2))
    }

    RowLayout {
        id: header

        x: Tokens.padding.large
        y: Tokens.padding.large
        width: root.width - Tokens.padding.large * 2
        spacing: Tokens.spacing.small

        // When the note is narrow, the title keeps its room and the buttons drop out instead
        // (edit first — double-click still edits — then delete, collapse last). Hover shows them all.
        readonly property real btnW: collapseBtn.implicitWidth + spacing
        readonly property int fitButtons: Math.max(0, Math.min(3, Math.floor((width - pin.implicitWidth - spacing - titleText.implicitWidth) / btnW)))
        readonly property int shownButtons: noteHover.hovered ? 3 : fitButtons

        MaterialIcon {
            id: pin

            text: "push_pin"
            color: Colours.palette.m3primary
        }

        StyledText {
            id: titleText

            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
            color: Colours.palette.m3onSurface
            font.family: Tokens.font.body.large.family
            font.pointSize: Tokens.font.body.large.pointSize
            font.weight: Font.DemiBold
        }

        IconButton {
            id: collapseBtn

            visible: header.shownButtons >= 1
            icon: root.collapsed ? "expand_more" : "expand_less"
            type: IconButton.Text
            inactiveOnColour: Colours.palette.m3onSurface
            onClicked: StickyNotes.update(root.modelData.id, { collapsed: !root.collapsed })
        }

        IconButton {
            visible: header.shownButtons >= 3
            icon: "edit"
            type: IconButton.Text
            inactiveOnColour: Colours.palette.m3onSurface
            onClicked: root.editRequested()
        }

        IconButton {
            visible: header.shownButtons >= 2
            icon: "close"
            type: IconButton.Text
            inactiveOnColour: Colours.palette.m3onSurface
            onClicked: StickyNotes.remove(root.modelData.id)
        }
    }

    Flickable {
        id: bodyFlick

        x: Tokens.padding.large
        y: header.y + header.height + Tokens.spacing.small
        width: root.width - Tokens.padding.large * 2
        height: Math.max(0, root.height - y - Tokens.padding.large)
        visible: !root.collapsed && root.body.length > 0
        interactive: false
        clip: true
        contentHeight: bodyText.implicitHeight

        StyledText {
            id: bodyText

            width: bodyFlick.width
            text: root.body
            wrapMode: Text.Wrap
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.large
        }
    }
}
