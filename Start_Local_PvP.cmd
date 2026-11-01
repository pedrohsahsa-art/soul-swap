@echo off
setlocal
if not exist "%~dp0play-v0.8.0\DELTARUNE_Local_PvP.exe" (
    echo Mod ainda nao instalado. Execute Install.cmd primeiro.
    pause
    exit /b 1
)
if not exist "%~dp0play-v0.8.0\data.win" (
    echo Arquivo do mod ausente. Execute Install.cmd -Reinstall.
    pause
    exit /b 1
)
pushd "%~dp0play-v0.8.0"
start "" "DELTARUNE_Local_PvP.exe"
popd
