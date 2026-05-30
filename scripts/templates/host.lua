-- ── Hardware: {{HOSTNAME}} ─────────────────────────
-- GPU: {{GPU_TYPE}}
-- Monitores detectados: {{MONITOR_COUNT}}

hl.monitor({
    output   = "",          -- "" aplica a todos los monitores conectados
    mode     = "preferred", -- usa la resolución preferida del monitor
    position = "auto",      -- posición automática
    scale    = "auto",      -- escala automática según DPI
})

{{GPU_CONFIG}}
