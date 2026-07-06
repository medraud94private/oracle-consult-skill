param(
    [string]$Prompt = "Smoke-test the oracle-consult-skill packaging. Do not provide implementation advice."
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$skillFile = Join-Path $repoRoot "skills\oracle-consult-skill\SKILL.md"
$metadataFile = Join-Path $repoRoot "skills\oracle-consult-skill\agents\openai.yaml"

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx was not found. Install Node.js 24+ before running Oracle smoke checks."
}

npx -y @steipete/oracle --dry-run summary --files-report `
    -p $Prompt `
    --file $skillFile `
    --file $metadataFile
