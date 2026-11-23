pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")
    // shortcut: watch the native Steam library here, extend when Workshop content moves to another library.
    readonly property string steamApps: `${Paths.home}/.local/share/Steam/steamapps`
    readonly property string workshopDir: `${Paths.wallsdir}/Workshop`
    readonly property string workshopConfig: {
        const name = isWorkshopWallpaper(actualCurrent) ? actualCurrent.slice(workshopDir.length + 1) : "";
        if (!GlobalConfig.background.wallpaperEnabled || !name.endsWith(".jpg") || name.includes("/"))
            return "";
        return `${Paths.config}/workshop/${name.slice(0, -4)}.toml`;
    }
    readonly property bool workshopPlaying: workshop.ready && workshop.activeConfig === workshopConfig

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    readonly property bool showDesktopPreview: showPreview && !isWorkshopWallpaper(previewPath)
    // Workshop thumbnails are only large enough for the picker.
    readonly property string desktopImage: showDesktopPreview ? previewPath : isWorkshopWallpaper(actualCurrent) ? lastLocalWallpaper : actualCurrent
    property string lastLocalWallpaper: fallback
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    onWorkshopConfigChanged: Qt.callLater(workshop.sync)
    onActualCurrentChanged: {
        if (actualCurrent && !isWorkshopWallpaper(actualCurrent))
            lastLocalWallpaper = actualCurrent;
    }

    function isWorkshopWallpaper(path: string): bool {
        return path.startsWith(`${workshopDir}/`);
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    FileView {
        path: `${root.steamApps}/workshop/appworkshop_431960.acf`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: importTimer.restart()
    }

    Timer {
        id: importTimer

        interval: 1000
        onTriggered: {
            if (workshopImport.running)
                restart();
            else
                workshopImport.running = true;
        }
    }

    Process {
        id: workshopImport

        command: ["python3", Quickshell.shellPath("assets/import-workshop.py"), root.steamApps, Paths.wallsdir, Paths.config, Paths.data, Paths.cache]
        stderr: SplitParser {
            onRead: line => console.warn(line)
        }
    }

    Process {
        id: workshop

        readonly property string rendererDir: `${Paths.data}/workshop-renderer`
        property string activeConfig
        property bool ready
        property bool stopping

        function sync(): void {
            if (activeConfig) {
                if (!stopping && activeConfig !== root.workshopConfig) {
                    stopping = true;
                    running = false;
                }
            } else if (root.workshopConfig) {
                activeConfig = root.workshopConfig;
                running = true;
            }
        }

        command: ["/usr/bin/env", `${rendererDir}/bin/we-layerd`, "run", "--config", activeConfig]
        environment: ({
            WE_CEF_HELPER_PATH: `${rendererDir}/lib/we-cef-helper`,
            WE_CEF_RESOURCES_DIR: `${rendererDir}/lib/cef`,
            WE_CEF_LOCALES_DIR: `${rendererDir}/lib/cef/locales`,
            GST_PLUGIN_PATH_1_0: [`${rendererDir}/lib/gstreamer-1.0`, Quickshell.env("GST_PLUGIN_PATH_1_0")].filter(Boolean).join(":"),
            PATH: `${rendererDir}/lib/we-layerd:${Quickshell.env("PATH")}`
        })

        stdout: SplitParser {
            onRead: line => {
                if (line === "caelestia-workshop-ready")
                    workshop.ready = true;
            }
        }

        stderr: SplitParser {
            onRead: line => {
                if (line.startsWith("Error:") || line.includes(" ERROR "))
                    console.warn(`Workshop: ${line}`);
            }
        }

        onExited: {
            const restart = stopping;
            activeConfig = "";
            ready = false;
            stopping = false;
            if (restart)
                Qt.callLater(sync);
        }
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
