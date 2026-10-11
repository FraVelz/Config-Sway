#!/usr/bin/env bash
# Toggle lupa ×8 centrada en el cursor real (Wayland).
# Super+I / window-zoom8
set -euo pipefail

ZOOM_FACTOR="${ZOOM_FACTOR:-8}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/fravelz-window-zoom8"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$STATE_DIR"
PIDFILE="$STATE_DIR/viewer.pid"
CURSORFILE="$STATE_DIR/cursor.prev"
SHOT="$STATE_DIR/zoom.png"
TITLE="window-zoom8"

notify() {
  notify-send -a "zoom×8" "$1" 2>/dev/null || true
}

viewer_running() {
  if [ -f "$PIDFILE" ]; then
    local old_pid
    old_pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    [ -n "${old_pid:-}" ] && kill -0 "$old_pid" 2>/dev/null && return 0
  fi
  pgrep -x shmooz >/dev/null 2>&1
}

stop_viewer() {
  if [ -f "$PIDFILE" ]; then
    local old_pid
    old_pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [ -n "${old_pid:-}" ] && kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
  fi
  pkill -x shmooz 2>/dev/null || true
  if [ -f "$CURSORFILE" ]; then
    read -r cx cy <"$CURSORFILE" || true
    if [ -n "${cx:-}" ] && [ -n "${cy:-}" ]; then
      swaymsg "seat - cursor set ${cx} ${cy}" >/dev/null 2>&1 || true
    fi
    rm -f "$CURSORFILE"
  fi
  rm -f "$SHOT"
}

if viewer_running; then
  stop_viewer
  notify "Zoom×${ZOOM_FACTOR} off"
  exit 0
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "Falta: $1" >&2; exit 1; }; }
need swaymsg
need python3
need grim
need mpv

pos="$("$SCRIPT_DIR/window-zoom8-cursor.py")" || {
  notify "No pude leer el cursor"
  exit 1
}
read -r cx cy ox oy ow oh <<<"$pos"

factor="$ZOOM_FACTOR"
vw=$((ow / factor))
vh=$((oh / factor))
vw=$((vw - vw % 2))
vh=$((vh - vh % 2))
[ "$vw" -ge 2 ] || vw=2
[ "$vh" -ge 2 ] || vh=2

gx=$((cx - vw / 2))
gy=$((cy - vh / 2))
# no salirse de la pantalla
[ "$gx" -lt "$ox" ] && gx=$ox
[ "$gy" -lt "$oy" ] && gy=$oy
maxx=$((ox + ow - vw))
maxy=$((oy + oh - vh))
[ "$gx" -gt "$maxx" ] && gx=$maxx
[ "$gy" -gt "$maxy" ] && gy=$maxy

printf '%s %s\n' "$cx" "$cy" >"$CURSORFILE"

grim -g "${gx},${gy} ${vw}x${vh}" "$SHOT" || {
  notify "Fallo al capturar la zona del cursor"
  exit 1
}

mpv --really-quiet --no-terminal --force-window=immediate --fullscreen \
  --title="$TITLE" --osc=no --osd-level=0 \
  --image-display-duration=inf --loop-file=inf \
  --scale=nearest --cscale=nearest --dscale=nearest \
  --no-keepaspect-window \
  -- "$SHOT" &
echo $! >"$PIDFILE"

swaymsg "seat - cursor set $((ox + ow / 2)) $((oy + oh / 2))" >/dev/null 2>&1 || true
notify "Zoom×${ZOOM_FACTOR} en el cursor (Super+I para salir)"
