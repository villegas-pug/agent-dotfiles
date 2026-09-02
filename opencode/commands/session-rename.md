---
description: Genera propuestas de nombre en inglés formato `{{feature}}-{{action}}` para la sesión actual de opencode a partir de un contexto en español. Requiere un contexto como argumento obligatorio.
agent: build
---

Genera entre 3 y 5 propuestas de nombre para la sesión actual de opencode siguiendo estrictamente el formato `{{feature}}-{{action}}` en inglés, a partir del contexto en español: $ARGUMENTS

## Reglas

1. **Sin argumentos** o con argumentos vacíos: responde **únicamente** con el mensaje "⚠️ Debes proporcionar un resumen en español de lo que se hizo en esta sesión (2-3 líneas)."

2. **Con contexto provisto**:
   1. Carga el skill `session-rename` y aplica la heurística completa (cuándo disparar, proceso, formato, ejemplos, anti-ejemplos).
   2. Genera las propuestas con la recomendada marcada.
   3. Devuelve el output en el formato del skill.
   4. Termina recordando que el skill solo propone: el usuario debe aplicar el título manualmente en el TUI de opencode.

3. **No ejecutes** ningún comando shell. Este comando es estrictamente delegativo: produce texto, no muta estado.
