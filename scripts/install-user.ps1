param(
    [switch]$Force,
    [switch]$LegacyCodexPath
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "install-helpers.ps1")

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "skills\oracle-consult-skill"
$base = if ($LegacyCodexPath) {
    Join-Path $HOME ".codex\skills"
} else {
    Join-Path $HOME ".agents\skills"
}
$target = Join-Path $base "oracle-consult-skill"

if (-not (Test-Path $source)) {
    throw "Source skill not found: $source"
}

if ((Test-Path $target) -and -not $Force) {
    throw "Target already exists: $target. Re-run with -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null
Remove-LegacyStandaloneOracleSkill -Base $base -Force:$Force
if (Test-Path $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $target -Recurse

& (Join-Path $PSScriptRoot "validate-skill.ps1") -SkillRoot $target
Write-Host "Installed oracle-consult-skill skill to $target"
