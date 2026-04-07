[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $HOME ".claude\skills")
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $scriptDir "skills"

if (-not (Test-Path $sourceDir)) {
    throw "skills directory not found: $sourceDir"
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$installed = 0

Get-ChildItem -Path $sourceDir -Directory | ForEach-Object {
    $skillName = $_.Name
    $targetDir = Join-Path $Destination $skillName
    if (Test-Path $targetDir) {
        Remove-Item -LiteralPath $targetDir -Recurse -Force
    }
    Copy-Item -Path $_.FullName -Destination $targetDir -Recurse -Force
    $installed += 1
    Write-Host "Installed $skillName -> $targetDir"
}

Write-Host "Installed $installed skills into $Destination"
