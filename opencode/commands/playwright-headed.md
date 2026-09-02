---
description: Abre un navegador Chrome en modo headed usando playwright-cli. Requiere un prompt como argumento obligatorio.
agent: build
---

Usa playwright-cli para abrir un navegador Chrome en modo headed (`--headed`) y ejecuta las acciones descritas en el prompt: $ARGUMENTS

Si $ARGUMENTS está vacío o no se proporcionó ningún prompt, responde únicamente con el mensaje "⚠️ Debes proporcionar un prompt que describa las acciones a realizar con playwright-cli."

Si se proporcionó un prompt:
1. Abre el navegador en modo headed con: `playwright-cli open --browser=chrome --headed`
2. Ejecuta las acciones del prompt usando playwright-cli
3. Deja el navegador abierto
4. Reporta el resultado de las acciones
