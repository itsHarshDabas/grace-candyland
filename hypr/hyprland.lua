-- Grace Candyland: Hyprland defaults (Hyprland 0.55+ reads Lua; 0.57 dropped hyprland.conf).
-- Don't edit this file. Put your own Hyprland settings in ~/.config/grace/hyprland.lua
-- (loaded last, so it wins), and desktop options in ~/.config/grace/desktop.conf.
-- Gaps, rounding, blur, animations and layout below are startup values; the shell
-- re-applies them from desktop.conf.

local shell = "@SHELLDIR@"
local home = os.getenv("HOME") or ""
local grace = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/grace"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Adwaita: a plain, sharp arrow. Pick another theme in ~/.config/grace/hyprland.lua,
-- e.g. hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        -- Hairline edges, never colored outlines.
        col = {
            active_border = "rgba(ffffff24)",
            inactive_border = "rgba(ffffff12)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 12,
        rounding_power = 2.6,
        shadow = {
            enabled = true,
            range = 28,
            render_power = 3,
            offset = "0 10",
            color = "rgba(00000070)",
        },
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            vibrancy = 0.17,
            popups = true,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "rgb(121419)",
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

hl.curve("grace", { type = "bezier", points = { { 0.2, 0.9 }, { 0.25, 1 } } })
hl.curve("graceOut", { type = "bezier", points = { { 0.4, 0 }, { 0.6, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4.5, bezier = "grace", style = "popin 90%" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "graceOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "grace", style = "slidefade 12%" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "grace", style = "fade" })

-- Grace Settings (the shell's only normal window) floats at its own size instead of tiling.
hl.window_rule({ name = "grace-settings-float", match = { class = "org.quickshell" }, float = true })

-- Frosted glass behind the shell's own surfaces; transparent pixels stay unblurred.
hl.layer_rule({ name = "grace-shell-blur", match = { namespace = "grace-(bar|panel|popup|launcher|dock)" }, blur = true, ignore_alpha = 0.4 })

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    -- Some GPU drivers (VMware's 3D, for one) run Hyprland but reject Qt's GPU buffers; the shell then
    -- exits at once, so start it again with software rendering.
    hl.exec_cmd("qs -p " .. shell .. " || LIBGL_ALWAYS_SOFTWARE=1 qs -p " .. shell)
    -- Same driver bug for every app (GTK 4, Qt Quick, kitty...): Hyprland keeps the GPU, apps it starts
    -- from now on draw on the CPU. Only on VMware's vmwgfx, where it was seen.
    hl.exec_cmd("grep -qs DRIVER=vmwgfx /sys/class/drm/card*/device/uevent && hyprctl eval 'hl.env(\"LIBGL_ALWAYS_SOFTWARE\", \"1\")' && dbus-update-activation-environment --systemd LIBGL_ALWAYS_SOFTWARE=1")
    hl.exec_cmd("hyprctl setcursor \"$XCURSOR_THEME\" \"$XCURSOR_SIZE\"")
    hl.exec_cmd("hypridle -c @DATADIR@/hypridle.conf")
    -- Virtual machines often draw the hardware cursor in the wrong place.
    hl.exec_cmd("systemd-detect-virt -q && hyprctl eval 'hl.config({ cursor = { no_hardware_cursors = true } })'")
end)

-- Keys. Super+Space is "Ask Grace" (app search and AI), like Spotlight.
hl.bind("SUPER + SPACE", hl.dsp.global("quickshell:launcher"))
hl.bind("SUPER + N", hl.dsp.global("quickshell:controlcenter"))
hl.bind("SUPER + L", hl.dsp.global("quickshell:lock"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("grace-settings"))
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("grace-launch terminal"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("grace-launch terminal"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("grace-launch files"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.exit())

for key, dir in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = dir }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end
for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd("grace-launch screenshot"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q set 5%-"), { locked = true, repeating = true })

-- Settings → Displays writes monitors.lua; your own hyprland.lua comes last, so it wins.
-- A mistake in either is reported (hyprctl configerrors) without losing the Grace defaults.
for _, name in ipairs({ "monitors.lua", "hyprland.lua" }) do
    local path = grace .. "/" .. name
    local f = io.open(path, "r")
    if f then
        f:close()
        local ok, err = pcall(dofile, path)
        if not ok then
            hl.notification.create({ text = "Grace: " .. tostring(err), timeout = 10000, color = "rgba(ec6271ff)" })
        end
    end
end
