param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "plugins\oracle-consult"
$pluginBase = Join-Path $HOME ".agents\plugins"
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
    throw "Refusing to write outside Codex plugin directory: $resolvedPluginDir"
}

if (Test-Path $pluginDir) {
    Remove-Item -LiteralPath $pluginDir -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $pluginDir -Recurse

if (Test-Path $marketplacePath) {
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
} else {
    $marketplace = [pscustomobject]@{
        name = "personal"
        interface = [pscustomobject]@{ displayName = "Personal" }
        plugins = @()
    }
}

if (-not $marketplace.PSObject.Properties["name"]) {
    $marketplace | Add-Member -NotePropertyName name -NotePropertyValue "personal"
}
if (-not $marketplace.PSObject.Properties["interface"]) {
    $marketplace | Add-Member -NotePropertyName interface -NotePropertyValue ([pscustomobject]@{ displayName = "Personal" })
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
Write-Host "Installed Codex plugin source to $pluginDir"
Write-Host "Updated personal plugin marketplace at $marketplacePath"
Write-Host "Open /plugins in a new Codex thread and search for Oracle Consult."
