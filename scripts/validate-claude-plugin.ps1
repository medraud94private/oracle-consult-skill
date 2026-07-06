param(
    [string]$PluginRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "claude\plugins\oracle-consult"),
    [string]$MarketplaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [switch]$NoStrict
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude CLI was not found. Install or update Claude Code before validating the plugin."
}

$pluginPath = Resolve-Path $PluginRoot
$marketplacePath = Resolve-Path $MarketplaceRoot

$strictArgs = @()
if (-not $NoStrict) {
    $strictArgs += "--strict"
}

claude plugin validate @strictArgs $pluginPath
claude plugin validate @strictArgs $marketplacePath

Write-Host "Claude Code plugin validation passed: $pluginPath"
Write-Host "Claude Code marketplace validation passed: $marketplacePath"
