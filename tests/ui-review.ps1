param([string]$Version = '0.8.0', [switch]$Native, [string[]]$Scenarios = @('lobby','menu','combat','garden','pause','help','lan'))
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path (Join-Path $root 'build') | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class PvPUIReview {
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
public struct RECT { public int Left,Top,Right,Bottom; }
}
'@
$play = Join-Path $root "play-v$Version"
foreach ($scenario in $Scenarios) {
    $mode = if ($Native) { 'native' } else { 'scaled' }
    $p = Start-Process (Join-Path $play 'DELTARUNE_Local_PvP.exe') -WorkingDirectory $play -ArgumentList '--pvp-ui-check',$scenario,$mode -PassThru
    try {
        $p.WaitForInputIdle(10000) | Out-Null
        Start-Sleep -Seconds 3
        $p.Refresh()
        if ($p.MainWindowHandle -eq 0) { throw "No window for $scenario" }
        $r = New-Object PvPUIReview+RECT
        [PvPUIReview]::GetWindowRect($p.MainWindowHandle,[ref]$r) | Out-Null
        $b = New-Object System.Drawing.Bitmap(($r.Right-$r.Left),($r.Bottom-$r.Top))
        $g = [System.Drawing.Graphics]::FromImage($b)
        $dc = $g.GetHdc()
        $ok = [PvPUIReview]::PrintWindow($p.MainWindowHandle,$dc,2)
        $g.ReleaseHdc($dc)
        if (!$ok) { throw "Capture failed: $scenario" }
        $out = Join-Path $root "build/ui-$Version-$scenario-$mode.png"
        $b.Save($out)
        $g.Dispose()
        $b.Dispose()
        Write-Output $out
        if ($p.MainWindowTitle -ne "DELTARUNE / SOUL SWAP / local PvP $Version") {
            throw "Unexpected runner window '$($p.MainWindowTitle)' in $scenario; inspect $out"
        }
    } finally {
        # Only the preview process launched by this iteration is closed.
        if (!$p.HasExited) { Stop-Process -Id $p.Id }
    }
}
