#!/usr/bin/env bash
set -euo pipefail

# Instalador simple para estos dots de Sway.
# NO borra nada: hace backup de ~/.config y de algunos dotfiles en $HOME y copia encima.

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SRC="$REPO_DIR/.config"
DST="$HOME/.config"

HOME_SRC="$REPO_DIR/home"

if [ ! -d "$SRC" ]; then
  echo "No existe: $SRC" >&2
  exit 1
fi

ts="$(date +%Y%m%d-%H%M%S)"
bak="$HOME/.config.bak-$ts"
home_bak="$HOME/home-dots.bak-$ts"

if [ -d "$DST" ]; then
  echo "Backup: $DST -> $bak"
  cp -a "$DST" "$bak"
else
  echo "No existe $DST, creando..."
  mkdir -p "$DST"
fi

echo "Copiando: $SRC/* -> $DST/"
cp -a "$SRC"/. "$DST"/

# Si existe carpeta home/ en el repo, copia también dotfiles del $HOME, con backup previo.
if [ -d "$HOME_SRC" ]; then
  echo "Backup de dotfiles de $HOME en: $home_bak"
  mkdir -p "$home_bak"

  # Recorre solo primer nivel de home/ (ej. .zshrc, .gitconfig, etc.)
  (
    cd "$HOME_SRC"
    find . -mindepth 1 -maxdepth 1 -print0
  ) | while IFS= read -r -d '' entry; do
    rel="${entry#./}"
    # Si ya existe en $HOME, guarda copia
    if [ -e "$HOME/$rel" ]; then
      mkdir -p "$(dirname "$home_bak/$rel")"
      cp -a "$HOME/$rel" "$home_bak/$rel"
    fi
  done

  echo "Copiando: $HOME_SRC/. -> $HOME/"
  cp -a "$HOME_SRC"/. "$HOME"/
fi

echo "Listo. Si estás en Sway, recarga con: swaymsg reload"

# Autor: Fravelz 
