#!/bin/bash

sleep 3
hyprctl dispatch workspace 1 
sleep 0.5
firefox &

sleep 2
hyprctl dispatch workspace 2 
sleep 1
code &

sleep 2

hyprctl dispatch workspace 3 
sleep 1
kitty &

# Autor: Fravelz
