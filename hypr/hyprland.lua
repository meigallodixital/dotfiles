-- ─────────────────────────────────────────────
-- Hyprland — configuración (Lua, API hl 0.55+)
-- ─────────────────────────────────────────────

local cfg   = os.getenv("HOME") .. "/.config/hypr/"
local host  = io.popen("hostname"):read("*l")
local theme = dofile(cfg .. "theme.lua")

-- ── Config general ───────────────────────────
hl.config({
    general = {
        gaps_in     = theme.gaps_in,       -- espacio entre ventanas (px)
        gaps_out    = theme.gaps_out,      -- espacio entre ventanas y borde de pantalla (px)
        border_size = theme.border_size,   -- grosor del borde de ventana (px)
        ["col.active_border"]   = theme.active_border,   -- color borde ventana activa
        ["col.inactive_border"] = theme.inactive_border, -- color borde ventanas inactivas
        layout = "master",                 -- layout por defecto: master-stack
    },

    master = {
        mfact       = 0.65,          -- proporción de pantalla que ocupa la ventana maestra (0-1)
        new_status  = "master",      -- las ventanas nuevas se abren como maestras
        orientation = "left",        -- ventana maestra a la izquierda
    },

    decoration = {
        rounding = theme.rounding,   -- radio de esquinas redondeadas (px)
        blur = {
            enabled = false,         -- desactiva blur de fondo (coste GPU)
        },
    },

    render = {
        xp_mode = true,              -- desactiva back buffer y capa inferior; mejora rendimiento
    },

    animations = {
        enabled = true,              -- activa animaciones globales (curvas en animations.lua)
    },

    input = {
        kb_layout  = "es",           -- distribución de teclado
        kb_options = "eurosign:e",   -- AltGr+e produce €
        follow_mouse = 1,            -- el foco sigue al ratón
        sensitivity  = 0.0,          -- sensibilidad del ratón (0 = sin aceleración)
        touchpad = {
            natural_scroll       = true,  -- scroll natural (igual que macOS/móvil)
            disable_while_typing = true,  -- desactiva táctil al escribir
        },
    },

    misc = {
        force_default_wallpaper = 0,  -- no fuerza el fondo de Hyprland por defecto
        disable_hyprland_logo   = true, -- oculta el logo de Hyprland en el fondo
    },
})

-- ── Variables de entorno ─────────────────────
hl.env("LANG",   "es_ES.UTF-8")
hl.env("LC_ALL", "es_ES.UTF-8")

-- ── Módulos ──────────────────────────────────
dofile(cfg .. "animations.lua")
dofile(cfg .. "autostart.lua")
dofile(cfg .. "binds.lua")
dofile(cfg .. "hosts/" .. host .. ".lua")
