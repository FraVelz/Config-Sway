#!/usr/bin/env bash
# Visor de mapa XKB (paquete tecla). No cambia fcitx5 ni el layout de Sway.
set -euo pipefail

THEME="${ROFI_THEME:-$HOME/.config/rofi/styles/_core/wallpaper-switcher.rasi}"
[ -f "$THEME" ] || THEME="$HOME/.config/rofi/styles/wallpaper-switcher.rasi"

close_tecla() {
  pkill -x tecla 2>/dev/null || true
}

layout_for() {
  case "$1" in
    es) printf '%s\n' latam ;;
    en) printf '%s\n' us ;;
    ru) printf '%s\n' ru ;;
    br) printf '%s\n' br ;;
    zh|ko) printf '%s\n' us ;;
    *) return 1 ;;
  esac
}

open_map() {
  local code="$1"
  local layout
  layout="$(layout_for "$code")" || {
    notify-send "Teclado" "Idioma de mapa desconocido: $code" 2>/dev/null || true
    echo "Error: idioma de mapa desconocido: $code" >&2
    exit 1
  }

  if ! command -v tecla >/dev/null 2>&1; then
    notify-send "Teclado" "Instala el paquete tecla (pacman -S tecla) para ver el mapa" 2>/dev/null || true
    echo "Error: tecla no está instalado" >&2
    exit 1
  fi

  case "$code" in
    zh|ko)
      notify-send "Teclado" "Pinyin/Hangul se componen desde teclas latinas (mapa US). No hay un carácter por tecla." 2>/dev/null || true
      ;;
  esac

  close_tecla
  exec tecla "$layout"
}

parse_choice() {
  local choice="$1"
  local code
  code="${choice%%[[:space:]]*}"
  code="${code,,}"
  case "$code" in
    es|en|zh|ru|ko|br) printf '%s\n' "$code"; return 0 ;;
  esac
  case "$choice" in
    *Español*|*Espanol*) printf '%s\n' es ;;
    *English*)           printf '%s\n' en ;;
    *Pinyin*|*中文*)     printf '%s\n' zh ;;
    *Русский*|*Russian*) printf '%s\n' ru ;;
    *Hangul*|*한국어*)   printf '%s\n' ko ;;
    *Português*|*Portugues*|*Brasil*) printf '%s\n' br ;;
    *) return 1 ;;
  esac
}

if [ "${1:-}" != "" ]; then
  CMD="$(basename -- "$1")"
  case "$CMD" in
    es|en|zh|ru|ko|br) open_map "$CMD" ;;
    *)
      echo "Uso: teclado-mapa.sh [es|en|zh|ru|ko|br]" >&2
      exit 2
      ;;
  esac
fi

if pgrep -x tecla >/dev/null 2>&1; then
  close_tecla
  exit 0
fi

if ! command -v rofi >/dev/null 2>&1; then
  echo "Error: rofi no está instalado" >&2
  exit 1
fi

if ! command -v tecla >/dev/null 2>&1; then
  notify-send "Teclado" "Instala el paquete tecla (pacman -S tecla) para ver el mapa" 2>/dev/null || true
  echo "Error: tecla no está instalado" >&2
  exit 1
fi

menu() {
  printf '%s\n' \
    "es  Español" \
    "en  English" \
    "zh  中文 Pinyin" \
    "ru  Русский" \
    "ko  한국어 Hangul" \
    "br  Português"
}

rofi_args=(
  -dmenu
  -i
  -no-custom
  -p "Mapa"
  -format s
  -me-select-entry ""
  -me-accept-entry "MousePrimary,Return,KP_Enter"
)
if [ -f "$THEME" ]; then
  rofi_args+=(-theme "$THEME" -theme-str "listview { lines: 6; }")
fi

set +e
choice="$(menu | rofi "${rofi_args[@]}")"
rc=$?
set -e
[ "$rc" -eq 0 ] || exit 0
choice="${choice//$'\r'/}"
choice="${choice#"${choice%%[![:space:]]*}"}"
choice="${choice%"${choice##*[![:space:]]}"}"
[ -n "${choice:-}" ] || exit 0

code="$(parse_choice "$choice")" || {
  notify-send "Teclado" "Opción no reconocida: [$choice]" 2>/dev/null || true
  exit 1
}

open_map "$code"

# Autor: Fravelz
