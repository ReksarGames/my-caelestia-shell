"""Manual Hyprland shortcut replay; sends only Alt/Shift and restores layout state."""
import json
import os
from pathlib import Path
import select
import socket
import subprocess
import sys
import time

def command(*args):
    return subprocess.check_output(args, text=True).strip()

def keyboards():
    return json.loads(command('hyprctl', '-j', 'devices'))['keyboards']


def main():
    from evdev import UInput, ecodes as e

    before = keyboards()
    initial = next(k['active_layout_index'] for k in before if k['main'])
    device_name = 'codex-layout-diagnostic'
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock")
    sock.setblocking(False)
    buffer = b''
    events = []

    def collect(wait=0):
        nonlocal buffer
        if select.select([sock], [], [], wait)[0]:
            while True:
                try:
                    data = sock.recv(65536)
                except BlockingIOError:
                    break
                if not data:
                    raise RuntimeError('Hyprland event socket closed')
                buffer += data
            while b'\n' in buffer:
                line, buffer = buffer.split(b'\n', 1)
                text = line.decode(errors='replace')
                if text.startswith(f'activelayout>>{device_name},'):
                    events.append((time.monotonic(), text.split(',', 1)[1]))

    report = []
    try:
        with UInput({e.EV_KEY: [e.KEY_LEFTALT, e.KEY_LEFTSHIFT, e.KEY_LEFTCTRL]}, name=device_name, phys='codex/layout-diagnostic') as ui:
            for _ in range(30):
                if any(k['name'] == device_name for k in keyboards()):
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError('Diagnostic keyboard not registered')
            command('hyprctl', 'switchxkblayout', 'all', str(initial))
            time.sleep(0.1)
            collect()
            patterns = [
                ('alt-shift_shift-alt', [(e.KEY_LEFTALT,1),(e.KEY_LEFTSHIFT,1),(e.KEY_LEFTSHIFT,0),(e.KEY_LEFTALT,0)]),
                ('alt-shift_alt-shift', [(e.KEY_LEFTALT,1),(e.KEY_LEFTSHIFT,1),(e.KEY_LEFTALT,0),(e.KEY_LEFTSHIFT,0)]),
                ('shift-alt_alt-shift', [(e.KEY_LEFTSHIFT,1),(e.KEY_LEFTALT,1),(e.KEY_LEFTALT,0),(e.KEY_LEFTSHIFT,0)]),
                ('shift-alt_shift-alt', [(e.KEY_LEFTSHIFT,1),(e.KEY_LEFTALT,1),(e.KEY_LEFTSHIFT,0),(e.KEY_LEFTALT,0)]),
            ]
            try:
                for name, keys in patterns:
                    begin = len(events)
                    for _ in range(5):
                        for code, value in keys:
                            ui.write(e.EV_KEY, code, value)
                            ui.syn()
                            collect(0.015)
                        time.sleep(0.04)
                        collect()
                    time.sleep(0.1)
                    collect()
                    count = len(events)-begin
                    report.append({'pattern': name, 'expected': 5, 'switches': count})
            finally:
                for code in (e.KEY_LEFTSHIFT,e.KEY_LEFTALT,e.KEY_LEFTCTRL):
                    ui.write(e.EV_KEY,code,0)
                ui.syn()
                time.sleep(0.15)
            state = next(k for k in keyboards() if k['name'] == device_name)
            assert not state['capsLock'], 'Caps Lock changed during modifier-only test'
    finally:
        sock.close()
        for k in before:
            command('hyprctl', 'switchxkblayout', k['name'], str(k['active_layout_index']))
        after = {k['name']: k for k in keyboards()}
        assert all(after[k['name']]['active_layout_index'] == k['active_layout_index'] and after[k['name']]['capsLock'] == k['capsLock'] for k in before if k['name'] in after), 'Keyboard state was not restored'

    label = sys.argv[1] if len(sys.argv)>1 else 'fixed'
    print(json.dumps({'label': label, 'results': report}, ensure_ascii=False))
    if label != 'original':
        assert all(r['switches'] == r['expected'] for r in report), report


if __name__ == "__main__":
    main()
