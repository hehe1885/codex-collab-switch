[CmdletBinding()]
param(
    [switch]$Legacy,
    [string]$HomeDirectory = $HOME
)

$ErrorActionPreference = "Stop"
$PackageDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($HomeDirectory)) {
    throw "HOME must identify a user directory."
}

if ($Legacy) {
    $CodexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HomeDirectory ".codex" }
    $CodexFullPath = [IO.Path]::GetFullPath($CodexRoot)
    if ([string]::IsNullOrWhiteSpace($CodexRoot) -or $CodexFullPath -eq [IO.Path]::GetPathRoot($CodexFullPath)) {
        throw "Refusing an empty or filesystem-root CODEX_HOME."
    }
    $SkillsRoot = Join-Path $CodexRoot "skills"
    $BackupRoot = Join-Path $CodexRoot "skill-backups"
} else {
    $AgentsRoot = Join-Path $HomeDirectory ".agents"
    $SkillsRoot = Join-Path $AgentsRoot "skills"
    $BackupRoot = Join-Path $AgentsRoot "skill-backups"
}

$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ") + "-" + $PID + "-" + [guid]::NewGuid().ToString("N")

function Get-DirectorySignature {
    param([Parameter(Mandatory = $true)][string]$Path)
    $ResolvedRoot = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\', '/')
    Get-ChildItem -LiteralPath $ResolvedRoot -Recurse -Force -File |
        Sort-Object FullName |
        ForEach-Object {
            if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                "__SYMLINK__"
            } else {
                $Relative = $_.FullName.Substring($ResolvedRoot.Length).TrimStart('\', '/')
                $Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                "$Relative`0$Hash"
            }
        }
}

function Test-DirectoryMatches {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )
    $Difference = Compare-Object @(Get-DirectorySignature $Source) @(Get-DirectorySignature $Target)
    return $null -eq $Difference
}

function Uninstall-Skill {
    param([Parameter(Mandatory = $true)][string]$Name)
    $Source = Join-Path (Join-Path $PackageDir "skills") $Name
    $Target = Join-Path $SkillsRoot $Name
    $Marker = Join-Path $Target ".codex-collab-switch-v04"

    if (-not (Test-Path -LiteralPath $Target -PathType Container) -or
        -not (Test-Path -LiteralPath $Marker -PathType Leaf)) {
        Write-Output "Skipped missing, unowned, or modified skill: $Target"
        return
    }
    $TargetItem = Get-Item -LiteralPath $Target -Force
    if (($TargetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not (Test-DirectoryMatches $Source $Target)) {
        Write-Output "Skipped missing, unowned, or modified skill: $Target"
        return
    }
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $Backup = Join-Path $BackupRoot "$Name.uninstalled-v04-$Timestamp"
    Move-Item -LiteralPath $Target -Destination $Backup
    Write-Output "Moved installed skill to recoverable backup: $Backup"
}

Uninstall-Skill "codex-collab-switch"
Write-Output "Uninstall complete. No Codex config.toml or custom agent was changed."
