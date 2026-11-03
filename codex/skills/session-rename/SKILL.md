---
name: session-rename
description: Propone nombres en inglés `{{feature}}-{{action}}` para la sesión actual de OpenCode, Codex o Claude Code, deja elegir uno y lo aplica cuando el arnés lo permite. Usar cuando el usuario pida nombrar, titular o etiquetar la sesión; el contexto sale del argumento o de la propia conversación.
---

# Session Rename

Propone título para la sesión actual en formato `{{feature}}-{{action}}` (inglés, kebab-case), deja elegir uno y lo aplica cuando el arnés lo permite.

## Cuándo disparar

Pedidos como "renombra esta sesión", "ponle nombre a este chat", "qué título le pongo" o "etiqueta la sesión". NO sirve para renombrar archivos, branches, commits ni recursos del proyecto.

## Fuente de contexto

Usa la primera fuente que dé una señal clara:

1. **Argumento del usuario**: si lo da, es la única fuente.
2. **Conversación ya presente**: las tareas visibles en el contexto (incluye el resumen tras `/compact`). Costo cero; no releas nada.
3. **Una consulta git**, solo si 1 y 2 no alcanzan: `git status --short` y `git log -3 --oneline`.
4. **Pedir el resumen**: si nada de lo anterior es claro, pide en español 2-3 líneas de lo hecho. No insistas.

## Presupuesto de lectura (regla dura)

- Máximo una llamada de herramienta, con salida de ~20 líneas.
- Prohibido: leer transcripts `.jsonl`, `git diff` completo, archivos del proyecto o listar directorios para «entender» la sesión.

## Formato

- Forma `feature-action` o `feature-context-action`; `action` va siempre al final.
- Solo `[a-z-]`, kebab-case, sin guion inicial ni final, `feature` en singular, ≤ 40 caracteres.
- Acción del vocabulario cerrado: `fix`, `add`, `refactor`, `integrate`, `migrate`, `debug`, `optimize`, `remove`, `wire`, `setup`, `scaffold`, `implement`, `extract`, `rename`.
- Sesión multitema: nombra por el tema que ocupó más turnos o cerró con un cambio. Las alternativas pueden cubrir otros temas; nunca mezcles temas en un solo nombre.

## Salida

```
**Recomendado:** `<nombre>`

1. `<nombre>` — razón en ≤ 8 palabras.
2. `<nombre>` — razón en ≤ 8 palabras.
3. `<nombre>` — razón en ≤ 8 palabras.
Contexto usado: argumento | conversación | git
```

Entre 3 y 5 propuestas, una marcada como recomendada.

## Elegir y aplicar

1. **Elegir**: pide al usuario elegir una propuesta; la recomendada va primero. Usa la herramienta nativa de preguntas (`AskUserQuestion` en Claude Code, `question` en OpenCode). Si no existe, usa opciones numeradas en texto. Acepta texto libre. No elijas por el usuario.
2. **Aplicar**:
   - Si `session_rename` está entre tus herramientas (OpenCode con el plugin instalado), llámala con el nombre elegido y confirma el resultado.
   - Si no está (Claude Code y Codex no permiten renombrar desde una skill), muestra la línea `/rename <nombre>` lista para pegar y di que el título se aplica con ese comando.
3. Si `session_rename` falla, muestra el error tal cual y ofrece `/rename <nombre>` como alternativa.

Aplicar el título no cuenta como lectura y no requiere consultas adicionales.

## Referencias

- `references/examples.md`: ejemplos y anti-ejemplos. Léelo solo si hay duda sobre el formato; no lo cargues por defecto.
