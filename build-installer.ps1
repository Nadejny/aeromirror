param(
    [string]$PortableZip = "",
    [string]$Version = "0.10.0"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $projectRoot "installer\AirPlayReceiverSetup.cs"
$icon = Join-Path $projectRoot "assets\AirPlayReceiver.ico"
$manifest = Join-Path $projectRoot "app.manifest"
$outputFolder = Join-Path $projectRoot "artifacts\installer"
$output = Join-Path $outputFolder ("AeroMirror-Setup-" + $Version + ".exe")
$uninstaller = Join-Path $outputFolder "Uninstall.exe"
$compiler = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

function Get-PeMachine([string]$Path) {
    $stream = [IO.File]::Open(
        $Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        $reader = [IO.BinaryReader]::new($stream)
        if ($reader.ReadUInt16() -ne 0x5A4D) {
            throw "Not a PE executable: $Path"
        }
        $stream.Position = 0x3C
        $peOffset = $reader.ReadUInt32()
        $stream.Position = $peOffset
        if ($reader.ReadUInt32() -ne 0x00004550) {
            throw "Invalid PE signature: $Path"
        }
        return $reader.ReadUInt16()
    }
    finally {
        $stream.Dispose()
    }
}

if (-not $PortableZip) {
    $PortableZip = Join-Path $projectRoot (
        "artifacts\AeroMirror-review-payload-x64-" + $Version + ".zip")
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must use the numeric MAJOR.MINOR.PATCH format."
}
if (-not (Test-Path $compiler)) {
    $compiler = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}
if (-not (Test-Path $compiler)) {
    throw "The built-in .NET Framework C# compiler was not found."
}
if (-not (Test-Path $PortableZip)) {
    throw "Portable payload was not found: $PortableZip"
}
if (-not (Test-Path $icon)) {
    throw "Application icon was not found: $icon"
}
if (-not (Test-Path $manifest)) {
    throw "Application manifest was not found: $manifest"
}

New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null
$validationRoot = Join-Path $outputFolder (
    "payload-check-" + [Guid]::NewGuid().ToString("N"))
try {
    $allowedEntries = @(
        "AeroMirror/AeroMirror.exe",
        "AeroMirror/CHANGELOG.md",
        "AeroMirror/CONTRIBUTING.md",
        "AeroMirror/LICENSE",
        "AeroMirror/README.md",
        "AeroMirror/SECURITY.md",
        "AeroMirror/THIRD_PARTY_NOTICES.md",
        "AeroMirror/update-repository.txt",
        "AeroMirror/core/uxplay-windows.exe",
        "AeroMirror/core/resources/build-manifest.json",
        "AeroMirror/core/resources/runtime-delivery.json",
        "AeroMirror/docs/TROUBLESHOOTING.md"
    )
    $archive = [IO.Compression.ZipFile]::OpenRead(
        [IO.Path]::GetFullPath($PortableZip))
    try {
        $actualEntries = @(
            $archive.Entries | ForEach-Object {
                $_.FullName.Replace('\', '/').TrimEnd('/')
            }
        )
    }
    finally {
        $archive.Dispose()
    }
    $unexpected = @(Compare-Object `
        -ReferenceObject $allowedEntries `
        -DifferenceObject $actualEntries)
    if ($actualEntries.Count -ne $allowedEntries.Count -or
        $unexpected.Count -ne 0) {
        throw (
            "The installer accepts only the reviewed thin payload; " +
            "unexpected or missing archive entries were found.")
    }

    [IO.Compression.ZipFile]::ExtractToDirectory(
        [IO.Path]::GetFullPath($PortableZip), $validationRoot)
    $payloadShell = Join-Path $validationRoot "AeroMirror\AeroMirror.exe"
    $payloadCore = Join-Path $validationRoot "AeroMirror\core\uxplay-windows.exe"
    $payloadManifest = Join-Path $validationRoot (
        "AeroMirror\core\resources\build-manifest.json")
    $payloadDelivery = Join-Path $validationRoot (
        "AeroMirror\core\resources\runtime-delivery.json")
    if (-not (Test-Path -LiteralPath $payloadShell -PathType Leaf) -or
        -not (Test-Path -LiteralPath $payloadCore -PathType Leaf) -or
        -not (Test-Path -LiteralPath $payloadManifest -PathType Leaf) -or
        -not (Test-Path -LiteralPath $payloadDelivery -PathType Leaf)) {
        throw "Portable payload is incomplete or is not a reviewed headless package."
    }
    $payloadVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo(
        $payloadShell).FileVersion
    if (-not $payloadVersion.StartsWith($Version + ".")) {
        throw "Portable shell version $payloadVersion does not match $Version."
    }
    $payloadBuild = Get-Content -LiteralPath $payloadManifest `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($payloadBuild.shellMode -ne "headless" -or
        $payloadBuild.architecture -ne "x64" -or
        $payloadBuild.qtBuildVersion -ne "6.10.1" -or
        $payloadBuild.pinnedRuntimeRelease -ne "2.0.0.1736" -or
        $payloadBuild.coreRuntimeCompatibility -ne
            "uxplay-windows-2.0.0.1736") {
        throw "Portable payload does not identify a headless x64 core."
    }
    if ((Get-PeMachine $payloadShell) -ne 0x8664 -or
        (Get-PeMachine $payloadCore) -ne 0x8664) {
        throw "Portable payload contains a non-x64 executable."
    }
    $payloadCoreHash = (Get-FileHash -Algorithm SHA256 `
        -LiteralPath $payloadCore).Hash
    if (-not $payloadBuild.headlessExecutableSha256 -or
        $payloadCoreHash -ne $payloadBuild.headlessExecutableSha256) {
        throw "Portable core hash does not match its reviewed build manifest."
    }
    $payloadDeliveryData = Get-Content -LiteralPath $payloadDelivery `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($payloadDeliveryData.deliveryMode -ne "upstream-download" -or
        $payloadDeliveryData.url -notmatch '^https://' -or
        $payloadDeliveryData.sha256 -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Portable payload does not contain a valid pinned runtime delivery manifest."
    }
}
finally {
    if (Test-Path -LiteralPath $validationRoot) {
        Remove-Item -LiteralPath $validationRoot -Recurse -Force
    }
}

& $compiler /nologo /target:winexe /platform:x64 /optimize+ `
    /out:$uninstaller `
    /win32icon:$icon `
    /win32manifest:$manifest `
    /reference:System.dll `
    /reference:System.Core.dll `
    /reference:System.Drawing.dll `
    /reference:System.IO.Compression.dll `
    /reference:System.IO.Compression.FileSystem.dll `
    /reference:System.Web.Extensions.dll `
    /reference:System.Windows.Forms.dll `
    $source

if ($LASTEXITCODE -ne 0) {
    throw "Uninstaller compilation failed with exit code $LASTEXITCODE."
}

& $compiler /nologo /target:winexe /platform:x64 /optimize+ `
    /out:$output `
    /win32icon:$icon `
    /win32manifest:$manifest `
    "/resource:$PortableZip,AirPlayReceiverPayload" `
    "/resource:$uninstaller,AirPlayReceiverUninstaller" `
    /reference:System.dll `
    /reference:System.Core.dll `
    /reference:System.Drawing.dll `
    /reference:System.IO.Compression.dll `
    /reference:System.IO.Compression.FileSystem.dll `
    /reference:System.Web.Extensions.dll `
    /reference:System.Windows.Forms.dll `
    $source

if ($LASTEXITCODE -ne 0) {
    throw "Installer compilation failed with exit code $LASTEXITCODE."
}

Write-Host "Built $output"
