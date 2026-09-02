---
name: dotfiles
description: Gestiona los symlinks de dotfiles para OpenCode y Codex instalados vía el script `install.ps1` del repo `~/dotfiles/`. Usar cuando el usuario diga "sincroniza / verifica / audita / revierte / vista previa / qué cambiaría" en relación a sus dotfiles, o cuando pida correr el script de bootstrap. Subacciones canónicas: `dry` (vista previa), `sync` (aplicar con backup), `doctor` (auditar), `uninstall` (revertir symlinks), `help` (menú).
---

# Dotfiles Skill (Codex)

Metodología para administrar el repositorio de dotfiles versionado en `~/dotfiles/` y su script de bootstrap `install.ps1`. **NO aplica al repositorio del proyecto actual**: solo a este dotfiles-repo personal.

Este skill es el espejo Codex del `opencode/skills/dotfiles/SKILL.md`. Las reglas son las mismas; lo único que difiere es la forma de invocar (Codex no tiene comandos slash personalizados, toda la UX pasa por NL).

## Cuándo disparar

Cargar este skill cuando el usuario exprese intención relacionada con sus dotfiles, por ejemplo:

- "sincroniza / aplica / actualiza / regenera mis dotfiles"
- "verifica / audita / comprueba el estado de los dotfiles"
- "qué cambiaría / vista previa / preview / simular"
- "revierte / desinstala / quita / elimina los symlinks"
- "qué hace este comando / ayuda / opciones / qué puedo hacer"
- Cualquier mención explícita de las palabras clave canónicas.

**NO usar este skill** para:

- Cualquier repositorio distinto a `~/dotfiles/`.
- Cambios al `AGENTS.md` del proyecto actual.
- Tareas de git genéricas (`git commit`, `git push`) — están prohibidas salvo instrucción explícita.
- Cualquier compilación, build, test o dev-server (prohibido por `codex/AGENTS.md`).

## Subacciones canónicas

| Subacción | Flag `install.ps1` | Mutación | Side effects |
|---|---|---|---|
| `dry` | `-DryRun` | no | ninguno; solo imprime el plan |
| `sync` | `-Force` | sí | backup con timestamp + crea/actualiza symlinks |
| `doctor` | `-Doctor` | no | ninguno; auditoría |
| `uninstall` | `-Uninstall` | sí | elimina symlinks; respeta archivos reales |
| `help` | (no invoca script) | no | ninguno; imprime el menú |

Hay un único estilo canónico: la palabra clave literal. No aliases. No inferencia si la frase no matchea la tabla de heurística.

## Heurística NL → subacción

Si la frase del usuario matchea claramente una categoría, **deducir** y aplicar el comportamiento de confirmación correspondiente.

| Frase en español | Subacción deducida |
|---|---|
| "verifica / audita / comprueba / estado / salud / doctor" | `doctor` |
| "qué cambiaría / vista previa / preview / plan / simular / dry-run" | `dry` |
| "sincroniza / aplica / actualiza / regenera / refresca" | `sync` |
| "revierte / desinstala / quita / elimina / remueve" | `uninstall` |
| "ayuda / opciones / qué puedo hacer / qué hace este comando" | `help` |

Cualquier otra frase — incluidas las ambiguas como "arregla", "configura", "ponlo a punto" — **no se deduce**. Se listan las 5 opciones en una línea y se pide aclaración.

### Comportamiento por categoría

- **Read-only** (`dry`, `doctor`, `help`): ejecutar directamente con la deducción + una línea de contexto. **Sin confirmación**.
- **Destructivas** (`sync`, `uninstall`): **siempre** pedir confirmación explícita con resumen del impacto antes de correr.

## Menú (respuesta cuando `help` / no deduce / intención ambigua)

Subacciones disponibles:

- `dry` — vista previa de cambios (sin tocar nada)
- `sync` — crear / actualizar symlinks (hace backup automático)
- `doctor` — auditar estado (sin tocar nada)
- `uninstall` — revertir symlinks (no toca archivos ni backups)
- `help` — reimprimir este menú

## Confirmaciones obligatorias

### `sync`

1. Si no se conoce el plan, correr primero `dry` o estimar desde el estado actual.
2. Resumir: "Voy a crear **M** symlinks nuevos y respaldar **N** archivos reales con sufijo `.bak-yyyyMMdd-HHmmss`."
3. Preguntar: **"¿Confirmo?"** — esperar `sí` / `no` textual.
4. Solo con `sí` explícito, correr `install.ps1 -Force`.

### `uninstall`

1. Recordar: "Los symlinks creados por este script se eliminan. Los backups `.bak-*` y los archivos que nunca fueron parte del repo **no** se tocan."
2. Preguntar: **"¿Confirmo la eliminación de los N symlinks listados?"** — esperar `sí` / `no` textual.

## Cómo invocar el script

Codex ejecuta bash, no PowerShell nativo en Windows. Usar rutas con conversión `/c/...`:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File /c/Users/cristopher/dotfiles/install.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File /c/Users/cristopher/dotfiles/install.ps1 -Doctor
pwsh -NoProfile -ExecutionPolicy Bypass -File /c/Users/cristopher/dotfiles/install.ps1 -Force
pwsh -NoProfile -ExecutionPolicy Bypass -File /c/Users/cristopher/dotfiles/install.ps1 -Uninstall
```

Ruta local del script: `C:\Users\cristopher\dotfiles\install.ps1`.

**Nunca** correr `install.ps1` desde una ruta distinta a `~/dotfiles/`.

## Casos de error conocidos

### Developer Mode apagado

Si el script aborta con `[ERROR] Windows Developer Mode no está activo`:

```
1. Configuración de Windows → Privacidad y seguridad → Desarrolladores
2. Activar "Modo Desarrollador"
3. Confirmar UAC
4. Volver a ejecutar
```

Verificación rápida:

```bash
powershell -NoProfile -Command "(Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock').AllowDevelopmentWithoutDevLicense"
```

Debe ser `1`.

### Permiso insuficiente

`New-Item SymbolicLink` fallando → Developer Mode o PowerShell como Administrador.

### Symlinks rotos (FAIL en `doctor`)

1. Verificar que `~/dotfiles/` exista.
2. Si el repo fue movido: regenerar con `-Force`.
3. Si fue eliminado: ofrecer `uninstall` para limpiar symlinks huérfanos.

### BACKUP `.bak-*` residuales

El script **nunca** los borra. Mencionar al usuario si ve residuos viejos. Acción manual, no automática.

## Reglas inquebrantables

1. **Nunca** auto-ejecutar `-Force` ni `-Uninstall` sin `sí` textual del usuario en el turno actual.
2. **Nunca** borrar archivos `*.bak-*` sin instrucción explícita.
3. **Nunca** correr `install.ps1` desde una ruta distinta a `~/dotfiles/`.
4. Si la intención del usuario es ambigua, preferir la opción read-only más cercana (default: `doctor`).
5. Si el frontmatter `description:` y una frase del usuario entran en conflicto, seguir la intención del usuario, no la palabra clave literal.
6. **Nunca** ejecutar el script si el repo está incompleto (`install.ps1 -Doctor` reporta `WARN` por `target file does not exist in repo`); informar al usuario antes de cualquier acción.

## Salida esperada

Después de invocar el script, presentar al usuario:

1. Una línea con la subacción ejecutada.
2. El output del script **tal cual** lo devolvió.
3. Una frase de cierre breve: "Symlinks en su lugar." / "Doctor terminó OK." / "Se respaldaron N archivos." / etc.

No parafrasear ni filtrar el output del script.
