#!/usr/bin/env bash
set -euo pipefail

# Layout "hacker" para Sway (adaptación de mode-hacker.sh de Hyprland)
# Crea: izquierda kitty (shell), derecha arriba tty-clock, derecha abajo cava.

sleep 0.3

if ! command -v swaymsg >/dev/null 2>&1; then
  notify-send "Mode hacker (Sway)" "swaymsg no disponible" 2>/dev/null || true
  exit 0
fi

swaymsg 'exec kitty --title x' >/dev/null 2>&1 || true
sleep 0.35

# Crear columna derecha
swaymsg 'split horizontal' >/dev/null 2>&1 || true
swaymsg 'exec kitty --override font_size=12 --title clock -- tty-clock -c -C 4' >/dev/null 2>&1 || true
sleep 0.35

# Dividir derecha en vertical y abrir cava abajo
swaymsg 'split vertical' >/dev/null 2>&1 || true
swaymsg 'exec kitty --title cava -- cava' >/dev/null 2>&1 || true

# Autor: Fravelz
