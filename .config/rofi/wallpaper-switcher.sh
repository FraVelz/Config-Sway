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
ROFI_ERR="$(mktemp)"
trap 'rm -f "$OPTIONS_FILE" "$ROFI_ERR"' EXIT

shopt -s nullglob
for img in "$FONDOS_DIR"/*; do
  name="$(basename "$img")"
  printf '%s\0icon\x1f%s\n' "$name" "$img" >> "$OPTIONS_FILE"
done

if [ ! -s "$OPTIONS_FILE" ]; then
  notify-send "Wallpaper" "No se encontraron imágenes en $FONDOS_DIR" 2>/dev/null || true
  exit 0
fi

set +e
FONDO="$(rofi -i -dmenu -show-icons -p "> " -theme "$THEME_PATH" <"$OPTIONS_FILE" 2>"$ROFI_ERR")"
rc=$?
set -e

if [ "$rc" -ne 0 ] && [ -s "$ROFI_ERR" ]; then
  err="$(tr -s '\n' ' ' < "$ROFI_ERR" | cut -c1-220)"
  notify-send "Wallpaper" "Rofi error: $err" 2>/dev/null || true
fi

FONDO="${FONDO:-}"
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

# Autor: Fravelz
