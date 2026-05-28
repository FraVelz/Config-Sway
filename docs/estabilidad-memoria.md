# Estabilidad de memoria (Arch Linux + Sway)

Documentación de los cambios de sistema aplicados para reducir congelamientos por agotamiento de RAM y zram. Los archivos viven en `/etc` y se aplican **manualmente**; este documento es la referencia en el repo Config-Sway.

**Auditoría de referencia:** 2026-05-28  
**Aplicación documentada:** pendiente — ejecutar el script con sudo (ver abajo)

---

## Aplicar cambios (rápido)

Desde la raíz del repo Config-Sway:

```bash
# Fase 1 (sin reinicio)
sudo ./scripts/setup-estabilidad-memoria.sh --phase 1

# Fase 2 + reinicio (zram 8 GiB)
sudo ./scripts/setup-estabilidad-memoria.sh --phase 2 --reboot

# O todo en un solo paso (Fase 1, escribe zram, reinicia)
sudo ./scripts/setup-estabilidad-memoria.sh --phase all --reboot
```

Archivos de referencia (copiados por el script a `/etc`):

| Repo | Sistema |
|------|---------|
| [`system/etc/default/earlyoom`](../system/etc/default/earlyoom) | `/etc/default/earlyoom` |
| [`system/etc/sysctl.d/99-swappiness.conf`](../system/etc/sysctl.d/99-swappiness.conf) | `/etc/sysctl.d/99-swappiness.conf` |
| [`system/etc/default/cpupower-service.conf`](../system/etc/default/cpupower-service.conf) | `/etc/default/cpupower-service.conf` |
| [`system/etc/systemd/zram-generator.conf`](../system/etc/systemd/zram-generator.conf) | `/etc/systemd/zram-generator.conf` |

Comprobar sin modificar nada: `sudo ./scripts/setup-estabilidad-memoria.sh --verify`

---

## Resumen

Los microfreezes y congelamientos temporales **no se debieron a Sway ni a la GPU**, sino a **presión extrema de memoria**:

- RAM de 16 GiB saturada con Cursor (~4,9 GiB), Firefox (~4 GiB) y herramientas de desarrollo.
- zram de 4 GiB llegó a **`Free swap = 0kB`**.
- El kernel activó OOM killer (múltiples procesos `electron` y `Web Content` / Firefox).
- Errores `Write-error on swap-device` en zram durante el colapso.

**Objetivo del tuning:** actuar antes del OOM duro (earlyoom), ampliar swap comprimido (zram 8 GiB), reducir swap prematuro (swappiness) y mejorar respuesta de CPU bajo carga (schedutil), sin tocar la configuración de Sway.

---

## Hardware de referencia

| Componente | Valor |
|------------|-------|
| Equipo | Acer Aspire AL16-51P |
| CPU | Intel Core i7-1255U (12 hilos) |
| RAM | 16 GiB |
| GPU | Intel UHD Graphics (i915) |
| Disco | NVMe 512 GiB (`/dev/nvme0n1p2`, ext4) |
| Compositor | Sway (Wayland) |

---

## Tabla de cambios

| Cambio | Archivo / unidad | Antes | Después | Prioridad | Reboot |
|--------|------------------|-------|---------|-----------|--------|
| Docker bajo demanda | `docker.service` | enabled + running | disabled + stopped | Recomendado | No |
| PostgreSQL bajo demanda | `postgresql.service` | enabled + running | disabled + stopped | Recomendado | No |
| OOM preventivo | `earlyoom.service`, `/etc/default/earlyoom` | inactivo | `EARLYOOM_ARGS="-r 60 -m 10"` | Crítico | No |
| Swappiness | `/etc/sysctl.d/99-swappiness.conf` | `60` (default) | `15` | Recomendado | No |
| Governor CPU | `cpupower.service`, `/etc/default/cpupower-service.conf` | `powersave` | `schedutil` o `performance`* | Recomendado | No |

\* En CPUs Intel con `intel_pstate` (p. ej. i7-1255U) solo existen `performance` y `powersave`; el script usa `performance` como alternativa a `schedutil`.
| Tamaño zram | `/etc/systemd/zram-generator.conf` | ~4 GiB (default) | `min(ram/2, 8192)` → 8 GiB | Crítico | **Sí** |

**Nota:** zswap permanece activo (`enabled=Y`). No se modificó en esta fase.

---

## Fase 1 — Cambios sin reinicio

### 1.1 Docker y PostgreSQL bajo demanda

**Por qué:** uso ocasional; liberan RAM y reducen procesos en reclaim (containerd apareció en la cadena OOM).

```bash
sudo systemctl stop docker postgresql
sudo systemctl disable docker postgresql
```

**Arrancar cuando los necesites:**

```bash
sudo systemctl start postgresql   # primero la DB si aplica
sudo systemctl start docker
```

**Riesgo:** ninguno si no los usas en esa sesión.  
**Beneficio:** ~100–300 MiB+ y menos contención en presión de memoria.

---

### 1.2 earlyoom (crítico)

**Por qué:** sin `earlyoom` ni `systemd-oomd`, el sistema llegaba a freeze + OOM del kernel.

```bash
sudo pacman -S --needed earlyoom
sudo tee /etc/default/earlyoom <<'EOF'
EARLYOOM_ARGS="-r 60 -m 10"
EOF
sudo systemctl enable --now earlyoom
systemctl status earlyoom --no-pager
```

| Parámetro | Significado |
|-----------|-------------|
| `-r 60` | Actuar cuando quede ~10 % de RAM libre (aprox.) |
| `-m 10` | Umbral mínimo de RAM |

**Riesgo:** puede cerrar Cursor o Firefox antes de un freeze total (comportamiento deseado).  
**Beneficio:** stalls más cortos; menos “sistema muerto” prolongado.

---

### 1.3 swappiness

**Por qué:** con `60`, el kernel empujaba a zram antes de tiempo en carga de desarrollo.

```bash
echo 'vm.swappiness=15' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system
sysctl vm.swappiness
```

**Riesgo:** bajo; si la RAM se llena, earlyoom actúa antes.  
**Beneficio:** aplicaciones interactivas permanecen más tiempo en RAM.

---

### 1.4 Governor CPU (schedutil o performance)

**Por qué:** `powersave` con throttling elevado empeoraba latencia bajo carga + swap.

En este portátil (`intel_pstate`) solo hay `performance` y `powersave`; `schedutil` no está disponible. El script elige `schedutil` si existe; si no, `performance`.

```bash
sudo pacman -S --needed cpupower
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
# Si aparece schedutil:
sudo cpupower frequency-set -g schedutil
# Si solo performance/powersave (Intel típico):
sudo cpupower frequency-set -g performance
echo "GOVERNOR='performance'" | sudo tee /etc/default/cpupower-service.conf
sudo systemctl enable --now cpupower
sudo systemctl restart cpupower
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

**Riesgo:** mayor consumo en batería (`performance` más que `schedutil`).  
**Beneficio:** CPU más reactiva en picos (compilación, IA, reclaim).

---

## Fase 2 — zram 8 GiB (requiere reinicio)

**Por qué:** el journal registró `Free swap = 0kB` con zram de 4 GiB.

```bash
sudo mkdir -p /etc/systemd
sudo tee /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
sudo reboot
```

**Contenido de `/etc/systemd/zram-generator.conf`:**

```ini
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
```

### Verificación post-reboot

```bash
zramctl
swapon --show
free -h
```

Se espera `DISKSIZE` de zram0 cercano a **8G** y swap activo en `/dev/zram0`.

**Riesgo:** más CPU en compresión (ya presente bajo presión de memoria).  
**Beneficio:** más margen antes de saturar swap comprimido.

---

## Verificación mínima

```bash
# Servicios
systemctl is-active earlyoom cpupower
systemctl is-enabled docker postgresql   # debe ser "disabled"

# Memoria y swap
free -h
swapon --show
sysctl vm.swappiness

# Governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# OOM en la sesión actual (idealmente 0 en uso normal)
journalctl -b | grep -ci 'out of memory'
```

---

## Rollback

Revertir **solo** lo que corresponda.

### earlyoom

```bash
sudo systemctl disable --now earlyoom
sudo pacman -Rns earlyoom
sudo rm -f /etc/default/earlyoom
```

### swappiness

```bash
sudo rm -f /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system
```

### cpupower

```bash
sudo cpupower frequency-set -g powersave
sudo rm -f /etc/default/cpupower-service.conf /etc/default/cpupower
sudo systemctl disable --now cpupower
```

### zram (volver al default del generador)

```bash
sudo rm -f /etc/systemd/zram-generator.conf
sudo reboot
```

### Docker y PostgreSQL (arranque automático)

```bash
sudo systemctl enable --now docker postgresql
```

---

## Referencia de auditoría (2026-05-28)

Hallazgos clave que motivaron este documento:

| Evidencia | Detalle |
|-----------|---------|
| OOM | Varios `Out of memory` en la misma sesión (`electron`, `Web Content`, `Isolated Web Co`) |
| Swap agotado | `Free swap = 0kB`, `kswapd0: page allocation failure` |
| zram | `Write-error on swap-device (253:0:...)` durante el pico |
| PSI memoria | `full avg300` ~5,7–6,6 % (presión sostenida) |
| Sway / i915 | Sin hangs del compositor; `Purging GPU memory` fue efecto del OOM |
| Carga | `load average` 15 min ~15 en pico (12 hilos) |

**Causa raíz:** agotamiento de RAM + zram al 100 % → reclaim agresivo → OOM → congelamientos percibidos.

---

## Fuera de alcance

- Cambios en `.config/sway/config` (no relacionados con memoria).
- Tuning GPU/i915 (sin evidencia de hang en la auditoría).
- Ajustes de Cursor, Firefox, webpack o monitoreo continuo post-instalación.

---

## Historial de aplicación

| Fecha | Fase | Notas |
|-------|------|-------|
| | Fase 1 | |
| | Fase 2 + reboot | |
