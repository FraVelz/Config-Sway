#!/usr/bin/env bash
set -euo pipefail

# Autostart de apps en Sway (equivalente a autostart.sh de Hyprland)
# Requiere: swaymsg

sleep 2

if ! command -v swaymsg >/dev/null 2>&1; then
  notify-send "Autostart (Sway)" "swaymsg no disponible" 2>/dev/null || true
  exit 0
fi

# Firefox en workspace 1
swaymsg 'workspace number 1; exec firefox' >/dev/null 2>&1 || true
sleep 1

# VSCode en workspace 2
swaymsg 'workspace number 2; exec code' >/dev/null 2>&1 || true
sleep 1

# Kitty en workspace 3
swaymsg 'workspace number 3; exec kitty' >/dev/null 2>&1 || true

