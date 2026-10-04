#requires -Version 7
<#
.SYNOPSIS
    Enlaza las configuraciones versionadas de Codex, OpenCode y Claude Code.
.DESCRIPTION
    El clon que contiene este script es la fuente de verdad. Solo se reemplazan
    las rutas mapeadas; nunca se crean archivos .bak-*.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Doctor,
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

if ($Doctor -and ($DryRun -or $Uninstall)) {
    throw '-Doctor no puede combinarse con -DryRun ni -Uninstall.'
}

# -Force se conserva como alias de la instalación normal para llamadas antiguas.
# No habilita respaldos ni amplía el alcance de los mapeos.
$targets = @(
    @{ Source = 'AGENTS.md'; Target = (Join-Path $HOME '.codex/AGENTS.md') },
    @{ Source = 'AGENTS.md'; Target = (Join-Path $HOME '.config/opencode/AGENTS.md') },
    @{ Source = 'AGENTS.md'; Target = (Join-Path $HOME '.claude/CLAUDE.md') },
    @{ Source = 'codex/agents'; Target = (Join-Path $HOME '.codex/agents') },
    @{ Source = 'codex/skills'; Target = (Join-Path $HOME '.codex/skills') },
    @{ Source = 'opencode/agents'; Target = (Join-Path $HOME '.config/opencode/agents') },
    @{ Source = 'opencode/commands'; Target = (Join-Path $HOME '.config/opencode/commands') },
    @{ Source = 'opencode/themes'; Target = (Join-Path $HOME '.config/opencode/themes') },
    @{ Source = 'claude/agents'; Target = (Join-Path $HOME '.claude/agents') },
    @{ Source = 'claude/commands'; Target = (Join-Path $HOME '.claude/commands') },
    @{ Source = 'claude/statusline.js'; Target = (Join-Path $HOME '.claude/statusline.js') },
    # Configuración sin datos de la máquina. Al desinstalar se materializa como
    # copia para no dejar al arnés sin configuración.
    @{ Source = 'claude/settings.json'; Target = (Join-Path $HOME '.claude/settings.json'); Materialize = $true },
    @{ Source = 'opencode/opencode.jsonc'; Target = (Join-Path $HOME '.config/opencode/opencode.jsonc'); Materialize = $true },
    @{ Source = 'opencode/dcp.jsonc'; Target = (Join-Path $HOME '.config/opencode/dcp.jsonc'); Materialize = $true }
)

# Convención: toda skill de opencode/skills es compartida por defecto y se
# instala una sola vez en ~/.claude/skills (OpenCode también lo descubre),
# evitando dos definiciones con el mismo nombre. Las listadas en $openCodeOnly
# son exclusivas de OpenCode: conservan su ruta nativa y nunca se presentan
# a Claude. El catálogo ya no vive en este script: añadir una skill compartida
# no requiere editarlo, basta crear su directorio y reinstalar.
$openCodeOnly = @()
$openCodeSkills = Join-Path $repoRoot 'opencode/skills'
$openCodeSkillsTarget = Join-Path $HOME '.config/opencode/skills'
$claudeSkillsTarget = Join-Path $HOME '.claude/skills'
$skillShadowPaths = @()

foreach ($skill in Get-ChildItem -LiteralPath $openCodeSkills -Directory) {
    if ($skill.Name -in $openCodeOnly) {
        $targets += @{ Source = "opencode/skills/$($skill.Name)"; Target = (Join-Path $openCodeSkillsTarget $skill.Name) }
        $skillShadowPaths += @{ Path = (Join-Path $claudeSkillsTarget $skill.Name); Reason = 'skill exclusiva de OpenCode fuera de su directorio' }
    } else {
        $targets += @{ Source = "opencode/skills/$($skill.Name)"; Target = (Join-Path $claudeSkillsTarget $skill.Name) }
        $skillShadowPaths += @{ Path = (Join-Path $openCodeSkillsTarget $skill.Name); Reason = 'skill compartida duplicada en el directorio exclusivo' }
    }
}

# Una distribución incompleta no debe provocar la eliminación de ningún destino.
foreach ($entry in $targets) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $entry.Source))) {
        throw "Falta en el clon: $($entry.Source)"
    }
}

function Get-LinkState {
    param([string]$Target, [string]$Source)
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) { return 'missing' }
    if ($item.LinkType -ne 'SymbolicLink') { return 'real' }
    $expected = [IO.Path]::GetRelativePath([IO.Path]::GetDirectoryName($Target), $Source)
    if ($item.Target -eq $expected) { return 'linked' }
    return 'other-link'
}

function Remove-MappedPath {
    param([string]$Target)
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) { return }
    if ($item.LinkType) {
        Remove-Item -LiteralPath $Target -Force
    } else {
        Remove-Item -LiteralPath $Target -Recurse -Force
    }
}

function Test-DeveloperMode {
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path -LiteralPath $key)) { return $false }
    return (Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense -eq 1
}

if (-not ($Doctor -or $Uninstall -or $DryRun) -and -not (Test-DeveloperMode)) {
    throw 'Windows Developer Mode debe estar activo para crear los enlaces simbólicos.'
}

# Migración del enlace anterior, que ocupaba todo el directorio de skills.
# El nuevo esquema deja el directorio real y enlaza únicamente cada skill propia.
$legacy = Get-Item -LiteralPath $openCodeSkillsTarget -Force -ErrorAction SilentlyContinue
if ($Doctor) {
    if ($legacy -and $legacy.LinkType) {
        "WARN $openCodeSkillsTarget (enlace antiguo; reinstalar para migrar)"
    }
} elseif (-not $Uninstall -and $legacy -and $legacy.LinkType) {
    if ($DryRun) {
        "would-replace $openCodeSkillsTarget (enlace antiguo por directorio de skills exclusivas)"
    } else {
        Remove-Item -LiteralPath $openCodeSkillsTarget -Force
    }
}

# Limpiar enlaces de skills ubicados fuera de su destino correspondiente.
# Si el directorio antiguo es un enlace, eliminarlo basta: su destino se conserva.
if (-not $Uninstall -and -not ($legacy -and $legacy.LinkType)) {
    foreach ($shadow in $skillShadowPaths) {
        if (-not (Get-Item -LiteralPath $shadow.Path -Force -ErrorAction SilentlyContinue)) { continue }
        if ($Doctor) {
            "WARN $($shadow.Path) ($($shadow.Reason))"
        } elseif ($DryRun) {
            "would-replace $($shadow.Path) ($($shadow.Reason))"
        } else {
            Remove-MappedPath -Target $shadow.Path
        }
    }
}

foreach ($entry in $targets) {
    $source = Join-Path $repoRoot $entry.Source
    $target = $entry.Target
    $state = Get-LinkState -Target $target -Source $source
    if ($legacy -and $legacy.LinkType -and -not $Uninstall -and
        [IO.Path]::GetDirectoryName($target) -eq $openCodeSkillsTarget) {
        # Al retirar el enlace del directorio antiguo, estos destinos quedan
        # vacíos; no son carpetas reales que la instalación vaya a borrar.
        $state = 'missing'
    }

    if ($Doctor) {
        if ($state -eq 'linked') { "OK $target -> $($entry.Source)" }
        else { "WARN $target ($state; origen esperado: $($entry.Source))" }
        continue
    }

    if ($Uninstall) {
        if ($state -ne 'linked') { "skip $target ($state)"; continue }
        if ($entry.Materialize) {
            if ($DryRun) { "would-materialize $target (copia del contenido en lugar del enlace)"; continue }
            Remove-Item -LiteralPath $target -Force
            Copy-Item -LiteralPath $source -Destination $target
            "materialized $target"
            continue
        }
        if ($DryRun) { "would-unlink $target"; continue }
        Remove-Item -LiteralPath $target -Force
        "unlinked $target"
        continue
    }

    if ($state -eq 'linked') { "OK $target"; continue }
    if ($DryRun) { "would-link $target ($state; reemplazo sin respaldo)"; continue }

    $parent = [IO.Path]::GetDirectoryName($target)
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Remove-MappedPath -Target $target
    $relative = [IO.Path]::GetRelativePath($parent, $source)
    New-Item -ItemType SymbolicLink -Path $target -Target $relative | Out-Null
    "linked $target -> $($entry.Source)"
}
