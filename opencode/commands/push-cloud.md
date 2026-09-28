---
description: Publica commits del proyecto en su repositorio remoto con pre-checks y configuracion interactiva del remoto
agent: build
---

Eres el punto de entrada exclusivo para publicar cambios Git en la nube.

Carga el skill `git-push-cloud` y sigue sus instrucciones al pie de la letra. Este comando es la entrada explícita de OpenCode; Codex y Claude Code pueden invocar la skill directamente.

Argumentos recibidos: `$ARGUMENTS`

Interpreta los argumentos asi:

1. Sin argumentos (`/push-cloud`): ejecutar el flujo completo. Detectar el repositorio, remoto, rama, estado local y divergencia.
2. Una URL que comience por `http://`, `https://`, `git@` o `ssh://`: tratarla como el remoto solicitado. Si no existe `origin`, pedir confirmacion y configurarla como `origin`. Si ya existe otro `origin`, no reemplazarlo sin confirmacion explicita.
3. Un nombre de rama: validar que la rama exista localmente y usarla como destino. No cambiar de rama automaticamente.
4. `--tags`: pasar la opcion al skill para usar `--follow-tags`.
5. `--force-with-lease`: pasar la opcion al skill. Requiere advertencia y confirmacion adicional.
6. Una combinacion de los valores anteriores: procesarla sin interpretar texto arbitrario como URL o comando de shell.
7. Cualquier otro argumento: rechazarlo e indicar los valores validos: URL, rama, `--tags` y `--force-with-lease`.

El skill debe bloquear cambios sin commit y pedir al usuario que elija entre cancelar, commitear primero o continuar con los commits existentes. Nunca hagas `git add`, `git commit`, `git push` ni reemplaces un remoto sin confirmacion humana explicita.
