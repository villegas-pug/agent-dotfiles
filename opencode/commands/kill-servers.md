---
description: Lista y termina procesos dev/server escuchando puertos locales (frontend, backend)
agent: build
---

Eres el punto de entrada del flujo para terminar procesos dev/server levantados en esta sesion.

Carga el skill `kill-session-processes` y sigue sus instrucciones al pie de la letra (rangos de puerto, reglas de seguridad, modo de fallo).

Argumentos recibidos: `$ARGUMENTS`

Comportamiento segun argumentos:

1. Sin argumentos (`/kill-servers`):
   - Cargar el skill `kill-session-processes`.
   - Ejecutar la accion `list` para mostrar la tabla de candidatos.
   - Preguntar al usuario que accion tomar: `kill <puerto|PID>`, `kill-all`, o cancelar.

2. Con un puerto (`/kill-servers 3000`):
   - Cargar el skill `kill-session-processes`.
   - Ejecutar la accion `kill <puerto>` directamente. Mostrar confirmacion previa con PID, proceso y comando antes de matar.

3. Con un PID numerico (`/kill-servers 12345`):
   - Cargar el skill `kill-session-processes`.
   - Aplicar filtros de seguridad del skill sobre ese PID.
   - Si pasa los filtros, pedir confirmacion explicita y luego ejecutar `kill <PID>`.

4. Con `all` (`/kill-servers all`):
   - Cargar el skill `kill-session-processes`.
   - Mostrar tabla completa de candidatos filtrados.
   - Pedir confirmacion explicita antes de `kill-all`.

5. Con cualquier otro argumento:
   - Rechazar con mensaje claro indicando los valores validos: vacio, puerto, PID, o `all`.

Importante:

- Nunca omitir la confirmacion humana para acciones destructivas (`kill`, `kill-all`).
- Nunca saltar los filtros de seguridad documentados en el skill.
- Si el skill reporta que no hay candidatos, terminar el flujo sin acciones.
