---
description: Administra symlinks de dotfiles para OpenCode y Codex vía `install.ps1`. Subacciones canónicas (estilo slash): `dry` (vista previa), `sync` (aplicar con backup), `doctor` (auditar), `uninstall` (revertir symlinks), `help` (menú). Sin argumentos imprime el menú y se detiene — no ejecuta nada.
agent: build
---

# Dotfiles — comando slash

Comando canónico para administrar el repo `~/agent-dotfiles/`. Subacciones: `dry | sync | doctor | uninstall | help`. **Sin args / args desconocido → imprimir menú y detenerse. No se ejecuta PowerShell.**

## Reglas de dispatch

1. Parsear `$ARGUMENTS` (trim, lower-case).
2. Comparar contra la tabla `Keyword → Flag`. Si no matchea exactamente, ejecutar paso "Menú + parada".
3. Si matchea una subacción **read-only** (`dry`, `doctor`, `help`): ejecutar el comando correspondiente sin pedir confirmación, presentar el output del script, cerrar.
4. Si matchea una subacción **destructiva** (`sync`, `uninstall`): ejecutar paso "Confirmación obligatoria" antes de invocar PowerShell.

## Tabla Keyword → Flag (única verdad)

| Keyword | Flag `install.ps1` | Categoría |
|---|---|---|
| `dry` | `-DryRun` | read-only |
| `doctor` | `-Doctor` | read-only |
| `help` | (no invoca script) | read-only |
| `sync` | `-Force` | destructiva |
| `uninstall` | `-Uninstall` | destructiva |

Solo se aceptan estos 5 valores literales. No aliases. No inferencia.

## Menú + parada

Cuando `$ARGUMENTS` está vacío, no matchea la tabla, o el usuario pide `help`:

```
Subacciones disponibles para /dotfiles:

  dry        vista previa de cambios (sin tocar nada)
  sync       crear / actualizar symlinks (hace backup automático)
  doctor     auditar estado (sin tocar nada)
  uninstall  revertir symlinks (no toca archivos ni backups)
  help       reimprimir este menú
```

Después del menú, finalizar la respuesta sin ejecutar nada.

## Confirmación obligatoria

Cuando la subacción es `sync` o `uninstall`, **antes** de invocar el script:

### `sync`

Imprimir:

```
Voy a ejecutar: install.ps1 -Force
Esto creará M symlinks nuevos y respaldará N archivos reales con sufijo `.bak-yyyyMMdd-HHmmss`.
¿Confirmo?
```

Esperar respuesta. Solo con `sí` (o equivalente inequívoco) correr el comando. Con `no` o silencio → cancelar y reportar.

### `uninstall`

Imprimir:

```
Voy a ejecutar: install.ps1 -Uninstall
Esto eliminará los symlinks creados por este script. Los archivos reales y los backups `.bak-*` no se tocan.
¿Confirmo?
```

Esperar respuesta. Misma regla: solo `sí` inequívoco ejecuta.

## Comando a invocar (una vez confirmada la acción)

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "F:\work-space\agent-dotfiles\install.ps1" -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File "F:\work-space\agent-dotfiles\install.ps1" -Doctor
pwsh -NoProfile -ExecutionPolicy Bypass -File "F:\work-space\agent-dotfiles\install.ps1" -Force
pwsh -NoProfile -ExecutionPolicy Bypass -File "F:\work-space\agent-dotfiles\install.ps1" -Uninstall
```

## Reglas duras

1. **Nunca** invocar `install.ps1 -Force` ni `install.ps1 -Uninstall` sin `sí` textual en el turno actual.
2. **Nunca** aceptar argumentos fuera de la tabla. Si el usuario escribe `/dotfiles foo`, no es un error: es "muéstrale el menú".
3. **Nunca** correr el script desde una ruta distinta a `~/agent-dotfiles/`.
4. **Nunca** borrar archivos `.bak-*` desde este comando.
5. Si `install.ps1` aborta con `Developer Mode no está activo`, no se intenta ejecutar otra vez: se imprime la guía de activación y se detiene.

## Estado del repo (no se commitea automáticamente)

Ruta del repo: `F:\work-space\agent-dotfiles`

Estado de git (solo informativo):

!`git status --short`

Último commit (solo informativo):

!`git log -1 --format="%h %s" 2>/dev/null || echo "(no commits)"`

## Salida esperada

Después de invocar el script, presentar:

1. Una línea con la subacción ejecutada.
2. El output del script **tal cual** se imprimió en consola.
3. Una frase de cierre breve: "OK." / "Doctor terminó sin warnings." / "Symlinks en su lugar." / etc.

No parafrasear el output del script.

## Errores conocidos y respuesta

### Developer Mode apagado

```
[ERROR] Windows Developer Mode no está activo.

Para activarlo:
  1. Configuración de Windows
  2. Privacidad y seguridad → Desarrolladores
  3. Activar "Modo Desarrollador"
  4. Confirmar la advertencia de UAC
  5. Volver a ejecutar /dotfiles <subacción>
```

### Permiso insuficiente para symlinks

Si PowerShell devuelve `Required registry access is not allowed` u `Operación rechazada por el sistema`:

```
[ERROR] No se puede crear symlink en este proceso.

Causa probable: Developer Mode desactivado o PowerShell sin privilegios.
Solución preferida: activar Developer Mode (ver arriba).
Alternativa: ejecutar PowerShell como Administrador (no recomendado a largo plazo).
```

### FAIL en `doctor` (symlinks rotos)

Si `install.ps1 -Doctor` reporta `FAIL`:

1. Indicar al usuario cuál entrada falló y por qué.
2. Ofrecer dos caminos:
   - Si el repo fue movido: `sync` (recreará los symlinks; los anteriores se borran).
   - Si el repo fue eliminado: `uninstall` para limpiar, luego decidir reinstalar o abandonar.

## Relación con el skill `dotfiles`

Este comando **delega la metodología** al skill `dotfiles/SKILL.md`. Si el comando encuentra ambigüedad (e.g., el usuario escribe `/dotfiles sync` con intención vaga), reapunta al skill para aplicar la heurística NL → subacción.

En cualquier caso, este archivo manda: si la subacción canónica es `sync`, se requiere confirmación, sin excepciones.
