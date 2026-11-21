#!/usr/bin/env python3
"""Voxtype whisper-cli hook with a session-local recording backup."""

import argparse
from array import array
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import wave


def notify(message):
    try:
        subprocess.run(
            ["notify-send", "-a", "Voxtype", "-t", "10000", "Диктовка", message],
            check=False,
            timeout=2,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


def worker_input(path):
    with wave.open(str(path), "rb") as wav:
        if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (1, 2, 16000):
            raise ValueError("Expected a 16 kHz mono PCM16 WAV")
        samples = array("h", wav.readframes(wav.getnframes()))
    if sys.byteorder != "little":
        samples.byteswap()
    floats = array("f", (sample / 32768 for sample in samples))
    if sys.byteorder != "little":
        floats.byteswap()
    return struct.pack("<I", len(floats)) + floats.tobytes()


def transcribe(command, audio, *, cpu=False):
    env = dict(os.environ, GGML_NO_BACKTRACE="1")
    if cpu:
        env["VK_DRIVER_FILES"] = "/dev/null"
    result = subprocess.run(
        command, input=audio, capture_output=True, env=env, timeout=180 if cpu else 25
    )
    result.check_returncode()
    # shortcut: Voxtype 1.1.1's worker protocol, check it when upgrading Voxtype
    ready, _, response = result.stdout.partition(b"\n")
    if ready != b"READY":
        raise ValueError("Whisper worker failed to load the model")
    reply = json.loads(response)
    if not isinstance(reply, dict) or reply.get("ok") is not True:
        raise ValueError("Whisper worker did not finish transcription")
    if not isinstance(reply.get("text"), str):
        raise ValueError("Invalid Whisper worker response")
    return reply["text"].strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=Path, required=True)
    parser.add_argument("--output-file", required=True)
    parser.add_argument("--output-json", action="store_true")
    parser.add_argument("--no-prints", action="store_true")
    parser.add_argument("--model", required=True)
    parser.add_argument("--language")
    parser.add_argument("--threads")
    parser.add_argument("--translate", action="store_true")
    args = parser.parse_args()

    command = [str(Path.home() / ".local/bin/voxtype"), "transcribe-worker", "--model", args.model]
    if args.language:
        command.extend(["--language", args.language])
    if args.threads:
        command.extend(["--threads", args.threads])
    if args.translate:
        command.append("--translate")

    runtime = Path(os.environ["XDG_RUNTIME_DIR"]) / "voxtype"
    runtime.mkdir(mode=0o700, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        dir=runtime, prefix="dictation-", suffix=".wav", delete=False
    ) as backup:
        path = Path(backup.name)
        try:
            with args.file.open("rb") as recording:
                shutil.copyfileobj(recording, backup)
            backup.flush()
        except OSError:
            path.unlink()
            raise

    try:
        audio = worker_input(path)
        try:
            text = transcribe(command, audio)
        except (subprocess.SubprocessError, ValueError):
            notify("Whisper не смог завершить распознавание на GPU. Повторяю на CPU.")
            text = transcribe(command, audio, cpu=True)
        if not text:
            raise ValueError("Whisper did not recognize any speech")
        Path(f"{args.output_file}.json").write_text(
            json.dumps({"transcription": [{"text": text}]}), encoding="utf-8"
        )
    except (EOFError, OSError, subprocess.SubprocessError, ValueError, wave.Error) as error:
        notify(f"Распознавание не завершилось. Аудио сохранено: {path}")
        sys.exit(f"{error}. Recording saved at {path}")
    try:
        path.unlink()
    except OSError:
        notify(f"Не удалось удалить временную запись: {path}")


if __name__ == "__main__":
    main()
