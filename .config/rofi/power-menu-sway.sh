#!/usr/bin/env bash
set -euo pipefail

# Power menu para Sway (adaptado de tu power-menu.sh)

theme="$HOME/.config/rofi/styles/power-menu.rasi"

lastlogin="$(last "$USER" | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
uptime="$(uptime -p | sed -e 's/up //g')"
host="$(hostname)"

apagar=' '
reiniciar='󰦛 '
bloquear='󱅞'
suspender='󰽥'
cerrar_seccion='󰍂 '
cancelar=' '

rofi_cmd() {
  rofi -dmenu \
    -p "$USER@$host" \
    -mesg " Desde: $lastlogin, Tiempo encendido: $uptime" \
    -theme "${theme}"
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

