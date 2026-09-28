---
name: kill-session-processes
description: Enumera procesos que escuchan puertos de desarrollo y termina únicamente los seleccionados con confirmación explícita. Usar solo al invocar /kill-servers en OpenCode, /kill-session-processes en Claude Code, $kill-session-processes en Codex o al solicitar expresamente este flujo.
license: MIT
---

# Kill Session Processes

Skill para Windows con PowerShell 7+. OpenCode dispone de `/kill-servers`; Codex puede invocar `$kill-session-processes` y Claude Code `/kill-session-processes`. No termines procesos al cargar la skill ni por una mención genérica de servidores. Un puerto de desarrollo **no demuestra** que el proceso fue creado en la sesión actual: confirma su identidad con el usuario.

## Acciones

- Sin argumentos o con `list`: muestra candidatos sin modificar procesos.
- `kill <puerto|PID>`: identifica el proceso exacto; si el número coincide con ambos, pregunta cuál quiso decir el usuario. Pide confirmación antes de terminarlo.
- `kill-all`: solo si el usuario lo solicitó expresamente, muestra la lista completa ya filtrada y pide confirmación explícita de todos los PID. Sin una lista aprobada, no hagas nada.
- Argumentos no reconocidos: informa opciones y detente. No transformes texto libre en comandos.

## Detección y filtros

Los intervalos permitidos son `3000-3010`, `4200-4210`, `5000-5010`, `5173-5174`, `8000-8010`, `8080-8090`, `8888-8889` y `9000-9010`. Construye puertos **numéricos**; `Get-NetTCPConnection -LocalPort` no acepta intervalos como cadenas `"3000-3010"`.

```powershell
$ranges = @(@(3000,3010), @(4200,4210), @(5000,5010), @(5173,5174), @(8000,8010), @(8080,8090), @(8888,8889), @(9000,9010))
$allowedPorts = foreach ($range in $ranges) { $range[0]..$range[1] }
$listeners = Get-NetTCPConnection -State Listen -ErrorAction Stop |
    Where-Object { $_.LocalPort -in $allowedPorts }
```

Para cada listener consulta `Get-Process -Id <OwningProcess>` y, cuando esté disponible, `Get-CimInstance Win32_Process` para mostrar `ProcessId`, `ParentProcessId`, `ExecutablePath` y `CommandLine`. Cruza cada puerto con un solo PID y presenta una tabla `PID | Puerto | Proceso | Comando`. Si faltan datos para identificarlo, pide información adicional; nunca trates el puerto como autorización.

Antes de ofrecer `kill` o `kill-all`, **descarta**: PID menores a 100; ejecutables bajo `C:\Windows\`; procesos críticos o de usuario no relacionados (`sqlservr`, `docker`, `dockerd`, `vmware*`, `vbox*`, `msedge`, `chrome`, `Code`, `WindowsTerminal`); el proceso del agente, el shell que lo hospeda y sus ancestros identificables. No termines un proceso cuya identidad no puedas comprobar con suficiente seguridad. Si no puedes consultar `Get-NetTCPConnection` o comprobar los filtros, informa el límite y detente; no adivines PID desde `netstat`.

## Terminación

Tras mostrar puerto, PID, nombre y comando, espera una confirmación inequívoca **para ese PID** (o para la lista completa en `kill-all`). Revalida que siga escuchando el mismo puerto y que su identidad no haya cambiado antes de ejecutar `Stop-Process -Id <PID> -Force`. Usa un nombre como `$processId` en PowerShell: `$PID` es una variable automática de solo lectura. Verifica después que el puerto esté libre e informa fallos sin intentar terminar otros procesos.

No ejecutes esta skill como efecto de instalar dotfiles, comparar skills o leer instrucciones. Nunca inicies servidores ni pruebas para descubrir candidatos.
