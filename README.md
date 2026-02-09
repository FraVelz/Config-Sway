# Configuración Sway (Fravelz)

Configuración de **Sway** alineada con los atajos y preferencias de **Hyprland** en Arch. No se borra tu configuración: se hace **backup** antes de copiar/sobrescribir archivos.

## Dónde está todo

| Qué                                      | Ubicación                            |
| ---------------------------------------- | ------------------------------------ |
| Config principal de Sway (en tu sistema) | `~/.config/sway/config`              |
| Waybar para Sway (en tu sistema)         | `~/.config/waybar/config-sway.jsonc` |
| Repo (fuente de verdad)                  | `./.config/`                         |
| Config suelta (legacy)                   | `./config`                           |

## Instalar desde este repo

La “fuente de verdad” para subir a Git es `./.config/`.

### Opción recomendada (instalador)

El script **no borra nada**: hace un backup completo de `~/.config` y luego copia el contenido de `./.config/` encima.

```bash
./install.sh
```

El backup queda como `~/.config.bak-YYYYMMDD-HHMMSS/`. Si estás dentro de Sway, puedes recargar con `swaymsg reload`.

### Opción manual (si no quieres usar el script)

```bash
cp -a ~/.config ~/.config.bak-$(date +%Y%m%d-%H%M%S)
cp -a ./.config/. ~/.config/
```

### Volver atrás (restaurar backup)

```bash
mv ~/.config ~/.config.tmp-$(date +%Y%m%d-%H%M%S)
cp -a ~/.config.bak-YYYYMMDD-HHMMSS ~/.config
```

## Atajos de teclado (Sway) — completos y en tablas

### Leyenda

| Tecla / alias | Significado                          |
| ------------- | ------------------------------------ |
| `Super`       | Tecla Windows (\($mod = Mod4\))      |
| `Shift`       | Mayús                                |
| `Ctrl`        | Control                              |
| `Alt`         | Alt (\(Mod1\))                       |
| `H J K L`     | Izquierda / Abajo / Arriba / Derecha |

### Lanzadores / apps

| Atajo         | Acción                   |
| ------------- | ------------------------ |
| `Super+Enter` | Abrir terminal **Kitty** |
| `Super+F`     | Abrir **Firefox**        |
| `Super+Z`     | **Flameshot** (GUI)      |

### Menús (Rofi)

| Atajo               | Acción                                                 | Script                                           |
| ------------------- | ------------------------------------------------------ | ------------------------------------------------ |
| `Super+D`           | Lanzador de apps                                       | `~/.config/rofi/selector-app.sh`                 |
| `Super+Q`           | Power menu (apagar/reiniciar/bloquear/suspender/salir) | `bash ~/.config/rofi/power-menu-sway.sh`         |
| `Super+A`           | Cambiar tema (aplica kitty/waybar/wallpaper, etc.)     | `bash ~/.config/rofi/theme-switcher-sway.sh`     |
| `Super+W`           | Cambiar wallpaper (Sway)                               | `bash ~/.config/rofi/wallpaper-switcher-sway.sh` |
| `Super+E`           | Menú de iconos/emoji                                   | `~/.config/rofi/menu-iconos.sh`                  |
| `Super+Shift+Enter` | Layout “hacker”                                        | `bash ~/.config/rofi/mode-hacker-sway.sh`        |

### Ventanas / layout

| Atajo           | Acción                                      |
| --------------- | ------------------------------------------- |
| `Super+U`       | Alternar **flotante**                       |
| `Super+C`       | Cerrar ventana (kill)                       |
| `Super+P`       | Pantalla completa (fullscreen toggle)       |
| `Super+O`       | Alternar layout split (horizontal/vertical) |
| `Super+M`       | Salir de Sway (exit)                        |
| `Super+Shift+R` | Recargar config de Sway (reload)            |

### Foco (navegación)

| Atajo     | Acción              |
| --------- | ------------------- |
| `Super+H` | Foco a la izquierda |
| `Super+J` | Foco abajo          |
| `Super+K` | Foco arriba         |
| `Super+L` | Foco a la derecha   |

### Mover ventana flotante

| Atajo                 | Acción                           |
| --------------------- | -------------------------------- |
| `Super+Shift+H/J/K/L` | Mover ventana flotante \(50px\)  |
| `Super+Alt+H/J/K/L`   | Mover ventana flotante \(150px\) |

### Redimensionar ventana flotante

| Atajo          | Acción                  |
| -------------- | ----------------------- |
| `Super+Ctrl+H` | Reducir ancho \(50px\)  |
| `Super+Ctrl+L` | Aumentar ancho \(50px\) |
| `Super+Ctrl+J` | Reducir alto \(50px\)   |
| `Super+Ctrl+K` | Aumentar alto \(50px\)  |

### Workspaces

| Atajo              | Acción                               |
| ------------------ | ------------------------------------ |
| `Super+1..9`       | Ir a workspace 1..9                  |
| `Super+0`          | Ir a workspace 10                    |
| `Super+Shift+1..9` | Mover ventana a workspace 1..9       |
| `Super+Shift+0`    | Mover ventana a workspace 10         |
| `Super+S`          | Ir al workspace **magic**            |
| `Super+Shift+S`    | Mover ventana al workspace **magic** |

### Multimedia (teclas XF86)

| Tecla                   | Acción             | Comando                                          |
| ----------------------- | ------------------ | ------------------------------------------------ |
| `XF86AudioRaiseVolume`  | Subir volumen      | `wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+` |
| `XF86AudioLowerVolume`  | Bajar volumen      | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-`      |
| `XF86AudioMute`         | Mute/unmute salida | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`     |
| `XF86AudioMicMute`      | Mute/unmute mic    | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`   |
| `XF86MonBrightnessUp`   | Subir brillo       | `brightnessctl -e 4 -n 2 set 5%+`                |
| `XF86MonBrightnessDown` | Bajar brillo       | `brightnessctl -e 4 -n 2 set 5%-`                |
| `XF86AudioNext`         | Siguiente pista    | `playerctl next`                                 |
| `XF86AudioPause`        | Play/Pause         | `playerctl play-pause`                           |
| `XF86AudioPlay`         | Play/Pause         | `playerctl play-pause`                           |
| `XF86AudioPrev`         | Pista anterior     | `playerctl previous`                             |

### Notificaciones (Mako)

| Atajo           | Acción            | Comando               |
| --------------- | ----------------- | --------------------- |
| `Super+N`       | Descartar todas   | `makoctl dismiss -a`  |
| `Super+Shift+N` | Alternar modo DND | `makoctl mode -a dnd` |

### Ratón (Sway)

| Atajo                     | Acción               |
| ------------------------- | -------------------- |
| `Super + Scroll arriba`   | Workspace siguiente  |
| `Super + Scroll abajo`    | Workspace anterior   |
| `Super + Click izquierdo` | Mover ventana (drag) |
| `Super + Click medio`     | Redimensionar (drag) |
| `Super + Click derecho`   | Alternar flotante    |

## Requisitos (Arch)

```bash
sudo pacman -S sway swaybg waybar mako kitty rofi flameshot nm-applet
# Opcional: brightnessctl, playerctl, blueman
```

## Wallpaper (Sway)

- Sway guarda el wallpaper actual en `~/.config/sway/wallpaper` (un archivo con la ruta a la imagen).
- Si ese archivo no existe, **hace fallback** a `~/.config/hypr/wallpaper.png` si existe.

## Iniciar Sway

- Desde **TTY:** ejecutar `sway` (mejor desde un script o el gestor de sesión).
- Variables de entorno recomendadas antes de lanzar Sway (si no las pone tu gestor de sesión):

```bash
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
```

Puedes ponerlas en `~/.config/environment.d/sway.conf` (formato `KEY=value`, una por línea) o en el script que ejecuta `sway`.

## Waybar con Sway

En Sway se usa la config específica que ya lanza el `config` de Sway:

- `waybar -c ~/.config/waybar/config-sway.jsonc`

Usa `sway/workspaces` y `sway/window` en lugar de los módulos de Hyprland. El estilo (CSS) es el mismo que tu waybar actual; solo cambia el nombre del archivo de config.

El clic del módulo de red abre el menú WiFi:

- `bash ~/.config/rofi/wifi.sh`

## Notas

- **Hyprland** no se ha modificado: toda tu config en `~/.config/hypr/` sigue igual.
- **Centrar ventana:** Sway no tiene comando nativo; en el config hay un atajo comentado por si quieres enganchar un script propio.
- **Scripts Hypr → Sway:** en `~/.config/rofi/` se añadieron versiones para Sway:
  - `autostart-sway.sh`
  - `power-menu-sway.sh`
  - `theme-switcher-sway.sh`
  - `wallpaper-switcher-sway.sh`
  - `mode-hacker-sway.sh`
