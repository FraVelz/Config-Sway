#!/bin/bash

# ============================================================================
# THEME SWITCHER - Sistema mejorado de gestión de temas
# ============================================================================
# Este script permite cambiar entre temas de forma modular.
# Los temas pueden ser:
#   - Modulares: Solo colores y override específicos
#   - Independientes: Tienen su propio hyprland.conf completo (ej: Windows10)
# ============================================================================

set -uo pipefail

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

TEMAS_DIR="$HOME/.config/themes"
HYPR_CONFIG="$HOME/.config/hypr"
THEME_OVERRIDE="$HYPR_CONFIG/conf.d/theme-override.conf"
ROFI_THEME="$HOME/.config/rofi/styles/theme-switcher.rasi"

# ============================================================================
# FUNCIONES DE UTILIDAD
# ============================================================================

print_error() {
    echo "❌ Error: $1" >&2
    notify-send -u critical "Theme Switcher Error" "$1" 2>/dev/null || true
}

print_warning() {
    echo "⚠️  Advertencia: $1" >&2
    notify-send -u normal "Theme Switcher" "$1" 2>/dev/null || true
}

print_info() {
    echo "ℹ️  $1"
}

# Verificar que las herramientas necesarias estén disponibles
check_dependencies() {
    local missing=()
    
    if ! command -v rofi >/dev/null 2>&1; then
        missing+=("rofi")
    fi
    
    if ! command -v hyprctl >/dev/null 2>&1; then
        missing+=("hyprctl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq no está instalado. La detección de monitores puede fallar."
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Faltan dependencias: ${missing[*]}"
        exit 1
    fi
}

# Obtener lista de monitores
get_monitors() {
    if command -v jq >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Buscar wallpaper del tema
find_wallpaper() {
    local theme_dir="$1"
    local wallpaper=""
    
    # Buscar en diferentes formatos y ubicaciones
    for ext in jpg png webp; do
        if [ -f "$theme_dir/hypr/wallpaper.$ext" ]; then
            wallpaper="$theme_dir/hypr/wallpaper.$ext"
            break
        fi
    done
    
    echo "$wallpaper"
}

# Generar configuración de hyprpaper
generate_hyprpaper_config() {
    local wallpaper="$1"
    local config_file="$HYPR_CONFIG/hyprpaper.conf"
    
    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
        print_warning "Wallpaper no válido: $wallpaper"
        return 1
    fi
    
    local monitors
    monitors=$(get_monitors)
    
    # Crear directorio si no existe
    mkdir -p "$(dirname "$config_file")"
    
    {
        echo "# ============================================================================"
        echo "# HYPRPAPER CONFIGURATION - Generado por theme-switcher.sh"
        echo "# ============================================================================"
        echo "# Este archivo se sobrescribe automáticamente al cambiar temas"
        echo "# ============================================================================"
        echo ""
        echo "preload = $wallpaper"
        
        if [ -n "$monitors" ]; then
            # Configurar para cada monitor
            while IFS= read -r monitor; do
                [ -n "$monitor" ] && echo "wallpaper = $monitor,$wallpaper"
            done <<< "$monitors"
        else
            # Sintaxis genérica si no se pueden detectar monitores
            echo "wallpaper = ,$wallpaper"
        fi
    } > "$config_file"
    
    return 0
}

# Recargar hyprpaper
reload_hyprpaper() {
    local wallpaper="$1"
    
    # Matar hyprpaper si está corriendo
    killall hyprpaper 2>/dev/null || true
    sleep 0.3
    
    # Iniciar hyprpaper
    hyprpaper >/dev/null 2>&1 & disown
    
    # Esperar a que inicie
    sleep 0.5
    
    # Intentar forzar recarga del wallpaper si es posible
    if [ -n "$wallpaper" ] && [ -f "$wallpaper" ] && command -v hyprctl >/dev/null 2>&1; then
        local monitors
        monitors=$(get_monitors)
        
        if [ -n "$monitors" ]; then
            while IFS= read -r monitor; do
                [ -n "$monitor" ] && hyprctl hyprpaper wallpaper "$monitor,$wallpaper" 2>/dev/null || true
            done <<< "$monitors"
        fi
    fi
}

# Copiar configuración de aplicación
copy_app_config() {
    local source_dir="$1"
    local dest_dir="$2"
    local app_name="$3"
    
    if [ ! -d "$source_dir" ]; then
        return 0  # No hay configuración para esta app, está bien
    fi
    
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
    fi
    
    if cp -r "$source_dir"/* "$dest_dir/" 2>/dev/null; then
        print_info "Configuración de $app_name aplicada"
        return 0
    else
        print_warning "No se pudo copiar configuración de $app_name"
        return 1
    fi
}

# ============================================================================
# VALIDACIONES INICIALES
# ============================================================================

check_dependencies

# Verificar que el directorio de temas exista
if [ ! -d "$TEMAS_DIR" ]; then
    print_error "Directorio de temas no encontrado: $TEMAS_DIR"
    exit 1
fi

# Verificar que el directorio de configuración de hypr exista
if [ ! -d "$HYPR_CONFIG" ]; then
    print_error "Directorio de configuración de Hyprland no encontrado: $HYPR_CONFIG"
    exit 1
fi

# Crear directorio conf.d si no existe
mkdir -p "$HYPR_CONFIG/conf.d"

# ============================================================================
# MOSTRAR MENÚ CON ROFI
# ============================================================================

OPCIONES=$(mktemp)
trap 'rm -f "$OPCIONES"' EXIT

# Contar temas disponibles
theme_count=0

for theme_dir in "$TEMAS_DIR"/*; do
    if [ ! -d "$theme_dir" ]; then
        continue
    fi
    
    theme_name=$(basename "$theme_dir")
    
    # Buscar imagen de preview (wallpaper del tema)
    preview_img=""
    for ext in jpg png webp; do
        if [ -f "$theme_dir/hypr/wallpaper.$ext" ]; then
            preview_img="$theme_dir/hypr/wallpaper.$ext"
            break
        fi
    done
    
    # Si no hay preview, usar una imagen por defecto o el nombre del tema
    if [ -z "$preview_img" ]; then
        preview_img="$theme_dir"  # Rofi puede usar el directorio como fallback
    fi
    
    # Agregar al archivo de opciones
    printf '%s\0icon\x1f%s\n' "$theme_name" "$preview_img" >> "$OPCIONES"
    theme_count=$((theme_count + 1))
done

# Verificar que hay temas disponibles
if [ $theme_count -eq 0 ]; then
    print_error "No se encontraron temas en: $TEMAS_DIR"
    exit 1
fi

# Mostrar menú con rofi
if [ ! -s "$OPCIONES" ]; then
    print_error "No hay temas disponibles para mostrar"
    exit 1
fi

# Mostrar menú con rofi
# Nota: rofi envía la selección a stdout y errores a stderr
# Solo capturamos stdout para evitar que errores se interpreten como selección
TEMA=$(cat "$OPCIONES" | rofi -i -dmenu -show-icons -theme "$ROFI_THEME" 2>/dev/null || echo "")

# Si el usuario cancela o no selecciona nada
if [ -z "$TEMA" ] || [ "$TEMA" = "" ]; then
    exit 0
fi

# Limpiar el tema seleccionado (eliminar espacios en blanco)
TEMA=$(echo "$TEMA" | xargs)

# Si después de limpiar está vacío, salir
if [ -z "$TEMA" ]; then
    exit 0
fi

# ============================================================================
# VALIDAR TEMA SELECCIONADO
# ============================================================================

ELEGIDO="$TEMAS_DIR/$TEMA"

if [ ! -d "$ELEGIDO" ]; then
    print_error "Tema '$TEMA' no encontrado en: $ELEGIDO"
    exit 1
fi

print_info "Aplicando tema: $TEMA"

# ============================================================================
# DETECTAR TIPO DE TEMA
# ============================================================================

TEMA_INDEPENDIENTE=false
if [ -f "$ELEGIDO/hypr/hyprland.conf" ]; then
    TEMA_INDEPENDIENTE=true
    print_info "Tema independiente detectado"
fi

# ============================================================================
# APLICAR CONFIGURACIÓN DE HYPRLAND
# ============================================================================

if [ "$TEMA_INDEPENDIENTE" = true ]; then
    # TEMA INDEPENDIENTE: Solo crear mensaje en override
    {
        echo "# ============================================================================"
        echo "# THEME OVERRIDE - Tema Independiente: $TEMA"
        echo "# ============================================================================"
        echo "# Este tema usa su propio hyprland.conf completo"
        echo "# Para aplicar este tema completamente, copia manualmente:"
        echo "# cp $ELEGIDO/hypr/hyprland.conf $HYPR_CONFIG/hyprland.conf"
        echo "# ============================================================================"
    } > "$THEME_OVERRIDE"
    
    print_warning "Tema independiente requiere configuración manual. Ver: $THEME_OVERRIDE"
else
    # TEMA MODULAR: Copiar colors.conf y crear override
    if [ -f "$ELEGIDO/hypr/colors.conf" ]; then
        if cp "$ELEGIDO/hypr/colors.conf" "$HYPR_CONFIG/colors.conf" 2>/dev/null; then
            print_info "Colores del tema aplicados"
        else
            print_warning "No se pudo copiar colors.conf"
        fi
    else
        print_warning "No se encontró colors.conf en el tema '$TEMA'"
    fi
    
    # Crear archivo de override del tema
    {
        echo "# ============================================================================"
        echo "# THEME OVERRIDE - Tema: $TEMA"
        echo "# ============================================================================"
        echo "# Generado automáticamente por theme-switcher.sh"
        echo "# ============================================================================"
        echo ""
        
        # Si el tema tiene un archivo theme-override.conf, incluirlo
        if [ -f "$ELEGIDO/hypr/theme-override.conf" ]; then
            echo "# Override específico del tema:"
            cat "$ELEGIDO/hypr/theme-override.conf"
            echo ""
        fi
        
        # Si el tema tiene un archivo general.conf, puede sobrescribir configuraciones
        if [ -f "$ELEGIDO/hypr/general.conf" ]; then
            echo "# Configuración general del tema:"
            cat "$ELEGIDO/hypr/general.conf"
        fi
    } > "$THEME_OVERRIDE"
fi

# ============================================================================
# CAMBIAR WALLPAPER
# ============================================================================

WALL=$(find_wallpaper "$ELEGIDO")

if [ -n "${WALL:-}" ] && [ -f "${WALL:-}" ]; then
    if generate_hyprpaper_config "$WALL"; then
        print_info "Wallpaper configurado: $(basename "$WALL")"
    else
        print_warning "No se pudo generar configuración de hyprpaper"
    fi
else
    print_warning "No se encontró wallpaper para el tema '$TEMA'"
    WALL=""  # Asegurar que WALL esté definido
fi

# ============================================================================
# APLICAR CONFIGURACIONES DE OTRAS APLICACIONES
# ============================================================================

# Kitty
copy_app_config "$ELEGIDO/kitty" "$HOME/.config/kitty" "Kitty"

# Waybar
copy_app_config "$ELEGIDO/waybar" "$HOME/.config/waybar" "Waybar"

# Rofi-Style (comentado por defecto)
# copy_app_config "$ELEGIDO/rofi-style" "$HOME/.config/rofi/styles" "Rofi"

# ============================================================================
# RECARGAR CONFIGURACIÓN
# ============================================================================

print_info "Recargando configuración..."

# Recargar Waybar
if command -v waybar >/dev/null 2>&1; then
    killall waybar 2>/dev/null || true
    sleep 0.2
    waybar >/dev/null 2>&1 & disown
    print_info "Waybar recargado"
fi

# Recargar Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload 2>/dev/null; then
        print_info "Hyprland recargado"
    else
        print_warning "Error al recargar Hyprland"
    fi
else
    print_warning "hyprctl no disponible, no se puede recargar Hyprland"
fi

# Recargar hyprpaper
if [ -n "${WALL:-}" ] && [ -f "${WALL:-}" ]; then
    reload_hyprpaper "$WALL"
    print_info "Hyprpaper recargado"
else
    # Recargar hyprpaper sin wallpaper específico
    killall hyprpaper 2>/dev/null || true
    sleep 0.3
    hyprpaper >/dev/null 2>&1 & disown
fi

# ============================================================================
# NOTIFICACIÓN FINAL
# ============================================================================

notify-send -u normal "Theme Switcher" "Tema cambiado a: $TEMA" 2>/dev/null || true

print_info "✅ Tema '$TEMA' aplicado correctamente"

# Autor: Fravelz
