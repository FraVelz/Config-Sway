#!/usr/bin/env bash
set -euo pipefail

# Rofi WiFi menu usando NetworkManager (nmcli)
# Requiere: rofi, nmcli, notify-send (opcional)

ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/styles/selector-app.rasi}"

if ! command -v nmcli >/dev/null 2>&1; then
  notify-send "WiFi" "nmcli no está instalado" 2>/dev/null || true
  exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
  echo "Error: rofi no está instalado" >&2
  exit 1
fi

# Asegurar que NM esté levantado
nmcli general status >/dev/null 2>&1 || true

# Activar wifi si está apagado
wifi_state="$(nmcli -t -f WIFI g 2>/dev/null | head -n1 || true)"
if [ "${wifi_state:-}" = "disabled" ]; then
  nmcli radio wifi on >/dev/null 2>&1 || true
fi

connected_ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2; exit}' || true)"

# Listar redes (SSID puede venir vacío en redes ocultas)
mapfile -t lines < <(nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list 2>/dev/null | sed '/^:/d' || true)
if [ "${#lines[@]}" -eq 0 ]; then
  notify-send "WiFi" "No se encontraron redes (¿wifi apagado?)" 2>/dev/null || true
  exit 0
fi

menu=""
for l in "${lines[@]}"; do
  ssid="${l%%:*}"
  rest="${l#*:}"
  sec="${rest%%:*}"
  sig="${rest##*:}"

  [ -z "${ssid:-}" ] && continue

  lock=""
  if [ -z "${sec:-}" ] || [ "${sec:-}" = "--" ]; then
    lock=""
  fi

  marker=""
  if [ -n "${connected_ssid:-}" ] && [ "${ssid}" = "${connected_ssid}" ]; then
    marker="✓ "
  fi

  # Mostrar: ✓ SSID    70%
  menu+="${marker}${ssid}  ${lock}  ${sig}%\n"
done

choice="$(printf "%b" "$menu" | rofi -dmenu -i -p "WiFi" -theme "$ROFI_THEME" || true)"
choice="${choice%%$'\n'*}"
[ -z "${choice:-}" ] && exit 0

# Extraer SSID (primer token; SSID con espacios se corta, así que intentamos reconstruir)
# Como el SSID puede tener espacios, lo tomamos hasta dos espacios dobles antes del icono.
ssid="$(printf "%s" "$choice" | sed -E 's/^✓[[:space:]]+//; s/[[:space:]]{2,}(|)[[:space:]].*$//')"
[ -z "${ssid:-}" ] && exit 0

if [ -n "${connected_ssid:-}" ] && [ "${ssid}" = "${connected_ssid}" ]; then
  notify-send "WiFi" "Ya conectado a: ${ssid}" 2>/dev/null || true
  exit 0
fi

# Intentar conectar sin password primero (red guardada o abierta)
if nmcli dev wifi connect "$ssid" >/dev/null 2>&1; then
  notify-send "WiFi" "Conectado a: ${ssid}" 2>/dev/null || true
  exit 0
fi

pass="$(rofi -dmenu -password -p "Clave de ${ssid}" -theme "$ROFI_THEME" || true)"
[ -z "${pass:-}" ] && exit 0

if nmcli dev wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
  notify-send "WiFi" "Conectado a: ${ssid}" 2>/dev/null || true
else
  notify-send -u critical "WiFi" "No se pudo conectar a: ${ssid}" 2>/dev/null || true
  exit 1
fi

