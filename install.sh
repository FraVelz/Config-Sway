#!/usr/bin/env bash
set -euo pipefail

# Instalador de dependencias para Config-Sway (Arch/pacman).
# Este script SOLO instala paquetes necesarios.
# Para aplicar/sincronizar configs locales usa: ./update.sh

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

need() { command -v "$1" >/dev/null 2>&1; }

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      echo "Uso: ./install.sh"
      echo ""
      echo "Instala dependencias con pacman y luego ejecuta update.sh."
      echo "La calculadora Super+= es el proyecto aparte pyside-calc (~/.local/bin/pyside-calc)."
      echo "Teclados/idiomas (Alt+Shift+S): fcitx5 + ~/.local/bin/teclado-rofi."
      exit 0
      ;;
  esac
done

# ---------------------------------------------------------------------------
# 1) Paquetes necesarios (Arch Linux, pacman)
# ---------------------------------------------------------------------------
PKGS=(
  # WM / entorno
  sway swaybg waybar swaync kitty rofi flameshot network-manager-applet

  # Portales Wayland / capturas
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim

  # Sync
  rsync

  # Utils usados en la config
  brightnessctl playerctl blueman swaylock

  # Terminal / UX
  ranger lsd bat fastfetch

  # Audio / notificaciones usadas en scripts
  mpc alsa-utils libnotify bc

  # Input method (chino/coreano + teclados; menú Alt+Shift+S)
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-hangul
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
echo "Calculadora Super+=: instala/configura ~/Documentos/personal/pyside-calc → ~/.local/bin/pyside-calc"
echo "Para aplicar los dotfiles: $REPO_DIR/update.sh"

# Opcional: ejecutar update.sh al final
if [ -x "$REPO_DIR/update.sh" ]; then
  echo "Ejecutando update.sh..."
  "$REPO_DIR/update.sh"
elif [ -f "$REPO_DIR/update.sh" ]; then
  echo "Aviso: update.sh existe pero no es ejecutable. Ejecutándolo con bash..."
  bash "$REPO_DIR/update.sh"
fi
