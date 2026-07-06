param(
    [ValidateSet("auto", "ko", "en")]
    [string]$Language = "auto",

    [ValidateSet("interactive", "all", "codex", "claude", "skills", "plugins", "codex-skill", "codex-plugin", "claude-skill", "claude-plugin", "oracle-login")]
    [string]$Preset = "interactive",

    [switch]$Force,
    [switch]$OpenOracle,
    [switch]$NoOpenOracle,
    [switch]$NoPrompt
)

$ErrorActionPreference = "Stop"

if ($OpenOracle -and $NoOpenOracle) {
    throw "Use either -OpenOracle or -NoOpenOracle, not both."
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:InstallForce = [bool]$Force

function Resolve-Language {
    if ($Language -ne "auto") {
        return $Language
    }

    if (-not $NoPrompt) {
        Write-Host ""
        Write-Host "Choose language / 언어를 선택하세요"
        Write-Host "  [1] 한국어"
        Write-Host "  [2] English"
        $choice = Read-Host "1/2 (default: 1)"
        if ($choice -eq "2") {
            return "en"
        }
        return "ko"
    }

    if ([System.Globalization.CultureInfo]::CurrentUICulture.Name -like "ko*") {
        return "ko"
    }
    return "en"
}

$script:Lang = Resolve-Language

function Text([string]$Ko, [string]$En) {
    if ($script:Lang -eq "ko") {
        return $Ko
    }
    return $En
}

function Say([string]$Ko, [string]$En) {
    Write-Host (Text $Ko $En)
}

function Ask-YesNo([string]$Ko, [string]$En, [bool]$DefaultYes = $false) {
    if ($NoPrompt) {
        return $DefaultYes
    }

    $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $answer = Read-Host ("{0} {1}" -f (Text $Ko $En), $suffix)
    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $DefaultYes
    }
    return $answer -match "^(y|yes|예|네|ㅇ|ㅖ)$"
}

function Select-Preset {
    if ($Preset -ne "interactive") {
        return $Preset
    }

    if ($NoPrompt) {
        return "all"
    }

    Write-Host ""
    Say "설치할 대상을 선택하세요." "Choose what to install."
    Say "  [1] 추천: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin" "  [1] Recommended: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin"
    Say "  [2] Codex만: skill + plugin" "  [2] Codex only: skill + plugin"
    Say "  [3] Claude Code만: skill + plugin" "  [3] Claude Code only: skill + plugin"
    Say "  [4] skill만: Codex skill + Claude Code skill" "  [4] Skills only: Codex skill + Claude Code skill"
    Say "  [5] plugin만: Codex plugin + Claude Code plugin" "  [5] Plugins only: Codex plugin + Claude Code plugin"
    Say "  [6] Oracle 브라우저 로그인만 열기" "  [6] Open Oracle browser login only"
    Say "  [7] 취소" "  [7] Cancel"
    $choice = Read-Host "1-7 (default: 1)"

    switch ($choice) {
        "2" { return "codex" }
        "3" { return "claude" }
        "4" { return "skills" }
        "5" { return "plugins" }
        "6" { return "oracle-login" }
        "7" { return "cancel" }
        default { return "all" }
    }
}

function Invoke-InstallScript([string]$ScriptName, [string]$KoName, [string]$EnName) {
    $scriptPath = Join-Path $repoRoot ("scripts\{0}" -f $ScriptName)
    if (-not (Test-Path $scriptPath)) {
        throw "Missing script: $scriptPath"
    }

    Write-Host ""
    Say ("[단계] {0}" -f $KoName) ("[Step] {0}" -f $EnName)

    $scriptParams = @{}
    if ($script:InstallForce) {
        $scriptParams.Force = $true
    }
    & $scriptPath @scriptParams
}

function Invoke-OracleLogin {
    $scriptPath = Join-Path $repoRoot "scripts\open-oracle-login.ps1"
    if (-not (Test-Path $scriptPath)) {
        throw "Missing script: $scriptPath"
    }

    Write-Host ""
    Say "[단계] Oracle 브라우저 로그인 열기" "[Step] Open Oracle browser login"
    & $scriptPath -Language $script:Lang -Yes
}

$selectedPreset = Select-Preset
if ($selectedPreset -eq "cancel") {
    Say "취소했습니다." "Canceled."
    exit 0
}

Say "Oracle Consult 설치를 시작합니다." "Starting Oracle Consult setup."

switch ($selectedPreset) {
    "all" {
        Invoke-InstallScript "install-user.ps1" "Codex skill 설치" "Install Codex skill"
        Invoke-InstallScript "install-codex-plugin-user.ps1" "Codex plugin 등록" "Register Codex plugin"
        Invoke-InstallScript "install-claude-user.ps1" "Claude Code skill 설치" "Install Claude Code skill"
        Invoke-InstallScript "install-claude-plugin-user.ps1" "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "codex" {
        Invoke-InstallScript "install-user.ps1" "Codex skill 설치" "Install Codex skill"
        Invoke-InstallScript "install-codex-plugin-user.ps1" "Codex plugin 등록" "Register Codex plugin"
    }
    "claude" {
        Invoke-InstallScript "install-claude-user.ps1" "Claude Code skill 설치" "Install Claude Code skill"
        Invoke-InstallScript "install-claude-plugin-user.ps1" "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "skills" {
        Invoke-InstallScript "install-user.ps1" "Codex skill 설치" "Install Codex skill"
        Invoke-InstallScript "install-claude-user.ps1" "Claude Code skill 설치" "Install Claude Code skill"
    }
    "plugins" {
        Invoke-InstallScript "install-codex-plugin-user.ps1" "Codex plugin 등록" "Register Codex plugin"
        Invoke-InstallScript "install-claude-plugin-user.ps1" "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "codex-skill" {
        Invoke-InstallScript "install-user.ps1" "Codex skill 설치" "Install Codex skill"
    }
    "codex-plugin" {
        Invoke-InstallScript "install-codex-plugin-user.ps1" "Codex plugin 등록" "Register Codex plugin"
    }
    "claude-skill" {
        Invoke-InstallScript "install-claude-user.ps1" "Claude Code skill 설치" "Install Claude Code skill"
    }
    "claude-plugin" {
        Invoke-InstallScript "install-claude-plugin-user.ps1" "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "oracle-login" {
        if (-not $NoOpenOracle) {
            $OpenOracle = $true
        }
    }
}

if ($OpenOracle) {
    Invoke-OracleLogin
} elseif (-not $NoOpenOracle) {
    $shouldOpenOracle = Ask-YesNo `
        "Oracle 전용 Chrome을 열어 ChatGPT 로그인 단계까지 진행할까요? 로그인은 직접 해야 합니다." `
        "Open Oracle's Chrome profile for ChatGPT login setup? You still sign in manually." `
        $false
    if ($shouldOpenOracle) {
        Invoke-OracleLogin
    }
}

Write-Host ""
Say "설치가 끝났습니다." "Setup complete."
Say "Codex: 새 thread에서 `$oracle-consult 를 명시적으로 호출하세요. Codex plugin은 /plugins에서 Oracle Consult를 설치한 뒤 새 thread를 여세요." "Codex: in a new thread, explicitly invoke `$oracle-consult. For the Codex plugin, install Oracle Consult from /plugins, then open a new thread."
Say "Claude Code skill: /oracle-consult 로 호출합니다." "Claude Code skill: invoke /oracle-consult."
Say "Claude Code plugin: /oracle-consult:oracle-consult 로 호출합니다." "Claude Code plugin: invoke /oracle-consult:oracle-consult."
