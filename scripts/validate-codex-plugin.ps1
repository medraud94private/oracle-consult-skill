param(
    [string]$PluginRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "plugins\oracle-consult")
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$validator = Join-Path $HOME ".codex\skills\.system\plugin-creator\scripts\validate_plugin.py"
$skillValidator = Join-Path $HOME ".codex\skills\.system\skill-creator\scripts\quick_validate.py"

if (-not (Test-Path $validator)) {
    throw "Plugin validator not found: $validator"
}
if (-not (Test-Path $skillValidator)) {
    throw "Skill validator not found: $skillValidator"
}

python $validator $PluginRoot
python $skillValidator (Join-Path $PluginRoot "skills\oracle-consult")

Write-Host "Codex plugin validation passed: $PluginRoot"
