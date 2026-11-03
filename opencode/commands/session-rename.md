---
description: Propone nombres en inglés `{{feature}}-{{action}}` para la sesión actual de OpenCode, deja elegir uno y lo aplica al título. El contexto sale de la conversación; el argumento es opcional.
agent: build
---

Carga la skill `session-rename`, propón nombres para la sesión actual y aplica el que elija el usuario. Contexto adicional del usuario (opcional): $ARGUMENTS

## Reglas

1. **Delega en la skill**: su jerarquía de fuentes, presupuesto de lectura, formato y el paso de elegir y aplicar son la única referencia; no dupliques su heurística aquí.
2. **No ejecutes** ningún comando shell salvo lo que la skill indique como fuente de contexto.
3. **Efectos permitidos**: solo la herramienta `session_rename`, y únicamente con el nombre que el usuario eligió.
