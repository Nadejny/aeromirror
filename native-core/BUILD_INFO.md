# AeroMirror native build information

This file documents the patched native executable shipped by AeroMirror
0.10.0. The source bundle also contains the complete upstream trees and the
patch both separately and applied in place.

## Exact inputs

- `leapbtw/uxplay-windows`:
  `8cf3424b438424bc99a89155bd29a789f48a43c0`
- `leapbtw/libuxplay`:
  `437f37514257d9cb513ac7fbdee743b4da85852e`
- AeroMirror patch: `uxplay-windows-headless.patch`
- Patched files: `src/airplayworker.cpp`, `src/main.cpp`,
  `src/mainwindow.cpp`, and `src/mainwindow.h`
- Architecture: x64, MSYS2 UCRT64
- Compiler recorded in the binary:
  `gcc.exe (Rev6, Built by MSYS2 project) 16.1.0`
- Qt: 6.10.1, built from the official MSYS2 package
  `mingw-w64-ucrt-x86_64-qt6-base-6.10.1-1-any.pkg.tar.zst`
- Qt package URL:
  `https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-qt6-base-6.10.1-1-any.pkg.tar.zst`
- Qt package SHA-256:
  `1F7E95DFA1968910460087E8235C274BA5E14365E0F79EDC0C7672D951544D65`
- Qt package verified signing key:
  `5F944B027F7FE2091985AA2EFA11531AA0AA7F57`
- GStreamer: 1.28.5
- Resulting patched executable SHA-256:
  `2A7708704A1344C85A909D5F549DC74E500DE0A552290812DE490692A5187E09`
- Reproducible PE timestamp (`SOURCE_DATE_EPOCH`): `1786008050`
- Local checkout paths are remapped to `/src/uxplay-windows`, and debug
  sections are stripped from the released executable.

The `uxplay-windows` tree contains its exact `ucrt_x64_dependencies.txt`,
Python requirements, CMake files, Bluetooth beacon recipe, Bonjour build
script, packaging scripts, and verification scripts.

The AeroMirror patch adds the headless launcher integration and `--loader-test`.
It also keeps the receiver process arguments alive for the full native
startup call, avoiding invalid `char*` pointers when the argument storage
grows. The source packaging script accepts only the four files listed above
and verifies that their complete binary Git diff exactly matches the reviewed
patch.

The resulting x64 PE imports `qt_version_tag_6_10`, does not import
`qt_version_tag_6_11`, and its `--loader-test` passed with the unchanged
runtime from pinned `uxplay-windows` release `2.0.0.1736`. It contains no
`.debug_*` sections or local checkout path.

## Rebuild from this source bundle

The source files in this archive are already checked out at the pinned
upstream revisions and the AeroMirror patch is already applied. Do not run
`git checkout` or apply the patch again. Extract the exact Qt package listed
above to an isolated prefix. From an x64 Windows PowerShell prompt with MSYS2
installed, open the bundled `uxplay-windows` directory and run:

```powershell
.\AeroMirror-build-inputs\build-compatible-core.ps1 `
    -UpstreamRoot . `
    -Qt610Prefix C:\inputs\qt610\ucrt64 `
    -MsysRoot C:\msys64
```

## Rebuild from separate Git clones

When starting from Git repositories instead of this prepared source bundle,
clone `uxplay-windows` with its `libuxplay` submodule, select the pinned
revisions, copy the patch from this bundle, and apply it once:

```powershell
git clone --recurse-submodules https://github.com/leapbtw/uxplay-windows.git
Set-Location .\uxplay-windows
git checkout 8cf3424b438424bc99a89155bd29a789f48a43c0
git -C .\libuxplay checkout 437f37514257d9cb513ac7fbdee743b4da85852e
git apply C:\path\to\uxplay-windows-headless.patch
C:\path\to\build-compatible-core.ps1 `
    -UpstreamRoot . `
    -Qt610Prefix C:\inputs\qt610\ucrt64 `
    -MsysRoot C:\msys64
```

The compatible-core script configures CMake with:

```text
-G Ninja
-DCMAKE_BUILD_TYPE=Release
-DCMAKE_EXPORT_COMPILE_COMMANDS=ON
-DNO_MARCH_NATIVE=ON
-DCMAKE_PREFIX_PATH=<isolated Qt 6.10.1 prefix>
-DQt6_DIR=<isolated Qt 6.10.1 prefix>\lib\cmake\Qt6
-UDNSSD_INCLUDE_DIR
```

The actual `dns_sd.h` used for the interface and AeroMirror's `dnssd.def` are
included in the source bundle. The Bluetooth beacon is reused unchanged from
the pinned upstream runtime.

The full offline runtime is not published by AeroMirror 0.10.0. The review
installer downloads the unchanged, pinned upstream runtime asset directly
from the upstream GitHub release and verifies its SHA-256 before installing
it.
