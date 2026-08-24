#!/usr/bin/env bash
# Cierra instancias previas de rofi para evitar "Rofi already running?" / pidfile lock.
# Uso: source desde scripts de menú, o: ~/.config/scripts/rofi-replace.sh && rofi ...
rofi_replace() {
  if pgrep -x rofi >/dev/null 2>&1; then
    pkill -x rofi 2>/dev/null || true
    # Espera corta a que suelte el pidfile
    local i=0
    while pgrep -x rofi >/dev/null 2>&1 && [ "$i" -lt 20 ]; do
      sleep 0.05
      i=$((i + 1))
    done
  fi
  rm -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/rofi.pid" 2>/dev/null || true
}

# Si se ejecuta directamente, solo limpia.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  rofi_replace
fi
