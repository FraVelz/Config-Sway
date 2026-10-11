#!/usr/bin/env bash
# Lanzador de aplicaciones (drun). Tema: selector-app.rasi (imagebox + listbox).
set -euo pipefail

# Asegurar que ~/.local/share/applications entre en drun (Minecraft, Lunar, etc.)
_xdg_user="${HOME}/.local/share"
case ":${XDG_DATA_DIRS:-}:" in
  *":${_xdg_user}:"*) ;;
  *)
    export XDG_DATA_DIRS="${_xdg_user}:${_xdg_user}/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share${XDG_DATA_DIRS:+:${XDG_DATA_DIRS}}"
    ;;
esac

CORE_THEME="$HOME/.config/rofi/styles/selector-app.rasi"
IMG="$HOME/.config/rofi/images/arch-linux.png"
# shellcheck source=/dev/null
source "$HOME/.config/scripts/rofi-replace.sh"

rofi_args=(
  -modi drun
  -show drun
  -show-icons
  -display-drun "Aplicaciones"
  -drun-display-format "{name}"
  -theme "$CORE_THEME"
)

rofi_replace
if [ -f "$IMG" ]; then
  rofi "${rofi_args[@]}" -theme-str "imagebox { background-image: url(\"$IMG\", height); }" || true
else
  rofi "${rofi_args[@]}" || true
fi

# Autor: Fravelz
