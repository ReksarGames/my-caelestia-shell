local vars = require("variables")

hl.config({
    input = {
        kb_layout          = "us,ru,ua",
        kb_options         = "",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
        focus_on_close     = 1,

        touchpad           = {
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})

-- XKB Alt+Shift drops a modifier from Moonlight's Ctrl+Alt+Shift hotkeys.
for _, key in ipairs({ "Shift_L", "Shift_R", "Alt_L", "Alt_R" }) do
    -- Use one absolute index so newly connected devices cannot drift apart.
    hl.bind("ALT + SHIFT + " .. key, hl.dsp.exec_cmd([[hyprctl -j devices | jq -r '.keyboards[] | select(.main) | (.active_layout_index + 1) % (.layout | split(",") | length)' | xargs -r hyprctl switchxkblayout all]]), {
        release = true,
        locked = true,
        non_consuming = true,
        dont_inhibit = true,
    })
end
