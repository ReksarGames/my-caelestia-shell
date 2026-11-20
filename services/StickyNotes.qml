pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Desktop sticky notes + "hide all desktop widgets" toggle, persisted in one JSON file.
Singleton {
    id: root

    property list<var> notes: []
    property bool hidden: false // all desktop widgets (Super+Shift+R)
    property bool enabled: true // sticky notes + add button
    property int buttonSize: 20 // icon point size of the add button
    property string buttonPosition: "bottom-right"
    property real noteOpacity: 0.9 // sticker background opacity (text stays opaque)
    property int buttonX: -1 // dragged position; -1 = use buttonPosition preset
    property int buttonY: -1
    // Desktop areas of the button/notes per screen; the drawers window cuts them out of its input mask
    // so they stay clickable inside the edge swipe strip. Not persisted.
    property var hitRects: ({})
    property bool superHeld // set from Shortcuts.qml (stickySuper global), not persisted
    property bool ready // file read (or absent); saving before this would wipe it
    property bool loadFailed // never overwrite a file we could not parse

    onHiddenChanged: save()
    onEnabledChanged: save()
    onButtonSizeChanged: save()
    onButtonPositionChanged: save()
    onButtonXChanged: save()
    onNoteOpacityChanged: save()
    onButtonYChanged: save()

    function add(text: string, screen: string): void {
        const t = text.trim();
        if (!t)
            return;
        const offset = (notes.length % 6) * 30;
        notes = [...notes, { id: Date.now(), text: t, screen: screen || (Quickshell.screens[0]?.name ?? ""), x: 400 + offset, y: 150 + offset }];
        save();
    }

    function update(id: real, changes: var): void {
        notes = notes.map(n => n.id === id ? Object.assign({}, n, changes) : n);
        save();
    }

    function remove(id: real): void {
        notes = notes.filter(n => n.id !== id);
        save();
    }

    function setHitRect(screen: string, key: string, rect: var): void {
        const forScreen = Object.assign({}, hitRects[screen]);
        if (rect)
            forScreen[key] = rect;
        else if (key in forScreen)
            delete forScreen[key];
        else
            return;
        hitRects = Object.assign({}, hitRects, { [screen]: forScreen });
    }

    function save(): void {
        if (ready && !loadFailed)
            file.setText(JSON.stringify({ hidden, enabled, buttonSize, buttonPosition, buttonX, buttonY, noteOpacity, notes }, null, 2));
    }

    FileView {
        id: file

        path: `${Paths.state}/sticky-notes.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                // Old format was a bare array of notes
                root.notes = Array.isArray(data) ? data : (data.notes ?? []);
                if (!Array.isArray(data)) {
                    root.hidden = !!data.hidden;
                    root.enabled = data.enabled ?? true;
                    root.buttonSize = data.buttonSize ?? 20;
                    root.buttonPosition = data.buttonPosition ?? "bottom-right";
                    root.noteOpacity = data.noteOpacity ?? 0.9;
                    root.buttonX = data.buttonX ?? -1;
                    root.buttonY = data.buttonY ?? -1;
                }
            } catch (e) {
                root.loadFailed = true;
                console.warn("StickyNotes: cannot parse", path, e);
            }
            root.ready = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.ready = true;
            else
                root.loadFailed = true;
        }
    }

    IpcHandler {
        target: "stickyNotes"

        function toggleHidden(): void {
            root.hidden = !root.hidden;
        }

        function add(text: string): void {
            root.add(text, "");
        }
    }
}
