@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1" %*
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Instalacao nao concluida. Veja a mensagem acima e a pasta .logs.
pause
exit /b %result%
