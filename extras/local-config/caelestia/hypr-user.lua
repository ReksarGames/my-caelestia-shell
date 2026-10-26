-- Local voice dictation: press once to record, again to copy the transcript.
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/voxtype record toggle"))
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/voxtype record cancel"))
