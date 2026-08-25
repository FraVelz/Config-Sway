#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Arch vacío → Sway (paquetes, servicios, SDDM, OMZ, yay, pyside-calc, dotfiles).
# Ejecutar como usuario con sudo, nunca como root.

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PYSIDE_CALC_DIR="${HOME}/Documentos/personal/pyside-calc"
PYSIDE_CALC_URL="https://github.com/FraVelz/pyside-calc.git"
SDDM_THEME_SRC="${REPO_DIR}/sddm-astronaut-theme"
SDDM_THEME_DST="/usr/share/sddm/themes/sddm-astronaut-theme"
OMZ_DIR="${HOME}/.oh-my-zsh"

DO_MEMORY=0
DO_SDDM=1
DO_YAY=1
DO_OMZ=1
DO_CALC=1

need() { command -v "$1" >/dev/null 2>&1; }
die() { echo "Error: $*" >&2; exit 1; }
log() { printf '==> %s\n' "$*"; }

usage() {
  cat <<'EOF'
Uso: ./install.sh [opciones]

Bootstrap de Arch Linux (usuario con sudo, red). Instala el desktop Sway,
aplica los dotfiles (update.sh) y deja SDDM listo para reiniciar.

  --memory     También aplica scripts/setup-estabilidad-memoria.sh (earlyoom/zram)
  --no-sddm    No instala el tema astronaut ni habilita SDDM
  --no-yay     No instala yay (AUR)
  --no-omz     No clona Oh My Zsh ni plugins; no cambia el shell
  --no-calc    No clona ni instala pyside-calc
  -h, --help   Esta ayuda

NVIDIA: este script no instala drivers NVIDIA; Intel/AMD usan mesa.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --memory) DO_MEMORY=1 ;;
    --no-sddm) DO_SDDM=0 ;;
    --no-yay) DO_YAY=0 ;;
    --no-omz) DO_OMZ=0 ;;
    --no-calc) DO_CALC=0 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Opción desconocida: $arg (usa --help)" ;;
  esac
done

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  die "No ejecutes este script como root (los dotfiles irían a /root). Usa tu usuario: ./install.sh"
fi
need pacman || die "Este instalador es solo para Arch (falta pacman)."
need sudo || die "Falta sudo. Instálalo y añade tu usuario a wheel."

PKGS=(
  # WM / entorno
  sway swaybg waybar swaync kitty rofi flameshot network-manager-applet
  networkmanager

  # Portales Wayland / capturas
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim
  wl-clipboard

  # GPU genérica (Intel/AMD). NVIDIA: instalar a mano.
  mesa vulkan-intel vulkan-radeon xorg-xwayland qt6-wayland qt5-wayland

  # Login gráfico
  sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg

  # Sync / build
  rsync git base-devel

  # Utils usados en la config
  brightnessctl playerctl blueman bluez bluez-utils swaylock
  pacman-contrib which

  # Terminal / UX
  ranger lsd bat fastfetch zsh firefox neovim python python-pip

  # Audio / notificaciones
  pipewire pipewire-pulse pipewire-alsa wireplumber
  mpc alsa-utils libnotify bc sound-theme-freedesktop sof-firmware

  # Desktop glue
  polkit polkit-gnome xdg-user-dirs

  # Fuentes (Kitty / Waybar / Rofi)
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk
  ttf-nerd-fonts-symbols

  # Input method (chino/coreano + teclados; menú Alt+Shift+S)
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-hangul
)

clone_if_missing() {
  local dest="$1" url="$2"
  if [ -d "$dest/.git" ] || [ -d "$dest" ]; then
    return 0
  fi
  git clone --depth 1 "$url" "$dest"
}

install_packages() {
  log "Solicitando sudo (puede pedir contraseña)..."
  sudo -v || die "sudo rechazado."
  log "Instalando paquetes con pacman..."
  sudo pacman -S --needed --noconfirm "${PKGS[@]}"
}

enable_system_services() {
  log "Habilitando servicios de sistema..."
  if systemctl is-enabled systemd-networkd >/dev/null 2>&1; then
    log "Deshabilitando systemd-networkd (conflicto con NetworkManager; aplica en el próximo boot)"
    sudo systemctl disable systemd-networkd.service
    sudo systemctl disable systemd-networkd.socket 2>/dev/null || true
  fi
  sudo systemctl enable NetworkManager.service
  sudo systemctl enable bluetooth.service

  if [ "$DO_SDDM" -eq 1 ]; then
    sudo systemctl disable display-manager.service 2>/dev/null || true
    sudo systemctl enable sddm.service
  fi

  if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service \
      >/dev/null 2>&1 || true
  else
    log "systemd --user no disponible ahora; PipeWire arrancará al entrar en sesión gráfica"
  fi
}

install_sddm_theme() {
  [ "$DO_SDDM" -eq 1 ] || return 0
  [ -d "$SDDM_THEME_SRC" ] || die "No existe el tema SDDM vendido: $SDDM_THEME_SRC"

  log "Instalando tema SDDM astronaut (silencioso, desde el repo)..."
  sudo mkdir -p "$SDDM_THEME_DST"
  sudo cp -a "$SDDM_THEME_SRC"/. "$SDDM_THEME_DST"/
  if [ -d "$SDDM_THEME_DST/Fonts" ]; then
    sudo mkdir -p /usr/share/fonts
    sudo cp -a "$SDDM_THEME_DST/Fonts"/. /usr/share/fonts/
    sudo fc-cache -f >/dev/null 2>&1 || true
  fi
  sudo tee /etc/sddm.conf >/dev/null <<'EOF'
[Theme]
Current=sddm-astronaut-theme
EOF
  sudo mkdir -p /etc/sddm.conf.d
  sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null <<'EOF'
[General]
InputMethod=qtvirtualkeyboard
EOF
}

install_omz() {
  [ "$DO_OMZ" -eq 1 ] || return 0
  need git || die "Falta git (necesario para Oh My Zsh)."
  log "Oh My Zsh y plugins..."
  if [ ! -d "$OMZ_DIR" ]; then
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
  fi
  local custom="${ZSH_CUSTOM:-$OMZ_DIR/custom}/plugins"
  mkdir -p "$custom"
  clone_if_missing "$custom/zsh-autosuggestions" \
    https://github.com/zsh-users/zsh-autosuggestions.git
  clone_if_missing "$custom/zsh-syntax-highlighting" \
    https://github.com/zsh-users/zsh-syntax-highlighting.git
  clone_if_missing "$custom/zsh-history-substring-search" \
    https://github.com/zsh-users/zsh-history-substring-search.git

  local zsh_bin
  zsh_bin="$(command -v zsh)" || die "zsh no está en PATH tras pacman."
  if [ "${SHELL:-}" != "$zsh_bin" ]; then
    log "Cambiando shell de login a zsh (puede pedir contraseña)..."
    chsh -s "$zsh_bin" || die "chsh falló. Ejecuta: chsh -s $zsh_bin"
  fi
}

install_yay() {
  [ "$DO_YAY" -eq 1 ] || return 0
  if need yay; then
    log "yay ya está instalado."
    return 0
  fi
  need git || die "Falta git (necesario para yay)."
  log "Instalando yay desde AUR..."
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/yay-build.XXXXXX")"
  git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  need yay || die "yay no quedó instalado."
}

install_pyside_calc() {
  [ "$DO_CALC" -eq 1 ] || return 0
  need git || die "Falta git (necesario para pyside-calc)."
  log "Instalando pyside-calc → ~/.local/bin/pyside-calc..."
  mkdir -p "$(dirname "$PYSIDE_CALC_DIR")" "$HOME/.local/bin"

  if [ ! -d "$PYSIDE_CALC_DIR/.git" ] && [ ! -f "$PYSIDE_CALC_DIR/scripts/pyside-calc" ]; then
    git clone --depth 1 "$PYSIDE_CALC_URL" "$PYSIDE_CALC_DIR" \
      || die "No se pudo clonar pyside-calc ($PYSIDE_CALC_URL). El repo puede ser privado o la URL cambió."
  fi
  [ -f "$PYSIDE_CALC_DIR/scripts/pyside-calc" ] \
    || die "pyside-calc no tiene scripts/pyside-calc en $PYSIDE_CALC_DIR"

  if [ ! -x "$PYSIDE_CALC_DIR/.venv/bin/python" ]; then
    python3 -m venv "$PYSIDE_CALC_DIR/.venv"
  fi
  "$PYSIDE_CALC_DIR/.venv/bin/pip" install -r "$PYSIDE_CALC_DIR/requirements.txt"
  chmod +x "$PYSIDE_CALC_DIR/scripts/pyside-calc"
  ln -sfn "$PYSIDE_CALC_DIR/scripts/pyside-calc" "$HOME/.local/bin/pyside-calc"
}

apply_dotfiles() {
  [ -f "$REPO_DIR/update.sh" ] || die "No existe $REPO_DIR/update.sh"
  log "Aplicando dotfiles (update.sh)..."
  if [ -x "$REPO_DIR/update.sh" ]; then
    "$REPO_DIR/update.sh"
  else
    bash "$REPO_DIR/update.sh"
  fi
}

apply_memory() {
  [ "$DO_MEMORY" -eq 1 ] || return 0
  local script="$REPO_DIR/scripts/setup-estabilidad-memoria.sh"
  [ -f "$script" ] || die "No existe $script"
  log "Aplicando estabilidad de memoria (sin reboot automático)..."
  sudo "$script" --phase all
}

# ---------------------------------------------------------------------------
install_packages
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update >/dev/null 2>&1 || true
fi
enable_system_services
install_sddm_theme
install_omz
install_yay
install_pyside_calc
apply_dotfiles
apply_memory

echo ""
log "Instalación lista."
echo "Siguiente paso: reinicia e inicia sesión en SDDM (sesión Sway)."
echo "Notas: teclado latam; apagado automático 21:00 (hora del sistema);"
echo "  NVIDIA no se instala aquí; jarvis (Alt+Space) solo si existe ~/.local/bin/jarvis."
if [ "$DO_SDDM" -eq 0 ]; then
  echo "SDDM no se habilitó (--no-sddm). Desde TTY: sway"
fi
if [ "$DO_MEMORY" -eq 1 ]; then
  echo "Memoria: zram aplica tras reboot. Ver docs/estabilidad-memoria.md"
fi
echo "Opcional: ./install.sh --memory   (si no lo usaste ahora)"
