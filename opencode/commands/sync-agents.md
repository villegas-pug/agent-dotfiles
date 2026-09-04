---
description: Sincroniza contenido entre `opencode/` y `codex/` del repo `~/agent-dotfiles/`. Modos canónicos: `dry-run` (default, vista previa), `apply` (aplica con confirmación por par), `help` (menú). Sin argumentos imprime el menú y se detiene — no analiza ni muta nada. Detecta skills, commands, agents, themes y AGENTS.md; propone mirrors con adaptaciones y resolución de drift.
agent: build
---

# Sync Agents — comando slash

Comando canónico para mantener simetría cross-agent en el repo `~/agent-dotfiles/`. Modos: `dry-run | apply | help`. **Sin args / args desconocido → imprimir menú y detenerse. No se analiza ni se muta el repo.**

## Reglas de dispatch

1. Parsear `$ARGUMENTS` (trim, lower-case).
2. Comparar contra la tabla `Keyword → Modo`. Si no matchea exactamente, ejecutar paso "Menú + parada".
3. Si matchea `help`: imprimir menú + parada.
4. Si matchea `dry-run`: ejecutar análisis en modo lectura; imprimir el reporte completo; finalizar.
5. Si matchea `apply`: ejecutar análisis + solicitar confirmación por par antes de mutar.

## Tabla Keyword → Modo (única verdad)

| Keyword | Modo | Categoría |
|---|---|---|
| `dry-run` | análisis sin mutación | read-only |
| `help` | (no analiza) | read-only |
| `apply` | análisis + mutación con confirmación | destructiva |

Solo se aceptan estos 3 valores literales. No aliases. No inferencia. Frases ambiguas como `/sync-agents sync` o `/sync-agents ejecutar` caen al menú.

## Menú + parada

Cuando `$ARGUMENTS` está vacío, no matchea la tabla, o el usuario pide `help`:

```
Modos disponibles para /sync-agents:

  dry-run   analizar deltas entre opencode/ y codex/ (sin tocar nada)
  apply     analizar + aplicar mirrors y resolución de drift (con confirmación por par)
  help      reimprimir este menú
```

Después del menú, finalizar la respuesta sin ejecutar nada.

## Confirmación obligatoria (solo `apply`)

En modo `apply`, antes de mutar cada par:

1. Presentar el reporte del par:
   - Skills missing → cuántos, cuáles, dirección del mirror.
   - Skills drift → cuántos, cuáles, opciones A→B / B→A / skip.
   - Commands missing en CX-side → cuántos, cuáles.
   - Commands drift → cuántos, cuáles, opciones.
   - Agents `.md` missing/drift → cuántos, cuáles, opciones.
   - Agents `.yaml` → cuántos (Codex-only, no muta).
   - Themes → cuántos (asimetría, no muta).
   - AGENTS.md drift → opciones MERGE / A→B / B→A / skip.
2. Resumir el impacto: "Voy a crear/actualizar **M** archivos y dejar **N** pendientes de revisión manual."
3. Preguntar: **"¿Confirmo?"** — esperar `sí` / `no` textual.
4. Solo con `sí` explícito, ejecutar las acciones automáticas (missing → mirror). Para cada drift, esperar selección individual (A→B / B→A / MERGE / skip).

Si el usuario responde `no` o silencio → cancelar y reportar "Cancelado por el usuario".

### Casos especiales dentro de `apply`

- **MERGE en AGENTS.md**: el LLM redacta el draft unificado, lo imprime completo, y pregunta "¿Aplico este MERGE?". Solo con `sí` se escribe.
- **A→B o B→A en AGENTS.md**: el skill recuerda que se pierde contenido único del lado reemplazado; pide segunda confirmación.
- **Drift en `skills/` o `commands/`**: cada drift se resuelve individualmente; no se procesan en lote.

## Análisis en `dry-run` y `apply`

El análisis se delega completamente al skill `sync-agents/SKILL.md`. El comando solo:

1. Cambia al directorio del repo: `cd "F:\work-space\agent-dotfiles"`.
2. Invoca el skill (no se llama a un script externo; el LLM lee ambos lados directamente).
3. Imprime el reporte tal cual lo devuelve el skill.

Rutas de inspección esperadas:

```powershell
$opencode = "F:\work-space\agent-dotfiles\opencode"
$codex    = "F:\work-space\agent-dotfiles\codex"
```

## Reglas duras

1. **Nunca** ejecutar mutación sin modo `apply` explícito + `sí` textual en el turno actual.
2. **Nunca** aceptar argumentos fuera de la tabla. Si el usuario escribe `/sync-agents sync`, no es un error: es "muéstrale el menú".
3. **Nunca** ejecutar `git add`, `git commit` o `git push` desde este comando. Para eso existe `/commit`.
4. **Nunca** ejecutar `install.ps1` desde este comando. Para eso existe `/dotfiles`.
5. **Nunca** escribir `AGENTS.md` sin aprobación explícita, ni siquiera en modo `apply`.
6. **Nunca** copiar `codex/agents/*.yaml` a `opencode/agents/`.
7. **Nunca** modificar el contenido de un archivo en drift sin selección explícita del usuario por par.

## Estado del repo (no se commitea automáticamente)

Ruta del repo: `F:\work-space\agent-dotfiles`

Estado de git (solo informativo, no se muta):

!`git status --short`

Último commit (solo informativo):

!`git log -1 --format="%h %s" 2>/dev/null || echo "(no commits)"`

## Salida esperada

Después del análisis (en cualquier modo), presentar:

1. Una línea con el modo ejecutado.
2. El reporte del skill **tal cual** lo devolvió.
3. Una frase de cierre breve: "Sin cambios pendientes." / "Apply cancelado por el usuario." / "N mirrors aplicados, M drifts resueltos." / etc.

No parafrasear ni filtrar el output del skill.

## Errores conocidos y respuesta

### Repo no encontrado

Si `~/agent-dotfiles/` no existe o no es un repo git:

```
[ERROR] ~/agent-dotfiles/ no encontrado o no es un repo git.
Este comando solo aplica al repo dotfiles de OpenCode/Codex en este equipo.
```

Detenerse; no continuar.

### `.system/` detectado

Si al listar `codex/skills/` aparece contenido bajo `.system/`:

```
[INFO] Detectado codex/skills/.system/ (skills internos de Codex).
Estos archivos se ignoran (definido en .gitignore: **/.system/, **/.system-*).
No se reportan como missing ni entran en mirror.
```

### Drift detectado pero apply no confirmado

Si el usuario invoca `/sync-agents` (modo default `dry-run`) y hay drift:

```
[INFO] Drift detectado pero modo actual es dry-run.
Para resolver drift, invoca: /sync-agents apply
```

## Relación con el skill `sync-agents`

Este comando **delega la metodología** al skill `sync-agents/SKILL.md`. Si el comando encuentra ambigüedad (e.g., el usuario escribe `/sync-agents sync` con intención vaga), reapunta al skill para aplicar la heurística.

En cualquier caso, este archivo manda: si la subacción canónica es `apply`, se requiere confirmación, sin excepciones.
