#!/usr/bin/env bash
# Modo script Rofi (combi). El filtro llega en ROFI_INPUT; en Arch suele hacer falta rofi-git (AUR), no solo rofi 2.0 de extra.
set -euo pipefail

eval_math() {
  local expr="$1" out
  if command -v bc >/dev/null 2>&1; then
    out="$(echo "$expr" | bc -l 2>/dev/null)" || return 1
  else
    out="$(awk "BEGIN { print ($expr) }" 2>/dev/null)" || return 1
  fi
  [[ -z "${out//[[:space:]]/}" ]] && return 1
  printf '%s' "$out"
}

copy_result() {
  local line="$1"
  local num="${line##*= }"
  num="${num%% *}"
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$num" | wl-copy 2>/dev/null || true
  fi
  notify-send -a "Calc" "Resultado copiado" "$num" 2>/dev/null || true
}

# Quita prefijos que Rofi combi puede anteponer al filtro (ej. "C 10+10", letra de modo).
normalize_input() {
  local s="$1"
  s="$(printf '%s' "$s" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ "$s" =~ ^[Cc][[:space:]]+(.+)$ ]]; then
    s="${BASH_REMATCH[1]}"
    s="$(printf '%s' "$s" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  fi
  if [[ "$s" =~ ^[Cc]alc:[[:space:]]*(.*)$ ]]; then
    s="${BASH_REMATCH[1]}"
    s="$(printf '%s' "$s" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  fi
  if [[ "$s" =~ ^[[:alpha:]][[:space:]]+([0-9].*)$ ]]; then
    s="${BASH_REMATCH[1]}"
    s="$(printf '%s' "$s" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  fi
  printf '%s' "$s"
}

if [[ "${ROFI_RETV:-0}" -eq 1 ]] && [[ -n "${1:-}" ]]; then
  case "$1" in
    *'='*) copy_result "$1" ;;
  esac
  exit 0
fi

input="$(normalize_input "${ROFI_INPUT:-}")"
input="${input//$'\r'/}"
input="${input//$'\n'/}"

[[ -z "$input" ]] && exit 0

if [[ ! "$input" =~ ^[0-9+*/().^[:space:]-]+$ ]]; then
  exit 0
fi

if [[ "$input" =~ ^[0-9.]+$ ]]; then
  exit 0
fi

if ! echo "$input" | grep -qE '[+*/^%()]'; then
  if ! echo "$input" | grep -qE '[0-9]-[0-9]'; then
    exit 0
  fi
fi

out="$(eval_math "$input")" || exit 0
[[ -z "$out" ]] && exit 0

echo -en "${input} = ${out}\0icon\x1fcalculator\n"
