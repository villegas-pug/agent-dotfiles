---
name: dotfiles
description: Instala, audita o revierte los enlaces de dotfiles para OpenCode, Codex y Claude Code mediante install.ps1. Usar cuando el usuario pida sincronizar sus dotfiles locales, ver cambios, auditar enlaces o desinstalarlos.
---

# Dotfiles

Esta skill gestiona **enlaces de la máquina al clon**, no las diferencias entre arneses dentro del clon (para eso usa `sync-agents`). Localiza `install.ps1` en el clon donde reside esta skill; no asumas `~/agent-dotfiles`, una unidad concreta ni que el directorio actual sea el clon. Ejecuta mediante PowerShell 7+: `pwsh -NoProfile -File <ruta-del-clon>/install.ps1 <opción>`.

## Modos

| Entrada | Parámetro | Efecto |
|---|---|---|
| `dry` | `-DryRun` | Muestra destinos nuevos y reemplazos sin modificar nada |
| `doctor` | `-Doctor` | Audita el origen exacto de cada enlace sin modificar nada |
| `sync` | sin parámetros | Instala o sustituye rutas mapeadas sin respaldos |
| `uninstall` | `-Uninstall` | Quita solo enlaces que apuntan a este clon |
| `help` | ninguno | Muestra estas opciones sin ejecutar el script |

Las rutas mapeadas provienen de la tabla del script, no de una suposición sobre el contenido de `~/.codex/`, `~/.config/opencode/` o `~/.claude/`. Las skills compartidas con Claude se instalan por nombre y nunca se sustituye `~/.claude/skills/` ni su carpeta `synced/`. Solo existe un `AGENTS.md` en la raíz del clon. `-Force` permanece como alias antiguo de `sync`; **no crea `.bak-*`**.

## Uso seguro

1. Sin argumentos o con `help`, muestra el menú y termina. Para solicitudes ambiguas, pregunta qué modo desea el usuario.
2. `dry` y `doctor` son de lectura; presenta el resultado.
3. Antes de `sync`, muestra el resultado de `-DryRun`, incluyendo cada archivo o directorio real que se perderá al sustituirse, y pide confirmación inequívoca. No ejecutes si falta alguna fuente del clon. Después de confirmación, invoca el script sin parámetros.
4. Antes de `uninstall`, muestra los enlaces propios detectados y pide confirmación inequívoca. Nunca borres archivos reales durante la desinstalación.
5. Si se movió el clon, vuelve a instalar los enlaces desde su nueva ubicación; el script obtiene el origen desde su propio directorio.

No hagas `git commit`, `push` ni ejecutes `sync-agents` como efecto colateral. Un `git pull` que solo cambió contenido dentro de los directorios enlazados no exige reinstalar; un mapeo nuevo o un enlace roto sí.
