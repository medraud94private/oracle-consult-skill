param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "claude\plugins\oracle-consult"
$base = Join-Path $HOME ".claude\skills"
$target = Join-Path $base "oracle-consult-plugin"

if (-not (Test-Path $source)) {
    throw "Claude plugin source not found: $source"
}

if ((Test-Path $target) -and -not $Force) {
    throw "Target already exists: $target. Re-run with -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null

$resolvedBase = [System.IO.Path]::GetFullPath($base)
$resolvedTarget = [System.IO.Path]::GetFullPath($target)
$resolvedBaseWithSep = $resolvedBase.TrimEnd("\") + "\"
if (-not $resolvedTarget.StartsWith($resolvedBaseWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside Claude skills directory: $resolvedTarget"
}

if (Test-Path $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $target -Recurse

& (Join-Path $PSScriptRoot "validate-claude-plugin.ps1") -PluginRoot $target -MarketplaceRoot $repoRoot
Write-Host "Installed Claude Code oracle-consult plugin to $target"
Write-Host "Start a new Claude Code session, then invoke /oracle-consult:oracle-consult."
