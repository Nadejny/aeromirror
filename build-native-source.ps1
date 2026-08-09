param(
    [Parameter(Mandatory = $true)]
    [string]$UpstreamRoot,

    [string]$Version = "0.11.3"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression.FileSystem

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must use the numeric MAJOR.MINOR.PATCH format."
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$artifactRoot = Join-Path $projectRoot "artifacts"
$releaseRoot = Join-Path $artifactRoot ("release\" + $Version)
$upstream = (Resolve-Path -LiteralPath $UpstreamRoot).Path
$libuxplay = Join-Path $upstream "libuxplay"
$nativeRoot = Join-Path $projectRoot "native-core"
$provenancePath = Join-Path $nativeRoot "source-provenance.json"
$temporaryRoot = Join-Path $artifactRoot (
    "native-source-stage-" + [Guid]::NewGuid().ToString("N"))
$bundleName = "AeroMirror-native-source-" + $Version
$bundleRoot = Join-Path $temporaryRoot $bundleName
$sourceRoot = Join-Path $bundleRoot "uxplay-windows"
$inputsRoot = Join-Path $sourceRoot "AeroMirror-build-inputs"
$output = Join-Path $releaseRoot ($bundleName + ".zip")

function Invoke-Git {
    param(
        [string]$Repository,
        [string[]]$Arguments
    )
    & git -c ("safe.directory=" + $Repository) -C $Repository @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed in $Repository."
    }
}

function Assert-ChildPath([string]$Parent, [string]$Child) {
    $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith(
        $parentFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe source bundle path: $childFull is outside $parentFull"
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

if (-not (Test-Path -LiteralPath $provenancePath -PathType Leaf)) {
    throw "Native source provenance is missing: $provenancePath"
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
$expectedUpstream = [string]$provenance.uxplayWindowsCommit
$expectedLibuxplay = [string]$provenance.libuxplayCommit

$upstreamCommit = (
    & git -c ("safe.directory=" + $upstream) -C $upstream rev-parse HEAD
).Trim()
$libuxplayCommit = (
    & git -c ("safe.directory=" + $libuxplay) -C $libuxplay rev-parse HEAD
).Trim()
if ($upstreamCommit -ne $expectedUpstream -or
    $libuxplayCommit -ne $expectedLibuxplay) {
    throw "Native source commits do not match UPSTREAM.lock."
}

$modified = @(
    & git -c ("safe.directory=" + $upstream) -C $upstream `
        status --short --untracked-files=no
)
$expectedModified = @(
    " m libuxplay",
    " M src/airplayworker.cpp",
    " M src/main.cpp",
    " M src/mainwindow.cpp",
    " M src/mainwindow.h"
)
$statusDifferences = @(Compare-Object $modified $expectedModified)
if ($statusDifferences.Count -ne 0) {
    throw "Upstream tree contains changes other than the reviewed headless patch."
}

$libModified = @(
    & git -c ("safe.directory=" + $libuxplay) -C $libuxplay `
        status --short --untracked-files=no
)
$expectedLibModified = @(
    " M renderers/video_renderer.c",
    " M uxplay.cpp"
)
$libStatusDifferences = @(
    Compare-Object $libModified $expectedLibModified)
if ($libStatusDifferences.Count -ne 0) {
    throw "libuxplay contains changes other than the reviewed AeroMirror marker patch."
}

$reviewedPatch = Join-Path (
    $nativeRoot) "uxplay-windows-headless.patch"
Assert-FileHash -Path $reviewedPatch `
    -Expected $provenance.uxplayWindowsPatchSha256 `
    -Description "Reviewed uxplay-windows patch"
$actualPatch = [IO.Path]::GetTempFileName()
try {
    & git -c ("safe.directory=" + $upstream) -C $upstream `
        diff --binary --no-ext-diff `
        ("--output=" + $actualPatch) -- `
        "src/airplayworker.cpp" `
        "src/main.cpp" `
        "src/mainwindow.cpp" `
        "src/mainwindow.h"
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to generate the current native source diff."
    }
    $reviewedPatchHash = Get-Sha256Lower -Path $reviewedPatch
    $actualPatchHash = Get-Sha256Lower -Path $actualPatch
    if ($reviewedPatchHash -ne $actualPatchHash) {
        throw (
            "The modified native source does not exactly match " +
            "uxplay-windows-headless.patch.")
    }
}
finally {
    if (Test-Path -LiteralPath $actualPatch) {
        Remove-Item -LiteralPath $actualPatch -Force
    }
}

$reviewedLibPatch = Join-Path (
    $nativeRoot) "libuxplay-aeromirror.patch"
Assert-FileHash -Path $reviewedLibPatch `
    -Expected $provenance.libuxplayPatchSha256 `
    -Description "Reviewed libuxplay patch"
$actualLibPatch = [IO.Path]::GetTempFileName()
try {
    & git -c ("safe.directory=" + $libuxplay) -C $libuxplay `
        diff --binary --no-ext-diff `
        ("--output=" + $actualLibPatch) -- `
        "renderers/video_renderer.c" `
        "uxplay.cpp"
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to generate the current libuxplay source diff."
    }
    $reviewedLibPatchHash = Get-Sha256Lower -Path $reviewedLibPatch
    $actualLibPatchHash = Get-Sha256Lower -Path $actualLibPatch
    if ($reviewedLibPatchHash -ne $actualLibPatchHash) {
        throw (
            "The modified libuxplay source does not exactly match " +
            "libuxplay-aeromirror.patch.")
    }
}
finally {
    if (Test-Path -LiteralPath $actualLibPatch) {
        Remove-Item -LiteralPath $actualLibPatch -Force
    }
}

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

$bonjourHeader = Join-Path $upstream "Bonjour SDK\Include\dns_sd.h"
$dnssdDefinition = Join-Path $nativeRoot "dnssd.def"
Assert-FileHash -Path $bonjourHeader `
    -Expected $provenance.buildInputs.'dns_sd.h' `
    -Description "Bonjour interface header"
Assert-FileHash -Path $dnssdDefinition `
    -Expected $provenance.buildInputs.'dnssd.def' `
    -Description "Bonjour import definition"

Assert-ChildPath -Parent $artifactRoot -Child $temporaryRoot
New-Item -ItemType Directory -Force -Path $bundleRoot | Out-Null
New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

try {
    $upstreamArchive = Join-Path $temporaryRoot "uxplay-windows.zip"
    $libArchive = Join-Path $temporaryRoot "libuxplay.zip"
    Invoke-Git -Repository $upstream -Arguments @(
        "archive", "--format=zip", "-o", $upstreamArchive, "HEAD")
    [IO.Compression.ZipFile]::ExtractToDirectory(
        $upstreamArchive, $sourceRoot)
    Invoke-Git -Repository $libuxplay -Arguments @(
        "archive", "--format=zip", "-o", $libArchive, "HEAD")
    New-Item -ItemType Directory -Force -Path (
        Join-Path $sourceRoot "libuxplay") | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory(
        $libArchive, (Join-Path $sourceRoot "libuxplay"))

    foreach ($relative in @(
        "src\airplayworker.cpp",
        "src\main.cpp",
        "src\mainwindow.cpp",
        "src\mainwindow.h"
    )) {
        Copy-Item -LiteralPath (Join-Path $upstream $relative) `
            -Destination (Join-Path $sourceRoot $relative) -Force
    }
    foreach ($relative in @(
        "renderers\video_renderer.c",
        "uxplay.cpp"
    )) {
        Copy-Item -LiteralPath (Join-Path $libuxplay $relative) `
            -Destination (Join-Path $sourceRoot "libuxplay\$relative") `
            -Force
    }

    New-Item -ItemType Directory -Force -Path $inputsRoot | Out-Null
    foreach ($name in @(
        "uxplay-windows-headless.patch",
        "libuxplay-aeromirror.patch",
        "source-provenance.json",
        "build-compatible-core.ps1",
        "BUILD_INFO.md",
        "README.md",
        "dnssd.def",
        "build-headless-runtime.ps1",
        "gstreamer-features.txt"
    )) {
        Copy-Item -LiteralPath (Join-Path $nativeRoot $name) `
            -Destination $inputsRoot
    }
    Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") `
        -Destination (Join-Path $inputsRoot "AEROMIRROR-LICENSE")
    Copy-Item -LiteralPath (
        $bonjourHeader) `
        -Destination $inputsRoot

    foreach ($sourceProperty in $provenance.patchedSources.PSObject.Properties) {
        $stagedSourcePath = Join-Path $sourceRoot (
            $sourceProperty.Name.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $stagedSourcePath -PathType Leaf)) {
            throw "Packaged patched source is missing: $stagedSourcePath"
        }
        Assert-FileHash -Path $stagedSourcePath `
            -Expected ([string]$sourceProperty.Value) `
            -Description ("Packaged patched source " + $sourceProperty.Name)
    }

    if (Test-Path -LiteralPath $output) {
        Remove-Item -LiteralPath $output -Force
    }
    Compress-Archive -LiteralPath $bundleRoot -DestinationPath $output `
        -CompressionLevel Optimal
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

Write-Host "Native corresponding source is ready at $output"
