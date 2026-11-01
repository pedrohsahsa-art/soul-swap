@echo off
setlocal
if not exist "%~dp0play-v0.8.0\data.win" (
    echo Mod ainda nao instalado. Execute Install.cmd primeiro.
    pause
    exit /b 1
)
if not exist "%~dp0play-v0.8.0\DELTARUNE_Local_PvP.exe" (
    echo Executavel ausente. Execute Install.cmd -Reinstall.
    pause
    exit /b 1
)
echo IPv4 deste computador - informe o endereco da sua rede ao outro jogador:
powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254.*' } | Select-Object InterfaceAlias,IPAddress | Format-Table -AutoSize"
pushd "%~dp0play-v0.8.0"
start "" "DELTARUNE_Local_PvP.exe" --lan
popd
echo No jogo, escolha HOSPEDAR ou CONECTAR. Porta padrao: 6510 TCP.
pause
