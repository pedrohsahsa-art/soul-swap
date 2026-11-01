param([string]$Version = '0.8.0', [int]$Port = 16510, [int]$Seconds = 75)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path (Join-Path $root 'build') | Out-Null
$play = Join-Path $root "play-v$Version"
$exe = Join-Path $play 'DELTARUNE_Local_PvP.exe'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class PvPLanCapture {
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
public struct RECT { public int Left,Top,Right,Bottom; }
}
'@
function Capture($p, $name) {
    $p.Refresh()
    if ($p.MainWindowHandle -eq 0) { return }
    $r = New-Object PvPLanCapture+RECT
    [PvPLanCapture]::GetWindowRect($p.MainWindowHandle,[ref]$r) | Out-Null
    $b = New-Object System.Drawing.Bitmap(($r.Right-$r.Left),($r.Bottom-$r.Top))
    $g = [System.Drawing.Graphics]::FromImage($b)
    try {
        $dc=$g.GetHdc()
        try { [PvPLanCapture]::PrintWindow($p.MainWindowHandle,$dc,2) | Out-Null }
        finally { $g.ReleaseHdc($dc) }
        $b.Save((Join-Path $root "build/lan-$Version-$name.png"))
    } finally { $g.Dispose(); $b.Dispose() }
}
$hostProcess=$null
$guestProcess=$null
$samples=@()
try {
    $hostProcess=Start-Process $exe -WorkingDirectory $play -ArgumentList '--lan-host',"$Port",'--lan-test' -PassThru
    $hostProcess.WaitForInputIdle(10000) | Out-Null
    Start-Sleep -Seconds 2
    $guestProcess=Start-Process $exe -WorkingDirectory $play -ArgumentList '--lan-join','127.0.0.1',"$Port",'--lan-test' -PassThru
    $guestProcess.WaitForInputIdle(10000) | Out-Null
    $deadline=[DateTime]::UtcNow.AddSeconds($Seconds)
    $passed=$false
    while ([DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Seconds 1
        $hostProcess.Refresh();$guestProcess.Refresh()
        if ($hostProcess.HasExited -or $guestProcess.HasExited) { throw 'Runner exited during LAN smoke' }
        $ht=$hostProcess.MainWindowTitle;$gt=$guestProcess.MainWindowTitle
        $samples+=@{host=$ht;guest=$gt}
        if ($ht -eq 'Code Error' -or $gt -eq 'Code Error') { throw 'Runner code error; inspect captures' }
        if ($ht -match '^LANQA host ticks=(\d+) swaps=(\d+) damage=(\d+) seq=(\d+) checks=(\d+)$') {
            $hostTicks=[int]$Matches[1];$hostSwaps=[int]$Matches[2];$hostDamage=[int]$Matches[3]
            if ($gt -match '^LANQA client ticks=(\d+) swaps=(\d+) damage=(\d+) seq=(\d+) checks=(\d+)$') {
                $guestTicks=[int]$Matches[1];$guestSwaps=[int]$Matches[2];$guestDamage=[int]$Matches[3]
                $checks=[int]$Matches[5]
                if ($hostTicks -ge 600 -and $hostSwaps -ge 2 -and $hostDamage -gt 0 -and
                    [Math]::Abs($hostTicks-$guestTicks) -le 10 -and $guestSwaps -ge 2 -and
                    [Math]::Abs($hostDamage-$guestDamage) -le 10 -and $checks -ge 300) { $passed=$true;break }
            }
        }
    }
    if (!$passed) { throw 'LAN did not synchronize combat, damage and both roles before timeout' }
    Capture $hostProcess 'host'
    Capture $guestProcess 'guest'
    # A crashed peer must be detected without relying on a client disconnect event.
    Stop-Process -Id $hostProcess.Id
    Start-Sleep -Seconds 7
    $guestProcess.Refresh()
    if ($guestProcess.MainWindowTitle -ne "DELTARUNE / SOUL SWAP / local PvP $Version") { throw 'Guest did not leave a dead session' }
    Capture $guestProcess 'disconnect'
    @{passed=$true;transport='Native GameMaker TCP over 127.0.0.1';port=$Port;samples=$samples;
      limits='Two processes on one PC with explicit synthetic input; not two physical LAN PCs or human latency validation.'} |
        ConvertTo-Json -Depth 6 | Set-Content (Join-Path $root 'build/lan-smoke.json')
    Write-Output "PASS real runner TCP: host ticks=$hostTicks guest ticks=$guestTicks swaps=$guestSwaps damage=$guestDamage; dead-host timeout passed"
} catch {
    if ($hostProcess -and !$hostProcess.HasExited) { Capture $hostProcess 'host-error' }
    if ($guestProcess -and !$guestProcess.HasExited) { Capture $guestProcess 'guest-error' }
    @{passed=$false;error=$_.Exception.Message;samples=$samples} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $root 'build/lan-smoke.json')
    throw
} finally {
    # Only processes launched by this script are closed.
    foreach ($p in @($hostProcess,$guestProcess)) { if ($p -and !$p.HasExited) { Stop-Process -Id $p.Id } }
}
