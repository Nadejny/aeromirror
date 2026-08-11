[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$UpstreamRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Qt610Prefix,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$MsysRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw (
                "Command failed with exit code ${LASTEXITCODE}: " +
                "$FilePath $($Arguments -join ' ')")
        }
    }
    finally {
        Pop-Location
    }
}

function Assert-ChildPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Parent,

        [Parameter(Mandatory = $true)]
        [string]$Child
    )

    $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith(
        $parentFull,
        [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe build path: $childFull is outside $parentFull"
    }
}

function Get-Sha256Lower {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (
        Get-FileHash -Algorithm SHA256 -LiteralPath $Path
    ).Hash.ToLowerInvariant()
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $actual = Get-Sha256Lower -Path $Path
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw (
            "$Description does not match source-provenance.json. " +
            "Expected $Expected, found $actual at $Path.")
    }
}

function Assert-BinaryContainsAsciiToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Token,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $binaryText = [Text.Encoding]::ASCII.GetString(
        [IO.File]::ReadAllBytes($Path))
    if ($binaryText.IndexOf($Token, [StringComparison]::Ordinal) -lt 0) {
        throw "$Description does not contain required token '$Token'."
    }
}

$upstream = (Resolve-Path -LiteralPath $UpstreamRoot).Path
$qtPrefix = (Resolve-Path -LiteralPath $Qt610Prefix).Path
$msys = (Resolve-Path -LiteralPath $MsysRoot).Path
$libuxplay = Join-Path $upstream "libuxplay"
$msysBin = Join-Path $msys "ucrt64\bin"
$msysUsrBin = Join-Path $msys "usr\bin"
$qtBin = Join-Path $qtPrefix "bin"
$qtCore = Join-Path $qtBin "Qt6Core.dll"
$qtConfig = Join-Path $qtPrefix "lib\cmake\Qt6\Qt6Config.cmake"
$qtConfigDir = Split-Path -Parent $qtConfig
$qmake = Join-Path $qtBin "qmake6.exe"
$cmake = Join-Path $msysBin "cmake.exe"
$ninja = Join-Path $msysBin "ninja.exe"
$compiler = Join-Path $msysBin "c++.exe"
$cCompiler = Join-Path $msysBin "gcc.exe"
$objdump = Join-Path $msysBin "objdump.exe"
$strip = Join-Path $msysBin "strip.exe"
$dlltool = Join-Path $msysBin "dlltool.exe"
$buildGStreamerCore = Join-Path $msysBin "libgstreamer-1.0-0.dll"
$buildWasapi2Plugin = Join-Path $msys "ucrt64\lib\gstreamer-1.0\libgstwasapi2.dll"
$bonjourSdk = Join-Path $upstream "Bonjour SDK"
$bonjourHeader = Join-Path $bonjourSdk "Include\dns_sd.h"
$bonjourImportLibrary = Join-Path $bonjourSdk "Lib\x64\dnssd.lib"
$temporaryImportLibraryName = "aeromirror-dnssd.lib"
$temporaryImportLibrary = Join-Path $upstream $temporaryImportLibraryName
$provenancePath = Join-Path $PSScriptRoot "source-provenance.json"
$uxplayPatch = Join-Path $PSScriptRoot "uxplay-windows-headless.patch"
$libuxplayPatch = Join-Path $PSScriptRoot "libuxplay-aeromirror.patch"
$bundledHeader = Join-Path $PSScriptRoot "dns_sd.h"
$sourceHeader = if (Test-Path -LiteralPath $bundledHeader -PathType Leaf) {
    $bundledHeader
}
else {
    $bonjourHeader
}
$definitionFile = Join-Path $PSScriptRoot "dnssd.def"
$wrapperSource = Join-Path $upstream "src\mainwindow.cpp"
$buildDir = Join-Path $upstream "out\headless-x64-qt610"
$output = Join-Path $buildDir "uxplay-windows.exe"

if ($buildDir.Length -gt 170) {
    throw (
        "The native source path is too long for the MinGW/CMake object " +
        "layout. Extract or move the source bundle to a short path such " +
        "as C:\src\aeromirror and run the build again.")
}

$required = @(
    (Join-Path $upstream "CMakeLists.txt"),
    (Join-Path $libuxplay "CMakeLists.txt"),
    $qtCore,
    $qtConfig,
    $qmake,
    $cmake,
    $ninja,
    $compiler,
    $cCompiler,
    $objdump,
    $strip,
    $dlltool,
    $buildGStreamerCore,
    $buildWasapi2Plugin,
    $provenancePath,
    $uxplayPatch,
    $libuxplayPatch,
    $sourceHeader,
    $definitionFile,
    $wrapperSource
)
$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath $_)
})
if ($missing.Count -ne 0) {
    throw "Missing compatible-core inputs:`n$($missing -join [Environment]::NewLine)"
}

$provenance = Get-Content -LiteralPath $provenancePath -Raw -Encoding UTF8 |
    ConvertFrom-Json
if ($provenance.schemaVersion -ne 1 -or
    $provenance.uxplayWindowsCommit -notmatch '^[0-9a-f]{40}$' -or
    $provenance.libuxplayCommit -notmatch '^[0-9a-f]{40}$' -or
    $provenance.uxplayWindowsPatchSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.libuxplayPatchSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.headlessExecutableSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.runtimeGStreamerVersion -notmatch '^\d+\.\d+\.\d+$' -or
    $provenance.buildGStreamerVersion -notmatch '^\d+\.\d+\.\d+$' -or
    $provenance.runtimeGStreamerCoreSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.runtimeWasapi2PluginSha256 -notmatch '^[0-9a-f]{64}$' -or
    $provenance.runtimeWasapi2RequiredProperty -ne 'continue-on-error') {
    throw "source-provenance.json is missing required pinned values."
}

$expectedUpstream = [string]$provenance.uxplayWindowsCommit
$expectedLibuxplay = [string]$provenance.libuxplayCommit
$expectedQtVersion = [string]$provenance.qtBuildVersion
$sourceDateEpoch = [string]$provenance.sourceDateEpoch

Assert-FileHash -Path $uxplayPatch `
    -Expected $provenance.uxplayWindowsPatchSha256 `
    -Description "uxplay-windows patch"
Assert-FileHash -Path $libuxplayPatch `
    -Expected $provenance.libuxplayPatchSha256 `
    -Description "libuxplay patch"
Assert-FileHash -Path $sourceHeader `
    -Expected $provenance.buildInputs.'dns_sd.h' `
    -Description "Bonjour interface header"
Assert-FileHash -Path $definitionFile `
    -Expected $provenance.buildInputs.'dnssd.def' `
    -Description "Bonjour import definition"

foreach ($sourceProperty in $provenance.patchedSources.PSObject.Properties) {
    $relative = $sourceProperty.Name.Replace('/', '\')
    $sourcePath = Join-Path $upstream $relative
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Pinned patched source is missing: $sourcePath"
    }
    Assert-FileHash -Path $sourcePath `
        -Expected ([string]$sourceProperty.Value) `
        -Description ("Patched source " + $sourceProperty.Name)
}
foreach ($sourceProperty in $provenance.protectedSources.PSObject.Properties) {
    $relative = $sourceProperty.Name.Replace('/', '\')
    $sourcePath = Join-Path $upstream $relative
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Pinned protected source is missing: $sourcePath"
    }
    Assert-FileHash -Path $sourcePath `
        -Expected ([string]$sourceProperty.Value) `
        -Description ("Protected unmodified source " + $sourceProperty.Name)
}

$libuxplayPatchText = Get-Content -LiteralPath $libuxplayPatch `
    -Raw -Encoding UTF8
if ($libuxplayPatchText -match '(?i)audio_renderer\.c') {
    throw "The reviewed hotfix must not modify audio_renderer.c."
}

Assert-BinaryContainsAsciiToken -Path $buildGStreamerCore `
    -Token ([string]$provenance.buildGStreamerVersion) `
    -Description "Build-toolchain GStreamer core"
Assert-BinaryContainsAsciiToken -Path $buildWasapi2Plugin `
    -Token ([string]$provenance.buildGStreamerVersion) `
    -Description "Build-toolchain wasapi2 plug-in"
Assert-BinaryContainsAsciiToken -Path $buildWasapi2Plugin `
    -Token ([string]$provenance.runtimeWasapi2RequiredProperty) `
    -Description "Build-toolchain wasapi2 plug-in"

$wrapperText = Get-Content -LiteralPath $wrapperSource -Raw -Encoding UTF8
$wrapperMethod = $wrapperText.IndexOf(
    "void MainWindow::applyRendererAndFullscreenArgs",
    [StringComparison]::Ordinal)
$externalGuard = $wrapperText.IndexOf(
    "if (m_headless || !m_argumentOverride.isEmpty())",
    [Math]::Max(0, $wrapperMethod),
    [StringComparison]::Ordinal)
$passThroughMarker = $wrapperText.IndexOf(
    "AEROMIRROR_ARGUMENTS_PASSTHROUGH mode=external",
    [Math]::Max(0, $externalGuard),
    [StringComparison]::Ordinal)
$guardReturn = $wrapperText.IndexOf(
    "return;",
    [Math]::Max(0, $passThroughMarker),
    [StringComparison]::Ordinal)
$firstArgumentMutation = $wrapperText.IndexOf(
    "args.removeAt",
    [Math]::Max(0, $wrapperMethod),
    [StringComparison]::Ordinal)
if ($wrapperMethod -lt 0 -or
    $externalGuard -lt $wrapperMethod -or
    $passThroughMarker -lt $externalGuard -or
    $guardReturn -lt $passThroughMarker -or
    $firstArgumentMutation -lt 0 -or
    $guardReturn -gt $firstArgumentMutation) {
    throw (
        "The wrapper must return before mutating externally supplied " +
        "headless/--uxplay arguments.")
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
    if ($LASTEXITCODE -ne 0 -or $upstreamCommit -ne $expectedUpstream) {
        throw "uxplay-windows is not at the pinned commit $expectedUpstream."
    }
    $libuxplayCommit = (
        & git -c ("safe.directory=" + $libuxplay) -C $libuxplay rev-parse HEAD
    ).Trim()
    if ($LASTEXITCODE -ne 0 -or $libuxplayCommit -ne $expectedLibuxplay) {
        throw "libuxplay is not at the pinned commit $expectedLibuxplay."
    }
}
else {
    Write-Host (
        "No Git metadata found; verified the prepared source tree by " +
        "source-provenance.json hashes.")
}

$qtFileVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo(
    $qtCore).FileVersion
if ($qtFileVersion -notmatch (
        '^' + [Regex]::Escape($expectedQtVersion) + '(?:\.0)?$')) {
    throw (
        "Qt6Core.dll must be $expectedQtVersion; " +
        "'$qtFileVersion' was found at " +
        "$qtCore.")
}

New-Item -ItemType Directory -Force -Path (
    Split-Path -Parent $bonjourHeader) | Out-Null
New-Item -ItemType Directory -Force -Path (
    Split-Path -Parent $bonjourImportLibrary) | Out-Null
if (-not [IO.Path]::GetFullPath($sourceHeader).Equals(
        [IO.Path]::GetFullPath($bonjourHeader),
        [StringComparison]::OrdinalIgnoreCase)) {
    Copy-Item -LiteralPath $sourceHeader -Destination $bonjourHeader -Force
}
$previousDlltoolSourceDateEpoch = $env:SOURCE_DATE_EPOCH
if (Test-Path -LiteralPath $temporaryImportLibrary) {
    Remove-Item -LiteralPath $temporaryImportLibrary -Force
}
try {
    $env:SOURCE_DATE_EPOCH = $sourceDateEpoch
    # Keep the output argument short. GNU dlltool derives temporary
    # assembler filenames from it and otherwise exceeds Windows' filename
    # limit when the corresponding-source ZIP is extracted under a long path.
    Invoke-Native `
        -FilePath $dlltool `
        -WorkingDirectory $upstream `
        -Arguments @(
            "-d", $definitionFile,
            "-D", "dnssd.dll",
            "-l", $temporaryImportLibraryName
        )
    if (-not (Test-Path -LiteralPath $temporaryImportLibrary -PathType Leaf) -or
        (Get-Item -LiteralPath $temporaryImportLibrary).Length -le 0) {
        throw "dlltool did not create the Bonjour x64 import library."
    }
    Copy-Item -LiteralPath $temporaryImportLibrary `
        -Destination $bonjourImportLibrary -Force
}
finally {
    $env:SOURCE_DATE_EPOCH = $previousDlltoolSourceDateEpoch
    if (Test-Path -LiteralPath $temporaryImportLibrary) {
        Remove-Item -LiteralPath $temporaryImportLibrary -Force
    }
}
if (-not (Test-Path -LiteralPath $bonjourImportLibrary -PathType Leaf) -or
    (Get-Item -LiteralPath $bonjourImportLibrary).Length -le 0) {
    throw "dlltool did not create the Bonjour x64 import library."
}

$previousPath = $env:PATH
$previousMsystem = $env:MSYSTEM
$previousBonjourSdkHome = $env:BONJOUR_SDK_HOME
$previousBonjourSdk = $env:BONJOUR_SDK
$previousSourceDateEpoch = $env:SOURCE_DATE_EPOCH
$previousCFlags = $env:CFLAGS
$previousCxxFlags = $env:CXXFLAGS
try {
    $env:MSYSTEM = "UCRT64"
    $env:SOURCE_DATE_EPOCH = $sourceDateEpoch
    $env:PATH = "$qtBin;$msysBin;$msysUsrBin;$previousPath"
    $env:BONJOUR_SDK_HOME = $bonjourSdk
    $env:BONJOUR_SDK = $bonjourSdk
    $normalizedUpstream = $upstream.Replace('\', '/')
    $pathMapFlags = (
        "-ffile-prefix-map=$normalizedUpstream=/src/uxplay-windows " +
        "-fdebug-prefix-map=$normalizedUpstream=/src/uxplay-windows")
    $env:CFLAGS = $pathMapFlags
    $env:CXXFLAGS = $pathMapFlags

    $qmakeVersion = (& $qmake -query QT_VERSION).Trim()
    if ($LASTEXITCODE -ne 0 -or $qmakeVersion -ne $expectedQtVersion) {
        throw (
            "The isolated Qt prefix must report $expectedQtVersion; " +
            "qmake6 reported '$qmakeVersion'.")
    }

    Assert-ChildPath -Parent $upstream -Child $buildDir
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

    Invoke-Native `
        -FilePath $cmake `
        -WorkingDirectory $upstream `
        -Arguments @(
            "-S", $upstream,
            "-B", $buildDir,
            "-G", "Ninja",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
            "-DNO_MARCH_NATIVE=ON",
            ("-DCMAKE_MAKE_PROGRAM=" + $ninja),
            ("-DCMAKE_C_COMPILER=" + $cCompiler),
            ("-DCMAKE_CXX_COMPILER=" + $compiler),
            ("-DCMAKE_PREFIX_PATH=" + $qtPrefix),
            ("-DQt6_DIR=" + $qtConfigDir),
            "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON",
            "-UDNSSD_INCLUDE_DIR"
        )
    Invoke-Native `
        -FilePath $cmake `
        -WorkingDirectory $upstream `
        -Arguments @("--build", $buildDir, "--parallel")

    if (-not (Test-Path -LiteralPath $output)) {
        throw "Compatible core was not produced at $output."
    }

    Invoke-Native `
        -FilePath $strip `
        -WorkingDirectory $upstream `
        -Arguments @("--strip-debug", $output)

    $fileHeaders = (& $objdump -f $output 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or
        $fileHeaders -notmatch 'file format pei-x86-64' -or
        $fileHeaders -notmatch 'architecture:\s+i386:x86-64') {
        throw "Compatible core is not an x64 PE executable."
    }

    $imports = (& $objdump -p $output 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect compatible-core imports."
    }
    if ($imports -notmatch '\bqt_version_tag_6_10\b') {
        throw "Compatible core does not import qt_version_tag_6_10."
    }
    if ($imports -match '\bqt_version_tag_6_11\b') {
        throw "Compatible core unexpectedly imports qt_version_tag_6_11."
    }

    $sections = (& $objdump -h $output 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $sections -match '\.debug_') {
        throw "Compatible core still contains debug sections."
    }
    $binaryText = [Text.Encoding]::ASCII.GetString(
        [IO.File]::ReadAllBytes($output))
    if ($binaryText.IndexOf(
            "AEROMIRROR_ARGUMENTS_PASSTHROUGH mode=external",
            [StringComparison]::Ordinal) -lt 0) {
        throw "Compatible core is missing the external-argument pass-through marker."
    }
    if ($binaryText.IndexOf(
            $upstream,
            [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $binaryText.IndexOf(
            $normalizedUpstream,
            [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Compatible core still exposes the local source checkout path."
    }

    $hash = Get-Sha256Lower -Path $output
    if ($hash -ne $provenance.headlessExecutableSha256) {
        throw (
            "Built core does not match the reviewed reproducible SHA-256. " +
            "Expected $($provenance.headlessExecutableSha256), found $hash.")
    }
    Write-Host "Compatible Qt $expectedQtVersion core built at $output"
    Write-Host "SHA-256: $hash"
}
finally {
    $env:PATH = $previousPath
    $env:MSYSTEM = $previousMsystem
    $env:BONJOUR_SDK_HOME = $previousBonjourSdkHome
    $env:BONJOUR_SDK = $previousBonjourSdk
    $env:SOURCE_DATE_EPOCH = $previousSourceDateEpoch
    $env:CFLAGS = $previousCFlags
    $env:CXXFLAGS = $previousCxxFlags
}
