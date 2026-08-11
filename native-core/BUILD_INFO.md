# AeroMirror native build information

This file documents the patched native executable originally shipped by
AeroMirror 0.11.1. The current executable keeps the same pinned upstream and
runtime inputs and the reviewed stream-geometry, feedback, discovery, and
selected GStreamer pipeline diagnostics. AeroMirror 0.12.6 added native HTTP
listener reset validation and removed unsupported photo-presentation feature
declarations. AeroMirror 0.12.7 keeps those changes, restores client-managed
RTSP `TEARDOWN` handling, and preserves externally supplied headless renderer
arguments before the legacy Qt settings UI can rewrite them. The source bundle
contains the complete upstream trees and both patches separately and applied
in place.

## Exact inputs

- `leapbtw/uxplay-windows`:
  `8cf3424b438424bc99a89155bd29a789f48a43c0`
- `leapbtw/libuxplay`:
  `437f37514257d9cb513ac7fbdee743b4da85852e`
- AeroMirror patches: `uxplay-windows-headless.patch` and
  `libuxplay-aeromirror.patch`
- Patched files: `src/airplayworker.cpp`, `src/main.cpp`,
  `src/mainwindow.cpp`, `src/mainwindow.h`,
  `libuxplay/lib/http_handlers.h`, `libuxplay/lib/raop_handlers.h`,
  `libuxplay/lib/raop_rtp_mirror.c`,
  `libuxplay/renderers/video_renderer.c`, and `libuxplay/uxplay.cpp`
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
- Redistributed upstream GStreamer runtime: 1.28.1. The pinned
  `libgstreamer-1.0-0.dll` SHA-256 is
  `F2ED35F5089521F9C050530AB74B56C297CC48A190E6CDB80D5E370400ADFFA0`;
  the pinned `lib/gstreamer-1.0/libgstwasapi2.dll` SHA-256 is
  `EACD2DC97902D575298E65C4167F26C5809D82B26EF60B4E134F08DC08F35619`
  and that plug-in contains the `continue-on-error` property used by the
  managed Windows audio selection.
- Engineering build/staging GStreamer input: 1.28.5. It is not the
  redistributed-runtime version recorded above.
- Resulting patched executable SHA-256:
  `11B65324C83F23503F2D555D0064D1348C884407BF7F9B1C34D27B5D1C05FB9B`
- Reproducible PE timestamp (`SOURCE_DATE_EPOCH`): `1786008050`
- Local checkout paths are remapped to `/src/uxplay-windows`, and debug
  sections are stripped from the released executable.

The `uxplay-windows` tree contains its exact `ucrt_x64_dependencies.txt`,
Python requirements, CMake files, Bluetooth beacon recipe, Bonjour build
script, packaging scripts, and verification scripts.

The AeroMirror patches add the headless launcher integration,
`--loader-test`, stable video-size and codec-header geometry markers, a
feedback-health capability and one-shot recovery markers, a one-shot selected
GStreamer decoder/videosink marker, and stable DNS-SD readiness markers. The
native HTTP listener now reports initial/reset readiness with its actual port,
checks same-port reset binding, exits for full shell recovery when a reset
cannot restore the advertised port, and logs typed RTSP `TEARDOWN` as
client-managed instead of forcing the whole connection closed from the server.
The upstream `Connection: close` response header remains unchanged; the
hotfix removes only AeroMirror 0.12.6's additional server-side disconnect flag.
Unsupported photo, slideshow, and photo-preload feature bits are no
longer advertised by this screen-mirroring-focused receiver. The
shell uses the backward-compatible video-size marker to adapt the renderer
window when the iPhone changes orientation. `--beacon-ipv4` binds BLE
discovery to the physical Wi-Fi/Ethernet IPv4 selected by the shell instead of
letting a VPN default route choose the advertised address. The launcher also
forwards beacon diagnostics to stdout with the `AEROMIRROR_BLE` prefix and
keeps receiver arguments alive for the full native startup call. Headless or
external `--uxplay` launches now return before the wrapper removes or replaces
`-vs`/`-fs`. The source packaging script verifies that both complete binary
Git diffs exactly match the reviewed patches and separately pins the unchanged
`libuxplay/renderers/audio_renderer.c`; no native audio-renderer fallback is
part of this hotfix.

The resulting x64 PE imports `qt_version_tag_6_10`, does not import
`qt_version_tag_6_11`, and its `--loader-test` passed with the unchanged
GStreamer 1.28.1 runtime from pinned `uxplay-windows` release `2.0.0.1736`.
The build gate checks the exact runtime archive and both DLL hashes above,
their embedded 1.28.1 version, and the wasapi2 property before staging. It
also verifies that the separate build prefix contains GStreamer 1.28.5. The
executable contains no
`.debug_*` sections or local checkout path.

## Rebuild from this source bundle

The source files in this archive are already checked out at the pinned
upstream revisions and both AeroMirror patches are already applied. Do not run
`git checkout` or apply either patch again. Extract the exact Qt package listed
above to an isolated prefix. Extract the source archive under a short path such
as `C:\src\aeromirror`; deeply nested Downloads/workspace paths can exceed the
MinGW/CMake object-file limit. From an x64 Windows PowerShell prompt with
MSYS2 installed, open the bundled `uxplay-windows` directory and run:

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
git -C .\libuxplay apply C:\path\to\libuxplay-aeromirror.patch
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

The full offline runtime is not published by the AeroMirror 0.11.x review
releases. The installer downloads the unchanged, pinned upstream runtime asset
directly from the upstream GitHub release and verifies its SHA-256 before
installing it.
