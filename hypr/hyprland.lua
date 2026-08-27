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
require("modules.windowandworkspaces")



-----------------------
---- MISCELLANEOUS ----
-----------------------
misc = {
	disable_splash_rendering = true
}


