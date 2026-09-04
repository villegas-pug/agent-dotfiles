---
name: dotfiles
description: Gestiona los symlinks de dotfiles para OpenCode y Codex instalados vía el script `install.ps1` del repo `~/agent-dotfiles/`. Usar cuando el usuario diga "sincroniza / verifica / audita / revierte / vista previa / qué cambiaría" en relación a sus dotfiles. Subacciones canónicas: `dry` (vista previa), `sync` (aplicar con backup), `doctor` (auditar), `uninstall` (revertir symlinks), `help` (menú).
---

# Dotfiles Skill

Metodología para administrar el repositorio de dotfiles versionado en `~/agent-dotfiles/` y su script de bootstrap `install.ps1`. **NO aplica al repositorio del proyecto actual**: solo a este dotfiles-repo personal.

## Cuándo disparar

Cargar este skill cuando el usuario exprese intención relacionada con sus dotfiles, por ejemplo:

- "sincroniza / aplica / actualiza / regenera mis dotfiles"
- "verifica / audita / comprueba el estado de los dotfiles"
- "qué cambiaría / vista previa / preview / simular"
- "revierte / desinstala / quita / elimina los symlinks"
- "qué hace este comando / ayuda / opciones / qué puedo hacer"
- "doctor de dotfiles" / "dry-run de dotfiles" (cualquier mención explícita de las palabras canónicas)

**NO usar este skill** para:

- Cualquier repositorio distinto a `~/agent-dotfiles/`.
- Cambios al `AGENTS.md` del proyecto actual.
- Tareas de git genéricas (commit, push) — esas las maneja el comando `/commit`.
- Comandos de OpenCode/Codex del propio proyecto (e.g., crear otro skill).

## Subacciones canónicas

| Subacción | Flag `install.ps1` | Mutación | Side effects |
|---|---|---|---|
| `dry` | `-DryRun` | no | ninguno; solo imprime el plan |
| `sync` | `-Force` | sí | backup con timestamp + crea/actualiza symlinks |
| `doctor` | `-Doctor` | no | ninguno; auditoría |
| `uninstall` | `-Uninstall` | sí | elimina symlinks; respeta archivos reales |
| `help` | (no invoca script) | no | ninguno; imprime el menú |

Hay un único estilo canónico: la palabra clave (`dry`, `sync`, `doctor`, `uninstall`, `help`). Otras variantes o aliases no se aceptan — el allowlist es estricto.

## Heurística NL → subacción

Si la frase del usuario matchea claramente una categoría, **deducir** y aplicar comportamiento de confirmación correspondiente.

| Frase en español | Subacción deducida |
|---|---|
| "verifica / audita / comprueba / estado / salud / doctor" | `doctor` |
| "qué cambiaría / vista previa / preview / plan / simular / dry-run" | `dry` |
| "sincroniza / aplica / actualiza / regenera / refresca" | `sync` |
| "revierte / desinstala / quita / elimina / remueve" | `uninstall` |
| "ayuda / opciones / qué puedo hacer / qué hace este comando" | `help` |

Cualquier otra frase — incluidas las ambiguas como "arregla", "configura", "ponlo a punto", "setup", "inicializa" — **no se deduce**. Se listan las 5 opciones en una línea y se pide aclaración.

### Comportamiento por categoría

- **Read-only** (`dry`, `doctor`, `help`): ejecutar directamente con la deducción + una línea de contexto ("Voy a auditar sin tocar nada."). **Sin confirmación**.
- **Destructivas** (`sync`, `uninstall`): **siempre** pedir confirmación explícita con resumen del impacto antes de correr.

## Menú (respuesta cuando el usuario pide `help` / no deduce / invoca ambiguo)

Subacciones disponibles:

- `dry` — vista previa de cambios (sin tocar nada)
- `sync` — crear / actualizar symlinks (hace backup automático)
- `doctor` — auditar estado (sin tocar nada)
- `uninstall` — revertir symlinks (no toca archivos ni backups)
- `help` — reimprimir este menú

## Confirmaciones obligatorias

### `sync`

Antes de invocar `install.ps1 -Force`:

1. Si no se conoce el plan, correr primero `dry` o estimar desde el estado del filesystem (qué ya existe como archivo real, qué falta).
2. Resumir: "Voy a crear **M** symlinks nuevos y respaldar **N** archivos reales con sufijo `.bak-yyyyMMdd-HHmmss`."
3. Preguntar: **"¿Confirmo?"** — esperar `sí` / `no` textual.
4. Solo con `sí` explícito, correr `install.ps1 -Force`.

Si el usuario responde `sí` sin haber revisado el plan, no ejecutar; reformular pidiendo confirmación consciente.

### `uninstall`

Antes de invocar `install.ps1 -Uninstall`:

1. Recordar: "Los symlinks creados por este script se eliminan. Los backups con sufijo `.bak-*` y los archivos que nunca fueron parte del repo **no** se tocan."
2. Preguntar: **"¿Confirmo la eliminación de los N symlinks listados por `doctor`?"** — esperar `sí` / `no` textual.

## Cómo invocar el script

Desde la raíz del repo (`~/agent-dotfiles/`):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ./install.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File ./install.ps1 -Doctor
pwsh -NoProfile -ExecutionPolicy Bypass -File ./install.ps1 -Force
pwsh -NoProfile -ExecutionPolicy Bypass -File ./install.ps1 -Uninstall
```

Ruta absoluta en esta máquina: `F:\work-space\agent-dotfiles\install.ps1`.

**Nunca** correr `install.ps1` desde una ruta distinta a `~/agent-dotfiles/`. Los symlinks se crean relativos al repo; cambiar de directorio produce symlinks que no resuelven.

## Casos de error conocidos

### Developer Mode apagado

Síntoma: el script aborta con `[ERROR] Windows Developer Mode no está activo.`

Instruir al usuario:

1. Configuración de Windows.
2. Privacidad y seguridad → Desarrolladores (o "Para programadores").
3. Activar el interruptor **Modo Desarrollador**.
4. Confirmar la advertencia de UAC.
5. Volver a ejecutar la subacción.

Verificación rápida del estado desde PowerShell:

```powershell
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock').AllowDevelopmentWithoutDevLicense
```

Si retorna `1`, Developer Mode está activo.

### Permiso insuficiente para crear symlinks

Síntoma: `New-Item -ItemType SymbolicLink` falla con `Required registry access is not allowed` u `Operación rechazada por el sistema`.

Causa: el proceso PowerShell no tiene `SeCreateSymbolicLinkPrivilege`. Resolver activando Developer Mode (preferido) o ejecutando PowerShell como Administrador.

### Symlinks rotos (FAIL en `doctor`)

Síntoma: `install.ps1 -Doctor` reporta `FAIL` con "symlink broken".

Pasos:

1. Verificar que `~/agent-dotfiles/` exista; si fue movido o eliminado, los symlinks quedan huérfanos.
2. Si el repo fue movido de carpeta: regenerar con `-Force` (los symlinks anteriores se borran al reemplazarse; no se crean backups de symlinks porque no son archivos reales).
3. Si el repo fue eliminado: ofrecer `uninstall` para limpiar symlinks huérfanos. No queda forma de restaurar los archivos; los `*.bak-*` siguen en su ubicación original.

### BACKUP con `.bak-*` residuales

El script **nunca borra** los `*.bak-*`. Si `doctor` reporta que todo está OK pero existen muchos `.bak-*` viejos, ofrecérselo al usuario como acción manual (no como subacción automática). Los backups están listados en `.gitignore` (`**/*.bak-*`) y no entran al repo.

## Reglas inquebrantables

1. **Nunca** auto-ejecutar `-Force` ni `-Uninstall` sin `sí` textual del usuario en el turno actual.
2. **Nunca** borrar archivos `*.bak-*` sin instrucción explícita.
3. **Nunca** correr `install.ps1` desde una ruta distinta a `~/agent-dotfiles/`.
4. Si la intención del usuario es ambigua, preferir la opción read-only más cercana a la intención (default: `doctor`).
5. Si el frontmatter `description:` y una frase del usuario entran en conflicto, seguir la intención del usuario, no la palabra clave literal.
6. **Nunca** ejecutar el script si faltan archivos en el repo (cuando `install.ps1 -Doctor` reporta `WARN` por `target file does not exist in repo`); informar al usuario que el repo está incompleto antes de cualquier acción.

## Salida esperada

Después de invocar el script, presentar al usuario:

1. Una línea con la subacción ejecutada (e.g., "`sync` aplicado").
2. El bloque de output **tal cual** lo devolvió el script.
3. Una frase de cierre breve: "Symlinks en su lugar." / "Doctor terminó OK (8/8)." / "Se respaldaron N archivos." / etc.

No parafrasear ni filtrar el output del script sin pedir permiso.
