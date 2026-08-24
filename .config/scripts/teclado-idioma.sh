#!/usr/bin/env bash
# Cambia el método de entrada SOLO en la ventana activa (fcitx5).
# El teclado físico de Sway se queda siempre en español (latam).
set -euo pipefail

CMD="$(basename -- "${1:-${0##*/}}")"
shift 2>/dev/null || true
QUIET="${TECLADO_QUIET:-0}"

case "$CMD" in
  teclado-es|es|0|español|espanol)
    IM="keyboard-latam"; LABEL="Español" ;;
  teclado-en|en|1|english)
    IM="keyboard-us"; LABEL="English" ;;
  teclado-zh|zh|2|pinyin|cn)
    IM="pinyin"; LABEL="中文 Pinyin" ;;
  teclado-ru|ru|3|русский)
    IM="keyboard-ru"; LABEL="Русский" ;;
  teclado-ko|ko|4|hangul|kr)
    IM="hangul"; LABEL="한국어 Hangul" ;;
  teclado-idioma.sh|teclado-idioma)
    echo "Uso: teclado-idioma.sh es|en|zh|ru|ko" >&2
    exit 2
    ;;
  *)
    [ "$QUIET" = 1 ] || notify-send "Teclado" "Idioma desconocido: $CMD" 2>/dev/null || true
    echo "Idioma desconocido: $CMD" >&2
    exit 2
    ;;
esac

ensure_fcitx5() {
  if command -v fcitx5-remote >/dev/null 2>&1 && fcitx5-remote >/dev/null 2>&1; then
    return 0
  fi
  command -v fcitx5 >/dev/null 2>&1 || return 1
  fcitx5 -d >/dev/null 2>&1 || true
  local i
  for i in $(seq 1 30); do
    fcitx5-remote >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  return 1
}

# Siempre latam a nivel compositor: así Cursor/el resto no se quedan atrapados.
if command -v swaymsg >/dev/null 2>&1; then
  swaymsg "input type:keyboard xkb_layout latam" >/dev/null 2>&1 || true
fi

if ensure_fcitx5; then
  fcitx5-remote -s "$IM" >/dev/null 2>&1 || true
  if [ "$IM" = "keyboard-latam" ]; then
    fcitx5-remote -c >/dev/null 2>&1 || true
  else
    fcitx5-remote -o >/dev/null 2>&1 || true
  fi
fi

[ "$QUIET" = 1 ] || notify-send "Teclado" "$LABEL (esta ventana)" 2>/dev/null || true

# Autor: Fravelz
