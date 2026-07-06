param(
    [string]$SkillRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "claude\skills\oracle-consult-skill")
)

$ErrorActionPreference = "Stop"
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-ErrorMessage([string]$Message) {
    $errors.Add($Message) | Out-Null
}

function Add-WarningMessage([string]$Message) {
    $warnings.Add($Message) | Out-Null
}

$skillPath = Resolve-Path $SkillRoot
$skillFile = Join-Path $skillPath "SKILL.md"

if (-not (Test-Path $skillFile)) {
    Add-ErrorMessage "Missing SKILL.md"
} else {
    $skillText = Get-Content -LiteralPath $skillFile -Raw
    if ($skillText -notmatch "(?m)^---\s*\r?\nname:\s*oracle-consult-skill\r?\ndescription:\s*.+") {
        Add-ErrorMessage "SKILL.md frontmatter must include name: oracle-consult-skill and description."
    }
    if ($skillText -notmatch "(?m)^disable-model-invocation:\s*true\s*$") {
        Add-ErrorMessage "Claude skill must set disable-model-invocation: true."
    }
    if ($skillText -match "TODO|\[TODO\]") {
        Add-ErrorMessage "SKILL.md still contains TODO markers."
    }
    if ($skillText -match "C:\\Users\\|Moncaso|persona-forge|ROUT_LIFETIME|Monaka") {
        Add-ErrorMessage "SKILL.md contains local or product-specific paths/names."
    }
    if ($skillText -notmatch "--dry-run summary --files-report") {
        Add-ErrorMessage "SKILL.md must require dry-run file reporting before real consults."
    }
}

$npx = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npx) {
    Add-WarningMessage "npx was not found; Oracle smoke checks will not run."
}

$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $versionText = (& node -v).TrimStart("v")
    $major = [int]($versionText.Split(".")[0])
    if ($major -lt 24) {
        Add-WarningMessage "Node $versionText detected; Oracle recommends Node 24+."
    }
} else {
    Add-WarningMessage "node was not found; Oracle requires Node 24+."
}

foreach ($warning in $warnings) {
    Write-Warning $warning
}

if ($errors.Count -gt 0) {
    foreach ($err in $errors) {
        Write-Error $err
    }
    exit 1
}

Write-Host "Claude skill validation passed: $skillPath"
