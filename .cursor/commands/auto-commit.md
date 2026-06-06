# Autocommit — Config-Sway

Usar cuando el usuario pida **hacer commit**. Mensajes al estilo del `git log` del repo. **No** push salvo petición explícita.

## Prohibido (co-autor Cursor)

Cumplir [`.cursor/rules/git-commits.mdc`](../rules/git-commits.mdc): sin `Co-authored-by: Cursor`, commit con `-F`, verificar con `git log -1 --format=%B` antes de push.

## Antes de commitear

1. `git status` / `git diff` / `git log -12 --oneline`
2. No incluir secretos ni backups (`*.bak`, `.env`).

## Estilo de mensaje (este repo)

Primera línea = tipo + resumen. Detalle en líneas siguientes con **4 espacios** de indentación (patrón habitual):

```text
feat: add notification sounds and shutdown countdown at 21:00
    (swaync notification-sound.sh, timer 20:57 overlay + poweroff)
    (responsive kitty overlay, sway window rules, update.sh enable timer)
update: readme (sound notifications and auto shutdown docs)
```

También válido:

```text
fix(sway): shutdown-countdown overlay without title bar
    (remove default_border normal, use border pixel 2 only)
```

Tipos frecuentes: `feat`, `fix`, `update`, `add`, `chore`. Scopes opcionales: `sway`, `waybar`, `rofi`, `readme`, `scripts`.

## Commit

```bash
cat > /tmp/commit-msg.txt <<'EOF'
fix(sway): enable Super+U floating toggle

EOF
git add ...
git commit -F /tmp/commit-msg.txt
git log -1 --format=%B
```

Respuesta al usuario en **español**; mensaje de commit en **inglés** (como el historial reciente).
