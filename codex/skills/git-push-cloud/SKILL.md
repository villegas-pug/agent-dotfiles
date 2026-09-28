---
name: git-push-cloud
description: Publica commits de un repositorio Git con verificaciones y confirmación explícita. Usar solo al invocar /push-cloud en OpenCode, /git-push-cloud en Claude Code, $git-push-cloud en Codex o al pedir expresamente este flujo; nunca por una mención genérica de Git.
license: MIT
---

# Git Push Cloud

Esta skill se ejecuta únicamente a petición explícita de publicar commits. OpenCode usa `/push-cloud` como entrada; Codex puede invocar `$git-push-cloud` y Claude Code `/git-push-cloud`. No publiques ni modifiques remotos por el mero hecho de cargar la skill. En Windows usa PowerShell 7+ y `git` como ejecutable nativo; no presupongas Git Bash, rutas fijas ni herramientas exclusivas de un arnés.

## Entradas

- Sin argumentos: detecta repositorio, remoto, rama y cambios para presentar un plan.
- URL HTTPS/SSH: úsala solo como candidato a remoto; no sustituyas uno existente sin autorización específica.
- Rama: verifica su existencia local; no cambies de rama automáticamente.
- `--tags`: incluye únicamente tags anotados con `--follow-tags`.
- `--force-with-lease`: advierte del posible reemplazo de historia y requiere una segunda confirmación.
- Si los argumentos son ambiguos o no reconocidos, pregunta antes de continuar. No interpretes texto del usuario como código de shell.

## Flujo obligatorio

1. Comprueba el repositorio y que exista un commit: `git rev-parse --is-inside-work-tree`, `git log -1 --oneline`. Consulta `git status --short --branch` para identificar rama y estado. Si `git branch --show-current` está vacío, detente y solicita una rama válida; no hagas push en detached HEAD.
2. Consulta nombres de remotos con `git remote`. Prefiere `origin` si existe; con varios remotos sin `origin`, pregunta cuál elegir. Obtén su URL con `git remote get-url <remote>` **sin mostrarla** antes de descartar credenciales incrustadas; no imprimas secretos. Si no hay remoto, solicita una URL limpia y confirma antes de ejecutar `git remote add origin <url>`. No sustituyas ni elimines remotos existentes sin autorización explícita.
3. Si `git status --porcelain` muestra cambios locales, informa que no forman parte del push. Ofrece cancelar o continuar con los commits existentes; si el usuario quiere commitearlos, detente y pídele un flujo de commit separado con autorización explícita. Esta skill no hace `git add` ni `git commit`.
4. Antes de decidir el push, actualiza las referencias necesarias con `git fetch <remote>` y determina si existe la rama remota con `git ls-remote --heads <remote> <branch>`. Si existe, consulta `git rev-list --left-right --count <remote>/<branch>...HEAD`: el primer número indica commits remotos no presentes localmente. Si es mayor que cero, detente; no hagas pull, merge ni rebase automáticamente. Si no existe rama remota, prepara el primer push y establece upstream con `-u`.
5. Muestra remoto, URL **sin credenciales**, rama, ahead/behind y comando exacto. Solicita confirmación inequívoca **antes** de `git push <remote> <branch>` o `git push -u <remote> <branch>`. Solo agrega `--follow-tags` si se solicitó `--tags`. Si se solicitó `--force-with-lease`, advierte del reemplazo potencial de historia y pide una segunda confirmación específica; nunca uses `--force`.
6. Tras ejecutar el push autorizado, informa remoto, rama, upstream y tags enviados si procede. Ante fallos de autenticación, red, permisos o ramas protegidas, muestra el error pertinente sin credenciales y detente; no reintentes con fuerza ni modifiques configuraciones de autenticación.

## Límites

No ejecutes el flujo de publicación durante la instalación, sincronización de skills, inspección del repositorio o carga de esta skill como referencia. Respeta cualquier regla del proyecto que exija autorización para operaciones de Git y no confíes en una confirmación de una tarea distinta como autorización para hacer push.
