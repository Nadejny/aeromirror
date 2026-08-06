param(
    [Parameter(Mandatory = $true)]
    [string]$UpstreamRoot,

    [Parameter(Mandatory = $true)]
    [string]$OriginalRuntime,

    [Parameter(Mandatory = $true)]
    [string]$HeadlessExecutable,

    [string]$MsysRoot = "C:\msys64"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$nativeRoot = $PSScriptRoot
$projectRoot = Split-Path -Parent $nativeRoot
$artifactRoot = Join-Path $projectRoot "artifacts"
$stage = Join-Path $artifactRoot "headless-runtime"
$prefix = Join-Path $MsysRoot "ucrt64"
$runtimeBin = Join-Path $prefix "bin"

function Assert-ChildPath([string]$Parent, [string]$Child) {
    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [System.IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe output path: $childFull is outside $parentFull"
    }
}

$upstream = (Resolve-Path -LiteralPath $UpstreamRoot).Path
$original = (Resolve-Path -LiteralPath $OriginalRuntime).Path
$headless = (Resolve-Path -LiteralPath $HeadlessExecutable).Path

$required = @(
    $headless,
    (Join-Path $original "uxplay-bluetooth-beacon.exe"),
    (Join-Path $original "Qt6Core.dll"),
    (Join-Path $original "dnssd.dll"),
    (Join-Path $original "mDNSResponder.exe"),
    (Join-Path $runtimeBin "windeployqt.exe"),
    (Join-Path $runtimeBin "python.exe"),
    (Join-Path $runtimeBin "objdump.exe")
)
$missing = $required | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missing) {
    throw "Missing build inputs:`n$($missing -join [Environment]::NewLine)"
}

$objdump = Join-Path $runtimeBin "objdump.exe"
$coreHeaders = (& $objdump -f $headless 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -or
    $coreHeaders -notmatch 'file format pei-x86-64' -or
    $coreHeaders -notmatch 'architecture:\s+i386:x86-64') {
    throw "The input headless core is not an x64 PE executable."
}
$coreImports = (& $objdump -p $headless 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the input headless core."
}
if ($coreImports -notmatch '\bqt_version_tag_6_10\b') {
    throw "The input headless core does not import qt_version_tag_6_10."
}
if ($coreImports -match '\bqt_version_tag_6_11\b') {
    throw "The input headless core imports incompatible qt_version_tag_6_11."
}
$runtimeQtVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo(
    (Join-Path $original "Qt6Core.dll")).FileVersion
if ($runtimeQtVersion -notmatch '^6\.10\.1(?:\.0)?$') {
    throw (
        "The pinned runtime must contain Qt6Core 6.10.1; found " +
        "'$runtimeQtVersion'.")
}

Assert-ChildPath -Parent $artifactRoot -Child $stage
if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $stage | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "resources") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "lib\gstreamer-1.0") | Out-Null

Copy-Item -LiteralPath $headless -Destination (Join-Path $stage "uxplay-windows.exe")
Copy-Item -LiteralPath (Join-Path $original "uxplay-bluetooth-beacon.exe") -Destination $stage
Copy-Item -LiteralPath (Join-Path $original "dnssd.dll") -Destination $stage
Copy-Item -LiteralPath (Join-Path $original "mDNSResponder.exe") -Destination $stage
Copy-Item -LiteralPath (Join-Path $original "LICENSE.rtf") -Destination $stage
Copy-Item -LiteralPath (Join-Path $upstream "stuff\newicon.ico") `
    -Destination (Join-Path $stage "resources\icon.ico")
Copy-Item -LiteralPath (Join-Path $upstream "stuff\uxplay_arguments_list.txt") `
    -Destination (Join-Path $stage "resources\uxplay_arguments_list.txt")
Copy-Item -LiteralPath (Join-Path $nativeRoot "gstreamer-features.txt") `
    -Destination (Join-Path $stage "resources\gstreamer-features.txt")

$env:MSYSTEM = "UCRT64"
$env:PATH = "$runtimeBin;$(Join-Path $MsysRoot 'usr\bin');$env:PATH"

& (Join-Path $runtimeBin "windeployqt.exe") `
    --release `
    --no-translations `
    --no-compiler-runtime `
    --dir $stage `
    (Join-Path $stage "uxplay-windows.exe")
if ($LASTEXITCODE -ne 0) {
    throw "windeployqt failed with exit code $LASTEXITCODE"
}

$pluginDir = Join-Path $prefix "lib\gstreamer-1.0"
$registry = Join-Path $artifactRoot "headless-build-registry.bin"
if (Test-Path -LiteralPath $registry) {
    Remove-Item -LiteralPath $registry -Force
}
$env:GST_PLUGIN_PATH = ""
$env:GST_PLUGIN_PATH_1_0 = ""
$env:GST_PLUGIN_SYSTEM_PATH = $pluginDir
$env:GST_PLUGIN_SYSTEM_PATH_1_0 = $pluginDir
$env:GST_REGISTRY_1_0 = $registry

& (Join-Path $runtimeBin "python.exe") `
    (Join-Path $upstream "scripts\resolve-gstreamer-plugins.py") `
    --features (Join-Path $nativeRoot "gstreamer-features.txt") `
    --plugin-dir $pluginDir `
    --destination (Join-Path $stage "lib\gstreamer-1.0") `
    --manifest (Join-Path $stage "resources\gstreamer-plugins.json")
if ($LASTEXITCODE -ne 0) {
    throw "GStreamer plugin resolution failed with exit code $LASTEXITCODE"
}

$scannerDestination = Join-Path $stage "libexec\gstreamer-1.0"
New-Item -ItemType Directory -Force -Path $scannerDestination | Out-Null
Copy-Item -LiteralPath (Join-Path $prefix "libexec\gstreamer-1.0\gst-plugin-scanner.exe") `
    -Destination $scannerDestination

$gioDestination = Join-Path $stage "lib\gio\modules"
New-Item -ItemType Directory -Force -Path $gioDestination | Out-Null
Get-ChildItem -LiteralPath (Join-Path $prefix "lib\gio\modules") -Filter "*.dll" -File |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $gioDestination
    }

Copy-Item -Path (Join-Path $prefix "etc\fonts") `
    -Destination (Join-Path $stage "etc") -Recurse -Force

$buildManifest = [ordered]@{
    generatedAtUtc = [DateTime]::UtcNow.ToString("o")
    architecture = "x64"
    shellMode = "headless"
    qtBuildVersion = "6.10.1"
    pinnedRuntimeRelease = "2.0.0.1736"
    coreRuntimeCompatibility = "uxplay-windows-2.0.0.1736"
    qtImportedVersionTag = "qt_version_tag_6_10"
    qtRejectedVersionTag = "qt_version_tag_6_11"
    loaderTest = "required-by-installer"
    headlessExecutableSha256 = (
        Get-FileHash -Algorithm SHA256 -LiteralPath (
            Join-Path $stage "uxplay-windows.exe")
    ).Hash.ToLowerInvariant()
    uxplayWindowsCommit = "8cf3424b438424bc99a89155bd29a789f48a43c0"
    libuxplayCommit = "437f37514257d9cb513ac7fbdee743b4da85852e"
    compiler = (& (Join-Path $runtimeBin "gcc.exe") --version |
        Select-Object -First 1)
    cmake = (& (Join-Path $runtimeBin "cmake.exe") --version |
        Select-Object -First 1)
    ninja = (& (Join-Path $runtimeBin "ninja.exe") --version |
        Select-Object -First 1)
}
$buildManifest | ConvertTo-Json |
    Set-Content -LiteralPath (Join-Path $stage "resources\build-manifest.json") -Encoding utf8

& (Join-Path $upstream "scripts\collect-runtime-dependencies.ps1") `
    -StageDir $stage `
    -MsysRoot $MsysRoot `
    -EnvironmentName "ucrt64" `
    -ManifestPath (Join-Path $stage "resources\bundle-files.json")

Write-Host "Headless runtime staged at $stage"
