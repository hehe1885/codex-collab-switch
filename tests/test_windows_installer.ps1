[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TestHome = Join-Path ([IO.Path]::GetTempPath()) ("sol-workflow-skills02-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TestHome | Out-Null

& (Join-Path $PackageRoot "install.ps1") -HomeDirectory $TestHome
$OfficialRoot = Join-Path (Join-Path $TestHome ".agents") "skills"
foreach ($Name in @("codex-collab-switch")) {
    $SkillFile = Join-Path (Join-Path $OfficialRoot $Name) "SKILL.md"
    if (-not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
        throw "Official installation missing: $SkillFile"
    }
}

$UserNote = Join-Path (Join-Path $OfficialRoot "codex-collab-switch") "user-note.txt"
Set-Content -LiteralPath $UserNote -Value "preserve me" -Encoding UTF8
$Refused = $false
try {
    & (Join-Path $PackageRoot "install.ps1") -HomeDirectory $TestHome
} catch {
    $Refused = $true
}
if (-not $Refused) { throw "Modified target was overwritten without -Force." }
& (Join-Path $PackageRoot "install.ps1") -Force -HomeDirectory $TestHome
$Backups = @(Get-ChildItem -LiteralPath (Join-Path $TestHome '.agents/skill-backups') -Directory -Filter 'codex-collab-switch.before-v1.0-*')
if ($Backups.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $Backups[0].FullName 'user-note.txt'))) {
    throw "Force installation did not preserve the modified target."
}
& (Join-Path $PackageRoot "install.ps1") -HomeDirectory $TestHome
Set-Content -LiteralPath $UserNote -Value "preserve me" -Encoding UTF8
& (Join-Path $PackageRoot "uninstall.ps1") -HomeDirectory $TestHome
if (-not (Test-Path -LiteralPath $UserNote -PathType Leaf)) {
    throw "Modified skill was removed instead of preserved."
}
& (Join-Path $PackageRoot "install.ps1") -Force -HomeDirectory $TestHome
& (Join-Path $PackageRoot "uninstall.ps1") -HomeDirectory $TestHome
if (Test-Path -LiteralPath (Join-Path $OfficialRoot "codex-collab-switch")) {
    throw "Unmodified skill was not uninstalled."
}

$LegacyRoot = Join-Path $TestHome "legacy-codex-home"
$PreviousCodexHome = $env:CODEX_HOME
try {
    $env:CODEX_HOME = $LegacyRoot
    & (Join-Path $PackageRoot "install.ps1") -Legacy -HomeDirectory $TestHome
    foreach ($Name in @("codex-collab-switch")) {
        $SkillFile = Join-Path (Join-Path (Join-Path $LegacyRoot "skills") $Name) "SKILL.md"
        if (-not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
            throw "Legacy installation missing: $SkillFile"
        }
    }
} finally {
    $env:CODEX_HOME = $PreviousCodexHome
}

Write-Output "Windows installer tests passed. Recoverable test artifacts: $TestHome"
