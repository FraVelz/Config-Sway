#!/bin/bash

# Variables  *********************************************************

theme="$HOME/.config/rofi/styles/power-menu.rasi"

lastlogin="`last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7`"
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

apagar=' '
reiniciar='󰦛 '
bloquear='󱅞'
suspender='󰽥'
cerrar_seccion='󰍂 '
cancelar=' '

# Funciones **********************************************************

# Rofi CMD

rofi_cmd() {
	rofi -dmenu \
		-p "$USER@$host" \
		-mesg " Desde: $lastlogin, Tiempo encendido: $uptime" \
		-theme ${theme}
}

# Pasa Variables a rofi dmenu

run_rofi() {
	echo -e "$cancelar\n$apagar\n$reiniciar\n$suspender\n$cerrar_seccion\n$bloquear" | rofi_cmd
}

# Acciones
chosen="$(run_rofi)"
case ${chosen} in
    $apagar)
		systemctl poweroff
        ;;

    $reiniciar)
		systemctl reboot
        ;;

    $bloquear)
		hyprlock
        ;;

    $suspender)
		mpc -q pause
		amixer set Master mute
		systemctl suspend
        ;;

    $cerrar_seccion)
		hyprctl dispatch exit
        ;;
esac

# Informacion ********************************************************

# Modificado por: Fravelz

# Author: Aditya Shakya (adi1090x)
# Github: @adi1090x
