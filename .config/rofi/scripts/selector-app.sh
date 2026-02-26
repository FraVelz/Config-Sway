#!/usr/bin/env bash
set -euo pipefail

CORE_THEME="$HOME/.config/rofi/styles/_core/selector-app.rasi"
IMG="$HOME/.config/rofi/images/arch-linux.png"

if [ -f "$IMG" ]; then
  rofi -show drun -show-icons -theme "$CORE_THEME" \
    -theme-str "imagebox { background-image: url(\"$IMG\", height); }"
else
  rofi -show drun -show-icons -theme "$CORE_THEME"
fi

# Autor: Fravelz
