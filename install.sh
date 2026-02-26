#!/usr/bin/env bash
set -euo pipefail

# Instalador de dependencias para Config-Sway (Arch/pacman).
# Este script SOLO instala paquetes necesarios.
# Para aplicar/sincronizar configs locales usa: ./update.sh

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

need() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# 1) Paquetes necesarios (Arch Linux, pacman)
# ---------------------------------------------------------------------------
PKGS=(
  # WM / entorno
  sway swaybg waybar mako kitty rofi flameshot network-manager-applet

  # Portales Wayland / capturas
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim

  # Sync
  rsync

  # Utils usados en la config
  brightnessctl playerctl blueman swaylock

  # Terminal / UX
  ranger lsd bat fastfetch

  # Audio / notificaciones usadas en scripts
  mpc alsa-utils libnotify
)

if need pacman; then
  if need sudo; then
    echo "Instalando paquetes necesarios con pacman (sudo pacman -S --needed)..."
    if sudo -n true 2>/dev/null; then
      sudo pacman -S --needed "${PKGS[@]}"
    else
      echo "Aviso: sudo requiere contraseña. Ejecuta manualmente:"
      echo "  sudo pacman -S --needed ${PKGS[*]}"
    fi
  else
    echo "Aviso: no existe sudo; se omite instalación de paquetes." >&2
  fi
else
  echo "Aviso: pacman no está disponible, se omite instalación de paquetes." >&2
fi

echo "Dependencias listas."
echo "Para aplicar los dotfiles: $REPO_DIR/update.sh"

# Opcional: ejecutar update.sh al final
if [ -x "$REPO_DIR/update.sh" ]; then
  echo "Ejecutando update.sh..."
  "$REPO_DIR/update.sh"
elif [ -f "$REPO_DIR/update.sh" ]; then
  echo "Aviso: update.sh existe pero no es ejecutable. Ejecutándolo con bash..."
  bash "$REPO_DIR/update.sh"
fi
