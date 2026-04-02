#!/usr/bin/env bash
# Lanzador de aplicaciones (drun). Tema: selector-app.rasi (imagebox + listbox).
set -euo pipefail

CORE_THEME="$HOME/.config/rofi/styles/selector-app.rasi"
IMG="$HOME/.config/rofi/images/arch-linux.png"

rofi_args=(
  -modi drun
  -show drun
  -show-icons
  -display-drun "Aplicaciones"
  -drun-display-format "{name}"
  -theme "$CORE_THEME"
)

if [ -f "$IMG" ]; then
  rofi "${rofi_args[@]}" -theme-str "imagebox { background-image: url(\"$IMG\", height); }"
else
  rofi "${rofi_args[@]}"
fi

# Autor: Fravelz
