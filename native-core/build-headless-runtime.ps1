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
$provenancePath = Join-Path $nativeRoot "source-provenance.json"
$uxplayPatch = Join-Path $nativeRoot "uxplay-windows-headless.patch"
$libuxplayPatch = Join-Path $nativeRoot "libuxplay-aeromirror.patch"
$dnssdDefinition = Join-Path $nativeRoot "dnssd.def"

function Assert-ChildPath([string]$Parent, [string]$Child) {
    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [System.IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe output path: $childFull is outside $parentFull"
    }
}

function Get-Sha256Lower([string]$Path) {
    return (
        Get-FileHash -Algorithm SHA256 -LiteralPath $Path
    ).Hash.ToLowerInvariant()
}

function Assert-FileHash(
    [string]$Path,
    [string]$Expected,
    [string]$Description
) {
    $actual = Get-Sha256Lower -Path $Path
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw (
            "$Description does not match source-provenance.json. " +
            "Expected $Expected, found $actual.")
    }
}

$upstream = (Resolve-Path -LiteralPath $UpstreamRoot).Path
$original = (Resolve-Path -LiteralPath $OriginalRuntime).Path
$headless = (Resolve-Path -LiteralPath $HeadlessExecutable).Path
$libuxplay = Join-Path $upstream "libuxplay"
$bonjourHeader = Join-Path $upstream "Bonjour SDK\Include\dns_sd.h"

$required = @(
    $headless,
    $provenancePath,
    $uxplayPatch,
    $libuxplayPatch,
    $dnssdDefinition,
    $bonjourHeader,
    (Join-Path $original "uxplay-bluetooth-beacon.exe"),
    (Join-Path $original "Qt6Core.dll"),
    (Join-Path $original "dnssd.dll"),
    (Join-Path $original "mDNSResponder.exe"),
    (Join-Path $original "LICENSE.rtf"),
    (Join-Path $runtimeBin "windeployqt.exe"),
    (Join-Path $runtimeBin "python.exe"),
    (Join-Path $runtimeBin "objdump.exe")
)
$missing = $required | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missing) {
    throw "Missing build inputs:`n$($missing -join [Environment]::NewLine)"
}

$provenance = Get-Content -LiteralPath $provenancePath -Raw -Encoding UTF8 |
    ConvertFrom-Json
if ($provenance.schemaVersion -ne 1 -or
    $provenance.uxplayWindowsCommit -notmatch '^[0-9a-f]{40}$' -or
    $provenance.libuxplayCommit -notmatch '^[0-9a-f]{40}$' -or
    $provenance.uxplayWindowsPatchSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.libuxplayPatchSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.headlessExecutableSha256 -notmatch '^[0-9a-f]{64}$') {
    throw "source-provenance.json is missing required pinned values."
}
$provenanceHash = Get-Sha256Lower -Path $provenancePath

Assert-FileHash -Path $uxplayPatch `
    -Expected $provenance.uxplayWindowsPatchSha256 `
    -Description "uxplay-windows patch"
Assert-FileHash -Path $libuxplayPatch `
    -Expected $provenance.libuxplayPatchSha256 `
    -Description "libuxplay patch"
Assert-FileHash -Path $headless `
    -Expected $provenance.headlessExecutableSha256 `
    -Description "Headless executable"
Assert-FileHash -Path $bonjourHeader `
    -Expected $provenance.buildInputs.'dns_sd.h' `
    -Description "Bonjour interface header"
Assert-FileHash -Path $dnssdDefinition `
    -Expected $provenance.buildInputs.'dnssd.def' `
    -Description "Bonjour import definition"

foreach ($sourceProperty in $provenance.patchedSources.PSObject.Properties) {
    $sourcePath = Join-Path $upstream (
        $sourceProperty.Name.Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Pinned patched source is missing: $sourcePath"
    }
    Assert-FileHash -Path $sourcePath `
        -Expected ([string]$sourceProperty.Value) `
        -Description ("Patched source " + $sourceProperty.Name)
}

$upstreamHasGit = Test-Path -LiteralPath (Join-Path $upstream ".git")
$libuxplayHasGit = Test-Path -LiteralPath (Join-Path $libuxplay ".git")
if ($upstreamHasGit -ne $libuxplayHasGit) {
    throw "Prepared source must contain either both Git repositories or neither."
}
if ($upstreamHasGit) {
    $upstreamCommit = (
        & git -c ("safe.directory=" + $upstream) -C $upstream rev-parse HEAD
    ).Trim()
    if ($LASTEXITCODE -ne 0 -or
        $upstreamCommit -ne $provenance.uxplayWindowsCommit) {
        throw "uxplay-windows commit does not match source-provenance.json."
    }
    $libuxplayCommit = (
        & git -c ("safe.directory=" + $libuxplay) -C $libuxplay rev-parse HEAD
    ).Trim()
    if ($LASTEXITCODE -ne 0 -or
        $libuxplayCommit -ne $provenance.libuxplayCommit) {
        throw "libuxplay commit does not match source-provenance.json."
    }
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
if ($runtimeQtVersion -notmatch (
        '^' + [Regex]::Escape($provenance.qtBuildVersion) + '(?:\.0)?$')) {
    throw (
        "The pinned runtime must contain Qt6Core " +
        "$($provenance.qtBuildVersion); found " +
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
Copy-Item -LiteralPath $provenancePath `
    -Destination (Join-Path $stage "resources\source-provenance.json")

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
    qtBuildVersion = [string]$provenance.qtBuildVersion
    pinnedRuntimeRelease = [string]$provenance.pinnedRuntimeRelease
    coreRuntimeCompatibility = [string]$provenance.coreRuntimeCompatibility
    qtImportedVersionTag = "qt_version_tag_6_10"
    qtRejectedVersionTag = "qt_version_tag_6_11"
    loaderTest = "required-by-installer"
    headlessExecutableSha256 = Get-Sha256Lower -Path (
        Join-Path $stage "uxplay-windows.exe")
    sourceProvenanceSha256 = $provenanceHash
    provenanceSchemaVersion = [int]$provenance.schemaVersion
    uxplayWindowsCommit = [string]$provenance.uxplayWindowsCommit
    libuxplayCommit = [string]$provenance.libuxplayCommit
    uxplayWindowsPatchSha256 = [string]$provenance.uxplayWindowsPatchSha256
    libuxplayPatchSha256 = [string]$provenance.libuxplayPatchSha256
    patchedSources = $provenance.patchedSources
    buildInputs = $provenance.buildInputs
    compiler = (& (Join-Path $runtimeBin "gcc.exe") --version |
        Select-Object -First 1)
    cmake = (& (Join-Path $runtimeBin "cmake.exe") --version |
        Select-Object -First 1)
    ninja = (& (Join-Path $runtimeBin "ninja.exe") --version |
        Select-Object -First 1)
}
$buildManifest | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath (Join-Path $stage "resources\build-manifest.json") -Encoding utf8

& (Join-Path $upstream "scripts\collect-runtime-dependencies.ps1") `
    -StageDir $stage `
    -MsysRoot $MsysRoot `
    -EnvironmentName "ucrt64" `
    -ManifestPath (Join-Path $stage "resources\bundle-files.json")

Write-Host "Headless runtime staged at $stage"
