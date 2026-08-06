param(
    [string]$Version = "0.10.0",

    [string]$RuntimePath = ".\artifacts\headless-runtime",

    [string]$UpstreamRoot = "..\upstream-uxplay-windows",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceRef,

    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must use the numeric MAJOR.MINOR.PATCH format."
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$artifactRoot = Join-Path $projectRoot "artifacts"
$releaseRoot = Join-Path $artifactRoot ("release\" + $Version)
$reviewPayload = Join-Path $artifactRoot (
    "AeroMirror-review-payload-x64-" + $Version + ".zip")
$setup = Join-Path $artifactRoot (
    "installer\AeroMirror-Setup-" + $Version + ".exe")
$releaseSetup = Join-Path $releaseRoot (
    "AeroMirror-Setup-" + $Version + ".exe")
$sourceArchive = Join-Path $releaseRoot (
    "AeroMirror-source-" + $Version + ".zip")
$nativeSourceArchive = Join-Path $releaseRoot (
    "AeroMirror-native-source-" + $Version + ".zip")
$checksums = Join-Path $releaseRoot "SHA256SUMS.txt"

function Assert-ChildPath([string]$Parent, [string]$Child) {
    $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith(
        $parentFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe release path: $childFull is outside $parentFull"
    }
}

Assert-ChildPath -Parent $artifactRoot -Child $releaseRoot
New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

if (-not $SkipBuild) {
    & (Join-Path $projectRoot "package-review.ps1") `
        -Version $Version `
        -HeadlessRuntimePath $RuntimePath
    if ($LASTEXITCODE -ne 0) {
        throw "Review payload packaging failed with exit code $LASTEXITCODE."
    }

    & (Join-Path $projectRoot "build-installer.ps1") `
        -Version $Version `
        -PortableZip $reviewPayload
    if ($LASTEXITCODE -ne 0) {
        throw "Installer build failed with exit code $LASTEXITCODE."
    }

    & (Join-Path $projectRoot "build-native-source.ps1") `
        -Version $Version `
        -UpstreamRoot $UpstreamRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Native source packaging failed with exit code $LASTEXITCODE."
    }
}

if (-not (Test-Path -LiteralPath $setup -PathType Leaf) -or
    -not (Test-Path -LiteralPath $nativeSourceArchive -PathType Leaf)) {
    throw "Review setup and native source artifacts are required."
}

Copy-Item -LiteralPath $setup -Destination $releaseSetup -Force

if (Test-Path -LiteralPath $sourceArchive) {
    Remove-Item -LiteralPath $sourceArchive -Force
}
$sourcePrefix = "AeroMirror-source-" + $Version + "/"
& git -C $projectRoot archive `
    --format=zip `
    ("--prefix=" + $sourcePrefix) `
    -o $sourceArchive `
    $SourceRef
if ($LASTEXITCODE -ne 0) {
    if (Test-Path -LiteralPath $sourceArchive) {
        Remove-Item -LiteralPath $sourceArchive -Force
    }
    throw "git archive failed with exit code $LASTEXITCODE."
}
if (-not (Test-Path -LiteralPath $sourceArchive -PathType Leaf) -or
    (Get-Item -LiteralPath $sourceArchive).Length -le 0) {
    throw "AeroMirror source archive was not created."
}

$releaseFiles = @($releaseSetup, $sourceArchive, $nativeSourceArchive)
$checksumLines = foreach ($file in $releaseFiles) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant()
    $name = Split-Path -Leaf $file
    "$hash  $name"
}
[IO.File]::WriteAllLines(
    $checksums,
    $checksumLines,
    [Text.UTF8Encoding]::new($false))

Write-Host "Release artifacts are ready in $releaseRoot"
