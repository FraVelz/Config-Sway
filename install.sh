#!/usr/bin/env bash
set -euo pipefail

# Instalador completo para estos dots de Sway.
# - Instala paquetes necesarios (Arch, pacman)
# - Hace backup de ~/.config y de algunos dotfiles en $HOME
# - Copia la configuración del repo
# - Al final ejecuta update.sh si existe

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1) Paquetes necesarios (Arch Linux, pacman)
# ---------------------------------------------------------------------------
PKGS=(
  # WM / entorno
  sway swaybg waybar mako kitty rofi flameshot network-manager-applet

  # Portales Wayland / capturas
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim

  # Utils usados en la config
  brightnessctl playerctl blueman swaylock

  # Terminal / UX
  ranger lsd bat fastfetch

  # Audio / notificaciones usadas en scripts
  mpc alsa-utils libnotify
)

if command -v pacman >/dev/null 2>&1; then
  echo "Instalando paquetes necesarios con pacman (sudo pacman -S --needed)..."
  sudo pacman -S --needed "${PKGS[@]}"
else
  echo "Aviso: pacman no está disponible, se omite instalación de paquetes." >&2
fi

# ---------------------------------------------------------------------------
# 4) Ejecutar update.sh al final (si existe)
# ---------------------------------------------------------------------------

if [ -x "$REPO_DIR/update.sh" ]; then
  echo "Ejecutando update.sh..."
  "$REPO_DIR/update.sh"
elif [ -f "$REPO_DIR/update.sh" ]; then
  echo "Aviso: update.sh existe pero no es ejecutable. Ejecutándolo con bash..."
  bash "$REPO_DIR/update.sh"
fi


# Instalar los paquetes
