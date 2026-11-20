pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtLocation
import QtPositioning
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property string location
    property string city
    readonly property var selectedCoordinate: {
        const parts = location.split(",");
        return parts.length === 2 && parts.every(part => part.trim())
            ? QtPositioning.coordinate(Number(parts[0]), Number(parts[1]))
            : QtPositioning.coordinate();
    }

    signal locationSelected(location: string)

    function choosePoint(position: point): void {
        if (!map.mapReady)
            return;

        const coordinate = map.toCoordinate(position);
        if (coordinate.isValid)
            locationSelected(`${coordinate.latitude.toFixed(5)},${coordinate.longitude.toFixed(5)}`);
    }

    onSelectedCoordinateChanged: {
        if (map && selectedCoordinate.isValid) {
            map.center = selectedCoordinate;
            map.zoomLevel = Math.max(map.zoomLevel, 9);
        }
    }

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2
    last: true

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.city || Tr.tr("Choose a location on the map")
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 280
            clip: true

            Map {
                id: map

                anchors.fill: parent
                activeFocusOnTab: true
                Accessible.role: Accessible.Pane
                Accessible.name: Tr.tr("Weather location map")
                Accessible.description: Tr.tr("Drag to move, scroll to zoom, click to choose. Arrow keys move the map; Enter selects its centre.")

                objectName: "weather-location-map"

                plugin: Plugin {
                    name: "osm"
                    PluginParameter { name: "osm.useragent"; value: `caelestia-shell/${CUtils.version} (+https://github.com/caelestia-dots/shell)` }
                    PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
                    PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
                    PluginParameter { name: "osm.mapping.custom.datacopyright"; value: "© <a href='https://www.openstreetmap.org/copyright'>OpenStreetMap contributors</a>" }
                    PluginParameter { name: "osm.mapping.cache.directory"; value: `${Paths.cache}/weather-map` }
                    PluginParameter { name: "osm.mapping.prefetching_style"; value: "NoPrefetching" }
                }
                activeMapType: supportedMapTypes[supportedMapTypes.length - 1]
                center: root.selectedCoordinate.isValid ? root.selectedCoordinate : QtPositioning.coordinate(30, 0)
                zoomLevel: root.selectedCoordinate.isValid ? 9 : 2
                onCopyrightLinkActivated: link => Qt.openUrlExternally(link)

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        map.forceActiveFocus();
                        root.choosePoint(point.position);
                    }
                }

                MapQuickItem {
                    visible: root.selectedCoordinate.isValid
                    coordinate: root.selectedCoordinate
                    anchorPoint.x: marker.width / 2
                    anchorPoint.y: marker.height
                    sourceItem: MaterialIcon {
                        id: marker

                        text: "location_on"
                        color: Colours.palette.m3primary
                        style: Text.Outline
                        styleColor: Colours.palette.m3surface
                        fontStyle: Tokens.font.icon.extraLarge
                        fill: 1
                    }
                }

                DragHandler {
                    target: null
                    onTranslationChanged: delta => map.pan(-delta.x, -delta.y)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const coordinate = map.toCoordinate(point.position);
                        map.zoomLevel = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, map.zoomLevel + event.angleDelta.y / 120));
                        map.alignCoordinateToPoint(coordinate, point.position);
                        event.accepted = true;
                    }
                }

                PinchHandler {
                    target: null
                    property var startCoordinate
                    onActiveChanged: if (active) startCoordinate = map.toCoordinate(centroid.position, false)
                    onScaleChanged: delta => {
                        map.zoomLevel = Math.max(map.minimumZoomLevel, Math.min(map.maximumZoomLevel, map.zoomLevel + Math.log2(delta)));
                        map.alignCoordinateToPoint(startCoordinate, centroid.position);
                    }
                    grabPermissions: PointerHandler.TakeOverForbidden
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Left: map.pan(-80, 0); break;
                    case Qt.Key_Right: map.pan(80, 0); break;
                    case Qt.Key_Up: map.pan(0, -80); break;
                    case Qt.Key_Down: map.pan(0, 80); break;
                    case Qt.Key_Plus:
                    case Qt.Key_Equal: map.zoomLevel = Math.min(map.maximumZoomLevel, map.zoomLevel + 1); break;
                    case Qt.Key_Minus: map.zoomLevel = Math.max(map.minimumZoomLevel, map.zoomLevel - 1); break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space: root.choosePoint(Qt.point(map.width / 2, map.height / 2)); break;
                    default: event.accepted = false; return;
                    }
                    event.accepted = true;
                }
            }

            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                IconButton {
                    icon: "add"
                    Accessible.role: Accessible.Button
                    Accessible.name: Tr.tr("Zoom in")
                    disabled: map.zoomLevel >= map.maximumZoomLevel
                    onClicked: map.zoomLevel = Math.min(map.maximumZoomLevel, map.zoomLevel + 1)
                }

                IconButton {
                    icon: "remove"
                    Accessible.role: Accessible.Button
                    Accessible.name: Tr.tr("Zoom out")
                    disabled: map.zoomLevel <= map.minimumZoomLevel
                    onClicked: map.zoomLevel = Math.max(map.minimumZoomLevel, map.zoomLevel - 1)
                }
            }

            StyledText {
                anchors.centerIn: parent
                width: parent.width - Tokens.padding.large * 2
                visible: map.error !== Map.NoError
                text: Tr.tr("Unable to load map. Check your connection.")
                color: Colours.palette.m3error
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Drag to move · Scroll or +/− to zoom · Click to choose\nClear the field to detect your location by IP")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
