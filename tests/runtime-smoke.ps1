# Interactive Windows smoke test, targeting only the process this script launches.
# Uses real mouse/keyboard input; requires the test window to remain foreground.
param([string]$Version = '0.8.0', [int]$ExistingProcessId = 0)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path (Join-Path $root 'build') | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class PvPRuntime {
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);
[DllImport("user32.dll")] public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
public struct POINT {public int X,Y;}
public struct RECT {public int Left,Top,Right,Bottom;}
}
'@
[PvPRuntime]::SetProcessDPIAware() | Out-Null
$play = Join-Path $root "play-v$Version"
$exe = Join-Path $play 'DELTARUNE_Local_PvP.exe'
if ($ExistingProcessId -gt 0) {
    $p = Get-Process -Id $ExistingProcessId
    if ($p.Path -ne $exe) { throw 'Existing process is not the requested version' }
} else {
    $p = Start-Process $exe -WorkingDirectory $play -PassThru
    $p.WaitForInputIdle(10000) | Out-Null
    Start-Sleep -Seconds 3
}
$p.Refresh()
$h = $p.MainWindowHandle
if ($h -eq 0) { throw 'Runner did not create a window' }
$shell = New-Object -ComObject WScript.Shell
$shell.AppActivate($p.Id) | Out-Null
[PvPRuntime]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 300
$rect = New-Object PvPRuntime+RECT
[PvPRuntime]::GetClientRect($h,[ref]$rect) | Out-Null
function CheckFocus {
    if ([PvPRuntime]::GetForegroundWindow() -ne $h) { throw 'Foreground changed; smoke test stopped without sending more input' }
}
function PointAt($x,$y) {
    CheckFocus
    $pt = New-Object PvPRuntime+POINT
    $pt.X = [int]($x*$rect.Right/640)
    $pt.Y = [int]($y*$rect.Bottom/480)
    [PvPRuntime]::ClientToScreen($h,[ref]$pt) | Out-Null
    [PvPRuntime]::SetCursorPos($pt.X,$pt.Y) | Out-Null
}
function ClickAt($x,$y) {
    PointAt $x $y
    [PvPRuntime]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 100
    [PvPRuntime]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 120
}
function Tap($key) {
    CheckFocus
    [PvPRuntime]::keybd_event($key,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 100
    [PvPRuntime]::keybd_event($key,0,2,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 120
}
$clock = [Diagnostics.Stopwatch]::StartNew()
function Capture($name) {
    $wr = New-Object PvPRuntime+RECT
    [PvPRuntime]::GetWindowRect($h,[ref]$wr) | Out-Null
    $bitmap = New-Object System.Drawing.Bitmap(($wr.Right-$wr.Left),($wr.Bottom-$wr.Top))
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $dc = $graphics.GetHdc()
    [PvPRuntime]::PrintWindow($h,$dc,2) | Out-Null
    $graphics.ReleaseHdc($dc)
    $bitmap.Save((Join-Path $root "build/runtime-$Version-$name.png"))
    $graphics.Dispose()
    $bitmap.Dispose()
    Write-Output "$name at $($clock.Elapsed.TotalSeconds)s"
}
# New process starts in lobby. Resume is inert there if focus never paused it.
ClickAt 240 180
Capture 'lobby'
ClickAt 120 340
Tap 13
Capture 'selection'
ClickAt 360 195
ClickAt 400 330
Start-Sleep -Milliseconds 1600
Tap 114
Capture 'combat-start'
PointAt 240 260
[PvPRuntime]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 1000
[PvPRuntime]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
[PvPRuntime]::mouse_event(8,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 100
[PvPRuntime]::mouse_event(16,0,0,0,[UIntPtr]::Zero)
Capture 'mine-warning'
Start-Sleep -Milliseconds 1400
Capture 'mine-active'
ClickAt 430 20
Capture 'paused'
$p.Refresh()
$p | Select-Object Id, MainWindowTitle, Responding
