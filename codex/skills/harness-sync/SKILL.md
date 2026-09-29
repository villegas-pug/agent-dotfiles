---
name: harness-sync
description: Migra y sincroniza skills, comandos, agentes, instrucciones y configuración entre OpenCode, Claude Code y Codex dentro del proyecto actual. Usar cuando se pida migrar, sincronizar o adaptar artefactos de un arnés a otro en el repositorio activo. Efectos solo locales al proyecto invocado; para alinear artefactos dentro del clon de agent-dotfiles usar sync-agents.
---

# Harness Sync

## Alcance e invariantes

Trabaja exclusivamente sobre el repositorio activo desde el que fue invocada. La skill es global; **sus efectos no lo son**: nunca escribe fuera de la raíz de ese repositorio. Prohibido escribir en `~/.claude`, `~/.codex`, `~/.config/opencode` y `~/.agents` (esas rutas solo sirven para instalar esta skill, no para migrar). Si el proyecto invocado es el clon de `agent-dotfiles`, detente y remite a la skill `sync-agents`: esa alinea contenido dentro del clon; esta migra artefactos entre proyectos.

- **No destructiva**: nunca elimina ni modifica los artefactos del harness origen.
- **Idempotente**: una segunda ejecución sin cambios no escribe nada.
- **Sin inventos**: cada equivalencia se clasifica (directa | parcial | alternativa funcional | no soportada) y las pérdidas semánticas se informan siempre. No generes capacidades inexistentes en el destino.
- **No destructiva ante lo manual**: un destino editado a mano jamás se sobrescribe sin confirmación y advertencia git (ver `references/provenance.md`).

## Flujo

1. **Workspace**: determina la raíz con `git rev-parse --show-toplevel`. Si el comando falla o el resultado es ambiguo (worktree, submódulo), **detente y pregunta**; no asumas rutas ni escribas nada. Toda ruta destino debe quedar bajo esta raíz. Si el usuario corrige la ruta, verifica que sea un repositorio antes de continuar.
2. **Harnesses detectados**: inspecciona señales de proyecto — `.claude/` (settings.json, skills/, commands/, agents/, CLAUDE.md), `opencode.json(c)` o `.opencode/`, `.codex/` (config.toml, agents/, rules/), `.agents/skills/`, `AGENTS.md` y `CLAUDE.md` en raíz. Un `AGENTS.md` aislado es señal débil (lo leen los tres): anótalo, pero no concluyas con él solo.
3. **Harness invocador**: pregunta siempre, con la opción pre-seleccionada inferida del entorno (variables de entorno del harness; herramientas nativas disponibles: AskUserQuestion → Claude Code, `question` → OpenCode, ninguna → Codex). Solo adapta el estilo de interacción; el destino puede ser cualquiera de los tres.
4. **Inventario**: por cada harness detectado, lista artefactos por tipo — skills, commands, agents, instrucciones, config — con rutas relativas al workspace y hash SHA256 por archivo (`Get-FileHash -Algorithm SHA256 -LiteralPath <archivo>` en PowerShell 7+). Copia el árbol completo de cada skill (referencias, scripts, assets), no solo su `SKILL.md`.
5. **Origen y destino**: si hay una sola fuente posible, úsala y confírmala; si hay varias, deja elegir. El harness que ejecuta la skill y el destino son independientes (p. ej., puedes ejecutarte desde Codex y generar artefactos para OpenCode).
6. **Equivalencias**: lee `references/matrix.md` antes de clasificar. Normaliza cada artefacto a su forma canónica, clasifica la equivalencia hacia el destino y enumera las pérdidas. Consulta `references/formats.md` para el formato nativo exacto del destino y `references/harnesses.md` para versiones y rutas empíricas.
7. **Plan**: asigna a cada par origen→destino un estado (CREATE | UPDATE | UNCHANGED | ADAPT | UNSUPPORTED | CONFLICT) según `references/provenance.md`. Los artefactos sin transformación válida quedan UNSUPPORTED en el informe.
8. **Confirmación**: presenta el plan agrupado por tipo — tabla `nombre | origen → destino | estado | transformación | pérdidas` — y pide: **aplicar todo / revisar uno a uno / cancelar**. ADAPT y CONFLICT exigen ver pérdidas o diff antes de confirmar; la lista de pérdidas de un lote ADAPT se confirma una sola vez.
9. **Ejecución**: escribe únicamente bajo la raíz del workspace, en las rutas nativas del destino. Antes de sobrescribir cualquier archivo sin provenance de esta skill, aplica la advertencia git de `references/provenance.md`. No hay backups automáticos: el control de versiones del proyecto es la red de seguridad.
10. **Validación y reporte**: verifica frontmatter YAML parseable, coherencia nombre/directorio (exigencia de OpenCode v1) y archivos requeridos presentes; recalcula hashes para confirmar que el origen quedó intacto; y emite el informe final — rutas escritas, estados finales, omisiones con motivo, pérdidas semánticas por artefacto y advertencias.

## Interacción según el harness invocador

- **Claude Code**: usa la herramienta nativa de preguntas con opciones cuando esté disponible.
- **OpenCode**: usa la herramienta `question` (admite selección múltiple en v2 y respuesta libre siempre).
- **Codex**: no hay herramienta estructurada; presenta opciones numeradas en texto y pide responder con el número o texto libre.
- **Degradación común**: si la herramienta nativa no está disponible o no está permitida, usa texto numerado en cualquier harness.

Para selecciones con muchas opciones (p. ej., decidir shims skill a skill), ofrece además la decisión agrupada: todos / ninguno / revisar uno a uno.

## Referencias

- Lee `references/harnesses.md` para detectar harnesses, versiones de OpenCode (v1/v2) y las rutas empíricas de skills de Codex.
- Lee `references/matrix.md` antes de clasificar equivalencias.
- Lee `references/provenance.md` antes de asignar estados o escribir.
