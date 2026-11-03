# Detección de harnesses, versiones y rutas

## Harness invocador

Pregunta siempre, con una opción pre-seleccionada. Señales de inferencia, en orden:

1. Variables de entorno del harness en el proceso actual (p. ej. `CLAUDE_CODE_*`, `OPENCODE_*`, `CODEX_*`).
2. Herramientas nativas de pregunta disponibles en este contexto: AskUserQuestion → Claude Code; `question` → OpenCode; ninguna de las dos → Codex.
3. Si ninguna señal es concluyente, presenta las tres opciones sin pre-selección.

## OpenCode: versión v1 vs v2

Las documentaciones v1 (`opencode.ai/docs`) y v2 (`opencode.ai/v2/docs`) coexisten y difieren en campos y comportamientos relevantes. Detección, en orden:

1. `opencode --version` del binario en PATH (major 1.x = v1, 2.x = v2). Caveat: puede no ser el binario que realmente usa el usuario.
2. Señales en la config del proyecto: clave `agent` → v1; clave `agents` → v2.
3. Si persiste la ambigüedad, pregunta.

Regla de escritura — **mínimo común v1+v2**: skills en directorio kebab-case cuyo nombre coincida con el frontmatter `name` (exigencia de v1; válido también en v2, donde el identificador sale de la ruta). Nunca depender del fallback `CLAUDE.md` (eliminado en v2) ni de campos exclusivos de v2 (`slash`, `opencode/*`). `AGENTS.md` es la vía portable de instrucciones en ambas versiones.

## Codex: rutas de skills (discrepancia documentada)

La documentación vigente (learn.chatgpt.com/docs) lista como rutas de skills: `$REPO_ROOT/.agents/skills`, `$CWD/.agents/skills`, `$CWD/../.agents/skills`, `$HOME/.agents/skills`, `/etc/codex/skills` y las incluidas con Codex. **Ya no documenta `~/.codex/skills`**, aunque en la práctica sigue funcionando (0.154.x). Orden de lectura empírico dentro del proyecto:

1. `.agents/skills/<nombre>/SKILL.md` (ruta documentada; prioritaria).
2. `.codex/skills/<nombre>/SKILL.md` (no documentada; aceptar si existe y avisar una sola vez por sesión de la discrepancia).

Al **escribir** skills de proyecto para Codex, usa siempre `.agents/skills/`. Nunca escribas en `$HOME/.agents/skills` ni `~/.codex/skills`: son ámbito global, fuera del alcance de esta skill.

## Codex: comandos personalizados

El soporte de `.codex/prompts/*.md` no está confirmado en la documentación vigente del CLI (la app documenta `/prompts:<nombre>`). Detección empírica: si existe `.codex/prompts/` en el proyecto, trátalo como fuente de commands con frontmatter reducido (`description`). Si no existe y se piden migrar commands hacia Codex, ofrece la alternativa funcional de `references/matrix.md` (skill con `agents/openai.yaml: allow_implicit_invocation: false`).

## Detección de harnesses en el proyecto

| Señal en el workspace | Harness |
|---|---|
| `.claude/skills/`, `.claude/commands/`, `.claude/agents/`, `.claude/settings.json`, `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/` | Claude Code |
| `opencode.json`/`opencode.jsonc`, `.opencode/` | OpenCode |
| `.codex/config.toml`, `.codex/agents/`, `.codex/rules/`, `.codex/prompts/` | Codex |
| `.agents/skills/` | Codex (estándar vigente) |
| `AGENTS.md` en raíz | débil — lo leen los tres; combina con otras señales |
