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

**Rofi calculadora (`Super+=`):** el script [`selector-calc.sh`](.config/rofi/scripts/selector-calc.sh) abre solo el modo `calc` con [`rofi-calc.sh`](.config/rofi/scripts/rofi-calc.sh). En Arch conviene **`rofi-git`** (AUR) para que `ROFI_INPUT` llegue bien al modo script. Opcional: `./install.sh --rofi-git` o `yay -S rofi-git`.

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
| `Super+D`           | Lanzador de apps (`drun`, tema `selector-app.rasi`)    | `~/.config/rofi/scripts/selector-app.sh` |
| `Super+=`           | Calculadora Rofi (expresión → resultado; copia al portapapeles) | `~/.config/rofi/scripts/selector-calc.sh` |
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

### Notificaciones (SwayNC)

Centro de notificaciones con historial (panel lateral), agrupación y textos en español; config en `~/.config/swaync/`. Waybar muestra el icono de campana si está `swaync-client` (clic: abrir panel, clic derecho: alternar no molestar).

**Estilos:** el CSS final se arma con `_swaync-upstream.css` (copia del `style.css` de SwayNC), más **`colors-base.css`** o **`themes/<tema>/swaync/colors.css`**, y **`_swaync-pop.css`**: refuerzo de **notificaciones flotantes** (`notify-send`) con borde más marcado, sombra y halo de color (`--noti-accent-ring` acorde a cada tema), tipografía más grande y negrita en el título. Tras `./update.sh` se regenera `style.css` con esa base. Cada tema sustituye colores con **Super+A**; si tras un `./update.sh` vuelves al estilo base, vuelve a aplicar el tema con el switcher.

| Atajo              | Acción                         | Comando                    |
| ------------------ | ------------------------------ | -------------------------- |
| `Super+N`          | Cerrar todas las notificaciones | `swaync-client -C -sw`     |
| `Super+Shift+N`    | Alternar no molestar (DND)   | `swaync-client -d -sw`     |
| `Super+Ctrl+N`     | Abrir/cerrar panel (historial) | `swaync-client -t -sw`   |

No ejecutes otro daemon de notificaciones a la vez que **swaync** (conflicto por libnotify).

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
- **`swaync/`** (opcional): `colors.css` (variables `:root` y `@define-color` para el panel y las notificaciones; alineado con los colores del waybar del tema). Opcional `config.json` si quieres textos/widgets distintos solo en ese tema.

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

## Alertas de batería (80% / 20%)

- **Script:** `~/.config/scripts/battery-notify.sh` — lee la primera batería en sysfs (`/sys/class/power_supply/*/type == Battery`), usa `notify-send` (requiere **libnotify** y un daemon compatible, p. ej. **swaync**).
- **Umbrales:** aviso al **≥80%** solo mientras **carga** (“puedes desenchufar”); aviso al **≤20%** solo mientras **descarga** (“batería baja”). Con histéresis para no repetir el aviso hasta salir de la zona (por defecto reset al bajar de 75% o subir de 25% según corresponda).
- **Timer systemd (usuario):** `~/.config/systemd/user/battery-notify.timer` ejecuta el script cada **60 s**. Tras `./update.sh` se hace `daemon-reload` y `enable --now` del timer (si hay sesión `systemd --user`).
- **Variables opcionales** (para afinar sin editar el script): `BATTERY_NOTIFY_HIGH`, `BATTERY_NOTIFY_LOW`, `BATTERY_NOTIFY_HIGH_RESET`, `BATTERY_NOTIFY_LOW_RESET`.
- **Comprobar estado:** `systemctl --user status battery-notify.timer` y `systemctl --user list-timers --all | grep battery`.
- **Equipos sin batería** (torre): el script sale sin error y no notifica.

## Comprobar la instalación (tras `./update.sh`)

1. **Sincronizar el repo:** `cd /ruta/a/Config-Sway && ./update.sh`
2. **Paquetes:** `sudo pacman -S --needed swaync waybar rofi bc` (o `./install.sh`). Para la calculadora Rofi (`Super+=`): `./install.sh --rofi-git` o `yay -S rofi-git`.
3. **Sway:** en la sesión, `swaymsg reload` o vuelve a entrar en Sway.
4. **SwayNC:** `systemctl --user status` no debe estar fallando; `swaync-client -t -sw` debe abrir el panel; `notify-send prueba` debe mostrar una notificación.
5. **Waybar:** icono de campana visible; clic abre SwayNC; clic derecho alterna no molestar (según `swaync-client`).
6. **Rofi:** `Super+D` lista aplicaciones. `Super+=` abre la calculadora; escribe `10+10` y debe aparecer el resultado (recomendado **`rofi-git`**). Comprueba con `rofi -version` (build git).
7. **Versión de Rofi:** `rofi -version` — debería indicar commit/git si instalaste desde AUR.

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

En Arch, `install.sh` instala lo principal. Para **Rofi calculadora** (`Super+=`), conviene **`./install.sh --rofi-git`** (o `yay -S rofi-git`).

Si quieres hacerlo todo manual con `pacman`:

```bash
sudo pacman -S sway swaybg waybar swaync kitty rofi flameshot network-manager-applet \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim rsync \
  brightnessctl playerctl blueman swaylock ranger lsd bat fastfetch mpc alsa-utils libnotify bc
```

Y sustituye `rofi` por la versión AUR cuando quieras el modo script de la calculadora fiable:

```bash
yay -S rofi-git
```
