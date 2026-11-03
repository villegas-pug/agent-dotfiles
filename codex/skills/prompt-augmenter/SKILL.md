---
name: prompt-augmenter
description: Enriquece una solicitud base con uno o varios augmenters elegidos por el usuario y ejecuta la solicitud resultante. Usar cuando se invoque prompt-augmenter o se pida seleccionar criterios reutilizables antes de realizar una tarea.
---

# Prompt Augmenter

El prompt base es siempre la intención principal. Los augmenters solo agregan criterios para cumplirla; no agregan funcionalidades ni sustituyen el objetivo. Las reglas funcionales son compartidas entre Codex, OpenCode y Claude Code; la interacción para elegir augmenters se adapta al harness.

## Catálogo para seleccionar

Presenta estas cuatro categorías con su etiqueta y descripción en lenguaje llano. Este índice **no contiene las instrucciones completas**: están en `references/<nombre>.md` y se leen únicamente después de la selección.

### Analysis — Entender antes de cambiar

El agente investiga primero qué partes de tu app toca tu pedido y recién después hace el cambio. Elígelo cuando no sepas qué puede afectar.

- `impact-analysis` — **Revisar qué se afecta**: Antes de cambiar, mira qué otras pantallas o funciones podrían verse afectadas.
- `reuse-analysis` — **Ver dónde más se usa**: Busca en qué otros lugares se usa lo que vas a cambiar, para no dañarlos.
- `traceability` — **Seguir el dato completo**: Sigue un dato desde la pantalla hasta la base de datos y de vuelta, para que el cambio quede completo.

### Safety — Cuidar lo que ya funciona

El agente evita romper lo que ya anda y no hace nada que no pediste. Elígelo cuando tu app ya funciona y no quieres sorpresas.

- `regression-safety` — **No romper lo existente**: Comprueba que lo que ya funcionaba siga funcionando después del cambio.
- `scope-guard` — **Hacer solo lo pedido**: No agrega extras; si ve algo más por mejorar, te lo avisa pero no lo cambia.

### Behavior — Cambiar lo mínimo

Controla cuánto toca el agente: solo lo necesario, sin reordenar código ni alterar lo que tu app hace hoy. Elígelo para arreglos pequeños y precisos.

- `minimal-change` — **Cambio mínimo**: Hace el cambio más pequeño posible, solo lo necesario.
- `no-refactor` — **No reordenar código**: No reescribe ni reorganiza código que no tiene que ver con tu pedido.
- `preserve-existing-behavior` — **Mantener cómo funciona hoy**: Todo lo demás sigue funcionando igual que ahora.

### UI/UX — Pantallas bien hechas

El agente cuida que lo que ves y tocas en pantalla quede bien desde el primer intento. Elígelo cuando tu pedido crea o cambia pantallas, ventanas emergentes o formularios.

- `design-consistency` — **Mismo estilo que el resto**: La pantalla nueva usa los mismos colores, botones y estilos que tu app.
- `accessibility` — **Usable por todos**: Se puede usar con teclado y lector de pantalla, y los textos se leen bien.
- `ui-states` — **Estados de la pantalla**: Contempla qué se ve al cargar, sin datos, con errores y al terminar bien, con mensajes claros.
- `responsive-layout` — **Adaptado a celular y PC**: Se ve bien en celular, tablet y computadora, sin cortes ni scroll raro.
- `ui-polish` — **Diseño completo y cuidado**: Entrega la pantalla terminada y bien presentada, no una versión básica.
- `reactive-ui` — **Se actualiza al instante**: Los resultados cambian en vivo mientras el usuario responde, sin botón de «calcular».
- `fixed-layout` — **Cabecera y botones fijos**: El título y los botones se quedan visibles; solo el contenido del medio se desplaza.

## Flujo obligatorio

1. Admite **uno o varios** nombres de cualquier categoría. Si el usuario ya indicó nombres explícitos, omite el selector y consérvalos sin pedir confirmación. Si no indicó ninguno, sigue el flujo del arnés:
   - En Codex, usa el selector nativo de preguntas de opción única. Pregunta por cada categoría (Analysis, Safety, Behavior y UI/UX) con su etiqueta y explicación en lenguaje llano, hasta tres preguntas por pantalla. Muestra cada augmenter con su etiqueta y, entre paréntesis, su nombre técnico. Cada grupo ofrece **Omitir** (no usar el grupo), **Todos** (aplicar todos sus criterios) o **Personalizar** (elegir criterio por criterio). Cuenta solo respuestas enviadas, nunca opciones preseleccionadas por la interfaz. Si el usuario cancela el selector, termina sin aplicar augmenters.
   - Solo para cada grupo marcado **Personalizar**, pregunta por cada uno de sus augmenters con su descripción y las opciones **Agregar** (incluir ese criterio) u **Omitir** (dejarlo fuera), hasta tres preguntas por pantalla. Incorpora los marcados **Agregar**; si todos se omiten, el grupo queda omitido. Si al terminar no hay ningún augmenter, ofrece **Repetir / Cancelar**; al repetir, vuelve a preguntar por los cuatro grupos. No preguntes por los elementos de grupos marcados **Todos** u **Omitir**.
   - Si el selector nativo no está disponible, haz las mismas preguntas por grupo y, solo para **Personalizar**, por elemento en la conversación; acepta las palabras de cada opción como respuesta. No sustituyas este flujo por una lista numerada de augmenters.
   - En OpenCode, Claude Code y otros harnesses, conserva su mecanismo actual: usa una selección nativa múltiple si existe o pide una lista de nombres por conversación. No infieras augmenters adicionales.
2. Obtén el prompt base de los argumentos de la invocación o del mensaje explícito del usuario. Si no existe o no queda claro qué parte es la solicitud, pídelo y espera la respuesta. No inventes ni ejecutes un prompt provisional.
3. **Lee solo** los archivos `references/<nombre>.md` correspondientes a los nombres elegidos y existentes. No leas otros archivos de `references/`, aunque parezcan relacionados. Si hay un nombre desconocido, muéstrale el catálogo para corregirlo; no sustituyas nombres automáticamente.
4. Compón conceptualmente el prompt base y las instrucciones seleccionadas, sin reescribir ni alterar la intención original. Evita duplicar exigencias equivalentes si hay solapamiento. Ante un conflicto, respeta la intención explícita, luego la seguridad y la preservación de comportamiento y finalmente la interpretación más conservadora. Si la combinación sigue siendo contradictoria, pide aclaración antes de actuar.
5. Informa brevemente «Aplicaré: ...» con **solo** los elegidos, en la forma etiqueta (`nombre`); después ejecuta la solicitud enriquecida con las herramientas y autorizaciones normales del arnés. No te detengas tras mostrar un prompt reformulado. En tareas de solo análisis no modifiques archivos. No ejecutes builds ni pruebas si las reglas del usuario o del proyecto exigen autorización previa.

## Extender el catálogo

Para añadir un augmenter, crea `references/<nuevo-nombre>.md` con sus instrucciones complementarias y añade una línea con el formato `` `nombre` — **Etiqueta**: resumen `` en la categoría apropiada de este índice. La etiqueta tiene cinco palabras o menos y el resumen usa lenguaje llano; si un término técnico es inevitable, explícalo. Mantén equivalentes la skill y su referencia en Codex; Claude Code comparte directamente la versión de OpenCode. Si un augmenter necesita herramientas, fases propias o entradas/salidas independientes, considera una skill aparte.
