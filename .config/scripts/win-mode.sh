#!/usr/bin/env bash
# Alterna Windows10-Light ↔ Windows10-Dark solo si el tema actual es Win10.
set -euo pipefail

CURRENT_FILE="${HOME}/.config/themes/.current"
SWITCHER="${HOME}/.config/rofi/scripts/theme-switcher.sh"

DARK="Windows10-Dark"
LIGHT="Windows10-Light"

notify() {
  notify-send "win-mode" "$1" 2>/dev/null || true
}

current="$(tr -d '[:space:]' <"$CURRENT_FILE" 2>/dev/null || true)"

case "$current" in
  "$DARK")
    target="$LIGHT"
    ;;
  "$LIGHT")
    target="$DARK"
    ;;
  *)
    msg="win-mode solo funciona con ${LIGHT}/${DARK} (actual: ${current:-ninguno})"
    echo "Error: $msg" >&2
    notify "$msg"
    exit 1
    ;;
esac

if [ ! -x "$SWITCHER" ] && [ ! -f "$SWITCHER" ]; then
  echo "Error: no existe $SWITCHER" >&2
  exit 1
fi

exec bash "$SWITCHER" "$target"
