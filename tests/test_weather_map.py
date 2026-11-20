"""Run with python3 tests/test_weather_map.py in a desktop session with Qt Location."""
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
INSTALLED = Path.home() / ".config/quickshell/caelestia"
PROBE = '''import QtQuick
import Quickshell
import Caelestia
import "modules/nexus/pages" as Pages

ShellRoot {
    id: root
    property int ticks: 0
    property string selection
    function check(condition: bool, message: string): void {
        if (!condition) {
            console.error("FAIL: " + message);
            Qt.exit(1);
            throw new Error(message);
        }
    }
    FloatingWindow {
        visible: false
        implicitWidth: 720
        implicitHeight: 400
        Pages.WeatherMap {
            id: picker
            anchors.fill: parent
            location: "59.32938,18.06871"
            onLocationSelected: location => root.selection = location
        }
    }
    Timer {
        running: true
        repeat: true
        interval: 100
        onTriggered: {
            const map = CUtils.findChild(picker, "weather-location-map");
            if (!map?.mapReady) {
                root.check(++root.ticks < 100, "map initialization timed out");
                return;
            }
            stop();
            const centre = Qt.point(map.width / 2, map.height / 2);
            root.check(picker.selectedCoordinate.isValid, "configured location is valid");
            picker.choosePoint(centre);
            root.check(root.selection === "59.32938,18.06871", "click selects the displayed coordinate");
            root.selection = "";
            picker.choosePoint(Qt.point(-100, -100));
            root.check(root.selection === "", "click outside map is ignored");
            picker.location = "0,0";
            picker.choosePoint(centre);
            root.check(root.selection.split(",").length === 2 && root.selection.split(",").every(value => Number(value) === 0), "zero latitude and longitude are valid: " + root.selection);
            picker.location = "50.45010,30.52340";
            root.check(Math.abs(map.center.latitude - 50.45010) < .00001, "changing location recentres map");
            picker.choosePoint(centre);
            root.check(root.selection === "50.45010,30.52340", "new selection follows the map centre");
            for (const value of ["", "Kyiv", "91,181", "bad,0", ",", "Infinity,0"] ) {
                picker.location = value;
                root.check(!picker.selectedCoordinate.isValid, "invalid coordinates: " + value);
            }
            console.log("PASS: native map, point selection, bounds, zero coordinates and recentring");
            Qt.quit();
        }
    }
}
'''


def main():
    env = os.environ.copy()
    env["QML_IMPORT_PATH"] = f"{INSTALLED / 'imports'}:{env.get('QML_IMPORT_PATH', '')}"
    with tempfile.TemporaryDirectory(prefix="caelestia-map-test-") as directory:
        probe = Path(directory)
        for name in ["modules", "components", "services", "utils", "assets"]:
            (probe / name).symlink_to(ROOT / name, target_is_directory=True)
        (probe / "shell.qml").write_text(PROBE)
        for variable, name in [("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"), ("XDG_STATE_HOME", "state")]:
            env[variable] = str(probe / name)
        try:
            result = subprocess.run(["qs", "-p", str(probe)], env=env, capture_output=True,
                                    text=True, timeout=20)
            output = result.stdout + result.stderr
            assert result.returncode == 0 and "PASS: native map" in output, output
            print(next(line for line in output.splitlines() if "PASS: native map" in line))
        finally:
            subprocess.run(["qs", "-p", str(probe), "kill"], env=env, capture_output=True)


if __name__ == "__main__":
    main()
