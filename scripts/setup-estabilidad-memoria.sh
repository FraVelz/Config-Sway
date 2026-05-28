#!/usr/bin/env bash
# Aplica el plan de estabilidad de memoria (Fase 1 y opcionalmente Fase 2).
# Requiere root (sudo). Ver docs/estabilidad-memoria.md
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PHASE="all"
DO_REBOOT=0

usage() {
  cat <<'EOF'
Uso: ./scripts/setup-estabilidad-memoria.sh [opciones]

  --phase 1       Solo Fase 1 (docker/pg, earlyoom, swappiness, cpupower)
  --phase 2       Solo Fase 2 (zram-generator.conf); usa --reboot para reiniciar
  --phase all     Fase 1 + Fase 2 (default)
  --reboot        Tras Fase 2, reinicia el sistema
  --verify        Solo comprobaciones (sin cambios)
  -h, --help      Esta ayuda

Ejemplos:
  sudo ./scripts/setup-estabilidad-memoria.sh --phase 1
  sudo ./scripts/setup-estabilidad-memoria.sh --phase 2 --reboot
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      PHASE="${2:?}"
      shift 2
      ;;
    --reboot) DO_REBOOT=1; shift ;;
    --verify) PHASE="verify"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo $0 $*" >&2
  exit 1
fi

log() { printf '==> %s\n' "$*"; }

# intel_pstate (p. ej. i7-1255U) solo expone performance/powersave, no schedutil.
pick_cpu_governor() {
  local avail gov
  avail="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || true)"
  for gov in schedutil performance ondemand powersave; do
    if [[ " $avail " == *" $gov "* ]]; then
      echo "$gov"
      return 0
    fi
  done
  # shellcheck disable=SC2206
  set -- $avail
  [[ -n "${1:-}" ]] || return 1
  echo "$1"
}

phase1() {
  log "Fase 1.1: Docker y PostgreSQL bajo demanda"
  systemctl stop docker postgresql 2>/dev/null || true
  systemctl disable docker postgresql

  log "Fase 1.2: earlyoom"
  if ! command -v earlyoom >/dev/null; then
    pacman -S --needed --noconfirm earlyoom
  fi
  install -Dm644 "$REPO_DIR/system/etc/default/earlyoom" /etc/default/earlyoom
  systemctl enable --now earlyoom

  log "Fase 1.3: swappiness=15"
  install -Dm644 "$REPO_DIR/system/etc/sysctl.d/99-swappiness.conf" /etc/sysctl.d/99-swappiness.conf
  sysctl --system >/dev/null

  log "Fase 1.4: cpupower (governor según CPU)"
  if ! command -v cpupower >/dev/null; then
    pacman -S --needed --noconfirm cpupower
  fi
  local gov driver
  driver="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo unknown)"
  gov="$(pick_cpu_governor)" || {
    echo "No se pudo elegir governor (driver=$driver)" >&2
    exit 1
  }
  if [[ "$gov" != schedutil ]]; then
    log "  $driver: sin schedutil; usando governor=$gov"
  fi
  cpupower frequency-set -g "$gov"
  install -Dm644 "$REPO_DIR/system/etc/default/cpupower-service.conf" /etc/default/cpupower-service.conf
  sed -i "s/^GOVERNOR=.*/GOVERNOR='$gov'/" /etc/default/cpupower-service.conf
  rm -f /etc/default/cpupower
  systemctl enable --now cpupower
  systemctl restart cpupower
}

phase2() {
  log "Fase 2: zram-generator 8 GiB"
  install -Dm644 "$REPO_DIR/system/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
  if [[ "$DO_REBOOT" -eq 1 ]]; then
    log "Reiniciando en 5 s (Ctrl+C para cancelar)..."
    sleep 5
    reboot
  else
    echo "Config escrita. Reinicia manualmente: sudo reboot"
  fi
}

verify() {
  echo "--- earlyoom ---"
  systemctl is-active earlyoom 2>/dev/null || true
  echo "--- docker/postgresql ---"
  systemctl is-enabled docker postgresql 2>/dev/null || true
  echo "--- swappiness ---"
  sysctl vm.swappiness 2>/dev/null || true
  echo "--- cpupower ---"
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
  grep -E '^GOVERNOR=' /etc/default/cpupower-service.conf 2>/dev/null || true
  echo "--- zram ---"
  zramctl 2>/dev/null || true
  swapon --show 2>/dev/null || true
  free -h
}

case "$PHASE" in
  1) phase1; verify ;;
  2) phase2; [[ "$DO_REBOOT" -eq 0 ]] && verify ;;
  all)
    phase1
    phase2
    [[ "$DO_REBOOT" -eq 0 ]] && verify
    ;;
  verify) verify ;;
  *)
    echo "Fase inválida: $PHASE" >&2
    exit 1
    ;;
esac

log "Listo. Documentación: $REPO_DIR/docs/estabilidad-memoria.md"
