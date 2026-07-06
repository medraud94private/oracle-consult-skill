param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "claude\skills\oracle-consult"
$base = Join-Path $HOME ".claude\skills"
$target = Join-Path $base "oracle-consult"

if (-not (Test-Path $source)) {
    throw "Claude skill source not found: $source"
}

if ((Test-Path $target) -and -not $Force) {
    throw "Target already exists: $target. Re-run with -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null
if (Test-Path $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $target -Recurse

& (Join-Path $PSScriptRoot "validate-claude-skill.ps1") -SkillRoot $target
Write-Host "Installed Claude Code oracle-consult skill to $target"
Write-Host "Restart Claude Code if /oracle-consult is not visible immediately."

