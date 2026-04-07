export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="afowler"

ENABLE_CORRECTION="true"

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
	zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh

function open_code {
  sleep 1 && code .
}

function  ggpush {
  git add .
  git commit -m "$1"
  git push
}

# Pronmpt configuration

function dir_icon {
	if [[ "$PWD" == "$HOME" ]]; then
		echo "%B%F{black}%f%b"
	else
		echo "%B%F{cyan}%f%b"
	fi
}

function parse_git_branch {
	local branch
	branch=$(git symbolic-ref --short HEAD 2> /dev/null)
	if [ -n "$branch" ]; then
		echo " [$branch]"
	fi
}

function a(){
  cd ~/Documentos/WEB/
  ranger
}

# create-astro: Astro + Tailwind + React + ESLint/Prettier → countdown → editor → pnpm dev
# Uso: create-astro <nombre-proyecto> [segundos-countdown]
#
# Personalizar segundos del contador:
#   1) Por defecto (si no pasas segundo arg): cambia el "3" en la línea de abajo.
#   2) En cada llamada: create-astro mi-proyecto 10   → 10 s
function create-astro(){
  local name="${1:?Uso: create-astro <nombre-proyecto> [segundos-countdown]}"
  local countdown_sec="${2:-3}"
  local step_ms=100
  local remaining_ms=$(( countdown_sec * 1000 ))
  local url="http://localhost:4321"

  pnpm create astro@latest "$name" -- --template minimal --yes || return 1
  cd "$name" || return 1

  pnpm astro add tailwind react --yes || return 1
  pnpm add -D eslint @eslint/js typescript-eslint eslint-plugin-astro globals eslint-config-prettier eslint-plugin-prettier prettier prettier-plugin-astro prettier-plugin-tailwindcss eslint-plugin-react eslint-plugin-react-hooks || return 1

  cat > eslint.config.mjs <<'EOF'
import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";
import astro from "eslint-plugin-astro";
import eslintConfigPrettier from "eslint-config-prettier";
import eslintPluginPrettier from "eslint-plugin-prettier";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...astro.configs["flat/recommended"],
  ...astro.configs["flat/jsx-a11y-recommended"],
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
  },
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    ...react.configs.flat["jsx-runtime"],
    plugins: {
      ...react.configs.flat["jsx-runtime"].plugins,
      ...reactHooks.configs.flat.recommended.plugins,
    },
    rules: {
      ...react.configs.flat["jsx-runtime"].rules,
      ...reactHooks.configs.flat.recommended.rules,
    },
    settings: {
      react: { version: "detect" },
    },
  },
  eslintConfigPrettier,
  {
    plugins: { prettier: eslintPluginPrettier },
    rules: { "prettier/prettier": "error" },
  },
  {
    ignores: ["dist/**", ".astro/**", "node_modules/**"],
  },
);
EOF

  cat > .prettierrc.mjs <<'EOF'
/** @type {import("prettier").Config} */
const config = {
  plugins: ["prettier-plugin-astro", "prettier-plugin-tailwindcss"],
  overrides: [{ files: "**/*.astro", options: { parser: "astro" } }],
};
export default config;
EOF

  cat > .prettierignore <<'EOF'
dist
.astro
node_modules
pnpm-lock.yaml
EOF

  node <<'NODE'
const fs = require("fs");
const path = "package.json";
const p = JSON.parse(fs.readFileSync(path, "utf8"));
Object.assign(p.scripts || {}, {
  check: "astro check",
  lint: "eslint .",
  "lint:fix": "eslint . --fix",
  format: "prettier --write .",
  "format:check": "prettier --check .",
  style: "pnpm format && pnpm lint:fix",
});
fs.writeFileSync(path, JSON.stringify(p, null, 2) + "\n");
NODE

  echo "Página web creada (Tailwind, React, ESLint, Prettier)."
  echo "Abriendo editor en ${countdown_sec} s (countdown en ms)..."
  echo ""

  while (( remaining_ms >= 0 )); do
    local s=$(( remaining_ms / 1000 ))
    local ms=$(( remaining_ms % 1000 ))
    printf '\r  ⏱  %d.%03d s → 0.000 s   ' "$s" "$ms"
    (( remaining_ms <= 0 )) && break
    sleep 0.1
    (( remaining_ms -= step_ms ))
  done

  printf '\r  ✓ Listo. Abriendo editor. Servidor: %s   \n' "$url"

  if command -v code &>/dev/null; then
    code .
  else
    echo "code (VS Code) no encontrado; omite abrir editor."
  fi
  pnpm run dev
}

function create-next() {
  local name="${1:?Uso: create-next <nombre-proyecto> [segundos-countdown]}"
  local countdown_sec="${2:-3}"
  local step_ms=100
  local remaining_ms=$(( countdown_sec * 1000 ))
  local url="http://localhost:3000"

  # Crear el proyecto Next.js de forma automática
  # Flags: --ts (TypeScript), --tailwind, --eslint, --app (App Router), --src-dir, --import-alias
  pnpm create next-app "$name" --ts --tailwind --eslint --app --src-dir --import-alias "@/*" --use-pnpm || return 1

  cd "$name" || return 1

  # prettier+eslint and config+plugin for work hand los dos, y {plugin de tw para organizar clases}
  pnpm add -D prettier eslint-config-prettier eslint-plugin-prettier prettier-plugin-tailwindcss || return 1
  # testing (with types of ts) and library for contructor utility cn
  pnpm add -D vitest @testing-library/react @testing-library/jest-dom jsdom clsx tailwind-merge || return 1

  mkdir -p ./src/components/layout
  mkdir -p ./src/components/ui
  mkdir -p ./src/features
  mkdir -p ./src/hooks
  mkdir -p ./src/services
  mkdir -p ./src/lib

  mkdir -p ./docs/es
  mkdir -p ./docs/en

  cat > ./src/lib/utils.ts <<'EOF'
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Merges class names and resolves Tailwind CSS conflicts.
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(...inputs));
}
EOF

  cat > README.en.md <<'EOF'
# {Project title}

[Version en español](README.md)

text description short.

![description](path/to/image.png)

---

## Table of Contents

{Table of Contents generate by Markdown All in One}

---

## {Titles...}

---

## Documentation

text documentation.

---

## Contributing

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Contact

For suggestions or bug reports, create an issue in the GitHub repository.

---

**Development:** Fravelz

**License:** {Licence}
EOF

  cat > README.md <<'EOF'
# {Titulo del proyecto}

[English Version](README.en.md)

Texto de descripcion corto.

![Descripción](ruta/a/imagen.png)

---

## Tabla de Contenidos

{Tabla de Contenidos generada por Markdown All in One}

---

## {Titulos...}

---

## Documentación

Texto de documentación.

---

## Contribución

1. Haz un fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Haz commit de tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## Contacto

Para sugerencias o reportes de bugs, crea un issue en el repositorio de GitHub.

---

**Desarrollo:** Fravelz

**Licencia:** {Licence}
EOF

  cat > .eslint.mjs <<'EOF'
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import eslintConfigPrettier from "eslint-config-prettier";
import eslintPluginPrettier from "eslint-plugin-prettier";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  eslintConfigPrettier,
  {
    plugins: { prettier: eslintPluginPrettier },
    rules: { "prettier/prettier": "error" },
  },
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
]);

export default eslintConfig;
EOF

  cat > .prettierrc.mjs <<'EOF'
/** @type {import("prettier").Config} */

const config = {
  plugins: ["prettier-plugin-tailwindcss"],
};

export default config;
EOF

  cat > .prettierignore <<'EOF'
.next
out
build
node_modules
pnpm-lock.yaml
EOF

  node <<'NODE'
const fs = require("fs");
const path = "package.json";
const p = JSON.parse(fs.readFileSync(path, "utf8"));
Object.assign(p.scripts || {}, {
  lint: "eslint .",
  "lint:fix": "eslint . --fix",
  format: "prettier --write .",
  "format:check": "prettier --check .",
  style: "pnpm format && pnpm lint:fix",
});
fs.writeFileSync(path, JSON.stringify(p, null, 2) + "\n");
NODE

  echo ""
  echo "Proyecto Next.js creado (Tailwind, ESLint, Prettier + plugin Tailwind)."
  echo "Abriendo editor en ${countdown_sec} s..."
  echo ""

  while (( remaining_ms >= 0 )); do
    local s=$(( remaining_ms / 1000 ))
    local ms=$(( remaining_ms % 1000 ))
    printf '\r  ⏱  %d.%03d s → 0.000 s    ' "$s" "$ms"
    (( remaining_ms <= 0 )) && break
    sleep 0.1
    (( remaining_ms -= step_ms ))
  done

  printf '\r  ✓ Listo. Abriendo VS Code. Servidor: %s   \n' "$url"

  if command -v code &>/dev/null; then
    code .
  else
    echo "VS Code ('code') no encontrado en el PATH."
  fi

  pnpm dev
}

# Función para verificar el título
check_title() {
  if [[ -z $1 ]]; then
    echo "Uso: check_title \"Tu título aquí\""
    return 1
  fi
  local text="$1"
  local length=${#text}
  echo "Título: \"$text\""
  echo "Longitud: $length caracteres"
  if (( length < 37 )); then
    echo "⚠️ Demasiado corto. Recomendado: 50-60 caracteres"
  elif (( length > 60 )); then
    echo "⚠️ Demasiado largo. Recomendado: 50-60 caracteres"
  else
    echo "✅ Longitud óptima para título"
  fi
}

# Función para verificar la descripción
check_description() {
  if [[ -z $1 ]]; then
    echo "Uso: check_description \"Tu descripción aquí\""
    return 1
  fi
  local text="$1"
  local length=${#text}
  echo "Descripción: \"$text\""
  echo "Longitud: $length caracteres"
  if (( length < 110 )); then
    echo "⚠️ Demasiado corta. Recomendado: 110-160 caracteres"
  elif (( length > 160 )); then
    echo "⚠️ Demasiado larga. Recomendado: 110-160 caracteres"
  else
    echo "✅ Longitud óptima para descripción"
  fi
}

# Agregar target (ip victima) a el waybar (por medio del archivo)

function settarget(){
    ip_address=$1
    machine_name=$2
    echo "$ip_address $machine_name" > /home/fravelz/.config/bin/target
}

# Limpiar target (ip victima) a el waybar (por medio del archivo)

function cleartarget(){
    echo '' > /home/fravelz/.config/bin/target
}

# Yo guardo todos mis archivos en la nuve entonces los tengo estructurados 
# en carpetas y esta funcion sirve para entrar al directorio adonde tengo todos
# mis archivos

function home(){
  cd ~/Documentos/notas/Notas-Personales-Markdown
}

# comando para taildwindcss

function tailwindcss(){
  npx tailwindcss -i ./input.css -o ./output.css --watch
}

# comando para correr programa pnpm

function qq(){
  pnpm run dev
}

# Eliminar para que sea inrrecuperable
rmk(){
  if [ -z "$1" ]; then
    echo "Uso: rmk <ruta> [--yes]"
    return 1
  fi

  target="$1"
  force=false
  [ "$2" = "--yes" ] && force=true

  if [ ! -e "$target" ]; then
    echo "Error: '$target' no existe."
    return 1
  fi

  echo "ADVERTENCIA: Esta operación es IRREVERSIBLE. Se intentará sobrescribir y eliminar: $target"
  if ! $force; then
    read -p "¿Continuar? (y/N): " ans
    case "$ans" in
      y|Y) ;;
      *) echo "Abortado."; return 1;;
    esac
  fi

  # helper para sobrescribir un archivo
  secure_wipe_file(){
    f="$1"
    if command -v scrub >/dev/null 2>&1; then
      scrub -p dod "$f"
    fi

    if command -v shred >/dev/null 2>&1; then
      shred -zun 10 -v "$f" 2>/dev/null || true
    elif command -v wipe >/dev/null 2>&1; then
      wipe -q "$f"
    else
      # fallback: 1 pass con zeros (no es tan seguro, pero algo)
      dd if=/dev/zero of="$f" bs=1M count=1 conv=notrunc >/dev/null 2>&1 || true
    fi

    # intentar borrar el fichero
    rm -f -- "$f"
  }

  # Si es un directorio, iterar archivos dentro
  if [ -d "$target" ]; then
    echo "Procesando directorio: $target"
    # Primero tratar archivos regulares
    find "$target" -type f -print0 | while IFS= read -r -d '' file; do
      echo "Wiping: $file"
      secure_wipe_file "$file"
    done

    # Opcional: borrar ficheros especiales y luego el directorio
    find "$target" -depth -mindepth 1 -print0 | tac -s '' | xargs -0 -r rm -rf --
    # Finalmente intentar borrar el directorio raíz
    rm -rf -- "$target"
  else
    # archivo
    secure_wipe_file "$target"
  fi

  echo "Operación completada. Nota: en SSDs, sistemas con journaling o con snapshots este método puede no ser totalmente efectivo."
}

# Otros

PROMPT='%F{cyan}󰣇 %f %F{magenta}%n%f $(dir_icon) %F{red}%~%f%${vcs_info_msg_0_} %F{yellow}$(parse_git_branch)%f %(?.%B%F{green}.%F{red})%f%b '

export PATH="$HOME/.config/bin:$PATH:/opt/nvim/nvim-linux-x86_64/bin"

alias cat='bat'
alias ls='lsd'

fastfetch

# Autor: Fravelz

# pnpm
export PNPM_HOME="/home/fravelz/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="$HOME/.local/bin:$PATH"

# Autor: Fravelz 
