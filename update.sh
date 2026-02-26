#!/usr/bin/env bash
set -euo pipefail

# Instalador simple para dots de Sway
# NO borra nada: hace backup por defecto, pero se puede desactivar con --no-backup

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SRC="$REPO_DIR/.config"
DST="$HOME/.config"

HOME_SRC="$REPO_DIR/home"

# ===========================
# Manejo de flags
# ===========================
NO_BACKUP=0
for arg in "$@"; do
    case "$arg" in
        --no-backup)
            NO_BACKUP=1
            ;;
        *)
            echo "Opción desconocida: $arg" >&2
            exit 1
            ;;
    esac
done

# ===========================
# Validaciones
# ===========================
if [ ! -d "$SRC" ]; then
  echo "No existe: $SRC" >&2
  exit 1
fi

# Timestamps para backups
ts="$(date +%Y%m%d-%H%M%S)"
bak="$HOME/.config.bak-$ts"
home_bak="$HOME/home-dots.bak-$ts"

# ===========================
# Backup de .config
# ===========================
if [ "$NO_BACKUP" -eq 0 ]; then
    if [ -d "$DST" ]; then
      echo "Backup: $DST -> $bak"
      cp -a "$DST" "$bak"
    else
      echo "No existe $DST, creando..."
      mkdir -p "$DST"
    fi
else
    # Solo crear destino si no existe
    mkdir -p "$DST"
fi

# ===========================
# Copia principal de .config
# ===========================
echo "Copiando: $SRC/* -> $DST/"
cp -a "$SRC"/. "$DST"/

# ===========================
# Backup de dotfiles de home
# ===========================
if [ -d "$HOME_SRC" ]; then
    if [ "$NO_BACKUP" -eq 0 ]; then
        echo "Backup de dotfiles de $HOME en: $home_bak"
        mkdir -p "$home_bak"

        (
          cd "$HOME_SRC"
          find . -mindepth 1 -maxdepth 1 -print0
        ) | while IFS= read -r -d '' entry; do
          rel="${entry#./}"
          if [ -e "$HOME/$rel" ]; then
            mkdir -p "$(dirname "$home_bak/$rel")"
            cp -a "$HOME/$rel" "$home_bak/$rel"
          fi
        done
    fi

    echo "Copiando: $HOME_SRC/. -> $HOME/"
    cp -a "$HOME_SRC"/. "$HOME"/
fi

# ===========================
# Recargar Sway
# ===========================

swaymsg reload
echo "Listo."

# Autor: Fravelz
