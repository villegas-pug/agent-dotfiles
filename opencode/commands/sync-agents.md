---
description: Compara y alinea skills, agentes y comandos de OpenCode, Codex y Claude Code en agent-dotfiles. Solicita el modo si se omite; apply confirma cada cambio.
---

Carga la skill `sync-agents` y delega íntegramente en ella el análisis, las decisiones y la aplicación.

Argumentos: $ARGUMENTS

- Sin argumentos: carga la skill; debe solicitar `dry-run` o `apply` mediante la herramienta `question` antes de operar.
- Con `dry-run`: pásalo como modo explícito y ejecuta la vista previa de la skill sin volver a preguntar el modo.
- Con `apply`: pásalo como modo explícito y sigue los selectores y confirmaciones por elemento de la skill antes de escribir.
- Con `help`: muestra `dry-run` (solo lectura) y `apply` (decisiones y confirmación por elemento), y detente.
- Con otro argumento: muestra los modos válidos y detente.

No ejecutes comandos adicionales, `install.ps1` ni operaciones de Git por este punto de entrada.
