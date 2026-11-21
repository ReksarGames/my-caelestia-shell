import json
import os
from pathlib import Path
import runpy
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import wave


HOOK = (Path(__file__).resolve().parents[1] / "extras/local-config/voxtype/transcribe.py")


class DictationTest(unittest.TestCase):
    def test_recording_exists_during_inference_and_is_kept_only_on_failure(self):
        for gpu_timeout, cpu_fails, text in (
            (False, False, "Привет"),
            (True, False, "Привет"),
            (True, True, ""),
            (False, False, ""),
        ):
            with self.subTest(gpu_timeout=gpu_timeout, cpu_fails=cpu_fails, text=text):
                with tempfile.TemporaryDirectory() as directory:
                    runtime = Path(directory)
                    recording = runtime / "input.wav"
                    with wave.open(str(recording), "wb") as wav:
                        wav.setparams((1, 2, 16000, 0, "NONE", "not compressed"))
                        wav.writeframes(struct.pack("<hh", -16384, 8192))
                    output = runtime / "output"
                    argv = [str(HOOK), "--file", str(recording), "--output-file", str(output),
                            "--model", "large-v3-turbo", "--language", "ru"]
                    calls = []

                    def worker(command, *, input, capture_output, env, timeout):
                        calls.append(timeout)
                        (backup,) = (runtime / "voxtype").glob("dictation-*.wav")
                        self.assertEqual(backup.read_bytes(), recording.read_bytes())
                        self.assertEqual(backup.stat().st_mode & 0o777, 0o600)
                        self.assertEqual(struct.unpack("<Iff", input), (2, -0.5, 0.25))
                        if gpu_timeout and len(calls) == 1:
                            raise subprocess.TimeoutExpired(command, timeout)
                        if gpu_timeout:
                            self.assertEqual(env["VK_DRIVER_FILES"], "/dev/null")
                        if cpu_fails:
                            return subprocess.CompletedProcess(command, 1)
                        response = json.dumps({"ok": True, "text": text}).encode()
                        return subprocess.CompletedProcess(command, 0, b"READY\n" + response)

                    with patch.dict(os.environ, XDG_RUNTIME_DIR=directory), patch.object(sys, "argv", argv):
                        main = runpy.run_path(str(HOOK))["main"]
                        with patch.dict(main.__globals__, notify=lambda message: None):
                            with patch("subprocess.run", side_effect=worker):
                                if text:
                                    main()
                                else:
                                    with self.assertRaises(SystemExit):
                                        main()
                    self.assertEqual(calls, [25, 180] if gpu_timeout else [25])
                    backups = list((runtime / "voxtype").glob("dictation-*.wav"))
                    if text:
                        self.assertEqual(backups, [])
                        self.assertEqual(json.loads(output.with_suffix(".json").read_text()),
                                         {"transcription": [{"text": text}]})
                    else:
                        self.assertEqual(len(backups), 1)
                        self.assertFalse(output.with_suffix(".json").exists())


if __name__ == "__main__":
    unittest.main()
