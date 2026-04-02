#!/usr/bin/env bash
# Calculadora Rofi (solo modo script calc). Más fiable que combi + tema con sidebar.
set -euo pipefail

ROFI_CALC="$HOME/.config/rofi/scripts/rofi-calc.sh"
THEME="$HOME/.config/rofi/styles/selector-calc.rasi"

rofi -modi "calc:${ROFI_CALC}" -show calc -theme "$THEME"

# Autor: Fravelz
