param(
    [string]$Prompt = "Smoke-test the Claude Code oracle-consult plugin packaging. Do not provide implementation advice."
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$pluginRoot = Join-Path $repoRoot "claude\plugins\oracle-consult"
$skillFile = Join-Path $pluginRoot "skills\oracle-consult\SKILL.md"
$manifestFile = Join-Path $pluginRoot ".claude-plugin\plugin.json"

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx was not found. Install Node.js 24+ before running Oracle smoke checks."
}

npx -y @steipete/oracle --dry-run summary --files-report `
    -p $Prompt `
    --file $skillFile `
    --file $manifestFile
