#!/usr/bin/env bash
# Reproduce sonido al recibir notificaciones (invocado por swaync).
set -euo pipefail

play() {
  local file="$1"
  [ -f "$file" ] || return 0
  if command -v pw-play >/dev/null 2>&1; then
    pw-play "$file" >/dev/null 2>&1 &
  elif command -v paplay >/dev/null 2>&1; then
    paplay "$file" >/dev/null 2>&1 &
  fi
}

default="${NOTIFICATION_SOUND:-/usr/share/sounds/freedesktop/stereo/message.oga}"
critical="${NOTIFICATION_SOUND_CRITICAL:-/usr/share/sounds/freedesktop/stereo/bell.oga}"
sound="$default"

if [ -n "${SWAYNC_SOUND_FILE:-}" ] && [ -f "$SWAYNC_SOUND_FILE" ]; then
  sound="$SWAYNC_SOUND_FILE"
elif [ -n "${SWAYNC_SOUND_NAME:-}" ]; then
  for ext in oga wav; do
    candidate="/usr/share/sounds/freedesktop/stereo/${SWAYNC_SOUND_NAME}.${ext}"
    if [ -f "$candidate" ]; then
      sound="$candidate"
      break
    fi
  done
fi

case "${SWAYNC_URGENCY:-}" in
  Critical|2) sound="$critical" ;;
esac

play "$sound"
