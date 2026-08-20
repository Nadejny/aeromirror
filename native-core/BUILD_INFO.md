# AeroMirror native build information

This file documents the patched native executable originally shipped by
AeroMirror 0.11.1. The current executable keeps the same pinned upstream and
runtime inputs and the reviewed stream-geometry, feedback, discovery, and
selected GStreamer pipeline diagnostics. AeroMirror 0.12.6 added native HTTP
listener reset validation and removed unsupported photo-presentation feature
declarations. AeroMirror 0.12.7 keeps those changes, restores client-managed
RTSP `TEARDOWN` handling, and preserves externally supplied headless renderer
arguments before the legacy Qt settings UI can rewrite them. AeroMirror 0.12.8
adds epoch-correlated D3D11 presentation proof for feedback-gap recovery.
AeroMirror 0.12.13 adds bounded request-correlated DNS-SD pair refresh in the
same process and on the same ports, including persistent owner-thread callback
pumping and recovery across transient internal GLib-loop resets. AeroMirror
0.12.15 expanded the libuxplay patch into a full native-core safety audit across
worker lifecycle, socket ownership, parsers, setup/pairing, RTP/NTP, crypto,
buffers, and both renderers. The source bundle contains the complete upstream
trees and both patches separately and applied in place. Two clean compatible
0.12.18 builds reproduce the executable hash recorded below after extending
the GLib-owner Photos scale command for automatic portrait fill. The final 0.12.15 source
archive contained 147 validated entries; its no-Git extracted tree validated
all pinned hashes and a clean 57/57 rebuild reproduced that earlier executable.

## Exact inputs

- `leapbtw/uxplay-windows`:
  `8cf3424b438424bc99a89155bd29a789f48a43c0`
- `leapbtw/libuxplay`:
  `437f37514257d9cb513ac7fbdee743b4da85852e`
- AeroMirror patches: `uxplay-windows-headless.patch` and
  `libuxplay-aeromirror.patch`
- Patched wrapper files: `src/airplayworker.cpp`, `src/main.cpp`,
  `src/mainwindow.cpp`, and `src/mainwindow.h`
- Patched libuxplay files: `lib/crypto.c`, `lib/crypto.h`, `lib/dnssd.c`,
  `lib/dnssd.h`, `lib/fairplay_playfair.c`, `lib/http_handlers.h`,
  `lib/http_request.c`, `lib/http_request.h`, `lib/http_response.c`,
  `lib/http_response.h`, `lib/httpd.c`, `lib/mirror_buffer.c`,
  `lib/mirror_buffer.h`, `lib/mirror_payload_parser.c`,
  `lib/mirror_payload_parser.h`, `lib/netutils.c`, `lib/netutils.h`,
  `lib/pairing.c`, `lib/pairing.h`, `lib/raop.c`, `lib/raop.h`,
  `lib/raop_buffer.c`, `lib/raop_handlers.h`, `lib/raop_ntp.c`,
  `lib/raop_ntp.h`, `lib/raop_rtp.c`, `lib/raop_rtp.h`,
  `lib/raop_rtp_mirror.c`, `lib/raop_rtp_mirror.h`, `lib/utils.c`,
  `lib/worker_lifecycle.c`, `lib/worker_lifecycle.h`,
  `renderers/audio_renderer.c`, `renderers/video_renderer.c`,
  `renderers/video_renderer.h`, `uxplay.cpp`, and `uxplay_api.h`
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
- AeroMirror 0.12.18 compatible executable SHA-256 reproduced by clean
  builds:
  `C217386CBC916F8889A9C03774390FE7EC7D8C7EE0B6F64358215CACEEB35118`
- Materialized wrapper patch SHA-256:
  `8F48A4E72D765B0549119BC6366CB970384BAB8116B4430CE60ED67228213F9C`
- Materialized libuxplay patch SHA-256:
  `11330A0D905CF4480958DAA59B950F3A2CE2B4AD51A18563EBCC77924DD782C4`
- Provenance still pins 37 libuxplay sources and 41 patched sources in total.
  The 0.12.18 corresponding-source archive contains 147 entries. Its no-Git
  extracted tree passes the same input/hash validation, and a clean
  57/57 build reproduces the reviewed executable.
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
0.12.18 extension accepts the same exact fullscreen/scale control lines, marshals
them to the native GLib owner, and changes only documented properties on a
retained selected Direct3D 11 sink. Scale is uniform, bounded to 100–500%, and
reset at renderer start. The managed shell uses it only for deterministic
portrait fill of the exact known Photos transport canvas; no pixels are
inspected and no media bytes are rewritten. The
native HTTP listener now reports initial/reset readiness with its actual port,
checks same-port reset binding, exits for full shell recovery when a reset
cannot restore the advertised port, and logs typed RTSP `TEARDOWN` as
client-managed instead of forcing the whole connection closed from the server.
The upstream `Connection: close` response header remains unchanged; the
hotfix removes only AeroMirror 0.12.6's additional server-side disconnect flag.
The 0.12.14 diagnostic candidate also emits one fixed, numeric,
content-free media-health summary every two seconds during an active mirror
session. It separates mirror VCL/config/action ingress, appsrc flow, sink and
Direct3D 11 Present progress, timestamp retries, monotonic ages, and pipeline
state under session/geometry generations. The classifier is observational: it
does not reset, resume, reconnect, crop, map pixels, or otherwise alter the
pipeline. Video timestamp retries now derive each candidate from the same
immutable remote timestamp through a signed, clock-epoch-protected offset;
audio retains an independent checked mapping. These source and arithmetic
properties are regression-tested, while the original physical frozen-frame
symptom remains unverified until a new-device log is captured.
The 0.12.15 audit then makes worker and socket lifetime states explicit,
validates bounded HTTP/RTSP and mirror media structures before use, makes
SETUP and crypto publication transactional, and hardens RTP/NTP endpoint and
packet validation. Video/audio renderer callbacks take synchronized retained
GStreamer references across teardown. A complete decrypted and validated
type-0 video access unit now performs one implicit resume when the sender has
left the stream suspended without the usual resume option, before that same
access unit is delivered. This narrow repair remains physically unverified.
Unsupported photo, slideshow, and photo-preload feature bits are no
longer advertised by this screen-mirroring-focused receiver. The
shell uses the backward-compatible video-size marker to adapt the renderer
window when the iPhone changes orientation. `--beacon-ipv4` binds BLE
discovery to the physical Wi-Fi/Ethernet IPv4 selected by the shell instead of
letting a VPN default route choose the advertised address. The launcher also
keeps beacon diagnostics separate from the stdout command protocol and
keeps receiver arguments alive for the full native startup call. Headless or
external `--uxplay` launches now return before the wrapper removes or replaces
`-vs`/`-fs`. The source packaging script verifies that both complete binary
Git diffs exactly match the reviewed patches. The audited
`libuxplay/renderers/audio_renderer.c` and every new or modified source are
individually pinned in provenance.

DNS-SD identity and TXT storage now belong to the full `dnssd_t` lifetime,
while each RAOP/AirPlay service-ref pair is rolled back and refreshed
idempotently as one generation. Registration callbacks and
`DNSServiceProcessResult` remain pumped on the owning GLib thread. The bounded
stdin protocol reports request, generation, PID, and both unchanged ports;
active clients defer refresh without listener teardown. The separate BLE
helper and its pinned binary are unchanged, so a real physical IPv4 change
still requires the shell's full-process restart path.

The one stored DNS-SD receiver name is capped to 50 complete UTF-8 bytes so a
six-byte-MAC RAOP instance (`MAC@name`) is no longer than Bonjour's 63-byte
service-label boundary. The same canonical name is used for AirPlay, RAOP, and
`/info`; blank input falls back to `AeroMirror`. Its protocol diagnostic logs
only byte lengths and truncation state, never the original name.

The resulting x64 PE imports `qt_version_tag_6_10`, does not import
`qt_version_tag_6_11`, and its `--loader-test` passed with the unchanged
GStreamer 1.28.1 runtime from pinned `uxplay-windows` release `2.0.0.1736`.
The build gate checks the exact runtime archive and both DLL hashes above,
their embedded 1.28.1 version, and the wasapi2 property before staging. It
also verifies that the separate build prefix contains GStreamer 1.28.5. The
executable contains no
`.debug_*` sections or local checkout path.

The final staged-runtime audit covers 199 binaries and 148 staged DLLs. All 44
requested GStreamer features resolve to 27 plug-ins, and a manual staged
`--loader-test` exits 0. These are 0.12.15 prepackage checks; they do not imply
that the review payload or Setup has been built.

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
