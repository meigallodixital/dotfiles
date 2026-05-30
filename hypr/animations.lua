-- ── Animaciones ──────────────────────────────

-- curva bezier personalizada: ligero rebote al abrir ventanas
hl.curve("suave", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "suave" })             -- apertura/cierre de ventanas
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "default", style = "popin 80%" }) -- cierre con efecto pop-in desde 80%
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "default" })           -- fundido de ventanas y capas
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })           -- transición entre espacios de trabajo
