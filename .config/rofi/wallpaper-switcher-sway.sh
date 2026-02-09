#!/usr/bin/env bash
set -euo pipefail

FONDOS_DIR="$HOME/.config/wallpapers"
THEME_PATH="$HOME/.config/rofi/styles/wallpaper-switcher.rasi"
SWAY_WALL_FILE="$HOME/.config/sway/wallpaper"

if ! command -v rofi >/dev/null 2>&1; then
  echo "Error: rofi no está instalado" >&2
  exit 1
fi

if [ ! -d "$FONDOS_DIR" ]; then
  notify-send "Wallpaper" "No existe: $FONDOS_DIR" 2>/dev/null || true
  exit 0
fi

OPTIONS_FILE="$(mktemp)"
trap 'rm -f "$OPTIONS_FILE"' EXIT

shopt -s nullglob
for img in "$FONDOS_DIR"/*; do
  name="$(basename "$img")"
  printf '%s\0icon\x1f%s\n' "$name" "$img" >> "$OPTIONS_FILE"
done

if [ ! -s "$OPTIONS_FILE" ]; then
  notify-send "Wallpaper" "No se encontraron imágenes en $FONDOS_DIR" 2>/dev/null || true
  exit 0
fi

FONDO="$(cat "$OPTIONS_FILE" | rofi -dmenu -show-icons -p \"> \" -theme "$THEME_PATH" || true)"
[ -z "${FONDO:-}" ] && exit 0

WALL="$FONDOS_DIR/$FONDO"
if [ ! -f "$WALL" ]; then
  notify-send "Wallpaper" "Archivo no encontrado: $WALL" 2>/dev/null || true
  exit 1
fi

mkdir -p "$(dirname "$SWAY_WALL_FILE")"
printf '%s\n' "$WALL" > "$SWAY_WALL_FILE"

if command -v swaybg >/dev/null 2>&1; then
  killall swaybg 2>/dev/null || true
  swaybg -i "$WALL" -m fill >/dev/null 2>&1 & disown || true
fi

notify-send -i "$WALL" "Wallpaper (Sway)" "Cambiado a: $FONDO" 2>/dev/null || true

