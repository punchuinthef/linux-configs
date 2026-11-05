---------------------------------------
---- CUSTOM HYPRLAND CONFIGURATION ----
---------------------------------------

------------------
---- MONITORS ----
------------------
require("modules.monitors")


---------------------
---- KEYBINDINGS ----
---------------------
require("modules.keybinds")


-------------------
---- AUTOSTART ----
-------------------
require("modules.autostart")


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
require("modules.env-var")


-----------------------
----- PERMISSIONS -----
-----------------------
--require("modules.permissions")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Main File
require("modules.lookandfeel")

-- Curves
require("modules.curves")

-- Animations
require("modules.animations")

-- Gaps
--require("modules.gaps")

-- Layouts
require("modules.layout")

-- Quickshell Blur settings
require("modules.qs-blur")

----------------
----  MISC  ----
----------------


---------------
---- INPUT ----
---------------
require("modules.input")


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
require("modules.windowrules")
require("modules.windowandworkspaces")
-----------------------
---- MISCELLANEOUS ----
-----------------------
misc = {
	disable_splash_rendering = true
}


