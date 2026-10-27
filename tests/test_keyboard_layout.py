"""Live Hyprland check: cycles layouts, then restores the original main layout."""
import json
from pathlib import Path
import re
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
PROBE = '''import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services
ShellRoot {
    id: root
    property bool initialized: false
    property var changes: []
    property Connections listener: Connections {
        target: Services.Hypr
        function onKbLayoutFullChanged() {
            const layout = Services.Hypr.kbLayoutFull;
            if (root.initialized) root.changes = [...root.changes, layout];
            if (layout !== "Unknown") root.initialized = true;
        }
    }
    property IpcHandler ipc: IpcHandler {
        target: "keyboard-test"
        function state(): string {
            return JSON.stringify({full: Services.Hypr.kbLayoutFull,
                short: Services.Hypr.kbLayout, changes: root.changes});
        }
    }
}'''


def devices():
    return json.loads(subprocess.check_output(["hyprctl", "-j", "devices"]))["keyboards"]


def switch(device, index):
    subprocess.run(["hyprctl", "switchxkblayout", device, str(index)], check=True,
                   stdout=subprocess.DEVNULL)


def main():
    original = next(k for k in devices() if k["main"])
    command = re.search(r"hl\.dsp\.exec_cmd\(\[\[(.*?)\]\]\)",
                        (ROOT / "extras/local-config/hypr/hyprland/input.lua").read_text())[1]
    with tempfile.NamedTemporaryFile(dir=ROOT, prefix=".keyboard-test-", suffix=".qml") as qml, tempfile.TemporaryFile() as log:
        qml.write(PROBE.encode())
        qml.flush()
        process = subprocess.Popen(["qs", "-p", qml.name], stdout=log, stderr=log)
        try:
            for _ in range(100):
                result = subprocess.run(["qs", "-p", qml.name, "ipc", "call", "keyboard-test", "state"],
                                        capture_output=True, text=True)
                if result.returncode == 0 and json.loads(result.stdout)["full"] != "Unknown":
                    break
                time.sleep(.05)
            else:
                log.seek(0)
                raise AssertionError(log.read().decode())
            # Reproduce a newly connected device whose layout differs from the main one.
            switch("all", 0)
            switch(devices()[0]["name"], 1)
            for expected, full, short in [(2, "Ukrainian", "ua"), (0, "English (US)", "us"), (1, "Russian", "ru")]:
                subprocess.run(command, shell=True, check=True)
                for _ in range(100):
                    result = subprocess.check_output(["qs", "-p", qml.name, "ipc", "call", "keyboard-test", "state"])
                    state = json.loads(result)
                    if state["full"] == full and state["short"] == short:
                        break
                    time.sleep(.05)
                assert state["full"] == full and state["short"] == short, state
                assert "Unknown" not in state["changes"], state
                assert all(k["active_layout_index"] == expected for k in devices())
                print(f"PASS: all keyboards and Caelestia agree on {short} ({full})")
        finally:
            switch("all", original["active_layout_index"])
            process.terminate()
            process.wait(timeout=5)
            subprocess.run(["hyprctl", "reload"], check=True, stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    main()
