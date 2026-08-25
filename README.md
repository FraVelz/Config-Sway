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

### Arch vacío (recomendado): `./install.sh`

Requisitos: usuario con **sudo**, red y `git`. No ejecutes el script como root.

```bash
git clone <url-de-este-repo> && cd Config-Sway
./install.sh                 # desktop + SDDM astronaut + OMZ + yay + pyside-calc + update.sh
./install.sh --memory        # además earlyoom/zram (opcional; zram aplica tras reboot)
sudo reboot                  # login en SDDM → sesión Sway
```

Flags: `--no-sddm`, `--no-yay`, `--no-omz`, `--no-calc`, `--help`.

`install.sh` pide sudo (contraseña), instala paquetes, habilita NetworkManager/bluetooth/SDDM, copia el tema astronaut vendido en el repo, clona Oh My Zsh y plugins, instala yay, clona [pyside-calc](https://github.com/FraVelz/pyside-calc) en `~/Documentos/personal/pyside-calc` y luego corre `update.sh`.

**Límites (no se auto-configuran):** teclado **latam**; apagado automático a las **21:00** (hora del sistema); **NVIDIA** hay que instalarlo a mano; `Alt+Space` (jarvis) solo funciona si existe `~/.local/bin/jarvis`.

### Solo dotfiles (cualquier distro): `update.sh`

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

## Documentación

- [Estabilidad de memoria (Arch)](docs/estabilidad-memoria.md) — tuning earlyoom, zram, swappiness y servicios.
- Aplicar en el sistema: `sudo ./scripts/setup-estabilidad-memoria.sh --phase all --reboot`

### Notificaciones con sonido

SwayNC ejecuta `~/.config/scripts/notification-sound.sh` al recibir cada notificación (sonido por defecto: `message.oga`; críticas: `bell.oga`). Tras cambiar la config: `swaync-client --reload-config`.

### Apagado automático (21:00 hora local)

Timer de usuario `shutdown-countdown.timer`: a las **20:57** abre un overlay flotante (Kitty) con cuenta atrás de **3 minutos**; a las **21:00** apaga el PC. Usa la **hora del sistema** (Colombia si `timedatectl` está en `America/Bogota`).

- Cancelar esa noche: pulsa **`c`** en el overlay.
- Desactivar: `systemctl --user disable --now shutdown-countdown.timer`
- Probar ahora: `systemctl --user start shutdown-countdown.service`

Variables opcionales en el servicio: `SHUTDOWN_HOUR`, `SHUTDOWN_MINUTE`, `WARN_SECONDS`.

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

### Menús (Rofi) y calculadora

Los scripts de rofi viven en `~/.config/rofi/scripts/` (y los scripts generales en `~/.config/scripts/`).

| Atajo               | Acción                                                 | Script |
| ------------------- | ------------------------------------------------------ | ------ |
| `Super+D`           | Lanzador de apps (`drun`, tema `selector-app.rasi`)    | `~/.config/rofi/scripts/selector-app.sh` |
| `Super+=`           | Calculadora PySide (expresión → resultado; copia al portapapeles) | `~/.local/bin/pyside-calc` |
| `Super+Q`           | Power menu (apagar/reiniciar/bloquear/suspender/salir) | `~/.config/rofi/scripts/power-menu.sh` |
| `Super+A`           | Cambiar tema (aplica sway/kitty/waybar/rofi/wallpaper) | `~/.config/rofi/scripts/theme-switcher.sh` |
| `Super+W`           | Cambiar wallpaper (Sway)                               | `~/.config/rofi/scripts/wallpaper-switcher.sh` |
| `Super+E`           | Menú de iconos/emoji                                   | `~/.config/rofi/scripts/menu-iconos.sh` |
| `Alt+Shift+S`       | Menú de teclados/idiomas (ES/EN/中文/RU/한국어/BR)     | `~/.local/bin/teclado-rofi` |
| `Super+Shift+Enter` | Layout “hacker”                                        | `~/.config/scripts/mode-hacker.sh` |

**Windows 10 (claro/oscuro):** temas `Windows10-Dark` y `Windows10-Light`. Con uno de ellos activo, en terminal:

```bash
win-mode    # alterna Light ↔ Dark (solo si el tema actual es Win10)
```

En esos temas: click en el icono Win / “Buscar” abre el Start (Rofi abajo-izquierda); la campana abre el Action Center (SwayNC + quick actions).

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

### Audio sin salida (DroidCam / snd-aloop)

Si tienes **DroidCam** (`/etc/modules-load.d/droidcam.conf` carga `snd-aloop`), PipeWire puede elegir **Loopback** como salida por defecto en lugar de los altavoces del portátil. El repo incluye:

- `~/.config/wireplumber/wireplumber.conf.d/50-droidcam-loopback-priority.conf` — baja la prioridad del dispositivo Loopback
- `~/.config/scripts/fix-audio-defaults.sh` — al iniciar Sway, fuerza altavoces/mic reales si Loopback quedó por defecto

Comprobar: `wpctl status` (la salida marcada con `*` debe ser **Speaker**, no Loopback). Arreglo manual inmediato:

```bash
pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink
```

Si usas auriculares HDMI, elige la salida correcta con `pavucontrol` o `wpctl status` + `wpctl set-default <id>`.

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
  - Paleta: `rofi-style/_core/palette.rasi`.
  - Layouts opcionales: `selector-app.rasi`, `power-menu.rasi` (el switcher los copia a `rofi/styles/_core/` si existen).
- **`swaync/`** (opcional): `colors.css` (variables `:root` y `@define-color` para el panel y las notificaciones; alineado con los colores del waybar del tema). Opcional `config.json` si quieres textos/widgets distintos solo en ese tema (p. ej. Action Center Win10 con `buttons-grid`). Si el tema no trae `config.json`, se restaura `swaync/config-default.json`.

El theme switcher guarda el tema actual en:

- `~/.config/themes/.current`

Temas Windows 10: `Windows10-Dark` / `Windows10-Light`. Toggle: `~/.local/bin/win-mode` (requiere uno de esos como tema actual).

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

- `~/.config/xdg-desktop-portal/portals.conf` y `sway-portals.conf` (Screenshot/ScreenCast vía `wlr`)
- Unidad `~/.config/systemd/user/xdg-desktop-portal.service` sin depender de `graphical-session.target` (Sway desde TTY)
- `~/.config/flameshot/flameshot.ini` con bandeja desactivada (`disabledTrayIcon=true`; evita errores de QDBusTrayIcon)
- Líneas en `~/.config/sway/config` para importar el entorno a systemd/DBus y `QT_QPA_PLATFORM=wayland` en `Super+Z`
- Regla `for_window` para que Flameshot no se “tilee”

Si sigues con problemas, reinicia los portales (en tu usuario):

```bash
systemctl --user daemon-reload
systemctl --user restart xdg-desktop-portal xdg-desktop-portal-wlr
systemctl --user status xdg-desktop-portal
```

Comprueba que `org.freedesktop.portal.Desktop` esté activo (`busctl --user list | grep portal.Desktop`). Si el portal principal no arranca, suele ser porque Sway no activa `graphical-session.target`; la unidad de usuario del repo corrige eso.

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

1. **Arch nuevo:** `./install.sh` y reinicia a SDDM. **Solo configs:** `cd /ruta/a/Config-Sway && ./update.sh`
2. **Paquetes extra a mano:** `./install.sh` (o la lista de `pacman` más abajo). Calculadora `Super+=`: [pyside-calc](https://github.com/FraVelz/pyside-calc) → `~/.local/bin/pyside-calc`.
3. **Sway:** en la sesión, `swaymsg reload` o vuelve a entrar en Sway.
4. **SwayNC:** `systemctl --user status` no debe estar fallando; `swaync-client -t -sw` debe abrir el panel; `notify-send prueba` debe mostrar una notificación.
5. **Waybar:** icono de campana visible; clic abre SwayNC; clic derecho alterna no molestar (según `swaync-client`).
6. **Rofi:** `Super+D` lista aplicaciones.
7. **Calculadora:** `Super+=` abre pyside-calc; escribe `10+10` y debe aparecer el resultado; Enter copia al portapapeles.

## Iniciar Sway

- Tras `./install.sh`: reinicia y elige Sway en **SDDM** (tema astronaut).
- Desde **TTY** (`./install.sh --no-sddm`): ejecutar `sway`.
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

En Arch, `./install.sh` instala el desktop (Sway, PipeWire, NetworkManager, fuentes, Firefox, Neovim, SDDM, fcitx5, …), Oh My Zsh, yay y **pyside-calc**.

Si quieres los paquetes a mano con `pacman` (sin OMZ/yay/calc/SDDM theme):

```bash
sudo pacman -S sway swaybg waybar swaync kitty rofi flameshot network-manager-applet \
  networkmanager xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk grim \
  wl-clipboard mesa vulkan-intel vulkan-radeon xorg-xwayland qt6-wayland qt5-wayland \
  sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg rsync git base-devel \
  brightnessctl playerctl blueman bluez bluez-utils swaylock pacman-contrib which \
  ranger lsd bat fastfetch zsh firefox neovim python python-pip \
  pipewire pipewire-pulse pipewire-alsa wireplumber mpc alsa-utils libnotify bc \
  sound-theme-freedesktop sof-firmware polkit polkit-gnome xdg-user-dirs \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-nerd-fonts-symbols \
  fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons fcitx5-hangul
```
