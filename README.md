# agent-dotfiles

Baúl de dotfiles para configuraciones reutilizables de agentes AI: **OpenCode** y **Codex CLI**.

Este repositorio contiene únicamente archivos 100% portables. Cualquier configuración dependiente de la máquina (paths absolutos, API keys, identificadores de cuenta, estado runtime) queda fuera por diseño.

## Agentes cubiertos

| Agente | Versión cubierta |
|---|---|
| OpenCode | `~/.config/opencode/` |
| Codex CLI | `~/.codex/` |

## Estructura del repositorio

```
.
├── README.md
├── install.ps1                # bootstrap con 4 modos (DryRun, Force, Uninstall, Doctor)
├── .gitignore
├── .editorconfig
├── .gitattributes
│
├── opencode/                  # → ~/.config/opencode/
│   ├── AGENTS.md              # reglas globales para OpenCode
│   ├── agents/                # sub-agentes (.md)
│   ├── commands/              # slash commands (.md)
│   ├── skills/                # skills estilo Agent Skills
│   └── themes/                # temas de color (preventivo)
│
└── codex/                     # → ~/.codex/
    ├── AGENTS.md              # reglas globales para Codex
    ├── agents/                # sub-agentes (.toml)
    └── skills/                # skills estilo Agent Skills
```

## Requisitos

- **Windows 10/11** con **Modo Desarrollador** activo.
- **PowerShell 7+** (`pwsh`). Windows PowerShell 5.x no es soportado.
- **Git** instalado (para clonar y pushear).
- **OpenCode** y/o **Codex CLI** instalados y configurados en el sistema.

### Activar el Modo Desarrollador

1. Configuración de Windows → Privacidad y seguridad → Desarrolladores (o "Para programadores")
2. Activar "Modo Desarrollador"
3. Confirmar la advertencia de UAC

## Instalación (primera vez)

```powershell
git clone https://github.com/villegas-pug/agent-dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

El script crea los symlinks desde las rutas reales de los agentes hacia los archivos versionados en el repo. Es idempotente: puedes ejecutarlo varias veces sin romper nada.

## Modos de uso de `install.ps1`

| Comando | Propósito |
|---|---|
| `.\install.ps1` | Crea los symlinks que falten. Idempotente. |
| `.\install.ps1 -DryRun` | Muestra el plan de acción sin tocar el filesystem. |
| `.\install.ps1 -Force` | Si un destino existe como archivo real, hace backup con timestamp y reemplaza con el symlink. |
| `.\install.ps1 -Uninstall` | Elimina los symlinks creados por este script. No toca archivos reales. |
| `.\install.ps1 -Doctor` | Audita cada mapeo y reporta estado (OK / WARN / FAIL). |

## Cuándo re-ejecutar `install.ps1`

| Situación | Acción |
|---|---|
| Primera instalación | `.\install.ps1` una vez |
| `git pull` trajo archivos **nuevos** en `opencode/` o `codex/` | `.\install.ps1` para crear los symlinks nuevos |
| `git pull` solo modificó archivos existentes | No es necesario (los symlinks ya apuntan al archivo actualizado) |
| Eliminaste un archivo del repo | `.\install.ps1 -Uninstall` para limpiar el symlink huérfano |
| Sospechas que algo está mal | `.\install.ps1 -Doctor` |

## Flujo de trabajo diario

### Editar o crear contenido

Como los symlinks apuntan a archivos dentro del repo, cualquier edición en:

- `~/.config/opencode/skills/foo/SKILL.md`
- `~/dotfiles/opencode/skills/foo/SKILL.md`

termina en el mismo archivo físico. Los agentes ven los cambios inmediatamente.

### Versionar cambios

```powershell
cd $HOME\dotfiles
git status
git add .
git commit -m "feat(opencode): añadir skill mi-skill"
git push
```

### Sincronizar en otra máquina

```powershell
git clone https://github.com/villegas-pug/agent-dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

## Qué NO está en este repo

Por diseño, quedan **fuera del versionado** los siguientes archivos:

### OpenCode
- `opencode.jsonc` (paths absolutos a binarios y al Vault)
- `~/.config/opencode/plugins/` (los plugins Vault quedan locales)
- Comandos y skills acoplados al Vault

### Codex
- `config.toml` (providers, marketplaces, proyectos locales)
- `auth.json`, `installation_id`, `*.sqlite`, `*.jsonl`
- `prompts/` (formato deprecated por OpenAI, sustituido por skills)
- `skills/.system/` (skills internas de Codex)
- `memories/skills/piip-*` (skills específicas del proyecto piip)
- Estado runtime: `sessions/`, `plans/`, `artifacts/`, `cache/`, `browser/`, `log/`, `sqlite/`, etc.

### `~/.agents/skills/`

Las junctions `vault-*` que apuntan al Obsidian Vault quedan locales porque su fuente de verdad es el Vault, no este repositorio.

## Hooks de Codex (no incluidos en v1)

Los hooks de lifecycle de Codex viven en `~/.codex/hooks.json`. No están versionados porque los hooks actuales están acoplados al Vault y a plugins locales excluidos.

### Cuándo agregarlos

Cuando definas hooks que **no dependan del Vault ni de paths absolutos de máquina**:

1. Crear `codex/hooks.json` con la configuración portable.
2. Agregar scripts auxiliares en `codex/hooks/scripts/` (referenciados con rutas relativas).
3. Agregar el mapeo correspondiente a la tabla de `install.ps1`:
   ```
   'codex/hooks.json' = (Join-Path $HOME '.codex\hooks.json')
   ```
4. Documentar en este README que los hooks Vault se mantienen locales.

## Mapa de symlinks

| Fuente en repo | Destino real |
|---|---|
| `opencode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `opencode/agents/` | `~/.config/opencode/agents/` |
| `opencode/commands/` | `~/.config/opencode/commands/` |
| `opencode/skills/` | `~/.config/opencode/skills/` |
| `opencode/themes/` | `~/.config/opencode/themes/` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `codex/agents/` | `~/.codex/agents/` |
| `codex/skills/` | `~/.codex/skills/` |

Los symlinks se crean como **rutas relativas** desde el destino hacia el archivo en el repo, de modo que el repositorio puede moverse o clonarse en otra ruta sin necesidad de regenerar enlaces.

## Compatibilidad verificada

La estructura del repositorio refleja exactamente las rutas documentadas por cada agente:

- OpenCode: `AGENTS.md`, `agents/`, `commands/`, `skills/`, `plugins/` (documentación oficial OpenCode).
- Codex: `AGENTS.md`, `agents/*.toml`, `skills/<name>/SKILL.md` (verificado en `learn.chatgpt.com/codex/agent-configuration/subagents`).
- Skills siguen el estándar abierto **Agent Skills** (`agentskills.io`).

## Licencia

Sin licencia definida. Tratar como personal hasta que se indique lo contrario.
