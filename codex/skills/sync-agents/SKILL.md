---
name: sync-agents
description: Compara y alinea skills y agentes entre OpenCode, Codex y Claude Code dentro del clon de agent-dotfiles. Usar cuando el usuario solicite sincronizar los arneses o revisar sus diferencias. Por defecto solo informa; apply requiere decisiones y confirmaciones por elemento.
---

# Sync Agents

## Alcance

Trabaja exclusivamente sobre el clon de `agent-dotfiles` que contiene esta skill. Localiza el clon a partir de la ubicación real del archivo instalado; si no se puede determinar, solicita su ruta. No presupongas `~/agent-dotfiles`, una letra de unidad ni un shell Unix. `install.ps1` administra los enlaces de la máquina; esta skill administra contenido **dentro del clon**. No hagas `git commit`, `push`, builds ni pruebas.

Modos: `dry-run` por defecto (solo lectura) y `apply` cuando el usuario lo indique explícitamente. Si hay ambigüedad, permanece en `dry-run`. En `apply`, muestra el borrador de cada par y espera selección y confirmación explícitas antes de escribir. Nunca sobreescribas divergencias automáticamente.

## Descubrimiento e inspección

1. Localiza `opencode/skills/`, `codex/skills/`, `opencode/agents/`, `codex/agents/` y `claude/agents/` bajo el clon. Ignora `.system/`, archivos de estado y metadatos `skills/*/agents/openai.yaml`.
2. Para inspección en Windows usa PowerShell 7+ o herramientas nativas de lectura; por ejemplo `Get-FileHash -Algorithm SHA256 -LiteralPath <archivo>` para archivos comparables, y `git diff --no-index -- <origen> <destino>` para ver texto (su código 1 significa «diferencias»). Cita rutas y no uses `diff -u`, `/c/...`, `/dev/null` ni rutas fijas.
3. Agrupa hallazgos en iguales, faltantes, distintos e incompatibles. Si un elemento falta, presenta su propuesta de creación adaptada; nunca la apliques automáticamente.

## Skills

- Compara `opencode/skills/<nombre>/` con `codex/skills/<nombre>/` por archivos equivalentes, incluyendo referencias. No supongas que basta con comparar `SKILL.md`.
- Las skills compatibles de Claude Code **usan el archivo de `opencode/skills/`** mediante enlaces individuales en `~/.claude/skills/`; no existe una tercera copia de ellas que reconciliar. Señala si el contenido usa herramientas o rutas exclusivas de OpenCode y propón una adaptación portable antes de marcarlo como compatible.
- Si hay diferencias, ofrece siempre **OpenCode → Codex**, **Codex → OpenCode** u **omitir**. La dirección elegida es la fuente de verdad para ese par únicamente. Muestra los archivos afectados y adapta solo los detalles necesarios para que sigan siendo válidos en el destino.
- No copies un frontmatter de permisos exclusivo de un arnés como concesión automática de permisos en otro. Mantén intactos los recursos y referencias que no cambian.
- Una skill exclusiva de un arnés puede quedar exclusiva si no tiene equivalente funcional seguro; reporta la razón.

## Agentes

Empareja agentes por identidad declarada (`name`) y función, no por extensión. Formatos nativos:

| Arnés | Fuente | Campos indispensables |
|---|---|---|
| OpenCode | `opencode/agents/<nombre>.md` | `description` en YAML; instrucciones en el cuerpo; modo/permisos si corresponden |
| Codex | `codex/agents/<nombre>.toml` | `name`, `description`, `developer_instructions` |
| Claude Code | `claude/agents/<nombre>.md` | `name`, `description` en YAML; instrucciones en el cuerpo |

- Cuando haya diferencias entre dos o tres versiones, muestra cuáles existen y ofrece como fuente **OpenCode**, **Codex** o **Claude Code**, según corresponda, además de **omitir**. Pregunta qué destino(s) actualizar; confirma **cada destino** antes de aplicar. Ningún arnés tiene prioridad permanente.
- Convierte instrucciones, descripción y controles de forma semántica al formato nativo del destino. No copies `.toml` como `.md` ni supongas equivalencia entre modelos, herramientas, modos o permisos. Muestra un borrador y enumera campos que no puedas trasladar fielmente; si un tipo de agente carece de contraparte válida, omite esa conversión y explica por qué.
- Los `.yaml` de `skills/*/agents/` son metadatos de presentación de Codex, no definiciones de agentes; no los reflejes en `agents/`.

## Instrucciones globales y comandos

- Solo existe `AGENTS.md` en la raíz del clon. OpenCode y Codex lo reciben como `AGENTS.md`, Claude Code como `CLAUDE.md` mediante `install.ps1`. No lo compares como par ni generes copias en cada directorio. La auditoría de enlaces corresponde a `install.ps1 -Doctor`.
- Los comandos de OpenCode son entradas propias del arnés. Si `opencode/commands/<nombre>.md` apunta a una skill existente en Codex, **no** la sustituyas por documentación derivada del comando. Claude Code expone las skills con `/nombre` sin comando duplicado. Reporta los comandos sin equivalente solo como información.

## Resultado

En `dry-run`, muestra por nombre las diferencias de skills, agentes, incompatibilidades y asimetrías deliberadas, sin escribir nada. En `apply`, incluye las decisiones y confirmaciones de cada par y resume exactamente qué archivos cambiaste. No ejecutes `install.ps1` desde esta skill.
