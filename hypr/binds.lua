-- ── Atajos de teclado ────────────────────────
local mod = "SUPER"

-- Lanzadores y aplicaciones
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + T",      hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + R",      hl.dsp.exec_cmd("dms panel launcher toggle"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("wofi --show run"))
hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + M",      hl.dsp.exit())
hl.bind(mod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mod .. " + V",      hl.dsp.window.float({ action = "toggle" }))

-- Foco
hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L",     hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J",     hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Mover ventanas
hl.bind(mod .. " + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Ajustar proporción del maestro
hl.bind(mod .. " + equal",          hl.dsp.layout("mfact 0.05"))
hl.bind(mod .. " + minus",          hl.dsp.layout("mfact -0.05"))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.layout("swapwithmaster"))

-- Espacios de trabajo 1–9
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Navegar entre espacios de trabajo
hl.bind(mod .. " + mouse_down",           hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + mouse_up",             hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + CTRL + SHIFT + right", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + CTRL + SHIFT + left",  hl.dsp.focus({ workspace = "-1" }))

-- Mover ventana con el workspace (y seguirla)
hl.bind(mod .. " + CTRL + right", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mod .. " + CTRL + left",  hl.dsp.window.move({ workspace = "-1" }))

-- Mover/redimensionar ventanas flotantes con el ratón
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Capturas con hyprshot
hl.bind("PRINT",                 hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mod .. " + PRINT",       hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
