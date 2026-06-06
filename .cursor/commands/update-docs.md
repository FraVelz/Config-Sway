# Actualizar documentación — Config-Sway

Usar con **`/update-docs`** cuando el usuario pida revisar o alinear docs.

## Archivos de documentación en este repo

- `README.md` — atajos, install/update, features principales
- `docs/estabilidad-memoria.md` — tuning Arch (earlyoom, zram, cpupower, scripts)

No hay par ES/EN obligatorio salvo que el usuario lo pida.

## Qué hacer

1. Leer el archivo indicado y contrastar con el **código real** (sway config, scripts, `system/`, timers).
2. Corregir ortografía/redacción en español sin ampliar alcance sin permiso.
3. Actualizar rutas, comandos y tablas si el repo cambió.
4. Si tocas `docs/estabilidad-memoria.md`, verificar que coincida con `scripts/setup-estabilidad-memoria.sh` y `system/`.

## Restricciones

- No inventar features no presentes en el repo.
- No commitear salvo petición explícita.
- Respuesta al usuario en **español**.
