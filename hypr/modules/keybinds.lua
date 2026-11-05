---------------------
---- MY PROGRAMS ----
---------------------

-- Defined Programs:
local terminal  = "kitty"
local menu      = "rofi -show drun"
local browser   = "zen-browser"
local messenger = "vesktop"
local music    	= "spotify"
local music2    = "elisa"
local games     = "steam"
local files     = "dolphin" 
---------------------
---- KEYBINDINGS ----
---------------------

-- Pre-defined binds
local mainMod = "SUPER"


-- Default Hyprland Keybinds
local closeWindowBind = hl.bind(mainMod .." + C", hl.dsp.window.close()) 
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Opening Apps
hl.bind(mainMod .. "+ Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. "+ R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(messenger))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(music))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(games))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(music2))
hl.bind(mainMod .. "+ D", hl.dsp.exec_cmd(files))
-- Liquid Shell - Wallpaper Changer
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs -c ipc call wallpaper toggle"))

-- Screenshots and Recording
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - |wl-copy'))

-- Opening Clipboard
hl.bind(mainMod .. "+ SHIFT + V", hl.dsp.exec_cmd("copyq toggle"))

-- Switching Workspaces
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    end


-- Special workspaces
--hl.bind(mainMod .. " + SHIFT + S", hl.dsp.workspace.toggle_special("magic"))


-- Moving focus with arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))


-- Scrolling existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Hypremoji
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypremoji/?.lua"
require("hypremoji")
