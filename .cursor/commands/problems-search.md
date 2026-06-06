# Auditoría — Config-Sway (`/problems-search`)

Inventariar problemas en dotfiles y scripts. **No** commitear salvo petición explícita.

## Comprobaciones sugeridas

```bash
bash -n .config/scripts/*.sh scripts/*.sh
shellcheck .config/scripts/*.sh 2>/dev/null || true
./update.sh --no-backup   # solo si el usuario lo autoriza en entorno de prueba
sway -C -c .config/sway/config 2>&1 || true
systemctl --user list-timers --all
```

## Áreas por prioridad

| Nivel | Qué revisar |
|-------|-------------|
| **P0** | Scripts que apagan/reinician, `set -e` roto, paths systemd incorrectos, reglas sway inválidas |
| **P1** | Timers deshabilitados, desync repo vs README, `for_window` con `default_border normal` no pedido |
| **P2** | Duplicación local/repo, temas inconsistentes, swaync JSON inválido |
| **P3** | Typos en docs, comentarios obsoletos |

## Informe

Resumen P0→P3 en **español**, con rutas concretas y sugerencia de fix en una línea.
