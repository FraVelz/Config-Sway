#!/bin/sh

# Leer wallpaper
W="$(cat ~/.config/sway/wallpaper 2>/dev/null || true)"

# Si existe, cargarlo
if [ -n "$W" ] && [ -f "$W" ]; then
    killall swaybg 2>/dev/null || true
    swaybg -i "$W" -m fill >/dev/null 2>&1 &
# Si no, usar wallpaper alternativo del directorio de wallpapers
elif [ -f ~/.config/wallpapers/arch-linux-logo.webp ]; then
    killall swaybg 2>/dev/null || true
    swaybg -i ~/.config/wallpapers/arch-linux-logo.webp -m fill >/dev/null 2>&1 &
# Si nada, usar color sólido
else
    killall swaybg 2>/dev/null || true
    swaybg -c "#1e1e2e" >/dev/null 2>&1 &
fi
