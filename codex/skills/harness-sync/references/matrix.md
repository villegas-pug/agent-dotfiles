# Matriz de equivalencias y transformación

Principio anti-N×N: cada artefacto se normaliza a una **forma canónica** y se materializa en el destino con los deltas documentados aquí. No hay transformadores específicos por par.

Clasificaciones: **directa** (mismo contenido, distinta ubicación) · **parcial** (misma capacidad con pérdidas) · **alternativa funcional** (mecanismo distinto que cumple el mismo objetivo) · **no soportada** (sin equivalente; jamás inventar).

## Formas canónicas

- **Skill**: `name` (kebab-case) + `description` + cuerpo + adjuntos (referencias/, scripts/, assets/).
- **Command**: `name` + `description` + plantilla de cuerpo + argumentos declarados (si el origen los tiene).
- **Agent**: `name` + `description` + instrucciones (system prompt) + restricciones declaradas (whitelist de herramientas, modo, modelo) — solo cuando el origen las declara.
- **Instrucciones**: contenido markdown + mecanismos extra declarados (imports, globs por ruta).
- **Config-key**: clave concreta con valor comparable.

Regla general: copia siempre el **directorio completo** del artefacto (con referencias y adjuntos) y registra hash por archivo en el provenance. Los scripts ejecutables se señalan para revisión de seguridad, pero se copian para preservar la skill.

## Skills

| Origen → destino | Clasificación | Transformación y pérdidas |
|---|---|---|
| OpenCode ↔ Codex, OpenCode → Claude, Codex → Claude, Codex → OpenCode | directa | Copiar directorio; el frontmatter mínimo (`name` + `description`) ya es válido en ambos. Hacia Codex: ubicar en `.agents/skills/`; preguntar por `agents/openai.yaml` (`allow_implicit_invocation: false`) cuando el skill deba ser solo de invocación explícita. Hacia Claude Code: no añadir campos ricos que el usuario no haya especificado. |
| Claude Code → OpenCode | parcial (ADAPT) | Copiar directorio. Pérdidas a informar: `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context:*`, `agent`, `background`, `hooks`, `paths`, `argument-hint`, `arguments`; `when_to_use` se funde en `description` si aporta. Las sustituciones `$ARGUMENTS`/`$N` y `` !`cmd` `` quedan inertes: ofrece su eliminación o su documentación como texto en el cuerpo. Tras escribir, resuelve el shim (abajo). |
| Claude Code → Codex | parcial (ADAPT) | Igual que la anterior; además `metadata` rico no se interpreta (el bloque de provenance viaja igual y Codex lo ignora). Sin sustituciones: reescribe las referencias a `$ARGUMENTS` como instrucción textual al modelo. |

### Shim hacia OpenCode (skill → command)

OpenCode no invoca skills con `/nombre`: el modelo los carga con su herramienta `skill` (en v2 hay catálogo opcional controlado por frontmatter). Para invocación explícita por el usuario, la alternativa funcional es un command delgado en `.opencode/commands/<nombre>.md`:

```markdown
---
description: <descripción corta del skill>
---

Carga la skill `<nombre>` y sigue su flujo completo. Argumentos: $ARGUMENTS
```

Pregunta **después** de escribir los skills: crear commands para **todos / ninguno (default) / revisar uno a uno**. Si un skill origen ya tiene un command inequívoco (mismo nombre), preserva esa relación sin volver a preguntar por ese par. Nunca generes el command sin la skill, ni un command global.

## Commands

| Origen → destino | Clasificación | Transformación y pérdidas |
|---|---|---|
| OpenCode ↔ Claude Code | directa | Misma plantilla (`$ARGUMENTS`, `$N`, `` !`cmd` ``). Hacia Claude Code: `.claude/commands/<nombre>.md`; `description` portable; `model`/`allowed-tools` aceptados; `agent` no aplica a commands (va en skills con `context: fork`). |
| OpenCode / Claude Code → Codex | alternativa funcional | Sin comandos documentados en el CLI (ver `references/harnesses.md`): si no hay soporte empírico de `.codex/prompts/`, proponer skill-con-command en `.agents/skills/<nombre>/` con `agents/openai.yaml: allow_implicit_invocation: false` y un cuerpo que instruya ejecutar la plantilla. Pérdidas: `agent`, `model`, `` !`cmd` ``. |
| Codex → otros | parcial | Solo si existe `.codex/prompts/` (detección empírica): migrar como command del destino con frontmatter reducido a `description`. |

## Agents

| Origen → destino | Clasificación | Transformación y pérdidas |
|---|---|---|
| Claude Code ↔ OpenCode | parcial (ADAPT) | Ambos markdown. Claude→OpenCode: `tools` → `permission` por herramienta (las listadas pasan a `allow`; nunca inferir `deny` para el resto sin preguntar; **confirma la lista resultante**). Pérdidas: `maxTurns`, `memory`, `skills`, `permissionMode` (mapeable a `permission` general si aplica). OpenCode→Claude Code: la granularidad de `permission` se comprime — herramientas en `allow` → `tools`; `ask`/`deny` se documentan en el cuerpo o en `permissionMode` (confirmar). Pérdidas: `temperature`, `steps`, globs de permisos. |
| Claude Code / OpenCode → Codex | alternativa funcional | Materializar TOML (`.codex/agents/<nombre>.toml`): `name`, `description`, `developer_instructions` (del cuerpo/instrucciones). **Pérdida crítica — gritar siempre**: Codex no tiene whitelist de herramientas; el agente podrá hacer más que en el origen. Confirmación explícita obligatoria. También se pierden `maxTurns`, `memory`, `skills` y los permisos por herramienta. |
| Codex → Claude Code / OpenCode | parcial (ADAPT) con menor privilegio | TOML → markdown (`name`, `description` + cuerpo desde `developer_instructions`). Como el origen no declara herramientas, **propón siempre una whitelist conservadora** (`Read`, `Glob`, `Grep` + edición dentro del proyecto en Claude Code) y pide confirmación antes de ampliarla. Nunca dejes «todas las herramientas» por omisión. |

## Instrucciones (opt-in por categoría)

No migres instrucciones sin que el usuario elija la categoría explícitamente: el riesgo es pisar el «README del agente» del proyecto.

| Origen → destino | Clasificación | Regla |
|---|---|---|
| `CLAUDE.md` ↔ `AGENTS.md` | parcial (ADAPT) | `AGENTS.md` raíz lo leen los tres (Claude Code desde v2.1.277+). Materializa como `AGENTS.md` destino salvo que el proyecto destino prefiera `CLAUDE.md` nativo. `@imports` de Claude Code: fundir inline (máx 4 saltos) o perderse — avisar. `CLAUDE.local.md` nunca se migra. `.claude/rules/*.md` no tienen equivalente en Codex/OpenCode: default **omitir**; opción: fundir su contenido en `AGENTS.md` perdiendo `paths:` (ADAPT con pérdida explícita). Destino existente y distinto → siempre CONFLICT, nunca fusión automática. |
| `.codex/rules/*.rules` ↔ otros | no soportada | Starlark; concepto distinto (reglas de ejecución de comandos). Jamás generar ni traducir. |

## Config (caso por caso)

Las semánticas son incompatibles entre harnesses (5 scopes JSON vs TOML con trust vs JSONC con permisos por herramienta): no hay migración masiva. La skill:

1. Inventaria keys declarativas del origen y las presenta con equivalencia candidata y clasificación.
2. Equivalencias iniciales aceptables: `model` (informativo); reglas `permissions.allow`/`deny` de Claude Code ↔ `permission` de OpenCode (semántica cercana; revisar globs); nombres de fallback de documentos de proyecto de Codex (`project_doc_fallback_filenames`).
3. **Exclusiones absolutas** (nunca migrar): credenciales, `env`, API keys, `mcp_servers` con secretos, `auth.json`, cualquier valor que parezca un token.
4. Todo cambio entra al plan como ADAPT o CONFLICT con diff; el usuario decide key por key o por lote. `.codex/config.toml` de proyecto solo se escribe si el proyecto es «trusted» (advertir si no lo es).
