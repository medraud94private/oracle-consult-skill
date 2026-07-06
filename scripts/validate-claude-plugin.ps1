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

Write-Host "Claude Code plugin validation passed: $pluginPath"
if (-not $SkipMarketplace) {
    $marketplacePath = Resolve-Path $MarketplaceRoot
    claude plugin validate @strictArgs $marketplacePath
    Write-Host "Claude Code marketplace validation passed: $marketplacePath"
}
