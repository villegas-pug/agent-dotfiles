---
name: sync-agents
description: Mantiene simetría entre los directorios `opencode/` y `codex/` del repo `~/dotfiles/`. Detecta y propone mirrors de skills, commands y agents; analiza drift en `AGENTS.md` y ofrece resolución (MERGE / A→B / B→A / skip). Modos: `dry-run` (default, solo propone) y `apply` (aplica con confirmación por par). Cargar cuando el usuario diga "sincroniza los agentes", "mirror las skills", "alinea opencode y codex", "qué difiere entre lados", "propone mirror", "aplica sync", o mencione explícitamente `sync-agents`.
---

# Sync Agents Skill

Metodología para mantener simetría estructural entre `opencode/` y `codex/` dentro del repo de dotfiles `~/dotfiles/`. **NO aplica a ningún otro repo.** Este skill describe el "cómo"; el "cuándo" se delega al usuario o al comando slash `/sync-agents`.

## Cuándo disparar

Cargar este skill cuando el usuario exprese intención de sincronización cross-agent, por ejemplo:

- "sincroniza los agentes", "mirror las skills", "alinea opencode y codex".
- "qué difiere entre lados", "qué hay en un lado que no en el otro".
- "propone mirror", "aplica los mirrors", "aplica sync".
- "qué cambiaría si aplico la sync", "vista previa de sync".
- "ayuda", "opciones", "qué hace este skill".
- Cualquier mención explícita de `sync-agents` o de las palabras canónicas (`dry-run`, `apply`).

**NO usar este skill** para:

- Cualquier repositorio distinto a `~/dotfiles/`.
- Operaciones de git (`commit`, `push`) — usar `/commit`.
- Symlinks de dotfiles — usar el skill `dotfiles` o el comando `/dotfiles`.
- Cambios al `AGENTS.md` del proyecto actual (no del repo dotfiles).
- Compilar, build o tests — prohibido por `codex/AGENTS.md` y `opencode/AGENTS.md`.

## Cobertura

| Par | Sentido del mirror | Drift handling |
|---|---|---|
| `skills/` ↔ `skills/` | bidireccional con adaptaciones | side-by-side + A→B / B→A / skip |
| `commands/` → `codex/skills/<name>/SKILL.md` | unidireccional (OC → CX doc) | side-by-side + A→B / B→A / skip si CX-side existe |
| `agents/` ↔ `agents/` | por extensión: `.md` bidireccional; `.yaml` skip | side-by-side en `.md`; `.yaml` warning |
| `themes/` | sin counterpart | solo reportar asimetría |
| `opencode/AGENTS.md` ↔ `codex/AGENTS.md` | bidireccional solo por selección | MERGE / A→B / B→A / skip (nunca auto) |

## Modos

| Modo | Mutación | Uso típico |
|---|---|---|
| `dry-run` (default) | no | "qué cambiaría", inspección |
| `apply` | sí | aplicar con confirmación obligatoria por par |

Sin argumento explícito → `dry-run`. Cualquier acción destructiva dentro de `apply` requiere confirmación textual del usuario antes de cada paso.

## Proceso general

1. **Detección** — listar todos los archivos bajo `opencode/` y `codex/` (excluyendo `**/.system/`, `**/.bak-*`, `**/.git/`).
2. **Clasificación por par** — para cada archivo, determinar a qué par pertenece y si tiene contraparte.
3. **Diff** — para cada par con archivos en ambos lados, calcular hash y comparar bytes.
4. **Reporte** — imprimir, agrupado por par:
   - **simétricos**: lista (OK).
   - **missing** (existe en uno solo): propuesta de mirror con adaptaciones.
   - **drift** (existe en ambos con bytes distintos): opciones según tipo de par.
5. **Apply** (solo modo `apply`) — ejecutar la acción elegida con confirmación explícita por par.

## Comportamiento por par

### `skills/` ↔ `skills/`

**Missing en uno de los lados** (proponer mirror con adaptaciones automáticas):

- Strip `allowed-tools:` del frontmatter (Codex no lo usa). Solo aplica en dirección OC → CX.
- Traducción provisional de `description:` si está en inglés → español con marca `⚠️ revisar`. Solo aplica en dirección CX → OC.
- Reescritura de paths tipo `$CODEX_HOME/...` o `~/.codex/...` → `$DOTFILES_HOME/opencode/...` o `~/dotfiles/opencode/...`. Solo aplica en dirección CX → OC.
- Confirmar antes de escribir.

**Drift** (mismo nombre, bytes distintos):

1. Imprimir side-by-side (diff resumido si los archivos son >100 líneas; `diff` con `--unified=2` por defecto).
2. Ofrecer 3 acciones:
   - **A→B**: opencode gana; codex se reemplaza con copia exacta de opencode.
   - **B→A**: codex gana; opencode se reemplaza con copia exacta de codex.
   - **skip**: dejar drift sin tocar; registrar como pendiente.
3. Esperar selección del usuario; aplicar solo con confirmación.

### `commands/` → `codex/skills/<name>/SKILL.md`

**Missing en Codex-side** (proponer creación de doc):

- Generar `codex/skills/<command-name>/SKILL.md` con este template (mín. 6 líneas):

  ```
  ---
  name: <command-name>
  description: Documentación derivada del comando slash OpenCode `/<command-name>`. Codex no ejecuta comandos slash; este archivo es solo nota informativa sobre el counterpart en `opencode/commands/<command-name>.md`.
  ---

  # <command-name> (Codex)

  Este archivo es documentación derivada del comando OpenCode `/<command-name>`. No es ejecutable desde Codex.

  Fuente: `opencode/commands/<command-name>.md`.
  ```

- Confirmar antes de escribir.

**Codex-side es deriv-only**: nunca se lee como verdad. Si codex-side ya existe (de una ejecución previa), aplicarle la lógica de `skills/` drift: side-by-side + A→B / B→A / skip.

### `agents/` ↔ `agents/`

**Regla por extensión**:

| Extensión | Lado origen | Lado destino | Acción |
|---|---|---|---|
| `.md` | ambos | ambos | mirror con adaptaciones (idénticas a `skills/`); drift handling en `.md` |
| `.yaml` | `codex/agents/` | (nadie) | detectar y reportar como "Codex-only metadata; no se refleja a OpenCode" |

`.yaml` files son metadata de skills para Codex; OpenCode no los lee. **Nunca se copian a `opencode/agents/`.**

### `themes/`

`opencode/themes/` no tiene counterpart en Codex. Acción: detectar archivos existentes y reportar la asimetría. **No se muta nada.**

### `AGENTS.md` ↔ `AGENTS.md`

Caso especial: el drift aquí tiene **4 acciones disponibles** en lugar de 3.

1. Imprimir side-by-side (diff unificado).
2. Ofrecer:
   - **MERGE**: el LLM lee ambos, redacta un draft unificado.
     - Secciones comunes (mismo `## header` + mismo cuerpo) → una sola versión.
     - Secciones divergentes (mismo `## header`, cuerpo distinto) → marcadas con `<!-- ORIGIN: opencode -->` y `<!-- ORIGIN: codex -->` para revisión humana.
     - Secciones únicas (header solo en uno) → preservadas con su origen explícito.
   - **A→B**: opencode gana; codex se reemplaza. **Pierde contenido único de codex.**
   - **B→A**: codex gana; opencode se reemplaza. **Pierde contenido único de opencode.**
   - **skip**: dejar drift sin tocar.
3. Si MERGE: imprimir el draft completo; esperar aprobación textual del usuario; solo entonces escribir a disco.

**Regla dura**: `AGENTS.md` nunca se auto-edita, ni siquiera en modo `apply`. La aprobación es por archivo, no por lote.

## Adaptaciones automáticas (lista cerrada)

Estas transformaciones se aplican durante mirror o MERGE. Cualquier otra transformación requiere intervención manual.

1. **Strip `allowed-tools:`** — Codex no lo usa; OC sí. Solo aplica en dirección OC → CX.
2. **De-Codex paths** — paths tipo `$CODEX_HOME/skills/...` o `~/.codex/...` se reescriben a `$DOTFILES_HOME/opencode/skills/...` o `~/dotfiles/opencode/...`. Solo aplica en dirección CX → OC.
3. **Traducción provisional de `description:`** — si la `description:` del frontmatter está en inglés, traducir al español y marcar con `⚠️ revisar`. Solo aplica en dirección CX → OC.
4. **Skip `codex/agents/*.yaml`** — nunca copiar a OpenCode.
5. **Skip `sync-agents/SKILL.md` en auto-mirror** — es la misma skill en ambos lados; debe ser idéntica. No entra en el flujo de simetría.

## Drift handling resumido

| Par | Detección | Opciones |
|---|---|---|
| `skills/` | bytes distintos | A→B / B→A / skip |
| `commands/` (Codex-side) | bytes distintos | A→B / B→A / skip |
| `agents/` `.md` | bytes distintos | A→B / B→A / skip |
| `agents/` `.yaml` | siempre | reportar (no muta) |
| `themes/` | n/a | reportar (no muta) |
| `AGENTS.md` | bytes distintos | MERGE / A→B / B→A / skip (nunca auto) |

## Reglas duras

1. **Modo default: `dry-run`**. Cualquier mutación requiere modo `apply` explícito.
2. **Drift = stop**: nunca pisar contenido divergente sin selección explícita del usuario.
3. **MERGE = revisión obligatoria**: el draft unificado siempre se imprime completo antes de aplicar.
4. **Self-reference excluded**: `opencode/skills/sync-agents/SKILL.md` ↔ `codex/skills/sync-agents/SKILL.md` se excluye del auto-mirror.
5. **AGENTS.md nunca auto-edit**: solo aplica con A→B, B→A, o MERGE + aprobación explícita por archivo.
6. **Codex `.yaml` en agents/**: detectado y reportado, nunca copiado a OpenCode.
7. **Comandos Codex-side son deriv-only**: nunca se leen como verdad.
8. **Sin ejecución de git**: este skill NO corre `git add`, `git commit`, ni `git push`. El usuario corre `/commit` por separado.
9. **Sin ejecución de `install.ps1`**: este skill NO toca symlinks. Para eso existe `/dotfiles`.

## Salida esperada

Después de ejecutar el análisis (modo `dry-run`) o la aplicación (modo `apply`), presentar este reporte agrupado por par:

```
=== Sync Agents Report ===
Modo: dry-run | apply
Repo: ~/dotfiles/

[ skills/ ]
  OK simétricos: <N> [<nombres>]
  FALTA missing: <N> [<lado_origen> → <lado_destino>]
  DRIFT drift: <N> [<nombres>]

[ commands/ → codex/skills/ ]
  FALTA missing en Codex-side: <N> [<nombres>]
  DRIFT drift (CX-side vs OC): <N> [<nombres>]

[ agents/ ]
  OK simétricos (.md): <N>
  DRIFT drift (.md): <N>
  SKIP skip (.yaml): <N> [<nombres>]

[ themes/ ]
  ASIM asimetría reportada: <N> en OC, 0 en CX (sin counterpart)

[ AGENTS.md ]
  DRIFT drift detectado (<X> líneas difieren)
  → Opciones: MERGE / A→B / B→A / skip

=== Fin del reporte ===
```

No parafrasear ni filtrar este output. Es la fuente de verdad para que el usuario decida.

## Casos de error conocidos

### Repo no encontrado

Síntoma: `~/dotfiles/` no existe o `.git/` falta.

```
[ERROR] ~/dotfiles/ no encontrado o no es un repo git.
Este skill solo aplica al repo dotfiles de OpenCode/Codex en este equipo.
```

Detenerse; no continuar con el análisis.

### Permisos insuficientes para escribir

Si un mirror falla por permisos, reportar el archivo específico y **no continuar** con los siguientes. Esperar instrucción.

### `.system/` leakage detectado

Si al listar archivos aparece contenido bajo `codex/skills/.system/` (skills internos de Codex), confirmar que `.gitignore` contiene `**/.system/` y `**/.system-*`. No incluir esos archivos en ningún mirror ni reportarlos como missing.

## Relación con el comando `/sync-agents`

El comando slash delega toda la metodología a este skill. Diferencia operativa: el comando aplica las reglas de dispatch (sin args → menú + parada) y este skill contiene el "cómo". Cualquier ambigüedad → reapuntar al skill.
