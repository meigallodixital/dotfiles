-- ── Hardware: f5700x ─────────────────────────
-- GPU: NVIDIA
-- Monitores detectados: 1

hl.monitor({
    output   = "",          -- "" aplica a todos los monitores conectados
    mode     = "preferred", -- usa la resolución preferida del monitor
    position = "auto",      -- posición automática
    scale    = "auto",      -- escala automática según DPI
})

dofile(os.getenv("HOME") .. "/.config/hypr/nvidia.lua")
