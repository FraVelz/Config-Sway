#!/usr/bin/env bash
# Menú Rofi para elegir teclado/idioma (fcitx5 + XKB).
set -euo pipefail

# Resolver symlink (~/.local/bin/teclado-rofi → ~/.config/scripts/...).
# Si no, SCRIPT_DIR queda en ~/.local/bin y exec teclado-idioma.sh falla en silencio.
SELF="$(readlink -f -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
SWITCH="$SCRIPT_DIR/teclado-idioma.sh"
if [ ! -x "$SWITCH" ]; then
  SWITCH="$HOME/.config/scripts/teclado-idioma.sh"
fi
THEME="${ROFI_THEME:-$HOME/.config/rofi/styles/_core/wallpaper-switcher.rasi}"
[ -f "$THEME" ] || THEME="$HOME/.config/rofi/styles/wallpaper-switcher.rasi"

if [ ! -x "$SWITCH" ]; then
  notify-send "Teclado" "No se encontró teclado-idioma.sh" 2>/dev/null || true
  echo "Error: no está $SWITCH" >&2
  exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
  echo "Error: rofi no está instalado" >&2
  exit 1
fi

# Códigos ASCII estables; el texto es solo visual.
menu() {
  printf '%s\n' \
    "es  Español" \
    "en  English" \
    "zh  中文 Pinyin" \
    "ru  Русский" \
    "ko  한국어 Hangul"
}

rofi_args=(
  -dmenu
  -i
  -no-custom
  -p "Teclado"
  -format s
  -me-select-entry ""
  -me-accept-entry "MousePrimary,Return,KP_Enter"
)
if [ -f "$THEME" ]; then
  rofi_args+=(-theme "$THEME" -theme-str "listview { lines: 5; }")
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

code="${choice%%[[:space:]]*}"
code="${code,,}"

case "$code" in
  es|en|zh|ru|ko) exec "$SWITCH" "$code" ;;
  *)
    # Por si el tema devuelve solo la etiqueta, sin el código.
    case "$choice" in
      *Español*|*Espanol*) exec "$SWITCH" es ;;
      *English*)           exec "$SWITCH" en ;;
      *Pinyin*|*中文*)     exec "$SWITCH" zh ;;
      *Русский*|*Russian*) exec "$SWITCH" ru ;;
      *Hangul*|*한국어*)   exec "$SWITCH" ko ;;
      *)
        notify-send "Teclado" "Opción no reconocida: [$choice]" 2>/dev/null || true
        exit 1
        ;;
    esac
    ;;
esac

# Autor: Fravelz
