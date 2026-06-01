-- ── NVIDIA ───────────────────────────────────
hl.env("LIBVA_DRIVER_NAME",            "nvidia")  -- backend VA-API para aceleración de vídeo
hl.env("GBM_BACKEND",                  "nvidia-drm") -- backend GBM para Wayland con NVIDIA
hl.env("__GLX_VENDOR_LIBRARY_NAME",    "nvidia")  -- fuerza la librería GLX de NVIDIA (evita conflicto con Mesa)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")    -- Electron usa Wayland nativo si está disponible

hl.config({
    cursor = {
        no_hardware_cursors = 0, -- permite hardware cursors
    },
})
