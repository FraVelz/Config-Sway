#!/usr/bin/env bash
# Si DroidCam cargó snd-aloop antes que el audio real, PipeWire puede dejar
# Loopback como salida/mic por defecto (sin sonido audible). Corrige eso.
set -euo pipefail

command -v pactl >/dev/null 2>&1 || exit 0

sleep 3

default_sink="$(pactl get-default-sink 2>/dev/null || true)"
if [[ "$default_sink" == *snd_aloop* ]]; then
  real_sink="$(pactl list sinks short 2>/dev/null | awk '/HiFi__Speaker__sink/ { print $2; exit }')"
  if [ -n "${real_sink:-}" ]; then
    pactl set-default-sink "$real_sink"
  fi
fi

default_source="$(pactl get-default-source 2>/dev/null || true)"
if [[ "$default_source" == *snd_aloop* ]]; then
  real_source="$(pactl list sources short 2>/dev/null | awk '/HiFi__Mic1__source/ { print $2; exit }')"
  if [ -n "${real_source:-}" ]; then
    pactl set-default-source "$real_source"
  fi
fi
