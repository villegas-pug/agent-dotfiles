# Provenance, estados e idempotencia

## Bloque de provenance

Todo artefacto generado lleva este bloque en su frontmatter, namespaced bajo `metadata.harness-sync`:

```yaml
metadata:
  harness-sync:
    version: 1
    origin:
      harness: claude-code        # claude-code | opencode | codex
      name: demo                  # nombre canónico del artefacto origen
      path: ".claude/skills/demo/SKILL.md"
    source_sha256: "<sha256 del archivo semántico origen (SKILL.md, .md del agente, command)>"
    files:
      - path: "references/nota.md"
        sha256: "<sha256>"
    transformations: [strip-fields:allowed-tools, strip-syntax:$ARGUMENTS, add-shim-command:demo]
    losses: [allowed-tools, hooks]
    generated_sha256: "<sha256 del archivo destino en el momento de generarlo>"
    synced_at: "2026-09-28T18:30:00Z"
```

Reglas del bloque:

- **Tolerado por los tres destinos**: Claude Code trata `metadata` como mapa libre; OpenCode v1 ignora campos desconocidos; Codex solo interpreta `name`/`description`.
- `origin` es **inmutable**: en re-sincronizaciones posteriores no se reescribe. Un artefacto C generado desde B (que venía de A) conserva el `origin` de A. La identidad canónica es `origin.harness + origin.name`.
- `source_sha256` cubre el contenido semántico origen **excluyendo** campos de tiempo; `synced_at` nunca participa en comparaciones.
- `files` registra los adjuntos copiados con su hash (rutas relativas al directorio del artefacto).
- Los artefactos fundidos en `AGENTS.md` no llevan bloque: quedan marcados como no trazables y fuera de la re-idempotencia automática.

## Máquina de estados

Por cada par origen→destino decide en este orden:

1. ¿Existe transformación válida según `references/matrix.md`? No → **UNSUPPORTED** (va al informe; jamás escribir).
2. ¿Existe el destino? No → **CREATE**.
3. El destino tiene provenance de esta skill:
   - `origin` distinto al origen actual → **CONFLICT** de identidad (colisión de nombre): opciones renombrar destino / sobrescribir / omitir.
   - `source_sha256` == hash del origen actual y `generated_sha256` == hash actual del destino → **UNCHANGED** (no escribir).
   - `source_sha256` difiere y `generated_sha256` == hash actual del destino → **UPDATE** (el origen cambió; el destino está intacto; re-escritura segura).
   - `generated_sha256` != hash actual del destino → **CONFLICT** (edición manual del destino): opciones sobrescribir / conservar manual / fusionar / omitir. Aplicar la advertencia git de abajo.
4. El destino no tiene provenance:
   - Contenido idéntico al borrador generado → ofrecer **ADOPT** (adjuntar provenance sin copia). Confirmar siempre.
   - Distinto → **CONFLICT** (archivo manual): opciones sobrescribir / fusionar / omitir. Aplicar la advertencia git de abajo.
5. La transformación tiene pérdidas (clasificación parcial o alternativa funcional) → marcar **ADAPT** y adjuntar la lista de pérdidas; se confirma una vez por lote, no por archivo.

No regeneres contenido para decidir: los estados se calculan sobre hashes. Excepción deliberada: detectar «contenido idéntico» en el paso 4 requiere el borrador; calcúlalo solo cuando el destino existe y carece de provenance.

## Anti-ciclos

Al sincronizar un destino que a su vez es origen potencial (ciclo OpenCode → Claude Code → Codex → OpenCode):

- El `origin` inmutable da al artefacto una identidad estable: al volver a OpenCode, el plan encuentra UNCHANGED/UPDATE sobre el mismo `origin`, no CREATE de un artefacto «nuevo».
- Si en un proyecto coexisten el original y derivados del mismo `origin` (p. ej. `.opencode/skills/demo` original y `.claude/skills/demo` derivado), el inventario los deduplica por identidad canónica y presenta el **original** como fuente, señalando los derivados.
- Nunca materialices dos destinos distintos para el mismo `origin` dentro de un mismo plan sin señalarlo en la confirmación.

## Reglas git (sin backups automáticos)

Esta skill no crea backups: el control de versiones del proyecto es la red de seguridad. Antes de sobrescribir cualquier archivo sin provenance (CONFLICT de los pasos 3 y 4):

1. Ejecuta `git status --porcelain -- <ruta relativa>` desde la raíz del workspace.
2. Si el archivo aparece como modificado o sin seguimiento, o el comando falla (no es un repo git), advierte: «sin commit previo / sin repositorio; al sobrescribir no habrá recuperación automática» y exige confirmación reforzada (respuesta afirmativa explícita del usuario).
3. Si el archivo está limpio, recuerda que puede recuperarse con git y continúa con la confirmación normal.

## Validación post-escritura

- Frontmatter YAML parseable; en destinos OpenCode v1, `name` kebab-case igual al nombre del directorio.
- Archivos requeridos presentes (`SKILL.md` en skills; `name`/`description`/`developer_instructions` en TOML de Codex).
- Origen intacto: recalcula `source_sha256` del origen tras la ejecución y compáralo con el valor tomado en el inventario.
- Informe final: rutas escritas con estado final, omisiones con motivo, pérdidas semánticas por artefacto y advertencias (discrepancia de rutas de skills de Codex, proyecto Codex no «trusted», versión de OpenCode detectada, estado git de los archivos sobrescritos).
