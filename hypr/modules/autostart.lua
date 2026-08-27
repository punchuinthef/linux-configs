-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
  hl.exec_cmd("dunst & hyprpaper")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("hyprctl setcursor Moga-Light 24")
end)
