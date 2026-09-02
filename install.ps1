#requires -Version 7
<#
.SYNOPSIS
    Bootstrap de dotfiles para agentes AI: crea symlinks desde las rutas
    reales de OpenCode y Codex hacia los archivos versionados en este repo.

.DESCRIPTION
    Cada mapeo declara una pareja (origen en el repo -> destino en HOME).
    El script es idempotente: si se ejecuta varias veces no rompe nada.

.PARAMETER DryRun
    Muestra las acciones que realizaría sin tocar el filesystem.

.PARAMETER Force
    Si el destino existe como archivo o directorio real (no symlink),
    hace un backup con timestamp antes de reemplazarlo con el symlink.

.PARAMETER Uninstall
    Elimina los symlinks creados por este script. No toca archivos reales.

.PARAMETER Doctor
    Audita cada mapeo y reporta estado (OK / WARN / FAIL) sin modificar nada.

.EXAMPLE
    .\install.ps1
    Crea los symlinks que falten. Idempotente.

.EXAMPLE
    .\install.ps1 -DryRun
    Muestra el plan de acción sin tocar nada.

.EXAMPLE
    .\install.ps1 -Uninstall
    Elimina los symlinks creados por este script.

.EXAMPLE
    .\install.ps1 -Doctor
    Audita cada symlink y reporta su estado.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Uninstall,
    [switch]$Doctor
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

# ---------------------------------------------------------------------------
# Tabla declarativa de mapeos. Cada entrada: Source -> Target.
# Los targets son rutas absolutas dentro de $HOME. Los sources son rutas
# relativas al directorio del script. Los targets se crean como symlinks
# relativos al source, de modo que el repo pueda moverse o clonarse en
# otra ubicación sin romper los enlaces.
# ---------------------------------------------------------------------------

$targets = @{
    'opencode/AGENTS.md'         = (Join-Path $HOME '.config\opencode\AGENTS.md')
    'opencode/agents/'           = (Join-Path $HOME '.config\opencode\agents')
    'opencode/commands/'         = (Join-Path $HOME '.config\opencode\commands')
    'opencode/skills/'           = (Join-Path $HOME '.config\opencode\skills')
    'opencode/themes/'           = (Join-Path $HOME '.config\opencode\themes')

    'codex/AGENTS.md'            = (Join-Path $HOME '.codex\AGENTS.md')
    'codex/agents/'              = (Join-Path $HOME '.codex\agents')
    'codex/skills/'              = (Join-Path $HOME '.codex\skills')
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Test-DeveloperMode {
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path -LiteralPath $key)) { return $false }
    $val = (Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    return ($val -eq 1)
}

function Format-Action {
    param([string]$Status, [string]$Message, [int]$Width = 12)
    $padded = $Status.PadRight($Width)
    "[$padded] $Message"
}

function Get-RelativePath {
    param(
        [string]$SourceAbsolute,
        [string]$TargetAbsolute
    )
    $sourceDir = [System.IO.Path]::GetDirectoryName($TargetAbsolute)
    $rel = [System.IO.Path]::GetRelativePath($sourceDir, $SourceAbsolute)
    return $rel
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host 'install.ps1 - dotfiles bootstrap para OpenCode y Codex' -ForegroundColor Cyan
Write-Host ("Repo: {0}" -f $repoRoot) -ForegroundColor DarkGray
Write-Host ''

# ---------------------------------------------------------------------------
# Validación de prerrequisitos
# ---------------------------------------------------------------------------

if (-not $Doctor -and -not $Uninstall -and -not $DryRun) {
    if (-not (Test-DeveloperMode)) {
        Write-Host '[ERROR] Windows Developer Mode no está activo.' -ForegroundColor Red
        Write-Host ''
        Write-Host 'Para activar el Modo Desarrollador:' -ForegroundColor Yellow
        Write-Host '  1. Abre Configuración de Windows' -ForegroundColor Yellow
        Write-Host '  2. Ve a Privacidad y seguridad -> Desarrolladores (o "Para programadores")' -ForegroundColor Yellow
        Write-Host '  3. Activa el interruptor "Modo Desarrollador"' -ForegroundColor Yellow
        Write-Host '  4. Confirma la advertencia de UAC' -ForegroundColor Yellow
        Write-Host '  5. Vuelve a ejecutar este script' -ForegroundColor Yellow
        Write-Host ''
        Write-Host 'Alternativa: ejecuta PowerShell como Administrador, pero no es lo recomendado.' -ForegroundColor DarkGray
        exit 1
    }
    Write-Host 'checking Windows Developer Mode ... OK' -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Modo DOCTOR: solo audita
# ---------------------------------------------------------------------------

if ($Doctor) {
    Write-Host 'Doctor report' -ForegroundColor Cyan
    Write-Host ("{0}" -f ('-' * 65)) -ForegroundColor DarkGray

    $counts = @{ OK = 0; WARN = 0; FAIL = 0 }

    foreach ($entry in $targets.GetEnumerator()) {
        $sourceRel = $entry.Key
        $targetAbs = $entry.Value
        $sourceAbs = Join-Path $repoRoot $sourceRel

        # Verifica que el source exista en el repo
        if (-not (Test-Path -LiteralPath $sourceAbs)) {
            Write-Host (Format-Action 'WARN' "$sourceRel -> $targetAbs")
            Write-Host '         └─ target file does not exist in repo' -ForegroundColor Yellow
            $counts.WARN++
            continue
        }

        # Verifica que el target exista
        if (-not (Test-Path -LiteralPath $targetAbs)) {
            Write-Host (Format-Action 'WARN' "$sourceRel -> $targetAbs")
            Write-Host '         └─ symlink not installed yet (run install.ps1)' -ForegroundColor Yellow
            $counts.WARN++
            continue
        }

        $item = Get-Item -LiteralPath $targetAbs -Force
        if ($item.LinkType -ne 'SymbolicLink') {
            Write-Host (Format-Action 'WARN' "$sourceRel -> $targetAbs")
            Write-Host '         └─ target is not a symbolic link (run with -Force to replace)' -ForegroundColor Yellow
            $counts.WARN++
            continue
        }

        # Verifica que el symlink resuelva
        try {
            $resolved = (Resolve-Path -LiteralPath $targetAbs -ErrorAction Stop).Path
        } catch {
            Write-Host (Format-Action 'FAIL' "$sourceRel -> $targetAbs")
            Write-Host ('         └─ symlink broken: {0}' -f $_.Exception.Message) -ForegroundColor Red
            $counts.FAIL++
            continue
        }

        Write-Host (Format-Action 'OK' "$sourceRel -> $targetAbs")
        $counts.OK++
    }

    Write-Host ("{0}" -f ('-' * 65)) -ForegroundColor DarkGray
    $summary = 'Summary: {0} ok, {1} warning, {2} fail' -f $counts.OK, $counts.WARN, $counts.FAIL
    $color = if ($counts.FAIL -gt 0) { 'Red' } elseif ($counts.WARN -gt 0) { 'Yellow' } else { 'Green' }
    Write-Host $summary -ForegroundColor $color
    Write-Host ''
    exit 0
}

# ---------------------------------------------------------------------------
# Modo UNINSTALL
# ---------------------------------------------------------------------------

if ($Uninstall) {
    Write-Host 'Uninstalling symlinks created by this script' -ForegroundColor Cyan
    Write-Host ("{0}" -f ('-' * 65)) -ForegroundColor DarkGray

    $counts = @{ removed = 0; skip = 0; errors = 0 }

    foreach ($entry in $targets.GetEnumerator()) {
        $targetAbs = $entry.Value
        if (-not (Test-Path -LiteralPath $targetAbs)) {
            $counts.skip++
            continue
        }

        $item = Get-Item -LiteralPath $targetAbs -Force
        if ($item.LinkType -ne 'SymbolicLink') {
            Write-Host (Format-Action 'skip' "$($entry.Key) -> $targetAbs (not a symlink)")
            $counts.skip++
            continue
        }

        if ($DryRun) {
            Write-Host (Format-Action 'would-remove' "$($entry.Key) -> $targetAbs")
        } else {
            try {
                Remove-Item -LiteralPath $targetAbs -Force
                Write-Host (Format-Action 'removed' "$($entry.Key) -> $targetAbs")
                $counts.removed++
            } catch {
                Write-Host (Format-Action 'error' "$($entry.Key) -> $targetAbs : $($_.Exception.Message)") -ForegroundColor Red
                $counts.errors++
            }
        }
    }

    Write-Host ("{0}" -f ('-' * 65)) -ForegroundColor DarkGray
    if ($DryRun) {
        Write-Host ('Summary: 0 removed, {0} skipped (dry-run)' -f $counts.skip) -ForegroundColor DarkGray
    } else {
        Write-Host ('Summary: {0} removed, {1} skipped, {2} errors' -f $counts.removed, $counts.skip, $counts.errors) -ForegroundColor Cyan
    }
    Write-Host ''
    exit 0
}

# ---------------------------------------------------------------------------
# Modo principal: crear o reemplazar symlinks
# ---------------------------------------------------------------------------

Write-Host 'linking targets' -ForegroundColor Cyan
Write-Host ("{0}" -f ('-' * 65)) -ForegroundColor DarkGray

$counts = @{ linked = 0; ok = 0; relinked = 0; backup = 0; skip = 0; errors = 0 }

foreach ($entry in $targets.GetEnumerator()) {
    $sourceRel = $entry.Key
    $targetAbs = $entry.Value
    $sourceAbs = Join-Path $repoRoot $sourceRel

    # Verifica que el source exista
    if (-not (Test-Path -LiteralPath $sourceAbs)) {
        Write-Host (Format-Action 'error' "$sourceRel no existe en el repo") -ForegroundColor Red
        $counts.errors++
        continue
    }

    $relTarget = Get-RelativePath -SourceAbsolute $sourceAbs -TargetAbsolute $targetAbs

    # Estado 1: el target no existe. Crear symlink.
    if (-not (Test-Path -LiteralPath $targetAbs)) {
        if ($DryRun) {
            Write-Host (Format-Action 'would-link' "$sourceRel -> $targetAbs")
            $counts.linked++
            continue
        }
        try {
            $parent = [System.IO.Path]::GetDirectoryName($targetAbs)
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            New-Item -ItemType SymbolicLink -Path $targetAbs -Target $relTarget -Force | Out-Null
            Write-Host (Format-Action 'linked' "$sourceRel -> $targetAbs")
            $counts.linked++
        } catch {
            Write-Host (Format-Action 'error' "$sourceRel -> $targetAbs : $($_.Exception.Message)") -ForegroundColor Red
            $counts.errors++
        }
        continue
    }

    # Estado 2: el target existe. Analizar qué es.
    $item = Get-Item -LiteralPath $targetAbs -Force

    if ($item.LinkType -eq 'SymbolicLink') {
        # Ya es symlink. Verificar si apunta al source correcto.
        $currentTarget = $item.Target
        if ($currentTarget -eq $relTarget) {
            Write-Host (Format-Action 'ok' "$sourceRel -> $targetAbs (already correct)")
            $counts.ok++
        } else {
            # Apunta a otro lado. Reemplazar.
            if ($DryRun) {
                Write-Host (Format-Action 'would-relink' "$sourceRel -> $targetAbs (currently -> $currentTarget)")
                $counts.relinked++
            } else {
                try {
                    Remove-Item -LiteralPath $targetAbs -Force
                    New-Item -ItemType SymbolicLink -Path $targetAbs -Target $relTarget -Force | Out-Null
                    Write-Host (Format-Action 'relinked' "$sourceRel -> $targetAbs (was -> $currentTarget)")
                    $counts.relinked++
                } catch {
                    Write-Host (Format-Action 'error' "$sourceRel -> $targetAbs : $($_.Exception.Message)") -ForegroundColor Red
                    $counts.errors++
                }
            }
        }
        continue
    }

    # Estado 3: el target existe como archivo o directorio real.
    if (-not $Force) {
        Write-Host (Format-Action 'skip' "$sourceRel -> $targetAbs (real file/dir; use -Force to replace with backup)")
        $counts.skip++
        continue
    }

    # -Force está activo: hacer backup y reemplazar.
    if ($DryRun) {
        Write-Host (Format-Action 'would-backup' "$sourceRel -> $targetAbs (would backup then link)")
        $counts.backup++
        continue
    }

    try {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = "${targetAbs}.bak-${timestamp}"
        Move-Item -LiteralPath $targetAbs -Destination $backupPath -Force
        New-Item -ItemType SymbolicLink -Path $targetAbs -Target $relTarget -Force | Out-Null
        Write-Host (Format-Action 'backup' "$sourceRel -> $targetAbs (backup at $backupPath)")
        $counts.backup++
    } catch {
        Write-Host (Format-Action 'error' "$sourceRel -> $targetAbs : $($_.Exception.Message)") -ForegroundColor Red
        $counts.errors++
    }
}

Write-Host ("{0}" -f ('-' * 65)) -ForegroundColor DarkGray

if ($DryRun) {
    $summary = 'Summary (dry-run): {0} would-link, {1} ok, {2} would-relink, {3} would-backup, {4} skipped, {5} errors' -f `
        $counts.linked, $counts.ok, $counts.relinked, $counts.backup, $counts.skip, $counts.errors
    Write-Host $summary -ForegroundColor DarkGray
} else {
    $summary = 'Summary: {0} linked, {1} ok, {2} relinked, {3} backup+link, {4} skipped, {5} errors' -f `
        $counts.linked, $counts.ok, $counts.relinked, $counts.backup, $counts.skip, $counts.errors
    $color = if ($counts.errors -gt 0) { 'Red' } elseif ($counts.skip -gt 0) { 'Yellow' } else { 'Green' }
    Write-Host $summary -ForegroundColor $color
}
Write-Host ''
