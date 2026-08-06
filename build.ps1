param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $projectRoot "src\AirPlayReceiverMvp.cs"
$icon = Join-Path $projectRoot "assets\AirPlayReceiver.ico"
$logo = Join-Path $projectRoot "assets\logo.png"
$manifest = Join-Path $projectRoot "app.manifest"
$outputFolder = Join-Path $projectRoot "artifacts\$Configuration"
$output = Join-Path $outputFolder "AeroMirror.exe"
$compiler = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if (-not (Test-Path $compiler)) {
    $compiler = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}
if (-not (Test-Path $compiler)) {
    throw "The built-in .NET Framework C# compiler was not found."
}
if (-not (Test-Path $icon)) {
    throw "Application icon was not found: $icon"
}
if (-not (Test-Path $logo)) {
    throw "Application logo was not found: $logo"
}
if (-not (Test-Path $manifest)) {
    throw "Application manifest was not found: $manifest"
}

New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null

& $compiler /nologo /target:winexe /platform:x64 /optimize+ `
    /out:$output `
    /win32icon:$icon `
    /win32manifest:$manifest `
    "/resource:$logo,AeroMirrorLogo" `
    /reference:System.dll `
    /reference:System.Core.dll `
    /reference:System.Drawing.dll `
    /reference:System.ServiceProcess.dll `
    /reference:System.Web.Extensions.dll `
    /reference:System.Windows.Forms.dll `
    $source

if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE."
}

Write-Host "Built $output"
