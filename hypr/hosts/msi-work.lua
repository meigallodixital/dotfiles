-- ── Hardware: msi-work ─────────────────────────
-- GPU: NVIDIA
-- Monitores detectados: 2

hl.monitor({
	output = "HDMI-A-1", -- monitor primario
	mode = "preferred", -- usa la resolución preferida del monitor
	position = "0x0", -- origen del layout
	scale = "1.00", -- escala del monitor externo
})

hl.monitor({
	output = "eDP-1", -- portátil secundario
	mode = "preferred", -- usa la resolución preferida del monitor
	position = "-1536x0", -- a la izquierda del HDMI, sin solapar
	scale = "1.25", -- escala del portátil
})

dofile(os.getenv("HOME") .. "/.config/hypr/nvidia.lua")
