param(
    [string]$RepoPath = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "install-helpers.ps1")

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "claude\skills\oracle-consult-skill"
$resolvedRepo = Resolve-Path $RepoPath
$base = Join-Path $resolvedRepo ".claude\skills"
$target = Join-Path $base "oracle-consult-skill"

if (-not (Test-Path $source)) {
    throw "Claude skill source not found: $source"
}

if ((Test-Path $target) -and -not $Force) {
    throw "Target already exists: $target. Re-run with -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null
Remove-LegacyStandaloneOracleSkill -Base $base -Force:$Force

$resolvedBase = [System.IO.Path]::GetFullPath($base)
$resolvedTarget = [System.IO.Path]::GetFullPath($target)
$resolvedBaseWithSep = $resolvedBase.TrimEnd("\") + "\"
if (-not $resolvedTarget.StartsWith($resolvedBaseWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside repo Claude skills directory: $resolvedTarget"
}

if (Test-Path $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $target -Recurse

& (Join-Path $PSScriptRoot "validate-claude-skill.ps1") -SkillRoot $target
Write-Host "Installed Claude Code oracle-consult-skill skill to $target"
Write-Host "Invoke in Claude Code with: /oracle-consult-skill review this plan for missing risks."
