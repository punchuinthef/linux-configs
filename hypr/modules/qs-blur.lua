-- Liquid Shell background blur

hl.layer_rule({
    name = "liquid-shell-blur",

    match = {
        namespace = "quickshell",
    },

    blur = true,
    ignore_alpha = 0.2,
})
