# Configuración Sway (Fravelz)

Dotfiles para **Sway** (Wayland/wlroots) con atajos estilo Hyprland, **Waybar**, **Rofi**, y un sistema de **temas** que aplica colores y wallpaper de forma consistente.

Este repo está pensado para ser “**fuente de verdad**”: lo que esté dentro de `./.config/` y `./home/` es lo que se sincroniza a tu `$HOME`.

## Estructura del repo (qué se sincroniza)

| Carpeta/archivo (en el repo) | Destino (en tu sistema) | Qué contiene |
| --- | --- | --- |
| `./.config/` | `~/.config/` | Configs “gestionadas” (Sway, rofi, waybar, nvim, etc.) |
| `./home/` | `~/` | Dotfiles de primer nivel (ej. `~/.zshrc`) |
| `./.config/themes/<tema>/` | `~/.config/themes/<tema>/` | Recursos por tema (sway/waybar/kitty/rofi-style/wallpaper) |

## Cómo instalar / aplicar desde este repo

### Opción recomendada (Arch): `install.sh`

Instala dependencias con `pacman` y luego ejecuta `update.sh` para aplicar los dotfiles.

```bash
./install.sh
```

### Opción recomendada (cualquier distro): `update.sh`

Aplica los dotfiles del repo a tu `$HOME`.

```bash
./update.sh
```

#### Qué hace `update.sh` (importante)

- **Backup**: por defecto copia `~/.config` a `~/.config.bak-YYYYMMDD-HHMMSS/` antes de cambiar nada.
- **Sync gestionado**:
  - Sincroniza **solo** los top-level presentes en `./.config/` hacia `~/.config/` (con `rsync --delete`).
  - Sincroniza **solo** el primer nivel de `./home/` hacia tu `$HOME` (con `rsync --delete`).
- **Borrados controlados**: mantiene listas de “gestionado” en:
  - `~/.config/.config-sway-managed`
  - `~/.home-dots-managed`
  y elimina del destino lo que ya no exista en el repo (pero **solo** dentro de ese set).
- **Post-apply**: intenta recargar Sway (`swaymsg reload`), reiniciar portales y reiniciar Waybar.

Para aplicar **sin backup**:

```bash
./update.sh --no-backup
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

Los scripts de rofi viven en `~/.config/rofi/scripts/` (y los scripts generales en `~/.config/scripts/`).

| Atajo               | Acción                                                 | Script |
| ------------------- | ------------------------------------------------------ | ------ |
| `Super+D`           | Lanzador de apps                                       | `~/.config/rofi/scripts/selector-app.sh` |
| `Super+Q`           | Power menu (apagar/reiniciar/bloquear/suspender/salir) | `~/.config/rofi/scripts/power-menu.sh` |
| `Super+A`           | Cambiar tema (aplica sway/kitty/waybar/rofi/wallpaper) | `~/.config/rofi/scripts/theme-switcher.sh` |
| `Super+W`           | Cambiar wallpaper (Sway)                               | `~/.config/rofi/scripts/wallpaper-switcher.sh` |
| `Super+E`           | Menú de iconos/emoji                                   | `~/.config/rofi/scripts/menu-iconos.sh` |
| `Super+Shift+Enter` | Layout “hacker”                                        | `~/.config/scripts/mode-hacker.sh` |

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

## Temas (`~/.config/themes`)

Cada tema vive en `~/.config/themes/<tema>/` y puede incluir:

- **`sway/theme.conf`**: colores/bordes/gaps para Sway (se incluye desde `~/.config/sway/config`).
- **`waybar/`**: `config.jsonc`, `style.css`, `colors.css` (se genera `config-sway.jsonc` a partir del `config.jsonc` del tema).
- **`kitty/`**: config de Kitty.
- **`wallpaper.(png|jpg|webp)`**: wallpaper del tema.
- **`rofi-style/`** (opcional): estilos/paleta de rofi por tema.
  - En este repo, lo importante es la **paleta**: `rofi-style/_core/palette.rasi` (para cambiar colores sin tocar el layout).

El theme switcher guarda el tema actual en:

- `~/.config/themes/.current`

## Rofi: scripts, estilos y colores por tema

### Scripts

- Scripts de rofi: `~/.config/rofi/scripts/`
- Scripts generales (no rofi): `~/.config/scripts/`

### Estilos

- Estilos base: `~/.config/rofi/styles/`
- Estilos “core”: `~/.config/rofi/styles/_core/`

Los estilos “core” importan la paleta:

- `~/.config/rofi/styles/_core/palette.rasi`

### Paleta por tema (solo cambia colores)

Para que cada tema tenga su paleta propia, cada tema puede traer:

- `~/.config/themes/<tema>/rofi-style/_core/palette.rasi`

Cuando aplicas un tema con `theme-switcher.sh`, si existe esa paleta, se copia a:

- `~/.config/rofi/styles/_core/palette.rasi`

Eso hace que todos los menús de rofi se vean consistentes: **misma estructura/layout**, **distintos colores** según el tema.

### Imágenes (opcionales)

Algunos estilos/menús pueden usar imágenes en:

- `~/.config/rofi/images/arch-linux.png`
- `~/.config/rofi/images/arch-linux-2.webp`

Si no están, los scripts principales están preparados para funcionar igual (sin imagen).

## Waybar con Sway

En Sway se lanza Waybar con una config específica si existe; si no, cae a la default:

- `~/.config/waybar/config-sway.jsonc` (preferida)
- `~/.config/waybar/config.jsonc` (fallback)

Usa `sway/workspaces` y `sway/window` en lugar de los módulos de Hyprland.

El clic del módulo de red abre el menú WiFi:

- `bash ~/.config/rofi/scripts/wifi.sh`

## Flameshot en Wayland (Sway / wlroots)

Este repo incluye:

- `~/.config/xdg-desktop-portal/sway-portals.conf` (selecciona `wlr` para Screenshot/Screencast)
- Líneas en `~/.config/sway/config` para importar el entorno a systemd/DBus
- Regla `for_window` para que Flameshot no se “tilee”

Si sigues con problemas, reinicia los portales (en tu usuario):

```bash
systemctl --user restart xdg-desktop-portal xdg-desktop-portal-wlr
```

## Wallpaper (Sway)

- Sway guarda el wallpaper actual en `~/.config/sway/wallpaper` (un archivo con la ruta a la imagen).
- `~/.config/scripts/setwallpaper.sh` intenta:
  - usar esa ruta si existe,
  - si no, usar `~/.config/wallpapers/arch-linux-logo.webp` si existe,
  - si no, usar un color sólido.

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

## Requisitos (Arch)

En Arch, `install.sh` instala lo principal. Si quieres hacerlo manual:

```bash
sudo pacman -S sway swaybg waybar mako kitty rofi flameshot network-manager-applet \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim rsync \
  brightnessctl playerctl blueman swaylock ranger lsd bat fastfetch mpc alsa-utils libnotify
```
