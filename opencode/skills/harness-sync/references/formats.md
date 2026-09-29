# Formatos nativos por harness

Todas las rutas son relativas a la raíz del workspace. "—" = no soportado. Los ámbitos globales (`~/.claude`, `~/.codex`, `~/.config/opencode`, `~/.agents`) se listan solo como referencia: **esta skill nunca escribe en ellos**.

## Claude Code

### Skills
- Ruta: `.claude/skills/<nombre>/SKILL.md` (raíz del repo; también descubre `<subdir>/.claude/skills/` bajo demanda).
- Invocación: `/nombre args` explícita (apilable); automática por coincidencia con `description` (y `paths:`).
- Frontmatter documentado: `name` (default: nombre del directorio), `description` (truncada ~1536 chars combinada con `when_to_use`), `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context: fork`, `agent`, `background`, `hooks`, `paths`, `shell`, `metadata` (mapa libre), `license`, `compatibility`. **Sin campo `version`**. Campos desconocidos se ignoran.
- Sustituciones en el cuerpo: `$ARGUMENTS`, `$N`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`, `` !`cmd` `` (dinámico; un comando fallido aborta la invocación).
- Recomendación: SKILL.md < 500 líneas; material extenso a archivos de referencia.

### Commands
- Ruta: `.claude/commands/<nombre>.md`; subdirectorio `frontend/component.md` → `/frontend:component`.
- Skills y commands están **unificados**: mismo comportamiento; el command acepta los mismos campos que el skill excepto `name` y `paths`. En colisión de nombre gana el skill.
- Precedencia: personal (`~/.claude/commands/`) > proyecto.

### Agents
- Ruta: `.claude/agents/<nombre>.md`.
- Frontmatter: `name` (requerido, sin `:`), `description` (requerido), `tools` (whitelist; omitido = hereda todo), `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `omitClaudeMd`, `effort`, `isolation`, `color`, `initialPrompt`. El cuerpo markdown es el system prompt.
- Invocación: herramienta **Agent** (nombre anterior Task; el alias sigue funcionando) con `subagent_type`; delegación automática por `description`; @-mention garantizado. **No invocable como slash**.

### Instrucciones
- `CLAUDE.md` (raíz o `.claude/CLAUDE.md`) y `CLAUDE.local.md` (local, gitignored). Jerarquía concatenada root→cwd; lo más cercano al cwd va al final. `@ruta` importa archivos (relativos al que importa; máx 4 saltos). `.claude/rules/*.md` con frontmatter `paths:` (globs) aplican por ruta.
- `AGENTS.md` se lee de forma nativa desde v2.1.277+ (configurable; default `claude-md-or-agents-md`). En versiones anteriores solo vía `@AGENTS.md` dentro de un `CLAUDE.md`.

### Config
- `.claude/settings.json` (compartida, commiteable) y `.claude/settings.local.json` (personal, fuera de git). Scopes (mayor→menor): managed > CLI > local > proyecto > usuario. Las listas (p. ej. `permissions.allow`) se **fusionan** entre scopes. JSON estricto, sin comentarios.

## OpenCode

### Config y estructura
- Proyecto: `opencode.json`/`opencode.jsonc` en raíz, o `.opencode/opencode.json(c)`.
- Directorios de proyecto: `.opencode/{agents,commands,modes,plugins,skills,tools,themes}/` (nombres en plural; los singulares legacy aún se descubren).
- Instrucciones: `AGENTS.md`. v1: fallback `CLAUDE.md` solo si no hay `AGENTS.md` proyecto. v2: **sin fallback** (breaking change). Campo `instructions` del config: funcional en v1, **inerte en v2** — no usar.
- Global (referencia, nunca escribir): `~/.config/opencode/`.

### Skills
- Ruta: `.opencode/skills/<nombre>/SKILL.md`. Compatibilidad: también descubre `.claude/skills/` (proyecto y `~/.claude/skills`).
- v1: `name` kebab-case **igual al nombre del directorio**. v2: el identificador sale de la **ruta**; alinear nombre y directorio igualmente.
- Frontmatter: `name`, `description` (requeridos); el resto se ignora (v1 explícitamente). v2 añade catálogo: `slash` / `opencode/slash` (visibilidad) y `opencode/autoinvoke`.
- Invocación: el **modelo** carga el skill con su herramienta `skill` (v1 `skill({name})`, v2 `skill({id})`). **No existe `/nombre` para skills**; la vía de invocación explícita por el usuario es el shim command (ver `references/matrix.md`).

### Commands
- Ruta: `.opencode/commands/<nombre>.md`; anidados `team/review.md` → `/team/review`.
- Frontmatter: `description`, `agent`, `model` (opcionales). El cuerpo es la plantilla.
- Plantilla: `$ARGUMENTS`, `$1`, `$2`… (sin placeholders, los args se anexan tras línea en blanco), `` !`cmd` `` (shell, se expande pre-envío). Los custom pueden sobrescribir built-ins.
- Invocación: `/nombre` en el TUI. Proyecto gana a global.

### Agents
- Ruta: `.opencode/agents/<nombre>.md` (el filename es el nombre) o JSON de config (v1 clave `agent`; v2 `agents` con el prompt en `system`).
- Frontmatter md: `description`, `mode` (`primary`/`subagent`/`all`), `model`, `temperature`, `permission` por herramienta (`allow`/`ask`/`deny` + globs; herramientas conocidas: `read`, `edit`, `glob`, `grep`, `list`, `bash`, `task`, `webfetch`, `websearch`, `lsp`, `skill`, `question`), `steps`, `hidden`, `color`.
- Primarios se alternan con Tab; los subagentes se invocan desde primarios o manualmente con `@nombre`.

### Interactivo
- Herramienta nativa `question`: header corto + prompt + choices; selección múltiple en v2; respuesta libre siempre disponible. Gated por permisos (`permission.question` v1 / `action: "question"` v2).

## Codex

### Config y estructura
- Proyecto: `.codex/config.toml` (**solo en proyectos "trusted"**; si el proyecto no es trusted, la config de proyecto se ignora — advirtiendo antes de proponer escribirla).
- Instrucciones: `AGENTS.md` / `AGENTS.override.md` por directorio (concatenados root→cwd; máximo un archivo por nivel; `project_doc_fallback_filenames` en config define alternativas como `TEAM_GUIDE.md`). Sin `@import`, sin `AGENTS.local.md`.
- Rules: `.codex/rules/*.rules` en **Starlark** (`prefix_rule(...)`): reglas de ejecución de comandos, concepto distinto a `.claude/rules/`. Jamás generar ni traducir.
- Global (referencia, nunca escribir): `~/.codex/config.toml`.

### Skills
- Ruta documentada: `.agents/skills/<nombre>/SKILL.md` (ver `references/harnesses.md` para la discrepancia `~/.codex/skills`).
- Frontmatter: `name`, `description` (mínimo). Opcional `agents/openai.yaml` con `allow_implicit_invocation: false` (solo invocación explícita).
- Invocación: explícita `$nombre` o `/skills`; implícita por coincidencia con `description`.
- **Restricciones**: sin `allowed-tools`/`disallowed-tools`, `model`, `effort`, `context`, `hooks`, `paths`, `argument-hint`, `arguments`, `$ARGUMENTS`, `` !`cmd` ``. El catálogo consume ~2% del contexto: descriptions concisas.

### Commands
- `.codex/prompts/` sin confirmación documental en el CLI (ver `references/harnesses.md`). Sin soporte confirmado, la alternativa funcional es una skill-con-command.

### Agents
- Ruta: `.codex/agents/<nombre>.toml` (**TOML, no markdown**).
- Campos requeridos: `name`, `description`, `developer_instructions`. Opcionales: `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`. **Sin whitelist de `tools`** — pérdida crítica al migrar hacia Codex (avisar y confirmar siempre).
- Invocación: delegación por lenguaje natural, `/agent`, hilos en background.

### Interactivo
- Sin herramienta estructurada de preguntas: el modelo pregunta en texto y el usuario responde en el siguiente turno. `request_permissions` para permisos granulares.
