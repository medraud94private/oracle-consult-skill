param(
    [string]$PluginRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "claude\plugins\oracle-consult"),
    [string]$MarketplaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [switch]$SkipMarketplace,
    [switch]$NoStrict
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude CLI was not found. Install or update Claude Code before validating the plugin."
}

$pluginPath = Resolve-Path $PluginRoot

$strictArgs = @()
if (-not $NoStrict) {
    $strictArgs += "--strict"
}

claude plugin validate @strictArgs $pluginPath

$configFile = Join-Path $pluginPath "skills\oracle-consult\oracle-consult.config.json"
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

Write-Host "Claude Code plugin validation passed: $pluginPath"
if (-not $SkipMarketplace) {
    $marketplacePath = Resolve-Path $MarketplaceRoot
    claude plugin validate @strictArgs $marketplacePath
    Write-Host "Claude Code marketplace validation passed: $marketplacePath"
}
