@echo off
setlocal
node "%~dp0open-oracle-login.mjs" %*
exit /b %ERRORLEVEL%
