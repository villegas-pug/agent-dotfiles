---
name: prompt-augmenter
description: Enriquece una solicitud base con uno o varios augmenters elegidos por el usuario y ejecuta la solicitud resultante. Usar cuando se invoque prompt-augmenter o se pida seleccionar criterios reutilizables antes de realizar una tarea.
---

# Prompt Augmenter

El prompt base es siempre la intención principal. Los augmenters solo agregan criterios para cumplirla; no agregan funcionalidades ni sustituyen el objetivo. Esta skill funciona en OpenCode, Codex y Claude Code sin depender de herramientas o rutas exclusivas de ninguno.

## Catálogo para seleccionar

Presenta estas cuatro categorías con nombre, etiqueta y una breve explicación. Este índice **no contiene las instrucciones completas**: están en `references/<nombre>.md` y se leen únicamente después de la selección.

### Analysis

- `impact-analysis` — Impact Analysis: dependencias y efectos del cambio.
- `reuse-analysis` — Reuse Analysis: consumidores de lo compartido.
- `traceability` — Traceability: recorrido end-to-end de datos y flujo.
- `database-impact` — Database Impact: persistencia y consumidores de datos.

### Safety

- `regression-safety` — Regression Safety: comportamiento con riesgo de regresión.
- `scope-guard` — Scope Guard: límite de lo solicitado.
- `compatibility-check` — Compatibility Check: contratos y compatibilidad previa.
- `security-review` — Security Review: riesgos de seguridad pertinentes.

### Quality

- `architecture-review` — Architecture Review: coherencia arquitectónica.
- `test-impact` — Test Impact: escenarios y pruebas afectados.

### Behavior

- `analyze-only` — Analyze Only: entregar análisis sin modificaciones.
- `minimal-change` — Minimal Change: menor superficie de cambio razonable.
- `no-refactor` — No Refactor: evitar refactors ajenos a la solicitud.
- `preserve-existing-behavior` — Preserve Existing Behavior: mantener lo no solicitado.

## Flujo obligatorio

1. Presenta el catálogo agrupado. Admite **uno o varios** nombres de cualquier categoría. Si el arnés ofrece una herramienta nativa de preguntas con selección múltiple, habilita esa modalidad y úsala; de lo contrario pide una lista de nombres por conversación. Si el usuario ya indicó nombres explícitos, confirma la selección sin pedirla de nuevo. No preselecciones ni infieras otros augmenters. Si elige ninguno, solicita al menos uno o permite cancelar.
2. Obtén el prompt base de los argumentos de la invocación o del mensaje explícito del usuario. Si no existe o no queda claro qué parte es la solicitud, pídelo y espera la respuesta. No inventes ni ejecutes un prompt provisional.
3. **Lee solo** los archivos `references/<nombre>.md` correspondientes a los nombres elegidos y existentes. No leas otros archivos de `references/`, aunque parezcan relacionados. Si hay un nombre desconocido, muéstrale el catálogo para corregirlo; no sustituyas nombres automáticamente.
4. Compón conceptualmente el prompt base y las instrucciones seleccionadas, sin reescribir ni alterar la intención original. Evita duplicar exigencias equivalentes si hay solapamiento. Ante un conflicto, respeta la intención explícita, luego la seguridad y la preservación de comportamiento y finalmente la interpretación más conservadora. Si la combinación sigue siendo contradictoria (p. ej. «implementa» junto con `analyze-only`), pide aclaración antes de actuar.
5. Informa brevemente «Aplicaré: ...» con **solo** los nombres elegidos; después ejecuta la solicitud enriquecida con las herramientas y autorizaciones normales del arnés. No te detengas tras mostrar un prompt reformulado. En tareas de solo análisis no modifiques archivos. No ejecutes builds ni pruebas si las reglas del usuario o del proyecto exigen autorización previa.

## Extender el catálogo

Para añadir un augmenter, crea `references/<nuevo-nombre>.md` con sus instrucciones complementarias y añade una línea de nombre, etiqueta y resumen en la categoría apropiada de este índice. Mantén equivalentes la skill y su referencia en Codex; Claude Code comparte directamente la versión de OpenCode. Si un augmenter necesita herramientas, fases propias o entradas/salidas independientes, considera una skill aparte.
