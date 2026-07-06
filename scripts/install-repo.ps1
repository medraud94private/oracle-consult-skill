param(
    [string]$RepoPath = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "skills\oracle-consult"
$resolvedRepo = Resolve-Path $RepoPath
$base = Join-Path $resolvedRepo ".agents\skills"
$target = Join-Path $base "oracle-consult"

if (-not (Test-Path $source)) {
    throw "Source skill not found: $source"
}

if ((Test-Path $target) -and -not $Force) {
    throw "Target already exists: $target. Re-run with -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null
if (Test-Path $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $target -Recurse

& (Join-Path $PSScriptRoot "validate-skill.ps1") -SkillRoot $target
Write-Host "Installed oracle-consult skill to $target"
Write-Host "Test prompt: Use `$oracle-consult to pressure-test this implementation plan."

