param(
    [Parameter(Mandatory = $true)]
    [string]$UxPlayPortablePath,

    [Parameter(Mandatory = $true)]
    [string]$HeadlessCorePath,

    [string]$Version = "0.10.0"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceExe = Join-Path $projectRoot "artifacts\Release\AeroMirror.exe"
$stageRoot = Join-Path $projectRoot (
    "artifacts\package-stage-" + [Guid]::NewGuid().ToString("N"))
$stage = Join-Path $stageRoot "AeroMirror"
$core = Join-Path $stage "core"
$docs = Join-Path $stage "docs"

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must use the numeric MAJOR.MINOR.PATCH format."
}

function Assert-ChildPath([string]$Parent, [string]$Child) {
    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [System.IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe output path: $childFull is outside $parentFull"
    }
}

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

& (Join-Path $projectRoot "build.ps1")

if (-not (Test-Path (Join-Path $UxPlayPortablePath "uxplay-windows.exe"))) {
    throw "uxplay-windows.exe was not found in $UxPlayPortablePath"
}
$resolvedHeadlessCore = [System.IO.Path]::GetFullPath($HeadlessCorePath)
if (-not (Test-Path -LiteralPath $resolvedHeadlessCore -PathType Leaf)) {
    throw "Headless core executable was not found: $resolvedHeadlessCore"
}
$runtimeManifest = Join-Path $UxPlayPortablePath "resources\build-manifest.json"
if (-not (Test-Path -LiteralPath $runtimeManifest -PathType Leaf)) {
    throw "The reviewed headless runtime manifest is missing: $runtimeManifest"
}
$manifestData = Get-Content -LiteralPath $runtimeManifest -Raw -Encoding UTF8 |
    ConvertFrom-Json
if ($manifestData.shellMode -ne "headless" -or
    $manifestData.architecture -ne "x64") {
    throw "The runtime manifest does not identify a headless x64 build."
}
if (-not $manifestData.headlessExecutableSha256) {
    throw "The runtime manifest is not bound to a headless executable hash."
}
if ((Get-PeMachine $resolvedHeadlessCore) -ne 0x8664) {
    throw "The requested headless core is not an x64 PE executable."
}
$requestedCoreHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (
    $resolvedHeadlessCore)).Hash
if ($requestedCoreHash -ne $manifestData.headlessExecutableSha256) {
    throw "The requested core hash does not match the reviewed runtime manifest."
}

Assert-ChildPath -Parent $projectRoot -Child $stageRoot
New-Item -ItemType Directory -Force -Path $core | Out-Null
New-Item -ItemType Directory -Force -Path $docs | Out-Null
Copy-Item -LiteralPath $sourceExe -Destination $stage
Copy-Item -Path (Join-Path $UxPlayPortablePath "*") -Destination $core -Recurse -Force
Copy-Item -LiteralPath $resolvedHeadlessCore `
    -Destination (Join-Path $core "uxplay-windows.exe") -Force
$packagedCoreHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (
    Join-Path $core "uxplay-windows.exe")).Hash
if ($packagedCoreHash -ne $requestedCoreHash) {
    throw "The packaged core does not match the requested headless executable."
}
Copy-Item -LiteralPath (Join-Path $projectRoot "README.md") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "CHANGELOG.md") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "THIRD_PARTY_NOTICES.md") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "CONTRIBUTING.md") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "SECURITY.md") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "update-repository.txt") -Destination $stage
Copy-Item -LiteralPath (Join-Path $projectRoot "docs\TROUBLESHOOTING.md") `
    -Destination $docs
$shellVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo(
    (Join-Path $stage "AeroMirror.exe")).FileVersion
if (-not $shellVersion.StartsWith($Version + ".")) {
    throw "Shell version $shellVersion does not match requested release $Version."
}

$zip = Join-Path $projectRoot (
    "artifacts\AeroMirror-portable-x64-" + $Version + ".zip")
Assert-ChildPath -Parent $projectRoot -Child $zip
if (Test-Path $zip) {
    Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -LiteralPath $stage -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -LiteralPath $stageRoot -Recurse -Force
Write-Host "Packaged $zip"
