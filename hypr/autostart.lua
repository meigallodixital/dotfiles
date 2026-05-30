-- ── Autoarranque ─────────────────────────────
-- hl.exec_once("waybar")
-- hl.exec_once("dunst")
-- hl.exec_once("nm-applet")

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c noctalia-shell")
end)
