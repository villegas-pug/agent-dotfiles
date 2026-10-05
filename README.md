# agent-dotfiles

Dotfiles versionados para **OpenCode**, **Codex CLI** y **Claude Code CLI** en Windows. El clon desde el que se invoca `install.ps1` es la fuente de la instalación local. Solo se versiona configuración portable; credenciales, proveedores, sesiones, caches y plugins de la máquina permanecen fuera del repositorio.

## Estructura

```text
AGENTS.md                 Única fuente de reglas globales para los tres arneses
install.ps1               Instalación y auditoría de enlaces (PowerShell 7+)
opencode/commands/        Comandos slash propios de OpenCode
opencode/skills/          Skills propias y compartidas con Claude Code
opencode/agents/          Agentes Markdown con frontmatter de OpenCode
opencode/themes/          Temas de OpenCode
codex/skills/             Skills de Codex, espejos semánticos de las compatibles
codex/agents/             Agentes TOML de Codex
claude/agents/            Agentes Markdown con frontmatter de Claude Code
claude/commands/          Comandos slash nativos de Claude Code (adaptaciones de OpenCode)
claude/statusline.js      Status line de dos líneas de Claude Code (Node)
herdr/config.toml         Configuración portable del multiplexor herdr
```

Claude Code invoca las skills directamente con `/nombre`. Por convención, **toda skill de `opencode/skills/` es compartida por defecto** y se enlaza individualmente a `~/.claude/skills/<nombre>/`; OpenCode también la descubre allí. No se crean copias bajo `claude/skills/`. Las skills que jamás deban presentarse a Claude se listan en `$openCodeOnly` dentro de `install.ps1` y se enlazan solo en `~/.config/opencode/skills/`. Añadir una skill compartida no requiere editar el script: basta crear su directorio y reinstalar.

## Instalación en otra PC

1. Clona este repositorio en cualquier ruta de Windows.
2. Usa PowerShell **7+** y activa el Modo Desarrollador para permitir enlaces simbólicos.
3. Desde el clon, inspecciona y después instala:

```powershell
.\install.ps1 -DryRun
.\install.ps1
.\install.ps1 -Doctor
```

La ejecución normal **reemplaza sin respaldos** los archivos y directorios existentes en las rutas mapeadas. `-DryRun` indica exactamente cuáles sustituiría; los archivos reales contenidos en esas rutas dejarán de existir. No se crea ningún `.bak-*`. Si una fuente requerida falta en el clon, el instalador detiene la instalación antes de reemplazar destinos. `-Force` se acepta por compatibilidad con invocaciones anteriores, con el mismo comportamiento que la ejecución normal y sin respaldos.

| Parámetro | Efecto |
|---|---|
| `-DryRun` | Muestra creaciones y sustituciones sin modificar nada |
| Ninguno | Crea o corrige los enlaces a este clon; es idempotente |
| `-Doctor` | Comprueba si cada enlace apunta a la fuente correcta de este clon |
| `-Uninstall` | Quita únicamente enlaces que aún apuntan a este clon; conserva los archivos reales |
| `-Uninstall -DryRun` | Muestra los enlaces que se quitarían |

El script solo instala las rutas que mapea. No reemplaza enteros `~/.codex/`, `~/.config/opencode/` ni `~/.claude/`. En particular, conserva `~/.claude/skills/synced/` (descargas gestionadas por Claude), credenciales y sesiones. Una skill compartida se instala una vez bajo `~/.claude/skills/<nombre>/` y OpenCode también la descubre allí: evita registrar dos skills con el mismo nombre. Las skills exclusivas de OpenCode van bajo `~/.config/opencode/skills/<nombre>/`.

### Rutas de reglas y agentes

| Fuente en el clon | Destino en la máquina |
|---|---|
| `AGENTS.md` | `~/.codex/AGENTS.md` |
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `AGENTS.md` | `~/.claude/CLAUDE.md` |
| `codex/agents/`, `codex/skills/` | `~/.codex/agents/`, `~/.codex/skills/` |
| `opencode/agents/`, `opencode/commands/`, `opencode/themes/` | `~/.config/opencode/agents/`, `commands/`, `themes/` |
| `claude/agents/` | `~/.claude/agents/` |
| `claude/commands/` | `~/.claude/commands/` |
| `claude/statusline.js` | `~/.claude/statusline.js` |
| `claude/settings.json`, `opencode/opencode.jsonc`, `opencode/dcp.jsonc` | Ver «Archivos de configuración» |

### Archivos de configuración

Criterio: un archivo de configuración se versiona **solo si no contiene datos de la máquina** (rutas absolutas, usuario, secretos, dependencias de herramientas locales).

| Fuente en el clon | Destino | Notas |
|---|---|---|
| `claude/settings.json` | `~/.claude/settings.json` | Incluye la `statusLine`; requiere `node` y `git` en el PATH de Git Bash |
| `opencode/opencode.jsonc` | `~/.config/opencode/opencode.jsonc` | Las claves van por `{env:...}`; el bloque comentado usa `<USERPROFILE>` |
| `opencode/dcp.jsonc` | `~/.config/opencode/dcp.jsonc` | Solo `$schema` |
| `herdr/config.toml` | `%APPDATA%\herdr\config.toml` | Ver «herdr» |

No se versionan: `~/.config/opencode/tui.jsonc` (referencia el plugin `herdr-tui-session.js`, generado por herdr; en un PC sin herdr rompería la TUI), `plugins/`, `node_modules`, `~/.codex/config.toml` y `hooks.json` (rutas absolutas), credenciales e historial.

Estos enlaces apuntan al clon: **editar el archivo de destino edita el repo**, y los cambios aparecen en `git diff`. Claude Code reescribe `settings.json` (por ejemplo con `/effort`); si el enlace dejara de serlo, `install.ps1 -Doctor` lo avisa. Antes de commitear, revisa que no se hayan acumulado permisos con rutas absolutas ni claves de plugins locales. `-Uninstall` sustituye estos enlaces por una **copia** del contenido, para no dejar a la herramienta sin configuración.

### herdr

Solo se versiona `config.toml` (UI, sidebar, tema, notificaciones, `terminal.new_cwd`). Se enlaza **el archivo**, nunca el directorio `%APPDATA%\herdr\`, que contiene sockets, logs, `session.json` y `session-snapshots/`. Tampoco se versionan `%LOCALAPPDATA%\herdr\` (caché de detección de agentes), `~/.herdr/` (binario y worktrees) ni las máquinas SSH guardadas.

Los scripts de integración (`~/.claude/hooks/herdr-agent-state.ps1`, `~/.codex/herdr-agent-state.ps1`, `~/.config/opencode/plugins/herdr-agent-state.js`) los administra herdr y se regeneran por máquina. `claude/settings.json` sí registra el hook `SessionStart`, con ruta `$HOME/...` para ser portable; el script termina sin efecto fuera de un pane de herdr.

En una PC nueva, tras `install.ps1`:

```powershell
herdr integration install claude   # y codex / opencode según uso
herdr server reload-config
```

`herdr integration install claude` reescribe el hook de `settings.json` con la ruta absoluta del usuario: revisa `git diff` y restaura la forma `$HOME/.claude/hooks/herdr-agent-state.ps1` antes de commitear. En Linux, macOS o WSL herdr lee `~/.config/herdr/config.toml`; el instalador solo cubre Windows.

### Comandos de Claude Code

`/commit` y `/playwright-headed` son comandos sin skill equivalente, por lo que tienen un par nativo en `claude/commands/` además del de `opencode/commands/`. Los dos pares pueden divergir: `sync-agents` detecta la divergencia y propone la conversión (con confirmación por elemento), pero no es automática ni se ejecuta sola. Para un comando nuevo con lógica propia, ejecuta `/sync-agents apply`. Diferencias del par de Claude: `argument-hint`, `allowed-tools` y `disable-model-invocation` (solo `/commit`), sin `agent: build`, y sin las inyecciones de `log` y `upstream` (se consultan bajo demanda). El resto de comandos de OpenCode son envoltorios de skills que Claude ya expone con `/nombre`.

Cuando se migra una instalación anterior, el script sustituye el antiguo enlace del directorio completo de skills de OpenCode por enlaces individuales. Los enlaces usan rutas relativas **calculadas desde la ubicación de este clon**; si luego mueves el clon, vuelve a instalar desde la nueva ubicación. Cuando un `git pull` solo cambia archivos dentro de directorios enlazados, no hace falta reinstalar. Cuando cambia un mapeo o se rompe un enlace, vuelve a usar `-DryRun` e instala.

## Dos operaciones diferentes

- **`install.ps1` / `/dotfiles`**: enlaza las rutas locales de los tres arneses al clon. En OpenCode: `/dotfiles dry`, `/dotfiles sync`, `/dotfiles doctor` o `/dotfiles uninstall`; Codex usa la skill `$dotfiles` y Claude Code `/dotfiles`. Las acciones de sustitución solicitadas al agente requieren confirmación humana.
- **`sync-agents`**: compara y alinea **archivos dentro del clon**, sin tocar enlaces. Por defecto solo informa; `apply` pide dirección y confirmación por elemento. Skills: OpenCode ↔ Codex; Claude comparte la versión compatible de OpenCode. Agentes: OpenCode `.md` ↔ Codex `.toml` ↔ Claude `.md`, con adaptación al formato nativo y revisión de campos sin equivalencia. Comandos: OpenCode ↔ Claude (`opencode/commands/` ↔ `claude/commands/`); los envoltorios de skill no generan par y Codex no tiene equivalente. Solo existe un `AGENTS.md` en la raíz, por lo que no se sincroniza por pares.

OpenCode: `/sync-agents dry-run` o `/sync-agents apply`. Codex: invoca `$sync-agents` e indica `dry-run` o `apply`. Claude Code: `/sync-agents` e indica el modo. La sincronización local del clon no crea commits ni publica cambios en el remoto.

## Harness Sync

Migra y sincroniza skills, comandos, agentes, instrucciones y configuración entre OpenCode, Claude Code y Codex **dentro del proyecto desde el que se invoca**. La skill es global; sus efectos son solo locales a ese repositorio: nunca escribe en las rutas globales de los arneses. Detecta los artefactos del proyecto, permite elegir origen y destino, clasifica cada equivalencia (directa | parcial | alternativa funcional | no soportada) y ejecuta un plan con estados (CREATE | UPDATE | UNCHANGED | ADAPT | UNSUPPORTED | CONFLICT) tras confirmación. Los artefactos generados llevan un bloque de provenance en su frontmatter que hace la operación idempotente y trazable en ciclos sucesivos (OpenCode → Claude Code → Codex → OpenCode). No crea backups: el git del proyecto es la red de seguridad.

Invócala con `/harness-sync` en OpenCode y Claude Code, o `$harness-sync` en Codex. Para alinear artefactos **dentro de este clon** sigue correspondiendo `sync-agents`: cada skill cubre un ámbito distinto.

## Prompt Augmenter

Invoca `$prompt-augmenter` en Codex, `/prompt-augmenter` en OpenCode o `/prompt-augmenter` en Claude Code. Selecciona uno o varios augmenters de Analysis, Safety y Behavior; proporciona el prompt base si aún falta. La skill leerá **solo las instrucciones de los elegidos**, informará qué aplicará y ejecutará la solicitud preservando su objetivo.

Ejemplo: invocar `/prompt-augmenter` → elegir `impact-analysis`, `regression-safety` y `scope-guard` → escribir «Corrige el cálculo del costo de envío en el carrito» → la skill aplica esos tres criterios mientras corrige el cálculo. En Codex se inicia con `$prompt-augmenter`: el selector permite elegir **Omitir / Todos / Personalizar** por grupo, y **Personalizar** abre preguntas **Agregar / Omitir** por augmenter.

Para añadir un augmenter, crea `references/<nombre>.md` dentro de `prompt-augmenter` y una entrada resumida en `SKILL.md`; refleja el cambio en Codex. OpenCode y Claude Code ya comparten una sola fuente.

Las skills `git-push-cloud` y `kill-session-processes` también tienen entradas directas para Codex (`$git-push-cloud`, `$kill-session-processes`) y Claude Code (`/git-push-cloud`, `/kill-session-processes`). En OpenCode siguen disponibles mediante `/push-cloud` y `/kill-servers`. Publicar commits o terminar procesos exige las confirmaciones descritas en cada skill; ninguna de esas acciones ocurre durante la sincronización o instalación.

## Límites

- El instalador no ejecuta `sync-agents`, builds ni pruebas.
- Claude Code **CLI local** carga `~/.claude/skills/`; las sesiones cloud de Claude no cargan las skills personales de esa carpeta.
- Los agentes con campos o capacidades sin equivalente entre arneses requieren una decisión explícita; `sync-agents` no inventa equivalencias de permisos o modelos.
- Los symlinks requieren Modo Desarrollador en Windows o permisos para crearlos. OpenCode y Codex pueden necesitar reiniciar la sesión para descubrir cambios de configuración; Claude Code permite `/reload-skills` si el directorio de skills se creó después de iniciar la sesión.

Sin licencia definida.
