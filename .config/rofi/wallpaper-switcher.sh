#!/usr/bin/env bash

# CONFIGURACIÓN INICIAL ********************************************************

FONDOS_DIR="$HOME/.config/wallpapers"
THUMBS_DIR="$HOME/.config/wallpapers/.thumbs"
HYPR_CONF="$HOME/.config/hypr/hyprpaper.conf"      # Archivo de configuración de Hyprpaper.
THEME_PATH="$HOME/.config/rofi/styles/wallpaper-switcher.rasi"  # Tema visual (estilo) usado por rofi.

# CREAR LISTA PARA ROFI ********************************************************

# Cada línea del archivo contendrá: "Nombre\0icon\x1f/ruta/al/icono"
# Esto es el formato especial que usa rofi para mostrar iconos junto a texto.

OPTIONS_FILE=$(mktemp)  # Crea un archivo temporal donde se guardarán las opciones.
trap 'rm -f "$OPTIONS_FILE"' EXIT  # Elimina el archivo temporal al salir del script.

for img in "$FONDOS_DIR"/*; do
    name=$(basename "$img")

    # Escribe en el archivo: nombre + separadores especiales para rofi + icono.
    printf '%s\0icon\x1f%s\n' "$name" "$img" >> "$OPTIONS_FILE"
done

# SI NO HAY FONDOS, AVISAR

if [ ! -s "$OPTIONS_FILE" ]; then
    notify-send "Wallpaper switcher: No se encontraron imágenes en $FONDOS_DIR"
    exit 0
fi

# MOSTRAR MENÚ CON ROFI ********************************************************

# -dmenu → modo de menú simple
# -show-icons → muestra miniaturas
# -p → texto del prompt
# -theme → archivo .rasi del estilo personalizado

FONDO=$(cat "$OPTIONS_FILE" | rofi -dmenu -show-icons -p "> " -theme "$THEME_PATH")

# Si el usuario cierra rofi sin seleccionar nada, salir sin hacer nada.
[ -z "${FONDO:-}" ] && exit 0

# CAMBIAR EL FONDO *************************************************************

WALL="$FONDOS_DIR/$FONDO"
if [ ! -f "$WALL" ]; then
    notify-send "Wallpaper switcher Archivo no encontrado: $WALL"
    exit 1
fi

# Sobrescribe la configuración de hyprpaper con la nueva imagen seleccionada.
# Obtener lista de monitores
MONITORS=$(hyprctl monitors -j | jq -r '.[].name' 2>/dev/null || echo "")

if [ -z "$MONITORS" ]; then
    # Si no se pueden obtener monitores, usar sintaxis genérica
    cat > "$HYPR_CONF" <<EOF
preload = $WALL
wallpaper = ,$WALL
EOF
else
    # Crear configuración con cada monitor
    {
        echo "preload = $WALL"
        for monitor in $MONITORS; do
            echo "wallpaper = $monitor,$WALL"
        done
    } > "$HYPR_CONF"
fi

# RECARGAR HYPRPAPER ***********************************************************

killall hyprpaper 2>/dev/null
sleep 0.5
hyprpaper & disown
sleep 1

# Forzar recarga del wallpaper usando hyprctl si está disponible
if command -v hyprctl >/dev/null 2>&1; then
    for monitor in $MONITORS; do
        hyprctl hyprpaper wallpaper "$monitor,$WALL" 2>/dev/null || true
    done
fi

notify-send -i "$WALL" "Wallpaper cambiado: $FONDO"

# Autor: Fravelz
