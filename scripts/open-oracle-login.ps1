param(
    [ValidateSet("auto", "ko", "en", "ja")]
    [string]$Language = "auto",

    [switch]$Yes,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Resolve-Language {
    if ($Language -ne "auto") {
        return $Language
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
        "npx was not found. Install Node.js 24+ first." { return "npx が見つかりませんでした。先に Node.js 24+ をインストールしてください。" }
        "This step can open a visible Chrome window controlled by Oracle." { return "この手順では、Oracle が制御する表示状態の Chrome ウィンドウを開く場合があります。" }
        "ChatGPT sign-in is not automated. When the browser opens, sign in manually." { return "ChatGPT へのログインは自動化しません。ブラウザが開いたら手動でログインしてください。" }
        "It sends only a small non-secret temporary file and a short setup prompt." { return "送信するのは、秘密情報を含まない小さな一時ファイルと短いセットアップ用プロンプトだけです。" }
        "Continue? [y/N]" { return "続行しますか? [y/N]" }
        "Skipping Oracle browser setup." { return "Oracle ブラウザ設定をスキップします。" }
        "Starting Oracle browser setup. If Chrome opens, sign in to ChatGPT." { return "Oracle ブラウザ設定を開始します。Chrome が開いたら ChatGPT にログインしてください。" }
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

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw (Text "npx를 찾지 못했습니다. Node.js 24+를 먼저 설치하세요." "npx was not found. Install Node.js 24+ first.")
}

if (-not $Yes -and -not $DryRun) {
    Write-Host ""
    Say "이 단계는 Oracle이 제어하는 보이는 Chrome 창을 열 수 있습니다." "This step can open a visible Chrome window controlled by Oracle."
    Say "ChatGPT 로그인은 자동화하지 않습니다. 브라우저가 열리면 사용자가 직접 로그인해야 합니다." "ChatGPT sign-in is not automated. When the browser opens, sign in manually."
    Say "로그인 확인용으로 비밀이 없는 작은 임시 파일과 짧은 프롬프트만 보냅니다." "It sends only a small non-secret temporary file and a short setup prompt."
    $answer = Read-Host (Text "계속할까요? [y/N]" "Continue? [y/N]")
    if ($answer -notmatch "^(y|yes|예|네|ㅇ|ㅖ|はい|ハイ)$") {
        Say "Oracle 브라우저 열기를 건너뜁니다." "Skipping Oracle browser setup."
        exit 0
    }
}

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "oracle-consult-login-check.txt"
$tempText = @"
Oracle Consult login setup check.
This temporary file intentionally contains no project data or secrets.
"@
Set-Content -LiteralPath $tempFile -Encoding UTF8 -Value $tempText

$prompt = "Oracle Consult login/setup check. If this reaches ChatGPT, reply OK only."
$oracleArgs = @(
    "-y",
    "@steipete/oracle",
    "--engine",
    "browser",
    "--browser-manual-login",
    "--browser-keep-browser",
    "-p",
    $prompt,
    "--file",
    $tempFile
)

if ($DryRun) {
    $oracleArgs += @("--dry-run", "summary", "--files-report")
} else {
    Say "Oracle 브라우저 설정을 시작합니다. Chrome이 열리면 ChatGPT에 로그인하세요." "Starting Oracle browser setup. If Chrome opens, sign in to ChatGPT."
}

try {
    & npx @oracleArgs
} finally {
    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
}
