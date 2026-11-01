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
local function cycle_keyboard_layout()
    for _, keyboard in ipairs(hl.get_devices()) do
        if keyboard.type == "keyboard" and keyboard.main and keyboard.active_layout_index then
            local _, separators = keyboard.layout:gsub(",", "")
            -- Use one absolute index so newly connected devices cannot drift apart.
            hl.exec_cmd("hyprctl switchxkblayout all " .. ((keyboard.active_layout_index + 1) % (separators + 1)))
            return
        end
    end
end

for _, key in ipairs({ "Shift_L", "Shift_R", "Alt_L", "Alt_R" }) do
    hl.bind("ALT + SHIFT + " .. key, cycle_keyboard_layout, {
        locked = true,
        non_consuming = true,
        dont_inhibit = true,
    })
end
