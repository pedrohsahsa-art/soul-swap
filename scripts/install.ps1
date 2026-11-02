# Windows PowerShell 5.1. Tester install uses no Python, Node, Git or .NET SDK.
[CmdletBinding()]
param([string]$GameDirectory, [string]$ToolArchive, [switch]$ValidateOnly, [switch]$Reinstall)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$work = $null
$lock = $null
$transcript = $false
$oldRoot = $env:DR_PVP_ROOT
$exitCode = 0

function FileHash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Find-Game {
    $candidates = @("${env:ProgramFiles(x86)}\Steam\steamapps\common\DELTARUNE")
    $steamRoots = @()
    foreach ($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $entry = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if ($entry) {
            if ($entry.SteamPath) { $steamRoots += $entry.SteamPath }
            if ($entry.InstallPath) { $steamRoots += $entry.InstallPath }
        }
    }
    foreach ($steam in $steamRoots) {
        $candidates += Join-Path $steam 'steamapps\common\DELTARUNE'
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($match in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) {
                $library = $match.Groups[1].Value.Replace('\\','\')
                $candidates += Join-Path $library 'steamapps\common\DELTARUNE'
            }
        }
    }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'chapter2_windows\data.win')) { return $candidate }
    }
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Selecione a pasta DELTARUNE da Steam (contem DELTARUNE.exe e chapter2_windows).'
    $dialog.ShowNewFolderButton = $false
    try {
        if ($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw 'Selecao cancelada.' }
        return $dialog.SelectedPath
    } finally { $dialog.Dispose() }
}
function Invoke-Cli([string[]]$Arguments) {
    & $script:cli @Arguments
    if ($LASTEXITCODE -ne 0) { throw "UndertaleModCli falhou (codigo $LASTEXITCODE)." }
}

try {
    if (![Environment]::Is64BitOperatingSystem) { throw 'Esta versao requer Windows 64 bits.' }
    $config = Get-Content -LiteralPath (Join-Path $root 'release\compatibility.json') -Raw | ConvertFrom-Json
    $rules = Get-Content -LiteralPath (Join-Path $root 'rules.json') -Raw | ConvertFrom-Json
    if ($rules.version -ne $config.game_version -or $rules.version -notmatch '^\d+\.\d+\.\d+$') { throw 'Versao do pacote inconsistente.' }
    if (!$GameDirectory) { $GameDirectory = Find-Game }
    $game = (Resolve-Path -LiteralPath $GameDirectory).Path.TrimEnd('\')
    $absoluteRoot = [IO.Path]::GetFullPath($root).TrimEnd('\')
    if ($absoluteRoot -eq $game -or $absoluteRoot.StartsWith($game + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Extraia o mod fora da pasta do DELTARUNE e tente novamente.'
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.logs'),(Join-Path $root '.cache') | Out-Null
    $lock = [IO.File]::Open((Join-Path $root '.cache\install.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $log = Join-Path $root ('.logs\install-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
    Start-Transcript -Path $log | Out-Null
    $transcript = $true
    Write-Host "SOUL / SWAP $($config.package_version) - instalacao local"
    Write-Host "Jogo: $game"
    Write-Host '[1/5] Conferindo compatibilidade dos quatro arquivos originais...'
    foreach ($file in $config.files.PSObject.Properties) {
        $path = Join-Path $game $file.Name
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Arquivo necessario ausente: $($file.Name)" }
        $actual = FileHash $path
        if ($actual -ne $file.Value) { throw "Jogo incompativel: $($file.Name). SHA256 encontrado: $actual. Esta release aceita apenas a build indicada no README." }
    }
    if ($ValidateOnly) {
        Write-Host 'Compatibilidade OK. Nenhum build criado.'
    } else {
        $play = Join-Path $root "play-v$($rules.version)"
        if ((Test-Path -LiteralPath $play) -and !$Reinstall) { throw 'Esta versao ja esta instalada. Abra Start_LAN.cmd, ou use Install.cmd -Reinstall para reinstalar.' }
        # All compilation happens in a fresh staging directory. Publish only verified output.
        $work = Join-Path $root ('.cache\install-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $work | Out-Null
        Write-Host '[2/5] Obtendo UndertaleModCli oficial e conferindo SHA256...'
        if ($ToolArchive) { $archive = (Resolve-Path -LiteralPath $ToolArchive).Path }
        else {
            $archive = Join-Path $root ('.cache\' + $config.tool.filename)
            if (!(Test-Path -LiteralPath $archive)) {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $download = Join-Path $work 'download.zip'
                Invoke-WebRequest -UseBasicParsing -Uri $config.tool.url -OutFile $download
                if ((FileHash $download) -ne $config.tool.sha256) { throw 'Checksum do download incorreto. Tente novamente.' }
                Move-Item -LiteralPath $download -Destination $archive
            }
        }
        if ((FileHash $archive) -ne $config.tool.sha256) { throw 'ZIP do UndertaleModCli nao corresponde a versao oficial esperada.' }
        $tool = Join-Path $work 'tool'
        Expand-Archive -LiteralPath $archive -DestinationPath $tool
        $executables = @(Get-ChildItem -LiteralPath $tool -Filter UndertaleModCli.exe -Recurse)
        if ($executables.Count -ne 1) { throw 'ZIP da ferramenta tem estrutura inesperada.' }
        $script:cli = $executables[0].FullName
        $project = Join-Path $work 'project'
        New-Item -ItemType Directory -Path $project,(Join-Path $project 'build'),(Join-Path $project 'assets') | Out-Null
        Copy-Item -LiteralPath (Join-Path $root 'gml') -Destination $project -Recurse
        foreach ($name in @('patch.csx','verify.csx','rules.json')) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $project }
        Copy-Item -LiteralPath (Join-Path $root 'assets\manifest.json') -Destination (Join-Path $project 'assets')
        $header = @('// Generated by the tester installer from rules.json.')
        foreach ($rule in $rules.PSObject.Properties) {
            $name = if ($rule.Name -eq 'version') { 'mod_version' } else { $rule.Name }
            $header += "$name = $($rule.Value | ConvertTo-Json -Compress);"
        }
        [IO.File]::WriteAllLines((Join-Path $project 'build\rules-header.gml'),$header,(New-Object Text.UTF8Encoding($false)))
        $env:DR_PVP_ROOT = $project
        $source = Join-Path $game 'chapter2_windows\data.win'
        $roundtrip = Join-Path $project 'build\roundtrip.win'
        Write-Host '[3/5] Verificando leitura/escrita do arquivo original...'
        Invoke-Cli @('load',$source,'--output',$roundtrip)
        if (!(Test-Path -LiteralPath $roundtrip) -or (FileHash $roundtrip) -ne $config.files.'chapter2_windows/data.win') { throw 'Round-trip nao corresponde ao original.' }
        $patched = Join-Path $project 'build\patched.win'
        Write-Host '[4/5] Compilando os ataques e a conexao LAN; reabrindo para verificar...'
        Invoke-Cli @('load',$source,'--scripts',(Join-Path $project 'patch.csx'),'--output',$patched)
        if (!(Test-Path -LiteralPath $patched)) { throw 'Compilador nao produziu um arquivo novo. Veja o log.' }
        Invoke-Cli @('load',$patched,'--scripts',(Join-Path $project 'verify.csx'))
        $verification = Join-Path $project 'build\verification.json'
        if (!(Test-Path -LiteralPath $verification)) { throw 'Verificador nao produziu relatorio novo.' }
        $verified = Get-Content -LiteralPath $verification -Raw | ConvertFrom-Json
        if (!$verified.archive_reopened -or $verified.code.Count -ne 6) { throw 'Arquivo compilado nao passou na verificacao.' }
        $staged = Join-Path $work 'ready'
        New-Item -ItemType Directory -Path $staged | Out-Null
        Copy-Item -LiteralPath $patched -Destination (Join-Path $staged 'data.win')
        Copy-Item -LiteralPath (Join-Path $game 'DELTARUNE.exe') -Destination (Join-Path $staged 'DELTARUNE_Local_PvP.exe')
        Copy-Item -LiteralPath (Join-Path $game 'chapter2_windows\audiogroup1.dat') -Destination $staged
        # Keep the runtime filename; use THE WORLD REVOLVING from Chapter 1.
        Copy-Item -LiteralPath (Join-Path $game 'mus\joker.ogg') -Destination (Join-Path $staged 'battle.ogg')
        [IO.File]::WriteAllText((Join-Path $staged 'options.ini'),"[Windows]`nSleepMargin=30`nUsex64=True`n")
        foreach ($file in $config.files.PSObject.Properties) {
            if ((FileHash (Join-Path $game $file.Name)) -ne $file.Value) { throw 'Arquivos do jogo mudaram durante a instalacao.' }
        }
        $installed = @{}
        foreach ($file in Get-ChildItem -LiteralPath $staged -File) { $installed[$file.Name] = FileHash $file.FullName }
        @{package=$config.package_version;game=$rules.version;installed_at=(Get-Date -Format o);files=$installed} |
            ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $staged 'installation.json') -Encoding UTF8
        Write-Host '[5/5] Publicando instalacao verificada...'
        $backup = $null
        if (Test-Path -LiteralPath $play) {
            $backup = "$play.previous-$([Guid]::NewGuid().ToString('N'))"
            Move-Item -LiteralPath $play -Destination $backup
        }
        try { Move-Item -LiteralPath $staged -Destination $play }
        catch {
            if ($backup -and !(Test-Path -LiteralPath $play)) { Move-Item -LiteralPath $backup -Destination $play }
            throw
        }
        Copy-Item -LiteralPath $verification -Destination (Join-Path $root '.logs\installation-verification.json') -Force
        Write-Host "PRONTO: $play"
        Write-Host 'Abra Start_LAN.cmd ou Start_Local_PvP.cmd. A pasta original do jogo foi preservada.'
        if ($backup) { Write-Host "Instalacao anterior preservada em: $backup" }
    }
} catch {
    Write-Host ('ERRO: ' + $_.Exception.Message) -ForegroundColor Red
    $exitCode = 1
} finally {
    $env:DR_PVP_ROOT = $oldRoot
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    if ($transcript) { Stop-Transcript | Out-Null }
    if ($lock) { $lock.Dispose() }
}
exit $exitCode
