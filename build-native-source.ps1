param(
    [Parameter(Mandatory = $true)]
    [string]$UpstreamRoot,

    [string]$Version = "0.10.0"
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
$expectedUpstream = "8cf3424b438424bc99a89155bd29a789f48a43c0"
$expectedLibuxplay = "437f37514257d9cb513ac7fbdee743b4da85852e"
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
    " M src/airplayworker.cpp",
    " M src/main.cpp",
    " M src/mainwindow.cpp",
    " M src/mainwindow.h"
)
$statusDifferences = @(Compare-Object $modified $expectedModified)
if ($statusDifferences.Count -ne 0) {
    throw "Upstream tree contains changes other than the reviewed headless patch."
}

$reviewedPatch = Join-Path (
    Join-Path $projectRoot "native-core") "uxplay-windows-headless.patch"
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
    $reviewedPatchHash = (
        Get-FileHash -Algorithm SHA256 -LiteralPath $reviewedPatch).Hash
    $actualPatchHash = (
        Get-FileHash -Algorithm SHA256 -LiteralPath $actualPatch).Hash
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

    New-Item -ItemType Directory -Force -Path $inputsRoot | Out-Null
    foreach ($name in @(
        "uxplay-windows-headless.patch",
        "build-compatible-core.ps1",
        "BUILD_INFO.md",
        "README.md",
        "dnssd.def",
        "build-headless-runtime.ps1",
        "gstreamer-features.txt"
    )) {
        Copy-Item -LiteralPath (Join-Path $projectRoot "native-core\$name") `
            -Destination $inputsRoot
    }
    Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") `
        -Destination (Join-Path $inputsRoot "AEROMIRROR-LICENSE")
    Copy-Item -LiteralPath (
        Join-Path $upstream "Bonjour SDK\Include\dns_sd.h") `
        -Destination $inputsRoot

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
