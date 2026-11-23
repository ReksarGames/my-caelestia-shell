"""Add complete Wallpaper Engine downloads to Caelestia's wallpaper picker."""

import fcntl
import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path


def import_wallpapers(steam, wallpapers, config, data, cache):
    workshop = steam / "workshop/content/431960"
    assets = steam / "common/wallpaper_engine/assets"
    renderer = data / "workshop-renderer"
    if not (workshop.is_dir() and assets.is_dir() and (renderer / "bin/we-layerd").is_file()):
        return

    previews = wallpapers / "Workshop"
    configs = config / "workshop"
    configs.mkdir(parents=True, exist_ok=True)
    previews.mkdir(parents=True, exist_ok=True)
    with (configs / ".import.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        known = {}
        for existing in configs.glob("*.toml"):
            try:
                with existing.open("rb") as config_file:
                    known[tomllib.load(config_file)["renderer"]["source"]] = existing.stem
            except (KeyError, OSError, ValueError):
                continue

        for metadata in sorted(workshop.glob("*/project.json")):
            folder = metadata.parent.resolve()
            if folder.parent != workshop.resolve() or not folder.name.isdecimal():
                continue
            name = known.get(str(folder))
            if name and (previews / f"{name}.jpg").is_file():
                continue
            try:
                item = json.loads(metadata.read_text(encoding="utf-8-sig"))
                kind = str(item.get("type", "")).lower()
                if kind not in {"scene", "video", "web"}:
                    continue
                content = (folder / item["file"]).resolve()
                if kind == "scene" and not content.is_file():
                    content = content.with_suffix(".pkg").resolve()
                preview = (folder / item["preview"]).resolve()
                if not all(p.is_relative_to(folder) and p.is_file() for p in (content, preview)):
                    continue

                if not name:
                    title = re.sub(r"[\x00-\x1f\x7f/\\\u202a-\u202e\u2066-\u2069]", " ", item["title"])
                    name = " ".join(title.split()).encode()[:180].decode("utf-8", "ignore").strip(" .") or folder.name
                    base = name
                    while (configs / f"{name}.toml").exists() or (previews / f"{name}.jpg").exists():
                        name = f"{base} ({folder.name})" if name == base else f"{name}~"
                frame = preview.read_bytes() if kind != "video" else b""
                if not frame.startswith(b"\xff\xd8\xff"):
                    frame = subprocess.check_output([
                        "ffmpeg", "-nostdin", "-v", "error", "-threads", "1",
                        "-i", str(content if kind == "video" else preview), "-frames:v", "1",
                        "-vf", r"scale=w=min(1440\,iw):h=-2", "-threads", "1",
                        "-q:v", "3", "-f", "mjpeg", "-",
                    ], timeout=30)
                if not frame.startswith(b"\xff\xd8\xff"):
                    continue

                (configs / ".wallpaper.tmp").write_text(f'''[general]
backend = "force_layer_shell"
interactive = false

[renderer]
source = {json.dumps(str(folder), ensure_ascii=False)}
assets_path = {json.dumps(str(assets), ensure_ascii=False)}
library_path = {json.dumps(str(renderer / "lib/libwallpaper-engine-renderer.so"), ensure_ascii=False)}
cache_path = {json.dumps(str(cache / "workshop-renderer"), ensure_ascii=False)}
fps = 30
muted = true

[hooks.wallpaper_applied]
command = "/usr/bin/echo"
args = ["caelestia-workshop-ready"]
''')
                (configs / ".wallpaper.tmp").replace(configs / f"{name}.toml")
                (previews / ".wallpaper.tmp").write_bytes(frame)
                (previews / ".wallpaper.tmp").replace(previews / f"{name}.jpg")
            except (KeyError, OSError, TypeError, ValueError, subprocess.SubprocessError) as error:
                print(f"Workshop {folder.name}: {error}", file=sys.stderr)


if __name__ == "__main__":
    import_wallpapers(*map(Path, sys.argv[1:]))
