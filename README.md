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
```

Claude Code invoca las skills directamente con `/nombre`: las compatibles enlazan individualmente a `opencode/skills/`. No se crean copias de ellas bajo `claude/skills/`; el catálogo efectivo de skills compartidas está en `install.ps1`.

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

El script solo instala las rutas que mapea. No reemplaza enteros `~/.codex/`, `~/.config/opencode/` ni `~/.claude/`. En particular, conserva `~/.claude/skills/synced/` (descargas gestionadas por Claude), `~/.claude/settings.json`, credenciales y sesiones. Una skill compartida se instala una vez bajo `~/.claude/skills/<nombre>/` y OpenCode también la descubre allí: evita registrar dos skills con el mismo nombre. Las skills exclusivas de OpenCode van bajo `~/.config/opencode/skills/<nombre>/`.

### Rutas de reglas y agentes

| Fuente en el clon | Destino en la máquina |
|---|---|
| `AGENTS.md` | `~/.codex/AGENTS.md` |
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `AGENTS.md` | `~/.claude/CLAUDE.md` |
| `codex/agents/`, `codex/skills/` | `~/.codex/agents/`, `~/.codex/skills/` |
| `opencode/agents/`, `opencode/commands/`, `opencode/themes/` | `~/.config/opencode/agents/`, `commands/`, `themes/` |
| `claude/agents/` | `~/.claude/agents/` |

Cuando se migra una instalación anterior, el script sustituye el antiguo enlace del directorio completo de skills de OpenCode por enlaces individuales. Los enlaces usan rutas relativas **calculadas desde la ubicación de este clon**; si luego mueves el clon, vuelve a instalar desde la nueva ubicación. Cuando un `git pull` solo cambia archivos dentro de directorios enlazados, no hace falta reinstalar. Cuando cambia un mapeo o se rompe un enlace, vuelve a usar `-DryRun` e instala.

## Dos operaciones diferentes

- **`install.ps1` / `/dotfiles`**: enlaza las rutas locales de los tres arneses al clon. En OpenCode: `/dotfiles dry`, `/dotfiles sync`, `/dotfiles doctor` o `/dotfiles uninstall`; Codex usa la skill `$dotfiles` y Claude Code `/dotfiles`. Las acciones de sustitución solicitadas al agente requieren confirmación humana.
- **`sync-agents`**: compara y alinea **archivos dentro del clon**, sin tocar enlaces. Por defecto solo informa; `apply` pide dirección y confirmación por elemento. Skills: OpenCode ↔ Codex; Claude comparte la versión compatible de OpenCode. Agentes: OpenCode `.md` ↔ Codex `.toml` ↔ Claude `.md`, con adaptación al formato nativo y revisión de campos sin equivalencia. Solo existe un `AGENTS.md` en la raíz, por lo que no se sincroniza por pares.

OpenCode: `/sync-agents dry-run` o `/sync-agents apply`. Codex: invoca `$sync-agents` e indica `dry-run` o `apply`. Claude Code: `/sync-agents` e indica el modo. La sincronización local del clon no crea commits ni publica cambios en el remoto.

## Prompt Augmenter

Invoca `$prompt-augmenter` en Codex, `/prompt-augmenter` en OpenCode o `/prompt-augmenter` en Claude Code. Selecciona uno o varios augmenters de Analysis, Safety, Quality y Behavior; proporciona el prompt base si aún falta. La skill leerá **solo las instrucciones de los elegidos**, informará qué aplicará y ejecutará la solicitud preservando su objetivo.

Ejemplo: invocar `/prompt-augmenter` → elegir `impact-analysis`, `regression-safety`, `scope-guard` y `test-impact` → escribir «Corrige el cálculo del costo de envío en el carrito» → la skill aplica esos cuatro criterios mientras corrige el cálculo. En Codex se inicia con `$prompt-augmenter` y el mismo flujo.

Para añadir un augmenter, crea `references/<nombre>.md` dentro de `prompt-augmenter` y una entrada resumida en `SKILL.md`; refleja el cambio en Codex. OpenCode y Claude Code ya comparten una sola fuente.

Las skills `git-push-cloud` y `kill-session-processes` también tienen entradas directas para Codex (`$git-push-cloud`, `$kill-session-processes`) y Claude Code (`/git-push-cloud`, `/kill-session-processes`). En OpenCode siguen disponibles mediante `/push-cloud` y `/kill-servers`. Publicar commits o terminar procesos exige las confirmaciones descritas en cada skill; ninguna de esas acciones ocurre durante la sincronización o instalación.

## Límites

- El instalador no ejecuta `sync-agents`, builds ni pruebas.
- Claude Code **CLI local** carga `~/.claude/skills/`; las sesiones cloud de Claude no cargan las skills personales de esa carpeta.
- Los agentes con campos o capacidades sin equivalente entre arneses requieren una decisión explícita; `sync-agents` no inventa equivalencias de permisos o modelos.
- Los symlinks requieren Modo Desarrollador en Windows o permisos para crearlos. OpenCode y Codex pueden necesitar reiniciar la sesión para descubrir cambios de configuración; Claude Code permite `/reload-skills` si el directorio de skills se creó después de iniciar la sesión.

Sin licencia definida.
