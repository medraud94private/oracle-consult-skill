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

$configFile = Join-Path $PluginRoot "skills\oracle-consult\oracle-consult.config.json"
if (-not (Test-Path $configFile)) {
    throw "Missing oracle-consult.config.json: $configFile"
}
$config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
if (@("hidden", "attach", "visible", "render") -notcontains $config.browserMode) {
    throw "oracle-consult.config.json browserMode must be hidden, attach, visible, or render."
}
if ($config.sessionPolicy -ne "fresh-by-default") {
    throw "oracle-consult.config.json sessionPolicy must be fresh-by-default."
}

Write-Host "Codex plugin validation passed: $PluginRoot"
