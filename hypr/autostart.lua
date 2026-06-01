-- ── Autoarranque ─────────────────────────────
-- hl.exec_once("waybar")
-- hl.exec_once("dunst")
-- hl.exec_once("nm-applet")

hl.on("hyprland.start", function()
    hl.exec_cmd("env NOCTALIA_CONFIG_DIR=$HOME/.dotfiles/noctalia/machines/$(hostname)/ qs -c noctalia-shell")
end)
