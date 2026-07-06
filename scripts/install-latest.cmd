@echo off
setlocal EnableExtensions

if "%~1"=="--help" goto :usage
if "%~1"=="-h" goto :usage

set "REPO_OWNER=%ORACLE_CONSULT_REPO_OWNER%"
if "%REPO_OWNER%"=="" set "REPO_OWNER=medraud94private"
set "REPO_NAME=%ORACLE_CONSULT_REPO_NAME%"
if "%REPO_NAME%"=="" set "REPO_NAME=oracle-consult-skill"
set "REF=%ORACLE_CONSULT_REF%"
if "%REF%"=="" set "REF=main"
set "CALLER_PWD=%CD%"
set "TMP_ROOT=%TEMP%\oracle-consult-latest-%RANDOM%-%RANDOM%"

where curl >nul 2>nul
if errorlevel 1 (
  echo curl is required for install-latest.cmd.
  exit /b 1
)
where tar >nul 2>nul
if errorlevel 1 (
  echo tar is required for install-latest.cmd.
  exit /b 1
)
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required because install.cmd runs install.mjs.
  exit /b 1
)

mkdir "%TMP_ROOT%" || exit /b 1
set "ARCHIVE=%TMP_ROOT%\source.zip"
set "URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/%REF%.zip"

echo Downloading Oracle Consult %REF% from %REPO_OWNER%/%REPO_NAME%...
curl -fsSL -o "%ARCHIVE%" "%URL%"
if errorlevel 1 goto :fail

tar -xf "%ARCHIVE%" -C "%TMP_ROOT%"
if errorlevel 1 goto :fail

set "SOURCE_DIR="
for /d %%D in ("%TMP_ROOT%\%REPO_NAME%-*") do set "SOURCE_DIR=%%~fD"
if "%SOURCE_DIR%"=="" (
  echo Downloaded archive did not contain the expected source directory.
  goto :fail
)
if not exist "%SOURCE_DIR%\install.cmd" (
  echo Downloaded archive did not contain install.cmd.
  goto :fail
)

if "%~1"=="" (
  echo Installing into default repo path: %CALLER_PWD%
  call "%SOURCE_DIR%\install.cmd" --language auto --preset all --scope repo --repo-path "%CALLER_PWD%" --force --no-prompt --no-open-oracle
) else (
  call :scan_args %*
  if "%SCOPE_USER%"=="1" (
    call "%SOURCE_DIR%\install.cmd" %*
  ) else if "%PRESET_ORACLE_LOGIN%"=="1" (
    call "%SOURCE_DIR%\install.cmd" %*
  ) else if "%HAS_REPO_PATH%"=="1" (
    call "%SOURCE_DIR%\install.cmd" %*
  ) else (
    echo Installing into default repo path: %CALLER_PWD%
    call "%SOURCE_DIR%\install.cmd" %* --repo-path "%CALLER_PWD%"
  )
)
set "STATUS=%ERRORLEVEL%"
rmdir /s /q "%TMP_ROOT%" >nul 2>nul
exit /b %STATUS%

:fail
set "STATUS=%ERRORLEVEL%"
if "%STATUS%"=="0" set "STATUS=1"
rmdir /s /q "%TMP_ROOT%" >nul 2>nul
exit /b %STATUS%

:usage
echo Install or update Oracle Consult from the latest GitHub archive, without git clone/pull.
echo.
echo Run from the repository where you want repo-scoped installation:
echo   curl -fsSLO https://raw.githubusercontent.com/medraud94private/oracle-consult-skill/main/scripts/install-latest.cmd
echo   install-latest.cmd
echo.
echo Default behavior with no arguments:
echo   --language auto --preset all --scope repo --repo-path "%%CD%%" --force --no-prompt --no-open-oracle
echo.
echo Installer language values: auto, ko, en, ja.
echo.
echo Oracle browser mode values: default, hidden, attach, visible, render.
echo.
echo Pass normal install.cmd arguments to override.
exit /b 0

:scan_args
set "HAS_REPO_PATH=0"
set "SCOPE_USER=0"
set "PRESET_ORACLE_LOGIN=0"
:scan_loop
if "%~1"=="" exit /b 0
if /I "%~1"=="--repo-path" set "HAS_REPO_PATH=1"
if /I "%~1"=="--scope" if /I "%~2"=="user" set "SCOPE_USER=1"
if /I "%~1"=="--preset" if /I "%~2"=="oracle-login" set "PRESET_ORACLE_LOGIN=1"
shift
goto :scan_loop
