-- ── Autoarranque ─────────────────────────────
-- hl.exec_once("waybar")
-- hl.exec_once("dunst")
-- hl.exec_once("nm-applet")

hl.on("hyprland.start", function()
    hl.exec_cmd("env NOCTALIA_CONFIG_DIR=$HOME/.dotfiles/noctalia/machines/$(hostname)/ qs -c noctalia-shell")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM QT_WAYLAND_DISABLE_WINDOWDECORATION")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-gtk graphical-session.target 2>/dev/null || true")
end)
