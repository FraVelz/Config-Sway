#!/usr/bin/env bash
set -euo pipefail

# Instalador simple para estos dots de Sway.
# NO borra nada: hace backup de ~/.config y copia encima.

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/.config"
DST="$HOME/.config"

if [ ! -d "$SRC" ]; then
  echo "No existe: $SRC" >&2
  exit 1
fi

ts="$(date +%Y%m%d-%H%M%S)"
bak="$HOME/.config.bak-$ts"

echo "Backup: $DST -> $bak"
cp -a "$DST" "$bak"

echo "Copiando: $SRC/* -> $DST/"
mkdir -p "$DST"
cp -a "$SRC"/. "$DST"/

echo "Listo. Si estás en Sway, recarga con: swaymsg reload"

