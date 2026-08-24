#!/usr/bin/env bash
# Variables IM + fcitx5. Layout físico siempre español.
set -euo pipefail

systemctl --user unset-environment GTK_IM_MODULE >/dev/null 2>&1 || true
systemctl --user set-environment \
  XMODIFIERS=@im=fcitx \
  QT_IM_MODULE=fcitx \
  SDL_IM_MODULE=fcitx \
  GLFW_IM_MODULE=ibus \
  >/dev/null 2>&1 || true

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd \
    XMODIFIERS QT_IM_MODULE SDL_IM_MODULE GLFW_IM_MODULE \
    >/dev/null 2>&1 || true
fi

SRC="$HOME/.config/scripts/teclado/fcitx5"

mkdir -p "$HOME/.config/fcitx5"
if [ -f "$SRC/config" ]; then
  cp -f "$SRC/config" "$HOME/.config/fcitx5/config"
fi

if command -v swaymsg >/dev/null 2>&1; then
  swaymsg "input type:keyboard xkb_layout latam" >/dev/null 2>&1 || true
fi

if ! pgrep -x fcitx5 >/dev/null 2>&1; then
  if [ -f "$SRC/profile" ]; then
    cp -f "$SRC/profile" "$HOME/.config/fcitx5/profile"
  fi
  if command -v fcitx5 >/dev/null 2>&1; then
    fcitx5 -d >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
      fcitx5-remote >/dev/null 2>&1 && break
      sleep 0.1
    done
  fi
elif command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -r >/dev/null 2>&1 || true
  if [ -f "$SRC/config" ]; then
    cp -f "$SRC/config" "$HOME/.config/fcitx5/config"
  fi
fi

if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote -s keyboard-latam >/dev/null 2>&1 || true
  fcitx5-remote -c >/dev/null 2>&1 || true
fi

# Autor: Fravelz
