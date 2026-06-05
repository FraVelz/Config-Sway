#!/usr/bin/env bash
# Aviso flotante 3 min antes de las 21:00 (hora local del PC) y apagado automático.
set -euo pipefail

if [ -z "${WAYLAND_DISPLAY:-}" ] && command -v systemctl >/dev/null 2>&1; then
  while IFS='=' read -r key value; do
    case "$key" in
      WAYLAND_DISPLAY|DISPLAY|SWAYSOCK|XDG_RUNTIME_DIR)
        export "$key=$value"
        ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null || true)
fi

readonly SHUTDOWN_HOUR="${SHUTDOWN_HOUR:-21}"
readonly SHUTDOWN_MINUTE="${SHUTDOWN_MINUTE:-0}"
readonly WARN_SECONDS="${WARN_SECONDS:-180}"
readonly LOCK="${XDG_RUNTIME_DIR:-/tmp}/shutdown-countdown.lock"

clamp() {
  local val="$1" min="$2" max="$3"
  (( val < min )) && val=$min
  (( val > max )) && val=$max
  printf '%s' "$val"
}

screen_dims() {
  local w h
  if command -v swaymsg >/dev/null 2>&1; then
    read -r w h < <(swaymsg -t get_outputs 2>/dev/null | python3 -c "
import json, sys
try:
    outs = json.load(sys.stdin)
    active = [o for o in outs if o.get('active')]
    o = active[0] if active else max(outs, key=lambda x: x['rect']['width'])
    print(o['rect']['width'], o['rect']['height'])
except Exception:
    print('1920 1080')
" 2>/dev/null) && [ -n "$w" ] && [ -n "$h" ] && { printf '%s %s' "$w" "$h"; return; }
  fi
  printf '1920 1080'
}

calc_layout() {
  local sw sh
  read -r sw sh <<< "$(screen_dims)"

  export OVERLAY_WIN_W="$(clamp $(( sw * 42 / 100 )) 480 920)"
  export OVERLAY_WIN_H="$(clamp $(( sh * 36 / 100 )) 300 560)"
  export OVERLAY_TITLE_FONT="$(clamp $(( OVERLAY_WIN_H / 22 )) 13 18)"
  export OVERLAY_BODY_FONT="$(clamp $(( OVERLAY_WIN_H / 26 )) 12 16)"
  export OVERLAY_TIMER_FONT="$(clamp $(( OVERLAY_WIN_W / 7 )) 56 132)"
}

kitty_font_size() {
  printf '\033]1337;SetFontSize=%d\007' "$1"
}

term_cols() {
  tput cols 2>/dev/null || echo 80
}

term_lines() {
  tput lines 2>/dev/null || echo 24
}

center_line() {
  local text="$1" cols pad
  cols="$(term_cols)"
  pad=$(( (cols - ${#text}) / 2 ))
  (( pad < 0 )) && pad=0
  printf '%*s%s\n' "$pad" '' "$text"
}

clear_screen() {
  printf '\033[3J\033[2J\033[H\033[?25l'
}

position_overlay() {
  command -v swaymsg >/dev/null 2>&1 || return 0
  swaymsg "[title=\"shutdown-countdown\"] resize set ${OVERLAY_WIN_W} ${OVERLAY_WIN_H}, move position center, focus" \
    >/dev/null 2>&1 || true
  sleep 0.15
}

play_sound() {
  local file="${1:-/usr/share/sounds/freedesktop/stereo/bell.oga}"
  [ -f "$file" ] || return 0
  if command -v pw-play >/dev/null 2>&1; then
    pw-play "$file" >/dev/null 2>&1 &
  elif command -v paplay >/dev/null 2>&1; then
    paplay "$file" >/dev/null 2>&1 &
  fi
}

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "$@"
}

target_epoch() {
  local now target
  now="$(date +%s)"
  target="$(date -d "today ${SHUTDOWN_HOUR}:${SHUTDOWN_MINUTE}" +%s)"
  if [ "$now" -ge "$target" ]; then
    target="$(date -d "tomorrow ${SHUTDOWN_HOUR}:${SHUTDOWN_MINUTE}" +%s)"
  fi
  printf '%s' "$target"
}

draw_screen() {
  local mins="$1" secs="$2" urgent="$3"
  local time_str pct filled bar_w bar_empty i bar title subtitle cancel
  local timer_color=$'\033[38;5;220m' body_color=$'\033[38;5;245m' reset=$'\033[0m'

  time_str="$(printf '%02d:%02d' "$mins" "$secs")"
  [ "$urgent" -eq 1 ] && timer_color=$'\033[1;38;5;196m'

  pct=$(( (mins * 60 + secs) * 100 / WARN_SECONDS ))
  [ "$pct" -gt 100 ] && pct=100
  bar_w=$(( $(term_cols) - 24 ))
  bar_w="$(clamp "$bar_w" 18 46)"
  filled=$(( pct * bar_w / 100 ))
  bar_empty=$((bar_w - filled))
  bar="["
  for ((i = 0; i < filled; i++)); do bar+='#'; done
  for ((i = 0; i < bar_empty; i++)); do bar+='-'; done
  bar+="] ${pct}%"

  title="APAGADO AUTOMATICO - $(printf '%02d:%02d' "$SHUTDOWN_HOUR" "$SHUTDOWN_MINUTE") - HORA LOCAL"
  subtitle="Guarda tu trabajo - el PC se apagara solo"
  cancel="Cancelar: pulsa [ c ] en esta ventana"

  clear_screen

  kitty_font_size "$OVERLAY_TITLE_FONT"
  center_line "$title"

  printf '\n'
  kitty_font_size "$OVERLAY_TIMER_FONT"
  printf '%s' "$timer_color"
  center_line "$time_str"
  printf '%s' "$reset"

  printf '\n'
  kitty_font_size "$OVERLAY_BODY_FONT"
  center_line "$subtitle"
  center_line "$bar"
  printf '\n'
  center_line "$cancel"

  kitty_font_size "$OVERLAY_BODY_FONT"
  printf '%s' "$reset"
}

run_countdown() {
  local target now remaining mins secs cancelled=0 last_beep=-1 urgent=0

  if [ -f "$LOCK" ]; then
    old_pid="$(cat "$LOCK" 2>/dev/null || true)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      exit 0
    fi
  fi
  printf '%s' "$$" >"$LOCK"
  trap 'rm -f "$LOCK"; printf "\033[?25h"' EXIT

  calc_layout
  position_overlay

  target="$(target_epoch)"
  now="$(date +%s)"
  remaining=$((target - now))
  if [ "$remaining" -le 0 ]; then
    remaining=1
  elif [ "$remaining" -gt "$WARN_SECONDS" ]; then
    remaining="$WARN_SECONDS"
  fi

  notify -u critical "Apagado programado" \
    "Quedan ${remaining}s para guardar todo. Apagado a las ${SHUTDOWN_HOUR}:$(printf '%02d' "$SHUTDOWN_MINUTE") (hora local)."
  play_sound /usr/share/sounds/freedesktop/stereo/complete.oga

  stty -echo -icanon time 0 min 0 2>/dev/null || true

  while [ "$remaining" -gt 0 ]; do
    mins=$((remaining / 60))
    secs=$((remaining % 60))
    urgent=0
    [ "$remaining" -le 30 ] && urgent=1

    if [ "$mins" -eq 0 ] && [ "$secs" -le 10 ] && [ "$secs" -ne "$last_beep" ]; then
      play_sound /usr/share/sounds/freedesktop/stereo/bell.oga
      last_beep="$secs"
    elif [ "$secs" -eq 0 ] && [ "$mins" -ne "$last_beep" ] && [ "$mins" -gt 0 ]; then
      play_sound /usr/share/sounds/freedesktop/stereo/message.oga
      last_beep="$mins"
    fi

    draw_screen "$mins" "$secs" "$urgent"

    if read -t 1 -n 1 key 2>/dev/null && [ "$key" = "c" ]; then
      cancelled=1
      break
    fi
    remaining=$((remaining - 1))
  done

  stty sane 2>/dev/null || true
  printf '\033[?25h'

  if [ "$cancelled" -eq 1 ]; then
    notify "Apagado cancelado" "No se apagará el equipo esta noche."
    play_sound /usr/share/sounds/freedesktop/stereo/message.oga
    exit 0
  fi

  draw_screen 0 0 1
  kitty_font_size "$OVERLAY_TITLE_FONT"
  center_line "Apagando el equipo..."
  sleep 2

  notify -u critical "Apagando" "Son las ${SHUTDOWN_HOUR}:$(printf '%02d' "$SHUTDOWN_MINUTE"). Apagando el equipo..."
  play_sound /usr/share/sounds/freedesktop/stereo/complete.oga

  if command -v loginctl >/dev/null 2>&1; then
    loginctl poweroff || systemctl poweroff
  else
    systemctl poweroff
  fi
}

if [ -z "${SHUTDOWN_COUNTDOWN_CHILD:-}" ]; then
  export SHUTDOWN_COUNTDOWN_CHILD=1
  calc_layout

  if ! command -v kitty >/dev/null 2>&1; then
    notify -u critical "Apagado programado" "Kitty no está instalado; ejecutando contador en terminal."
    run_countdown
    exit 0
  fi

  exec kitty --class shutdown-countdown --title shutdown-countdown \
    --override "initial_window_width=${OVERLAY_WIN_W}" \
    --override "initial_window_height=${OVERLAY_WIN_H}" \
    --override remember_window_size=no \
    --override hide_window_decorations=yes \
    --override scrollback_lines=0 \
    --override window_padding_width=16 \
    --override window_margin_width=0 \
    --override font_size="${OVERLAY_BODY_FONT}" \
    --override disable_ligatures=always \
    --override background="#120808" \
    --override foreground="#e8c4c4" \
    --override cursor="#120808" \
    --override cursor_text_color="#120808" \
    --override background_opacity=1.0 \
    --override shell=bash \
    bash --noprofile --norc "$0"
fi

run_countdown
