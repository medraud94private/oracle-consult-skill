param(
    [ValidateSet("auto", "ko", "en", "ja")]
    [string]$Language = "auto",

    [ValidateSet("interactive", "all", "codex", "claude", "skills", "plugins", "codex-skill", "codex-plugin", "claude-skill", "claude-plugin", "oracle-login")]
    [string]$Preset = "interactive",

    [ValidateSet("interactive", "repo", "user")]
    [string]$Scope = "interactive",

    [string]$RepoPath = (Get-Location).Path,

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
$script:InstallScope = $null
$script:TargetRepoPath = $null

function Resolve-Language {
    if ($Language -ne "auto") {
        return $Language
    }

    if (-not $NoPrompt) {
        Write-Host ""
        Write-Host "Choose language / 언어를 선택하세요"
        Write-Host "  [1] 한국어"
        Write-Host "  [2] English"
        Write-Host "  [3] 日本語"
        $choice = Read-Host "1/2/3 (default: 1)"
        if ($choice -eq "2") {
            return "en"
        }
        if ($choice -eq "3") {
            return "ja"
        }
        return "ko"
    }

    if ([System.Globalization.CultureInfo]::CurrentUICulture.Name -like "ko*") {
        return "ko"
    }
    if ([System.Globalization.CultureInfo]::CurrentUICulture.Name -like "ja*") {
        return "ja"
    }
    return "en"
}

$script:Lang = Resolve-Language

function Get-JaText([string]$En) {
    switch -Exact ($En) {
        "Choose what to install." { return "インストールする内容を選択してください。" }
        "  [1] Recommended: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin" { return "  [1] 推奨: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin" }
        "  [2] Codex only: skill + plugin" { return "  [2] Codex のみ: skill + plugin" }
        "  [3] Claude Code only: skill + plugin" { return "  [3] Claude Code のみ: skill + plugin" }
        "  [4] Skills only: Codex skill + Claude Code skill" { return "  [4] Skills のみ: Codex skill + Claude Code skill" }
        "  [5] Plugins only: Codex plugin + Claude Code plugin" { return "  [5] Plugins のみ: Codex plugin + Claude Code plugin" }
        "  [6] Open Oracle browser login only" { return "  [6] Oracle ブラウザログインだけを開く" }
        "  [7] Cancel" { return "  [7] キャンセル" }
        "Choose install scope. Repository-level install is recommended." { return "インストール範囲を選択してください。リポジトリ単位のインストールを推奨します。" }
        "  [1] Recommended: install only into the current/target repository" { return "  [1] 推奨: 現在または指定したリポジトリにのみインストール" }
        "  [2] Install globally for this user" { return "  [2] このユーザー全体にインストール" }
        "Enter the target repository path." { return "対象リポジトリのパスを入力してください。" }
        "Prefer the actual work repository, not necessarily this installer repository." { return "installer repo ではなく、実際に作業する repo を指定することを推奨します。" }
        "Canceled." { return "キャンセルしました。" }
        "Starting Oracle Consult setup." { return "Oracle Consult のセットアップを開始します。" }
        "Install scope: global user" { return "インストール範囲: ユーザー全体" }
        "Open Oracle's Chrome profile for ChatGPT login setup? You still sign in manually." { return "Oracle 専用の Chrome プロファイルを開いて ChatGPT ログイン設定に進みますか? ログインは手動です。" }
        "Setup complete." { return "セットアップが完了しました。" }
        "Only Oracle browser login setup was run." { return "Oracle ブラウザログインの準備だけを実行しました。" }
        "Open a new Codex/Claude Code session from that repository root." { return "そのリポジトリルートから Codex/Claude Code を新しく開いて使ってください。" }
        "It is available across repositories, but already-open sessions may need a new thread or restart." { return "他のリポジトリでも利用できますが、既に開いているセッションは新しいスレッドまたは再起動が必要な場合があります。" }
        "Codex skill: explicitly invoke `$oracle-consult-skill." { return "Codex skill: `$oracle-consult-skill を明示的に呼び出します。" }
        "Codex plugin: install Oracle Consult from /plugins, then invoke `$oracle-consult in a new thread." { return "Codex plugin: /plugins から Oracle Consult をインストールし、新しい thread で `$oracle-consult を呼び出します。" }
        "Claude Code skill: invoke /oracle-consult-skill." { return "Claude Code skill: /oracle-consult-skill で呼び出します。" }
        "Claude Code plugin: invoke /oracle-consult:oracle-consult." { return "Claude Code plugin: /oracle-consult:oracle-consult で呼び出します。" }
        default { return $En }
    }
}

function Text([string]$Ko, [string]$En, [string]$Ja = $null) {
    if ($script:Lang -eq "ko") {
        return $Ko
    }
    if ($script:Lang -eq "ja") {
        if (-not [string]::IsNullOrEmpty($Ja)) {
            return $Ja
        }
        return (Get-JaText $En)
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
    if ($answer -match "^(y|yes|はい|ハイ)$") {
        return $true
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

function Select-Scope {
    if ($Scope -ne "interactive") {
        return $Scope
    }

    if ($NoPrompt) {
        return "repo"
    }

    Write-Host ""
    Say "설치 범위를 선택하세요. 추천은 리포지터리별 설치입니다." "Choose install scope. Repository-level install is recommended."
    Say "  [1] 추천: 현재/지정 리포지터리에만 설치" "  [1] Recommended: install only into the current/target repository"
    Say "  [2] 사용자 전체에 설치" "  [2] Install globally for this user"
    $choice = Read-Host "1/2 (default: 1)"
    if ($choice -eq "2") {
        return "user"
    }
    return "repo"
}

function Resolve-TargetRepoPath {
    if ($script:InstallScope -ne "repo") {
        return $null
    }

    $path = $RepoPath
    if (-not $NoPrompt) {
        Write-Host ""
        Say "설치할 대상 리포지터리 경로를 입력하세요." "Enter the target repository path."
        Say ("기본값: {0}" -f $RepoPath) ("Default: {0}" -f $RepoPath)
        Say "이 installer repo가 아니라 실제 작업 repo를 넣는 것을 권장합니다." "Prefer the actual work repository, not necessarily this installer repository."
        $inputPath = Read-Host "Repo path"
        if (-not [string]::IsNullOrWhiteSpace($inputPath)) {
            $path = $inputPath
        }
    }

    if (-not (Test-Path $path)) {
        throw "Repository path not found: $path"
    }
    return (Resolve-Path $path).Path
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
    if ($script:InstallScope -eq "repo") {
        $scriptParams.RepoPath = $script:TargetRepoPath
    }
    & $scriptPath @scriptParams
}

function Install-ScriptName([string]$Kind) {
    $userScripts = @{
        "codex-skill" = "install-user.ps1"
        "codex-plugin" = "install-codex-plugin-user.ps1"
        "claude-skill" = "install-claude-user.ps1"
        "claude-plugin" = "install-claude-plugin-user.ps1"
    }
    $repoScripts = @{
        "codex-skill" = "install-repo.ps1"
        "codex-plugin" = "install-codex-plugin-repo.ps1"
        "claude-skill" = "install-claude-repo.ps1"
        "claude-plugin" = "install-claude-plugin-repo.ps1"
    }

    if ($script:InstallScope -eq "repo") {
        return $repoScripts[$Kind]
    }
    return $userScripts[$Kind]
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

$script:InstallScope = "user"
if ($selectedPreset -ne "oracle-login") {
    $script:InstallScope = Select-Scope
    $script:TargetRepoPath = Resolve-TargetRepoPath
}

Say "Oracle Consult 설치를 시작합니다." "Starting Oracle Consult setup."
if ($selectedPreset -ne "oracle-login") {
    if ($script:InstallScope -eq "repo") {
        Say ("설치 범위: 리포지터리별 ({0})" -f $script:TargetRepoPath) ("Install scope: repository-level ({0})" -f $script:TargetRepoPath)
    } else {
        Say "설치 범위: 사용자 전체" "Install scope: global user"
    }
}

switch ($selectedPreset) {
    "all" {
        Invoke-InstallScript (Install-ScriptName "codex-skill") "Codex skill 설치" "Install Codex skill"
        Invoke-InstallScript (Install-ScriptName "codex-plugin") "Codex plugin 등록" "Register Codex plugin"
        Invoke-InstallScript (Install-ScriptName "claude-skill") "Claude Code skill 설치" "Install Claude Code skill"
        Invoke-InstallScript (Install-ScriptName "claude-plugin") "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "codex" {
        Invoke-InstallScript (Install-ScriptName "codex-skill") "Codex skill 설치" "Install Codex skill"
        Invoke-InstallScript (Install-ScriptName "codex-plugin") "Codex plugin 등록" "Register Codex plugin"
    }
    "claude" {
        Invoke-InstallScript (Install-ScriptName "claude-skill") "Claude Code skill 설치" "Install Claude Code skill"
        Invoke-InstallScript (Install-ScriptName "claude-plugin") "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "skills" {
        Invoke-InstallScript (Install-ScriptName "codex-skill") "Codex skill 설치" "Install Codex skill"
        Invoke-InstallScript (Install-ScriptName "claude-skill") "Claude Code skill 설치" "Install Claude Code skill"
    }
    "plugins" {
        Invoke-InstallScript (Install-ScriptName "codex-plugin") "Codex plugin 등록" "Register Codex plugin"
        Invoke-InstallScript (Install-ScriptName "claude-plugin") "Claude Code plugin 설치" "Install Claude Code plugin"
    }
    "codex-skill" {
        Invoke-InstallScript (Install-ScriptName "codex-skill") "Codex skill 설치" "Install Codex skill"
    }
    "codex-plugin" {
        Invoke-InstallScript (Install-ScriptName "codex-plugin") "Codex plugin 등록" "Register Codex plugin"
    }
    "claude-skill" {
        Invoke-InstallScript (Install-ScriptName "claude-skill") "Claude Code skill 설치" "Install Claude Code skill"
    }
    "claude-plugin" {
        Invoke-InstallScript (Install-ScriptName "claude-plugin") "Claude Code plugin 설치" "Install Claude Code plugin"
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
if ($selectedPreset -eq "oracle-login") {
    Say "Oracle 브라우저 로그인 준비만 실행했습니다." "Only Oracle browser login setup was run."
} elseif ($script:InstallScope -eq "repo") {
    Say "해당 리포지터리 루트에서 Codex/Claude Code를 새로 열어 사용하세요." "Open a new Codex/Claude Code session from that repository root."
} else {
    Say "다른 리포지터리에서도 보이지만, 이미 열린 세션은 새로 열거나 재시작해야 할 수 있습니다." "It is available across repositories, but already-open sessions may need a new thread or restart."
}
if ($selectedPreset -ne "oracle-login") {
    if (@("all", "codex", "skills", "codex-skill") -contains $selectedPreset) {
        Say "Codex skill: `$oracle-consult-skill 를 명시적으로 호출합니다." "Codex skill: explicitly invoke `$oracle-consult-skill."
    }
    if (@("all", "codex", "plugins", "codex-plugin") -contains $selectedPreset) {
        Say "Codex plugin: /plugins에서 Oracle Consult를 설치한 뒤 새 thread에서 `$oracle-consult 를 호출합니다." "Codex plugin: install Oracle Consult from /plugins, then invoke `$oracle-consult in a new thread."
    }
    if (@("all", "claude", "skills", "claude-skill") -contains $selectedPreset) {
        Say "Claude Code skill: /oracle-consult-skill 로 호출합니다." "Claude Code skill: invoke /oracle-consult-skill."
    }
    if (@("all", "claude", "plugins", "claude-plugin") -contains $selectedPreset) {
        Say "Claude Code plugin: /oracle-consult:oracle-consult 로 호출합니다." "Claude Code plugin: invoke /oracle-consult:oracle-consult."
    }
}
