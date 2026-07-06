param(
    [string]$RepoPath = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "plugins\oracle-consult"
$resolvedRepo = Resolve-Path $RepoPath
$pluginBase = Join-Path $resolvedRepo ".agents\plugins"
$pluginDir = Join-Path $pluginBase "plugins\oracle-consult"
$marketplacePath = Join-Path $pluginBase "marketplace.json"

if (-not (Test-Path $source)) {
    throw "Plugin source not found: $source"
}

if ((Test-Path $pluginDir) -and -not $Force) {
    throw "Target already exists: $pluginDir. Re-run with -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path (Join-Path $pluginBase "plugins") | Out-Null

$resolvedPluginBase = [System.IO.Path]::GetFullPath($pluginBase)
$resolvedPluginDir = [System.IO.Path]::GetFullPath($pluginDir)
$resolvedPluginBaseWithSep = $resolvedPluginBase.TrimEnd("\") + "\"
if (-not $resolvedPluginDir.StartsWith($resolvedPluginBaseWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside repo Codex plugin directory: $resolvedPluginDir"
}

if (Test-Path $pluginDir) {
    Remove-Item -LiteralPath $pluginDir -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $pluginDir -Recurse

if (Test-Path $marketplacePath) {
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
} else {
    $marketplace = [pscustomobject]@{
        name = "repo-local"
        interface = [pscustomobject]@{ displayName = "Repository Local" }
        plugins = @()
    }
}

if (-not $marketplace.PSObject.Properties["name"]) {
    $marketplace | Add-Member -NotePropertyName name -NotePropertyValue "repo-local"
}
if (-not $marketplace.PSObject.Properties["interface"]) {
    $marketplace | Add-Member -NotePropertyName interface -NotePropertyValue ([pscustomobject]@{ displayName = "Repository Local" })
}
if (-not $marketplace.PSObject.Properties["plugins"]) {
    $marketplace | Add-Member -NotePropertyName plugins -NotePropertyValue @()
}

$entry = [pscustomobject]@{
    name = "oracle-consult"
    source = [pscustomobject]@{
        source = "local"
        path = "./plugins/oracle-consult"
    }
    policy = [pscustomobject]@{
        installation = "AVAILABLE"
        authentication = "ON_INSTALL"
    }
    category = "Productivity"
}

$plugins = @($marketplace.plugins | Where-Object { $_.name -ne "oracle-consult" })
$plugins += $entry
$marketplace.plugins = $plugins

$marketplace | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $marketplacePath -Encoding UTF8

& (Join-Path $PSScriptRoot "validate-codex-plugin.ps1") -PluginRoot $pluginDir
Write-Host "Installed repo-scoped Codex plugin source to $pluginDir"
Write-Host "Updated repo plugin marketplace at $marketplacePath"
Write-Host "Open Codex from $resolvedRepo, then open /plugins and search for Oracle Consult."
