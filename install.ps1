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
    @{ Source = 'claude/agents'; Target = (Join-Path $HOME '.claude/agents') }
)

# OpenCode descubre también ~/.claude/skills. Instalar las compartidas una
# sola vez evita dos definiciones con el mismo nombre. Las internas de OpenCode
# conservan su ruta nativa y nunca se presentan a Claude.
$sharedSkills = @(
    'dotfiles', 'find-skills', 'git-push-cloud', 'hybrid-email-format', 'jupyter-notebook',
    'kill-session-processes', 'obsidian-markdown', 'playwright-cli', 'prompt-augmenter',
    'session-rename', 'sync-agents'
)
$openCodeSkills = Join-Path $repoRoot 'opencode/skills'
$openCodeSkillsTarget = Join-Path $HOME '.config/opencode/skills'
$sharedShadowPaths = @()

foreach ($skill in Get-ChildItem -LiteralPath $openCodeSkills -Directory) {
    if ($skill.Name -in $sharedSkills) {
        $targets += @{ Source = "opencode/skills/$($skill.Name)"; Target = (Join-Path $HOME ".claude/skills/$($skill.Name)") }
        $sharedShadowPaths += Join-Path $openCodeSkillsTarget $skill.Name
    } else {
        $targets += @{ Source = "opencode/skills/$($skill.Name)"; Target = (Join-Path $openCodeSkillsTarget $skill.Name) }
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

# Limpiar nombres compartidos antiguos del directorio exclusivo de OpenCode.
# Si el directorio antiguo es un enlace, eliminarlo basta: su destino se conserva.
if (-not $Uninstall -and -not ($legacy -and $legacy.LinkType)) {
    foreach ($shadow in $sharedShadowPaths) {
        if (-not (Get-Item -LiteralPath $shadow -Force -ErrorAction SilentlyContinue)) { continue }
        if ($Doctor) {
            "WARN $shadow (skill compartida duplicada)"
        } elseif ($DryRun) {
            "would-replace $shadow (skill compartida duplicada)"
        } else {
            Remove-MappedPath -Target $shadow
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
