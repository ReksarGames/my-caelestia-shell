import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property string currentTimezone: "Europe/Stockholm"
    property string requestedTimezone: ""

    property Process timezoneReader: Process {
        id: timezoneReader

        running: true
        command: ["timedatectl", "show", "--property=Timezone", "--value"]
        stdout: StdioCollector {
            onStreamFinished: {
                const timezone = text.trim();
                if (timezone.length > 0)
                    root.currentTimezone = timezone;
            }
        }
    }

    property Process timezoneSetter: Process {
        id: timezoneSetter

        onExited: exitCode => {
            if (exitCode === 0)
                root.currentTimezone = root.requestedTimezone;
        }
    }

    // Temperature units (there must be one for each value of the TemperatureUnit enum)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: TemperatureUnit.Auto
        },
        MenuItem {
            text: Tr.tr("°C")
            value: TemperatureUnit.Celsius
        },
        MenuItem {
            text: Tr.tr("°F")
            value: TemperatureUnit.Fahrenheit
        },
        MenuItem {
            text: Tr.tr("K")
            value: TemperatureUnit.Kelvin
        }
    ]

    // Data size units (there must be one for each value of the DataUnit enum)
    readonly property list<MenuItem> dataItems: [
        MenuItem {
            text: Tr.tr("Binary (KiB, MiB)")
            value: DataUnit.Binary
        },
        MenuItem {
            text: Tr.tr("Decimal (KB, MB)")
            value: DataUnit.Decimal
        }
    ]

    // Clock formats (there must be one for each value of the ClockFormat enum)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: ClockFormat.Auto
        },
        MenuItem {
            text: Tr.tr("12-hour")
            value: ClockFormat.TwelveHour
        },
        MenuItem {
            text: Tr.tr("24-hour")
            value: ClockFormat.TwentyFourHour
        }
    ]

    readonly property list<MenuItem> timezoneItems: [
        MenuItem {
            text: Tr.tr("Stockholm")
        },
        MenuItem {
            text: Tr.tr("Kyiv")
        }
    ]
    readonly property list<string> timezoneValues: ["Europe/Stockholm", "Europe/Kyiv"]

    function timezoneIndex(): int {
        const index = timezoneValues.indexOf(currentTimezone);
        return index < 0 ? 0 : index;
    }

    function setTimezone(index: int): void {
        requestedTimezone = timezoneValues[index];
        timezoneSetter.command = ["pkexec", "timedatectl", "set-timezone", requestedTimezone];
        timezoneSetter.running = true;
    }

    title: Tr.tr("Language & region")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: Tr.tr("Language")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("UI language")
            subtext: Tr.tr("The language used in the shell UI")
            active: menuItems.find(i => i.modelData === Tr.language) ?? autoLang
            onSelected: item => {
                Tr.language = item.modelData ?? ""; // qmllint disable missing-property
            }

            menuItems: [autoLang, ...langItems.instances]

            MenuItem {
                id: autoLang

                text: Tr.tr("Auto")
            }

            Variants {
                id: langItems

                model: Tr.supportedLanguages

                MenuItem {
                    required property string modelData

                    text: {
                        const locale = Qt.locale(modelData);
                        return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                    }
                }
            }
        }

        // Weather
        SectionHeader {
            text: Tr.tr("Weather")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("City or coordinates")
            subtext: Tr.tr("Enter a city in Latin letters, or choose a point below")
            value: GlobalConfig.services.weatherLocation
            placeholderText: Tr.tr("Location")
            onEditingFinished: value => {
                const location = value.trim();
                if (GlobalConfig.services.weatherLocation === location)
                    Weather.reload();
                else
                    GlobalConfig.services.weatherLocation = location;
            }
        }

        WeatherMap {
            location: Weather.loc
            city: Weather.city
            onLocationSelected: location => GlobalConfig.services.weatherLocation = location
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.largeIncreased
            visible: Weather.locationError.length > 0
            text: Weather.locationError
            color: Colours.palette.m3error
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        // Units
        SectionHeader {
            text: Tr.tr("Units")
        }

        SelectRow {
            first: true
            label: Tr.tr("Temperature")
            subtext: Tr.tr("Units for weather temperatures")
            menuItems: root.tempItems
            active: root.tempItems.find(i => i.value === GlobalConfig.services.weatherUnits)
            onSelected: item => GlobalConfig.services.weatherUnits = item.value
        }

        SelectRow {
            label: Tr.tr("System temperatures")
            subtext: Tr.tr("Units for CPU and GPU temperatures")
            menuItems: root.tempItems
            active: root.tempItems.find(i => i.value === GlobalConfig.services.sensorUnits)
            onSelected: item => GlobalConfig.services.sensorUnits = item.value
        }

        SelectRow {
            last: true
            label: Tr.tr("Data sizes")
            subtext: Tr.tr("Units for data sizes and network speeds")
            menuItems: root.dataItems
            active: root.dataItems.find(i => i.value === GlobalConfig.services.dataUnits)
            onSelected: item => GlobalConfig.services.dataUnits = item.value
        }

        // Time & date
        SectionHeader {
            text: Tr.tr("Time & date")
        }

        SelectRow {
            first: true
            label: Tr.tr("Clock format")
            subtext: Tr.tr("How times are shown across the shell")
            menuItems: root.clockItems
            active: root.clockItems.find(i => i.value === GlobalConfig.services.clockFormat)
            onSelected: item => GlobalConfig.services.clockFormat = item.value
        }

        SelectRow {
            last: true
            label: Tr.tr("Time zone")
            subtext: Tr.tr("Changes the system time zone for all applications")
            menuItems: root.timezoneItems
            active: root.timezoneItems[root.timezoneIndex()]
            onSelected: item => root.setTimezone(root.timezoneItems.indexOf(item))
        }
    }
}
