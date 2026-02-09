#!/usr/bin/env bash

# Tiempo de Espera :v
sleep 0.5

# 1) Abrir primera ventana. (x)
hyprctl dispatch -- exec kitty --title a &
sleep 0.25

# 2) Abrir 'a' dividiendo el conjunto (a,b) (arriba, abajo).
hyprctl dispatch layoutmsg preselect r
hyprctl dispatch -- exec kitty --override font_size=12 --title c -- tty-clock -c -C 4
sleep 0.30

# 3) Abrir 'b'
hyprctl dispatch -- exec kitty --title d -- cava &

# Quedaria todo asi:
# ________
#|   | a  |
#| x |----|
#|   | b  |
#|___|____|

# Autor: Fravelz