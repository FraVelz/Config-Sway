#!/usr/bin/env bash
set -euo pipefail

# Power menu para Sway (adaptado de tu power-menu.sh)

theme="$HOME/.config/rofi/styles/_core/power-menu.rasi"
bg="$HOME/.config/rofi/images/arch-linux-2.webp"

# Nota: mantenemos `set -euo pipefail`, pero estos datos son "nice to have".
# En algunos sistemas `hostname` puede no existir, o `last` puede fallar si no hay wtmp.
lastlogin="$(
  (last "$USER" 2>/dev/null || true) \
    | head -n1 \
    | tr -s ' ' \
    | cut -d' ' -f5,6,7
)"
uptime="$(
  (uptime -p 2>/dev/null || true) \
    | sed -e 's/^up //g'
)"
if command -v hostname >/dev/null 2>&1; then
  host="$(hostname)"
else
  host="$(uname -n 2>/dev/null || echo "host")"
fi

lastlogin="${lastlogin:-desconocido}"
uptime="${uptime:-desconocido}"

apagar=' '
reiniciar='󰦛 '
bloquear='󱅞'
suspender='󰽥'
cerrar_seccion='󰍂 '
cancelar=' '

rofi_cmd() {
  local -a args=(
    rofi -dmenu
    -p "$USER@$host"
    -mesg " Desde: $lastlogin, Tiempo encendido: $uptime"
    -theme "${theme}"
  )

  if [ -f "$bg" ]; then
    args+=(-theme-str "inputbar { background-image: url(\"$bg\", width); }")
  fi

  "${args[@]}"
}

run_rofi() {
  echo -e "$cancelar\n$apagar\n$reiniciar\n$suspender\n$cerrar_seccion\n$bloquear" | rofi_cmd
}

lock_now() {
  if command -v swaylock >/dev/null 2>&1; then
    swaylock -f
  elif command -v loginctl >/dev/null 2>&1; then
    loginctl lock-session
  else
    notify-send "Lock" "Instala swaylock o usa loginctl" 2>/dev/null || true
  fi
}

logout_now() {
  if command -v swaymsg >/dev/null 2>&1; then
    swaymsg exit >/dev/null 2>&1 || true
  fi
}

chosen="$(run_rofi)"
case "${chosen}" in
  "$apagar") systemctl poweroff ;;
  "$reiniciar") systemctl reboot ;;
  "$bloquear") lock_now ;;
  "$suspender")
    command -v mpc >/dev/null 2>&1 && mpc -q pause || true
    command -v amixer >/dev/null 2>&1 && amixer set Master mute >/dev/null 2>&1 || true
    systemctl suspend
    ;;
  "$cerrar_seccion") logout_now ;;
  *) exit 0 ;;
esac

# Autor: Fravelz
