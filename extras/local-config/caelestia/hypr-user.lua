-- Local voice dictation: press once to record, again to copy the transcript.
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/voxtype record toggle"))
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/voxtype record cancel"))

-- Hide/show desktop widgets (clock, visualiser, sticky notes)
hl.bind("SUPER + SHIFT + R", hl.dsp.global("caelestia:desktopWidgets"))

-- Tell the shell when Super is held, so sticky notes can do Super+LMB move / Super+RMB resize
-- (the desktop layer gets no keyboard focus, so it can't see modifiers itself)
hl.bind("SUPER + SUPER_L", hl.dsp.global("caelestia:stickySuper"), { non_consuming = true, transparent = true })
