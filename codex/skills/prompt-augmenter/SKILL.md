---
name: prompt-augmenter
description: Enriquece una solicitud base con uno o varios augmenters elegidos por el usuario y ejecuta la solicitud resultante. Usar cuando se invoque prompt-augmenter o se pida seleccionar criterios reutilizables antes de realizar una tarea.
---

# Prompt Augmenter

El prompt base es siempre la intención principal. Los augmenters solo agregan criterios para cumplirla; no agregan funcionalidades ni sustituyen el objetivo. Las reglas funcionales son compartidas entre Codex, OpenCode y Claude Code; la interacción para elegir augmenters se adapta al harness.

## Catálogo para seleccionar

Presenta estas tres categorías con sus opciones y descripciones breves. Este índice **no contiene las instrucciones completas**: están en `references/<nombre>.md` y se leen únicamente después de la selección.

### Analysis

Ayuda a entender el alcance del cambio.

- `impact-analysis` — Mira qué partes podrían verse afectadas por el cambio.
- `reuse-analysis` — Encuentra dónde más se usa lo que vas a cambiar.
- `traceability` — Sigue el recorrido de la información de principio a fin.

### Safety

Ayuda a cuidar lo que ya funciona y el alcance pedido.

- `regression-safety` — Ayuda a evitar que el cambio rompa algo que ya funciona.
- `scope-guard` — Mantiene el trabajo dentro de lo que pediste.

### Behavior

Indica cómo mantener el cambio enfocado.

- `minimal-change` — Hace solo los cambios necesarios.
- `no-refactor` — Evita reorganizar código fuera de esta tarea.
- `preserve-existing-behavior` — Conserva lo que ya funciona y no pediste cambiar.

## Flujo obligatorio

1. Admite **uno o varios** nombres de cualquier categoría. Si el usuario ya indicó nombres explícitos, omite el selector y consérvalos sin pedir confirmación. Si no indicó ninguno, sigue el flujo del arnés:
   - En Codex, usa el selector nativo de preguntas de opción única. Pregunta por Analysis, Safety y Behavior con su breve explicación, hasta tres preguntas por pantalla. Cada grupo ofrece **Omitir / Todos / Personalizar**. **Todos** incorpora todos sus augmenters; **Omitir** salta el grupo. Cuenta solo respuestas enviadas, nunca opciones preseleccionadas por la interfaz. Si el usuario cancela el selector, termina sin aplicar augmenters.
   - Solo para cada grupo marcado **Personalizar**, pregunta por cada uno de sus augmenters con su descripción y las opciones **Agregar / Omitir**, hasta tres preguntas por pantalla. Incorpora los marcados **Agregar**; si todos se omiten, el grupo queda omitido. Si al terminar no hay ningún augmenter, ofrece **Repetir / Cancelar**; al repetir, vuelve a preguntar por los tres grupos. No preguntes por los elementos de grupos marcados **Todos** u **Omitir**.
   - Si el selector nativo no está disponible, haz las mismas preguntas por grupo y, solo para **Personalizar**, por elemento en la conversación; acepta las palabras de cada opción como respuesta. No sustituyas este flujo por una lista numerada de augmenters.
   - En OpenCode, Claude Code y otros harnesses, conserva su mecanismo actual: usa una selección nativa múltiple si existe o pide una lista de nombres por conversación. No infieras augmenters adicionales.
2. Obtén el prompt base de los argumentos de la invocación o del mensaje explícito del usuario. Si no existe o no queda claro qué parte es la solicitud, pídelo y espera la respuesta. No inventes ni ejecutes un prompt provisional.
3. **Lee solo** los archivos `references/<nombre>.md` correspondientes a los nombres elegidos y existentes. No leas otros archivos de `references/`, aunque parezcan relacionados. Si hay un nombre desconocido, muéstrale el catálogo para corregirlo; no sustituyas nombres automáticamente.
4. Compón conceptualmente el prompt base y las instrucciones seleccionadas, sin reescribir ni alterar la intención original. Evita duplicar exigencias equivalentes si hay solapamiento. Ante un conflicto, respeta la intención explícita, luego la seguridad y la preservación de comportamiento y finalmente la interpretación más conservadora. Si la combinación sigue siendo contradictoria, pide aclaración antes de actuar.
5. Informa brevemente «Aplicaré: ...» con **solo** los nombres elegidos; después ejecuta la solicitud enriquecida con las herramientas y autorizaciones normales del arnés. No te detengas tras mostrar un prompt reformulado. En tareas de solo análisis no modifiques archivos. No ejecutes builds ni pruebas si las reglas del usuario o del proyecto exigen autorización previa.

## Extender el catálogo

Para añadir un augmenter, crea `references/<nuevo-nombre>.md` con sus instrucciones complementarias y añade una línea de nombre, etiqueta y resumen en la categoría apropiada de este índice. Mantén equivalentes la skill y su referencia en Codex; Claude Code comparte directamente la versión de OpenCode. Si un augmenter necesita herramientas, fases propias o entradas/salidas independientes, considera una skill aparte.
