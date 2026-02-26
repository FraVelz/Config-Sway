#!/usr/bin/env bash
set -euo pipefail

# Actualiza tu configuración local desde este repo.
# - Sincroniza (incluye BORRADOS) desde ./.config → ~/.config, limitado a los top-level del repo
# - Sincroniza (incluye BORRADOS) desde ./home → ~, limitado al primer nivel de home/
# - Hace backup antes de tocar nada (puedes desactivarlo con --no-backup)

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SRC_CONFIG="$REPO_DIR/.config"
DST_CONFIG="$HOME/.config"
SRC_HOME="$REPO_DIR/home"

need() { command -v "$1" >/dev/null 2>&1; }
die() { echo "Error: $*" >&2; exit 1; }

# Flags
NO_BACKUP=0
for arg in "$@"; do
  case "$arg" in
    --no-backup) NO_BACKUP=1 ;;
    *) die "Opción desconocida: $arg" ;;
  esac
done

[ -d "$SRC_CONFIG" ] || die "No existe: $SRC_CONFIG"
need rsync || die "Falta rsync. Instálalo (o ejecuta ./install.sh en Arch)."

ts="$(date +%Y%m%d-%H%M%S)"
config_bak="$HOME/.config.bak-$ts"
home_bak="$HOME/home-dots.bak-$ts"

mkdir -p "$DST_CONFIG"

if [ "$NO_BACKUP" -eq 0 ]; then
  echo "Backup: $DST_CONFIG -> $config_bak"
  cp -a "$DST_CONFIG" "$config_bak" 2>/dev/null || true
fi

managed_list_file="$DST_CONFIG/.config-sway-managed"
new_managed="$(
  cd "$SRC_CONFIG"
  find . -mindepth 1 -maxdepth 1 -printf '%P\n' | LC_ALL=C sort
)"
old_managed=""
if [ -f "$managed_list_file" ]; then
  old_managed="$(cat "$managed_list_file" 2>/dev/null || true)"
fi

echo "Sincronizando ~/.config (solo lo gestionado por el repo)..."
while IFS= read -r entry; do
  [ -n "${entry:-}" ] || continue
  if [ -d "$SRC_CONFIG/$entry" ]; then
    mkdir -p "$DST_CONFIG/$entry"
    rsync -a --delete "$SRC_CONFIG/$entry"/ "$DST_CONFIG/$entry"/
  else
    rsync -a "$SRC_CONFIG/$entry" "$DST_CONFIG/$entry"
  fi
done <<<"$new_managed"

# Borrar del destino lo que se eliminó del repo (solo dentro del set "managed")
if [ -n "${old_managed:-}" ]; then
  while IFS= read -r entry; do
    [ -n "${entry:-}" ] || continue
    if ! grep -Fxq -- "$entry" <<<"$new_managed"; then
      rm -rf -- "$DST_CONFIG/$entry"
    fi
  done <<<"$old_managed"
fi

printf '%s\n' "$new_managed" > "$managed_list_file"

if [ -d "$SRC_HOME" ]; then
  home_managed_file="$HOME/.home-dots-managed"
  new_home="$(
    cd "$SRC_HOME"
    find . -mindepth 1 -maxdepth 1 -printf '%P\n' | LC_ALL=C sort
  )"
  old_home=""
  if [ -f "$home_managed_file" ]; then
    old_home="$(cat "$home_managed_file" 2>/dev/null || true)"
  fi

  if [ "$NO_BACKUP" -eq 0 ]; then
    echo "Backup de dotfiles de $HOME en: $home_bak"
    mkdir -p "$home_bak"
  fi

  echo "Sincronizando dotfiles en ~ (solo lo gestionado por home/)..."
  while IFS= read -r entry; do
    [ -n "${entry:-}" ] || continue

    if [ "$NO_BACKUP" -eq 0 ] && [ -e "$HOME/$entry" ]; then
      mkdir -p "$(dirname "$home_bak/$entry")"
      cp -a "$HOME/$entry" "$home_bak/$entry" 2>/dev/null || true
    fi

    if [ -d "$SRC_HOME/$entry" ]; then
      mkdir -p "$HOME/$entry"
      rsync -a --delete "$SRC_HOME/$entry"/ "$HOME/$entry"/
    else
      rsync -a "$SRC_HOME/$entry" "$HOME/$entry"
    fi
  done <<<"$new_home"

  if [ -n "${old_home:-}" ]; then
    while IFS= read -r entry; do
      [ -n "${entry:-}" ] || continue
      if ! grep -Fxq -- "$entry" <<<"$new_home"; then
        if [ "$NO_BACKUP" -eq 0 ] && [ -e "$HOME/$entry" ]; then
          mkdir -p "$(dirname "$home_bak/$entry")"
          cp -a "$HOME/$entry" "$home_bak/$entry" 2>/dev/null || true
        fi
        rm -rf -- "$HOME/$entry"
      fi
    done <<<"$old_home"
  fi

  printf '%s\n' "$new_home" > "$home_managed_file"
fi

# Post-apply: recargas / servicios
if need systemctl; then
  systemctl --user restart xdg-desktop-portal xdg-desktop-portal-wlr 2>/dev/null || true
fi
if need swaymsg; then
  swaymsg reload >/dev/null 2>&1 || true
fi
if need waybar; then
  killall waybar 2>/dev/null || true
  sleep 0.2
  if [ -f "$HOME/.config/waybar/config.jsonc" ]; then
    waybar -c "$HOME/.config/waybar/config.jsonc" >/dev/null 2>&1 & disown || true
  fi
fi

echo "Update listo."

# Autor: Fravelz
