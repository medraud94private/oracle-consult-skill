function Remove-LegacyStandaloneOracleSkill {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Base,

        [switch]$Force
    )

    $legacyTarget = Join-Path $Base "oracle-consult"
    if (-not (Test-Path $legacyTarget)) {
        return
    }

    $legacySkill = Join-Path $legacyTarget "SKILL.md"
    if (-not (Test-Path $legacySkill)) {
        Write-Warning "Legacy oracle-consult path exists but was not recognized as this standalone skill, so it was left in place: $legacyTarget"
        return
    }

    $legacyText = Get-Content -LiteralPath $legacySkill -Raw
    $isLegacy = ($legacyText -match "(?m)^name:\s*oracle-consult\s*$") -and ($legacyText -match "steipete/oracle")
    if (-not $isLegacy) {
        Write-Warning "Legacy oracle-consult path exists but did not match the safety marker, so it was left in place: $legacyTarget"
        return
    }

    if (-not $Force) {
        Write-Warning "Legacy standalone oracle-consult remains. Re-run with -Force to remove the old conflicting name: $legacyTarget"
        return
    }

    $resolvedBase = [System.IO.Path]::GetFullPath($Base)
    $resolvedLegacy = [System.IO.Path]::GetFullPath($legacyTarget)
    $resolvedBaseWithSep = $resolvedBase.TrimEnd("\") + "\"
    if (-not $resolvedLegacy.StartsWith($resolvedBaseWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove outside skills directory: $resolvedLegacy"
    }

    Remove-Item -LiteralPath $legacyTarget -Recurse -Force
    Write-Host "Removed legacy standalone oracle-consult install: $legacyTarget"
}
