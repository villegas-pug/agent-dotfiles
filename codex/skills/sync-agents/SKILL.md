---
name: sync-agents
description: Compara y alinea skills, agentes y comandos entre OpenCode, Codex y Claude Code dentro del clon de agent-dotfiles. Si falta el modo, lo solicita mediante un selector; apply pide decisiones y confirmación por elemento.
---

# Sync Agents

## Alcance

Trabaja exclusivamente sobre el clon de `agent-dotfiles` que contiene esta skill. Localiza el clon a partir de la ubicación real del archivo instalado; si no se puede determinar, solicita su ruta. No presupongas `~/agent-dotfiles`, una letra de unidad ni un shell Unix. `install.ps1` administra los enlaces de la máquina; esta skill administra contenido **dentro del clon**. No hagas `git commit`, `push`, builds ni pruebas.

Modos: `dry-run` (solo lectura) y `apply`. Respeta `dry-run` o `apply` si el usuario lo especificó en la invocación. Si no indicó modo, solicítalo mediante el selector conversacional antes de inspeccionar o escribir. `help` muestra los modos y termina; un argumento desconocido muestra las opciones válidas y termina sin operar. Cancelar el selector de modo termina sin cambios. Elegir `apply` permite iniciar el flujo, pero no autoriza por sí solo ninguna escritura: cada cambio requiere las decisiones y confirmaciones descritas abajo. Nunca sobreescribas divergencias automáticamente.

## Selector conversacional

- Usa el selector nativo del arnés cuando esté disponible: `request_user_input` o `request_user_input_async` en Codex, la herramienta `question` en OpenCode y `AskUserQuestion` en Claude Code. Si no está disponible, presenta opciones numeradas en la conversación y espera la respuesta. No interpretes una opción preseleccionada como respuesta hasta que el usuario la envíe.
- Cuando falte el modo, ofrece `dry-run` y `apply`. En `apply`, presenta cada diferencia y su borrador antes de pedir decisiones. Para skills, ofrece la dirección aplicable y `Omitir`; para agentes, ofrece como fuente solo las versiones existentes y `Omitir`, y luego pregunta por cada destino por separado. Confirma cada escritura individualmente.
- Si se cancela durante `apply`, no escribas el cambio pendiente ni proceses los siguientes; conserva los cambios anteriores que el usuario ya confirmó y aplicó. Una respuesta vacía o inválida no equivale a `Omitir`: vuelve a preguntar solo esa decisión.

## Descubrimiento e inspección

1. Localiza `opencode/skills/`, `codex/skills/`, `opencode/agents/`, `codex/agents/`, `claude/agents/`, `opencode/commands/` y `claude/commands/` bajo el clon. Ignora `.system/`, archivos de estado y metadatos `skills/*/agents/openai.yaml`.
2. Para inspección en Windows usa PowerShell 7+ o herramientas nativas de lectura; por ejemplo `Get-FileHash -Algorithm SHA256 -LiteralPath <archivo>` para archivos comparables, y `git diff --no-index -- <origen> <destino>` para ver texto (su código 1 significa «diferencias»). Cita rutas y no uses `diff -u`, `/c/...`, `/dev/null` ni rutas fijas.
3. Agrupa hallazgos en iguales, faltantes, distintos e incompatibles. Si un elemento falta, presenta su propuesta de creación adaptada; nunca la apliques automáticamente.

## Skills

- Compara `opencode/skills/<nombre>/` con `codex/skills/<nombre>/` por archivos equivalentes, incluyendo referencias. No supongas que basta con comparar `SKILL.md`.
- Las skills compatibles de Claude Code **usan el archivo de `opencode/skills/`** mediante enlaces individuales en `~/.claude/skills/`; no existe una tercera copia de ellas que reconciliar. Señala si el contenido usa herramientas o rutas exclusivas de OpenCode y propón una adaptación portable antes de marcarlo como compatible.
- Si hay diferencias, ofrece por selector **OpenCode → Codex**, **Codex → OpenCode** u **Omitir**. La dirección elegida es la fuente de verdad para ese par únicamente. Muestra los archivos afectados y el borrador adaptado, y confirma antes de escribir. Si falta el par destino, ofrece la propuesta de creación y pide confirmación antes de crearla.
- No copies un frontmatter de permisos exclusivo de un arnés como concesión automática de permisos en otro. Mantén intactos los recursos y referencias que no cambian.
- Una skill exclusiva de un arnés puede quedar exclusiva si no tiene equivalente funcional seguro; reporta la razón.

## Agentes

Empareja agentes por identidad declarada (`name`) y función, no por extensión. Formatos nativos:

| Arnés | Fuente | Campos indispensables |
|---|---|---|
| OpenCode | `opencode/agents/<nombre>.md` | `description` en YAML; instrucciones en el cuerpo; modo/permisos si corresponden |
| Codex | `codex/agents/<nombre>.toml` | `name`, `description`, `developer_instructions` |
| Claude Code | `claude/agents/<nombre>.md` | `name`, `description` en YAML; instrucciones en el cuerpo |

- Cuando haya diferencias entre dos o tres versiones, muestra cuáles existen y ofrece por selector como fuente las versiones disponibles —**OpenCode**, **Codex** o **Claude Code**— además de **Omitir**. Pregunta por separado si se actualiza cada destino posible y confirma cada destino antes de escribir. Ningún arnés tiene prioridad permanente.
- Convierte instrucciones, descripción y controles de forma semántica al formato nativo del destino. No copies `.toml` como `.md` ni supongas equivalencia entre modelos, herramientas, modos o permisos. Muestra un borrador y enumera campos que no puedas trasladar fielmente; si un tipo de agente carece de contraparte válida, omite esa conversión y explica por qué.
- Los `.yaml` de `skills/*/agents/` son metadatos de presentación de Codex, no definiciones de agentes; no los reflejes en `agents/`.

## Comandos

Empareja por nombre de archivo: `opencode/commands/<n>.md` ↔ `claude/commands/<n>.md`. No uses listas de nombres: todo comando presente en cualquiera de los dos directorios entra en el análisis.

Clasifica cada comando de OpenCode:

- **Envoltorio de skill**: el cuerpo solo ordena usar una skill que existe en `opencode/skills/`. No generes par: Claude Code ya la expone como `/<skill>`. Reporta la equivalencia de nombre cuando difiera (por ejemplo `push-cloud` → `git-push-cloud`) y **no** sustituyas la skill por documentación derivada del comando.
- **Comando con lógica propia**: genera o compara el par en `claude/commands/`.
- **Codex**: no tiene comandos personalizados equivalentes. Reporta «no soportado» y no crees nada.

Si la clasificación no es clara, preséntala como duda y deja decidir al usuario.

Conversión **OpenCode → Claude** (borrador y confirmación por elemento):

- Cierra el frontmatter con `---` (corrige cierres malformados) y quita `agent`, `model` y `subtask`.
- Añade `argument-hint` si el cuerpo usa `$ARGUMENTS`.
- Deriva `allowed-tools` de las inyecciones `` !`cmd` ``, con un `Bash(<bin> <subcomando>:*)` por comando distinto. No concedas permisos fuera de los comandos detectados. Si una inyección usa redirecciones, tuberías o `|| true`, no es cubrible: muévela a una instrucción bajo demanda y avísalo.
- Propón `disable-model-invocation: true` cuando el comando tenga efectos secundarios (commit, push, borrado); lo decide el usuario.

Conversión **Claude → OpenCode**: quita `argument-hint`, `allowed-tools` y `disable-model-invocation`, informa qué campos se pierden y añade `agent` solo si el usuario lo pide.

Divergencias: si existe el par, compara el cuerpo ignorando las claves de frontmatter propias de cada arnés (no cuentan como diferencia). Si difiere, ofrece por selector **OpenCode → Claude**, **Claude → OpenCode** u **Omitir**; nunca sobrescribas sin confirmar.

## Instrucciones globales

- Solo existe `AGENTS.md` en la raíz del clon. OpenCode y Codex lo reciben como `AGENTS.md`, Claude Code como `CLAUDE.md` mediante `install.ps1`. No lo compares como par ni generes copias en cada directorio. La auditoría de enlaces corresponde a `install.ps1 -Doctor`.

## Resultado

En `dry-run`, muestra por nombre las diferencias de skills, agentes y comandos (pares iguales, faltantes, distintos, envoltorios de skill y no soportados), incompatibilidades y asimetrías deliberadas, sin escribir nada. En `apply`, incluye las decisiones y confirmaciones de cada par y resume exactamente qué archivos cambiaste. No ejecutes `install.ps1` desde esta skill.
