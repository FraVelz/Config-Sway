#!/usr/bin/env bash
set -euo pipefail

# Theme switcher para Sway usando tu carpeta ~/.config/themes
# Aplica: kitty, waybar (colors/style + genera config-sway), rofi-style (opcional) y wallpaper (swaybg)

TEMAS_DIR="$HOME/.config/themes"
ROFI_THEME="$HOME/.config/rofi/styles/_core/theme-switcher.rasi"
SWAY_WALL_FILE="$HOME/.config/sway/wallpaper"

print_error() {
  notify-send -u critical "Theme Switcher (Sway)" "$1" 2>/dev/null || true
  echo "Error: $1" >&2
}

print_info() {
  notify-send "Theme Switcher (Sway)" "$1" 2>/dev/null || true
}

need() {
  command -v "$1" >/dev/null 2>&1
}

if [ ! -d "$TEMAS_DIR" ]; then
  print_error "No existe: $TEMAS_DIR"
  exit 1
fi

need rofi || { print_error "Falta rofi"; exit 1; }

OPCIONES="$(mktemp)"
trap 'rm -f "$OPCIONES"' EXIT

theme_count=0
for theme_dir in "$TEMAS_DIR"/*; do
  [ -d "$theme_dir" ] || continue
  theme_name="$(basename "$theme_dir")"

  preview=""
  for ext in jpg png webp; do
    if [ -f "$theme_dir/wallpaper.$ext" ]; then
      preview="$theme_dir/wallpaper.$ext"
      break
    fi
  done
  [ -z "$preview" ] && preview="$theme_dir"

  printf '%s\0icon\x1f%s\n' "$theme_name" "$preview" >> "$OPCIONES"
  theme_count=$((theme_count + 1))
done

[ "$theme_count" -eq 0 ] && { print_error "No hay temas en $TEMAS_DIR"; exit 1; }

TEMA="${1:-}"
if [ -z "${TEMA:-}" ]; then
  # Nota: evitamos pipe para que rofi lea siempre bien la entrada
  TEMA="$(rofi -i -dmenu -show-icons -theme "$ROFI_THEME" <"$OPCIONES" 2>/dev/null || true)"
fi
TEMA="$(echo "${TEMA:-}" | xargs)"
[ -z "${TEMA:-}" ] && exit 0

ELEGIDO="$TEMAS_DIR/$TEMA"
[ -d "$ELEGIDO" ] || { print_error "Tema no encontrado: $TEMA"; exit 1; }

# Guardar tema actual (para que otros scripts de rofi puedan leerlo)
printf '%s\n' "$TEMA" > "$TEMAS_DIR/.current"

ts="$(date +%Y%m%d-%H%M%S)"

backup_dir() {
  local path="$1"
  local bak="$path.bak-$ts"
  if [ -e "$path" ] && [ ! -e "$bak" ]; then
    mkdir -p "$(dirname "$bak")"
    cp -a "$path" "$bak" 2>/dev/null || true
  fi
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  cp -a "$src"/. "$dst"/ 2>/dev/null || true
}

if [ -d "$ELEGIDO/kitty" ]; then
  backup_dir "$HOME/.config/kitty"
  copy_dir_contents "$ELEGIDO/kitty" "$HOME/.config/kitty"
fi

if [ -d "$ELEGIDO/waybar" ]; then
  backup_dir "$HOME/.config/waybar"
  mkdir -p "$HOME/.config/waybar"

  [ -f "$ELEGIDO/waybar/colors.css" ] && cp -a "$ELEGIDO/waybar/colors.css" "$HOME/.config/waybar/colors.css" 2>/dev/null || true
  [ -f "$ELEGIDO/waybar/style.css" ] && cp -a "$ELEGIDO/waybar/style.css" "$HOME/.config/waybar/style.css" 2>/dev/null || true

  if [ -f "$ELEGIDO/waybar/config.jsonc" ]; then
    sed \
      -e 's#hyprland/workspaces#sway/workspaces#g' \
      -e 's#hyprland/window#sway/window#g' \
      -e 's#hyprctl dispatcher togglespecialworkspace monitor#kitty -e btop#g' \
      -e 's#~/.config/rofi/wifi/script.sh#bash ~/.config/rofi/wifi.sh#g' \
      -e 's#~/.config/rofi/wifi.sh#bash ~/.config/rofi/wifi.sh#g' \
      "$ELEGIDO/waybar/config.jsonc" > "$HOME/.config/waybar/config-sway.jsonc"
  fi
fi

# Sway (estilo de ventanas)
if [ -f "$ELEGIDO/sway/theme.conf" ]; then
  backup_dir "$HOME/.config/sway/theme.conf"
  mkdir -p "$HOME/.config/sway"
  cp -a "$ELEGIDO/sway/theme.conf" "$HOME/.config/sway/theme.conf" 2>/dev/null || true

  # Rofi: solo cambia la paleta de colores según el tema
  rofi_palette="$HOME/.config/rofi/styles/_core/palette.rasi"
  mkdir -p "$(dirname "$rofi_palette")"

  bg="$(awk '$1=="set" && $2=="$bg"{print $3; exit}' "$ELEGIDO/sway/theme.conf" 2>/dev/null || true)"
  fg="$(awk '$1=="set" && $2=="$fg"{print $3; exit}' "$ELEGIDO/sway/theme.conf" 2>/dev/null || true)"
  active="$(awk '$1=="set" && $2=="$active"{print $3; exit}' "$ELEGIDO/sway/theme.conf" 2>/dev/null || true)"
  inactive="$(awk '$1=="set" && $2=="$inactive"{print $3; exit}' "$ELEGIDO/sway/theme.conf" 2>/dev/null || true)"
  font_line="$(awk '$1=="font"{ $1=""; sub(/^ /,""); print; exit }' "$ELEGIDO/sway/theme.conf" 2>/dev/null || true)"

  bg="${bg:-#1e1e2e}"
  fg="${fg:-#89b3fa}"
  active="${active:-#89b3fa}"
  inactive="${inactive:-#242438}"
  rofi_font="${font_line#pango:}"
  rofi_font="${rofi_font:-JetBrains Mono Nerd Font 14}"

  cat >"$rofi_palette" <<EOF
/* Paleta de colores (auto) - Tema: $TEMA */

* {
    font:                  "$rofi_font";
    background:            $bg;
    background-alt:        $inactive;
    foreground:            $fg;
    selected:              $active;
    active:                $active;
    urgent:                $active;
}
EOF
fi

WALL=""
for ext in jpg png webp; do
  if [ -f "$ELEGIDO/wallpaper.$ext" ]; then
    WALL="$ELEGIDO/wallpaper.$ext"
    break
  fi
done

if [ -z "${WALL:-}" ]; then
  print_error "Este tema no tiene wallpaper.* en la raíz: $ELEGIDO"
else
  mkdir -p "$(dirname "$SWAY_WALL_FILE")"
  printf '%s\n' "$WALL" > "$SWAY_WALL_FILE"
  if need swaybg; then
    killall swaybg 2>/dev/null || true
    swaybg -i "$WALL" -m fill >/dev/null 2>&1 & disown || true
  else
    print_error "Falta swaybg (no se pudo aplicar el wallpaper)"
  fi
fi

if need waybar; then
  killall waybar 2>/dev/null || true
  sleep 0.2
  waybar -c "$HOME/.config/waybar/config-sway.jsonc" >/dev/null 2>&1 & disown || true
fi

need swaymsg && swaymsg reload >/dev/null 2>&1 || true

print_info "Tema aplicado: $TEMA"

# Autor: Fravelz 
