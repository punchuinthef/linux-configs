

-- ========================================
-- Kitty
-- ========================================

hl.window_rule({
name	   = "kitty-rules",
match 	   = {class = "kitty"},
animation  = "poppin",
float 	   = true,
center 	   = true

})


-- Kitty Size
hl.window_rule({
name     = "kitty-size",
match	 = {class = "kitty"},
size 	 = {1400, 900},
min_size = {700, 900},
max_size = {2500, 1000}
})

-- Kitty's color
hl.window_rule({
name = "kitty's-color",
match = {class = "kitty"},
border_color = "rgb(7C3AED)"

})


-- ========================================
-- Dolphin
-- ========================================
hl.window_rule({
name         = "dolphin-settings",
match        = {class = "org.kde.dolphin"},
float        = true,
center       = true,
size         = {800, 600},
min_size     = {800, 600},
max_size     = {1600, 1200},
border_color = "rgb(000000)" 
})

-- ========================================
-- Spotify
-- ========================================
hl.window_rule({
name = "spotify-window",
match = {
	class = "Spotify",
},

fullscreen      = false,
float 	        = true,
center          = true, 
rounding        = 20,
xray  		= true,
border_color    = "rgb(FFFFFF)",

size            = {500, 500},
min_size        = {1000, 1000},
max_size        = {2000, 2000},
})


-- ========================================
-- Elisa
-- ========================================
hl.window_rule({
name = "elisa-rules",
match = {class = "org.kde.elisa"},

fullscreen   = false, 
float 	     = true,
center       = true,
rounding     = 20, 
border_color = "rgb(FFFFFF)",

size         = {500, 500},
min_size     = {1000, 1000},
max_size     = {1500, 1500}
})
