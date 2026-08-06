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

$expectedUpstream = "8cf3424b438424bc99a89155bd29a789f48a43c0"
$expectedLibuxplay = "437f37514257d9cb513ac7fbdee743b4da85852e"
$expectedQtVersion = "6.10.1"
$sourceDateEpoch = "1786008050"

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
$bonjourSdk = Join-Path $upstream "Bonjour SDK"
$buildDir = Join-Path $upstream "out\headless-x64-qt610"
$output = Join-Path $buildDir "uxplay-windows.exe"

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
    (Join-Path $bonjourSdk "Include\dns_sd.h"),
    (Join-Path $bonjourSdk "Lib\x64\dnssd.lib")
)
$missing = @($required | Where-Object {
    -not (Test-Path -LiteralPath $_)
})
if ($missing.Count -ne 0) {
    throw "Missing compatible-core inputs:`n$($missing -join [Environment]::NewLine)"
}

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

$qtFileVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo(
    $qtCore).FileVersion
if ($qtFileVersion -notmatch '^6\.10\.1(?:\.0)?$') {
    throw (
        "Qt6Core.dll must be 6.10.1; '$qtFileVersion' was found at " +
        "$qtCore.")
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
            $upstream,
            [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $binaryText.IndexOf(
            $normalizedUpstream,
            [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Compatible core still exposes the local source checkout path."
    }

    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $output).Hash
    Write-Host "Compatible Qt 6.10.1 core built at $output"
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
