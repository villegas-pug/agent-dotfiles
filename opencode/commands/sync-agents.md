---
description: Compara y alinea skills y agentes de OpenCode, Codex y Claude Code dentro del clon de agent-dotfiles. Modos dry-run, apply y help.
---

Carga la skill `sync-agents` y delega íntegramente en ella el análisis, las decisiones y la aplicación.

Argumentos: $ARGUMENTS

- Sin argumentos o con `help`: muestra `dry-run` (solo lectura) y `apply` (decisiones y confirmación por elemento), y detente.
- Con `dry-run`: ejecuta el modo de vista previa de la skill.
- Con `apply`: sigue las confirmaciones por elemento de la skill antes de escribir.
- Con otro argumento: muestra los modos válidos y detente.

No ejecutes comandos adicionales, `install.ps1` ni operaciones de Git por este punto de entrada.
