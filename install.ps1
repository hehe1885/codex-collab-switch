[CmdletBinding()]
param(
    [switch]$Force,
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

New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ") + "-" + $PID + "-" + [guid]::NewGuid().ToString("N")

function Get-DirectorySignature {
    param([Parameter(Mandatory = $true)][string]$Path)
    $ResolvedRoot = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\', '/')
    $Entries = Get-ChildItem -LiteralPath $ResolvedRoot -Recurse -Force -File |
        Sort-Object FullName
    foreach ($Entry in $Entries) {
        if (($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            return @("__SYMLINK__")
        }
        $Relative = $Entry.FullName.Substring($ResolvedRoot.Length).TrimStart('\', '/')
        $Hash = (Get-FileHash -LiteralPath $Entry.FullName -Algorithm SHA256).Hash
        "$Relative`0$Hash"
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

function Install-Skill {
    param([Parameter(Mandatory = $true)][string]$Name)
    $Source = Join-Path (Join-Path $PackageDir "skills") $Name
    $Target = Join-Path $SkillsRoot $Name

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "Invalid package skill: $Source"
    }
    if (Test-Path -LiteralPath $Target) {
        $TargetItem = Get-Item -LiteralPath $Target -Force
        if (($TargetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Refusing to replace a linked target: $Target"
        }
        if (-not $TargetItem.PSIsContainer) {
            throw "Target exists and is not a directory: $Target"
        }
        if (Test-DirectoryMatches $Source $Target) {
            Write-Output "Skill already matches: $Target"
            return
        }
        if (-not $Force) {
            throw "Target differs; review it before using -Force: $Target"
        }
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        $Backup = Join-Path $BackupRoot "$Name.before-v04-$Timestamp"
        Move-Item -LiteralPath $Target -Destination $Backup
        Write-Output "Preserved previous target: $Backup"
    }

    Copy-Item -LiteralPath $Source -Destination $Target -Recurse
    Write-Output "Installed skill: $Target"
}

Install-Skill "codex-collab-switch"
Write-Output "Installation complete. No Codex config.toml or custom agent was changed."
