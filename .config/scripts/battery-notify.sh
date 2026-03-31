#!/usr/bin/env bash
# Alertas de batería: ≥80% mientras carga, ≤20% mientras descarga.
# Requiere: notify-send (libnotify). Sin batería en sysfs: no hace nada.

set -euo pipefail

readonly HIGH_TH="${BATTERY_NOTIFY_HIGH:-80}"
readonly LOW_TH="${BATTERY_NOTIFY_LOW:-20}"
readonly HIGH_RESET="${BATTERY_NOTIFY_HIGH_RESET:-75}"
readonly LOW_RESET="${BATTERY_NOTIFY_LOW_RESET:-25}"

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_FILE="$STATE_DIR/battery-notify.state"

find_battery_sysfs() {
  local dev t
  for dev in /sys/class/power_supply/*; do
    [ -f "$dev/type" ] || continue
    t="$(cat "$dev/type" 2>/dev/null || true)"
    [ "$t" = "Battery" ] || continue
    echo "$dev"
    return 0
  done
  return 1
}

notify_msg() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "$@"
}

load_state() {
  HIGH_SENT=0
  LOW_SENT=0
  [ -f "$STATE_FILE" ] || return 0
  # shellcheck disable=SC1090
  source "$STATE_FILE" 2>/dev/null || true
  HIGH_SENT="${HIGH_SENT:-0}"
  LOW_SENT="${LOW_SENT:-0}"
}

save_state() {
  mkdir -p "$STATE_DIR"
  {
    echo "HIGH_SENT=$HIGH_SENT"
    echo "LOW_SENT=$LOW_SENT"
  } >"$STATE_FILE.tmp"
  mv -f "$STATE_FILE.tmp" "$STATE_FILE"
}

bat="$(find_battery_sysfs)" || exit 0
cap="$(cat "$bat/capacity" 2>/dev/null || true)"
status="$(cat "$bat/status" 2>/dev/null || true)"
status="${status:-Unknown}"

case "$cap" in
  ''|*[!0-9]*) exit 0 ;;
esac

load_state

# Histéresis: permitir volver a avisar al salir de la zona
if [ "$cap" -lt "$HIGH_RESET" ] || [ "$status" != "Charging" ]; then
  HIGH_SENT=0
fi
if [ "$cap" -gt "$LOW_RESET" ] || [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
  LOW_SENT=0
fi

if [ "$cap" -ge "$HIGH_TH" ] && [ "$status" = "Charging" ] && [ "$HIGH_SENT" -eq 0 ]; then
  notify_msg -u normal "Batería" "Carga al ${cap}% — puedes desenchufar el cargador."
  HIGH_SENT=1
fi

if [ "$cap" -le "$LOW_TH" ] && [ "$status" = "Discharging" ] && [ "$LOW_SENT" -eq 0 ]; then
  notify_msg -u critical "Batería baja" "Queda ${cap}% — enchufa el cargador."
  LOW_SENT=1
fi

save_state

# Autor: Fravelz
