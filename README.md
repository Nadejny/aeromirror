# AeroMirror for Windows

A native-style Windows tray application that makes an iPhone screen available
on a Windows 10/11 PC through the open-source UxPlay receiver.

**Set it up once and forget it:** AeroMirror starts quietly with Windows,
waits in the tray, and is ready from the iPhone's Screen Mirroring menu.
There is no phone app, account, subscription, advertising, or telemetry.

This is an independent project. It is not affiliated with or endorsed by
Apple. AirPlay, iPhone, and Apple are trademarks of Apple Inc.

## What works

- starts the receiver automatically and stays in the system tray;
- opens to a compact connection-status page; normal and advanced settings
  are separate pages inside the same application window;
- follows the Windows light/dark app theme by default and allows a manual
  light or dark override;
- starts with Windows and starts hidden in the tray by default;
- lets the user choose whether the main-window close button hides to the tray
  or exits the application;
- starts, stops, and restarts the UxPlay core;
- changes the receiver name shown under **Control Center → Screen Mirroring**;
- uses no PIN on a trusted/private network by default;
- can establish PIN trust once and keeps the receiver key and trusted-client
  register under the user's local application data, independently of the
  current Wi-Fi network and application install folder;
- detects the active physical Wi-Fi/Ethernet profile while ignoring VPN and
  virtual adapters, and reports how many overlay profiles were excluded;
- pauses unprotected reception on a Windows Public physical network and asks
  the user to enable a visible four-digit PIN;
- canonicalizes persisted protection state before use: only no-PIN mode or
  PIN mode with exactly four ASCII digits is accepted, so an obsolete,
  unknown, or malformed stored value becomes unprotected and the existing
  Public/Unknown physical-network rule fails closed;
- offers simple 720p/30, 1080p/30, 1080p/60, and HEVC 4K/60 quality
  presets in the normal settings;
- offers Windows Mobile Hotspot only as an optional advanced action while a
  Public physical network is active;
- selects automatic, Direct3D 11, or Direct3D 12 rendering;
- can use the default Windows audio output or mute receiver audio;
- keeps latency and audio controls in the normal settings, with Balanced
  latency selected by default; renderer selection and raw UxPlay arguments
  remain under Advanced settings;
- renames the stream window, gives a newly found renderer a provisional fit,
  captures an early phone-shaped size before the video-size debounce, ignores
  later media-canvas ratios that do not match the learned device frame, and
  treats only the complete observed Photos `3840x2160 aux=0x0` signature as an
  ambiguous canvas when it arrives first; a later phone-shaped frame can still
  establish portrait, while unresolved automatic fits cannot overwrite a valid
  saved placement; the window adapts on real portrait/landscape changes, and
  automatic fitting restores the learned proportions after a manual resize
  unless the user turns it off;
  the last normal position, size, and DPI are restored on the next session and
  clamped into an available monitor; saved bounds are applied from the early
  window-show event, unchanged native-window policy is cached, and the window
  can stay on top and remains on the taskbar by default;
- debounces Windows network events, refreshes discovery only after an actual
  physical network change, keeps a healthy receiver running after a normal
  disconnect, and retains one bounded ten-minute idle-discovery fallback;
  an incoming high-level AirPlay request re-arms that fallback so it cannot
  interrupt the next handshake, while a full manual receiver restart remains
  available; a stale end marker from the previous session also preserves the
  newer request/PIN grace instead of triggering deferred maintenance during
  the reconnect handshake; after completed lost-client cleanup, the recovered
  native process and AirPlay port are preserved instead of immediately being
  replaced, while an ordinary clean disconnect still leaves the receiver
  running; after a capable native three-second warning, the shell can show
  continuity at a deterministic four-second local deadline, cancel it on
  earlier recovery, and show connection-restored/waiting-for-image while the
  real renderer handoff is pending; confirmed loss keeps a
  softened in-memory view of unobscured renderer client pixels, or a dark
  fallback otherwise, until a positioned renderer is ready for a short fade
  handoff or the user closes it;
- checks a configured public GitHub Release channel only when requested,
  accepts only exact three-part release tags such as `v0.12.5`,
  requires the exact versioned asset name
  `AeroMirror-Setup-<MAJOR.MINOR.PATCH>.exe`, displays curated release notes,
  and verifies the setup SHA-256 before launching an update;
- provides a basic diagnostic report, a local log, and a **Report a problem**
  action that prepares a separately redacted log snapshot and opens a
  pre-filled GitHub Issue; the user reviews and attaches the file manually;
- captures UxPlay stdout/stderr in the rotating log while masking PINs,
  passwords, MAC addresses, user-profile paths, and labelled cryptographic
  material; the current review line records feedback-gap totals, the full raw AirPlay
  geometry header, and the selected GStreamer decoder/sink without treating
  the raw auxiliary geometry pair as crop, PAR, or rotation metadata;
- keeps streaming local to the LAN; the shell has no account, analytics, or
  cloud component.

The actual AirPlay handshake, decryption, H.264/H.265 decoding, audio, mDNS,
and player window come from UxPlay/uxplay-windows.

## System requirements

- Windows 10 version 1809 or newer, x64; or Windows 11, x64;
- the iPhone and PC on the same local network;
- local-network access allowed in Windows Firewall;
- HEVC-capable decoding for the 4K/60 preset.

The pinned runtime uses Qt 6.10.1, which officially supports Windows 10
1809 x64 and newer. Windows 10 is outside Microsoft's normal consumer support lifecycle,
but remains an explicit application target. ARM64 and 32-bit packages are not
included.

## Installer: recommended

For normal use, open the
[latest AeroMirror release](https://github.com/pyram1da/aeromirror/releases/latest)
and download:

```text
AeroMirror-Setup-0.12.5.exe
```

`v0.12.5` is the normal latest updater-visible public review Release. Its
managed build, resilience, Setup/lifecycle, provenance-reuse, exact-tag,
checksum, API-digest, and public re-download gates pass. The installed
0.12.4-to-0.12.5 update and physical Windows 10/11 plus iPhone matrix remain
pending and are not implied by those automated results.

The canonical repository is now `pyram1da/aeromirror`. AeroMirror 0.12.5 still
contains the former `Nadejny/aeromirror` updater slug; GitHub redirects its
`releases/latest` API and Setup download to the canonical repository, and both
redirect paths were verified after publication.

The installer:

- is a **network review installer**: it downloads the unchanged pinned
  `uxplay-windows` runtime directly from the upstream GitHub Release, verifies
  SHA-256, and fails closed if the download or checksum is wrong;
- installs for the current Windows user without an administrator prompt;
- places the application under
  `%LOCALAPPDATA%\Programs\AirPlayReceiverMvp` (the legacy internal path is
  retained so v0.7/v0.8 upgrade in place);
- adds AeroMirror to Windows **Installed apps**;
- creates a Start menu shortcut and can optionally create a desktop shortcut;
- closes the setup window before launching the receiver when installation
  finishes;
- updates an existing installed version in place, preserves the current
  shortcut choices, and rolls back application files plus installer metadata
  if replacement fails;
- keeps the exact pinned upstream runtime in a content-addressed local cache
  after SHA-256 verification, so a reinstall or later update using the same
  runtime does not download the 100+ MB archive again;
- includes an uninstaller while preserving user settings by default.

An internet connection is therefore required during installation. The pinned
third-party asset, source location, and checksum are recorded in
[UPSTREAM.lock](UPSTREAM.lock) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). AeroMirror's Release does
not mirror or silently fall back to another runtime.

The installer is currently unsigned, so Windows SmartScreen may display an
unknown-publisher warning. Code signing is required before a broad public
release. The GitHub-provided digest and HTTPS protect against corruption and
an accidental mismatch; until Authenticode publisher verification is added,
they are not a substitute for a signed release if the repository account
itself were compromised.

## Portable build: local testing only in 0.11

The offline portable package is intentionally **not attached** to the 0.11
review Release. It contains the full Qt/GStreamer/FFmpeg/MSYS2 DLL closure,
whose per-file source and license inventory is still being completed. Use the
network installer for review distribution.

Maintainers can still build the portable ZIP locally for engineering tests.
Windows does not register that variant as an installed application, and
deleting or cleaning its folder deletes the program.

1. Extract the whole ZIP to a normal folder. Do not run it from inside the ZIP.
2. Start `AeroMirror.exe`.
3. Allow network access if Windows Firewall asks.
4. If Bonjour is missing, the bundled core may ask for administrator
   permission to install its mDNS service.
5. Put the iPhone and PC on the same local network.
6. On iPhone, open **Control Center → Screen Mirroring** and select the PC name.
7. Use the tray icon to change settings or stop the receiver.

On a Windows **Private** physical network, a fresh installation accepts a
connection without a PIN. PIN protection remains available there as an
optional extra layer. On a Windows **Public** network, the shell pauses an
unprotected receiver until you enable PIN protection. The PIN is generated
and shown in the settings window, so the iPhone never asks for an invisible
code.

VPN, tunnel, Hyper-V, and other virtual profiles do not determine whether the
LAN is trusted. The UI shows the exact physical profile name and Windows
category. If Windows itself marks the physical Wi-Fi/Ethernet as Public while
a VPN is active, AeroMirror remains fail-closed: disconnect the VPN and repeat
the check, change the physical Windows profile to Private only when it really
is a trusted network, or use PIN protection. A personal hotspot is never
enabled automatically.

Settings and logs are stored under:

```text
%LOCALAPPDATA%\AirPlayReceiverMvp
```

Supported settings are normalized when loaded and before saving. AeroMirror
writes a same-directory temporary settings file and atomically replaces the
previous `settings.ini`, so an interrupted save does not publish a partially
written new configuration. Receiver keys and trusted-client data are separate
files and are not replaced by a normal settings save.

Receiver diagnostics are written to `receiver.log`; installer and update
failures are written to the separate rotating `setup.log`.

The **Report a problem** link creates a temporary, additionally redacted
snapshot and opens GitHub. Browsers do not allow AeroMirror to attach a local
file silently, so Explorer selects the snapshot and the user drags it into the
Issue after reviewing it. Nothing is uploaded automatically.

For a reproducible bug report, follow
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md). Never publish
`settings.ini`, `receiver-key.pem`, or `trusted-clients.txt`.

The patched core receives arguments directly from the shell. AeroMirror does
not duplicate the PIN in uxplay-windows' legacy `arguments.txt` file.

## Build the shell locally

No downloaded SDK is required on a standard Windows 10/11 installation. The
build script uses the C# compiler included with .NET Framework:

```powershell
.\build.ps1
```

If Windows marks a locally reviewed script as downloaded, inspect it first and
unblock that one file only:

```powershell
Unblock-File .\build.ps1
```

The result is:

```text
artifacts\Release\AeroMirror.exe
```

Create the public thin review payload and build the per-user network installer
from that exact ZIP with:

```powershell
.\package-review.ps1 `
  -Version 0.12.5 `
  -HeadlessRuntimePath .\artifacts\headless-runtime

.\build-installer.ps1 `
  -Version 0.12.5 `
  -PortableZip .\artifacts\AeroMirror-review-payload-x64-0.12.5.zip
```

The result is:

```text
artifacts\installer\AeroMirror-Setup-0.12.5.exe
```

Public release names use three-part semantic versions such as `0.12.5`.
Windows executable metadata internally requires four numeric fields and may
show `0.12.5.0` in a file-property dialog; the AeroMirror UI and GitHub
Release intentionally show only `0.12.5`.

For local offline engineering tests, create the full portable package with
both explicit inputs:

```powershell
.\package.ps1 `
  -Version 0.12.5 `
  -UxPlayPortablePath .\artifacts\headless-runtime `
  -HeadlessCorePath .\artifacts\headless-runtime\uxplay-windows.exe
```

`package.ps1` now rejects a runtime without the reviewed headless build
manifest, requires the patched executable explicitly, verifies its hash after
staging, and writes a versioned local ZIP. Do not attach that offline ZIP to
the 0.11 review Release. The network installer instead downloads the unchanged
pinned upstream asset at install time and verifies the locked SHA-256.

### Rebuild the reviewed native core

`AeroMirror-native-source-0.12.5.zip` is a prepared corresponding-source
archive: the `uxplay-windows` and `libuxplay` patches are already applied, so
do not apply them a second time. After providing the pinned Qt 6.10.1 and
MSYS2 toolchains listed in
`AeroMirror-build-inputs\BUILD_INFO.md`, run from the extracted archive:

```powershell
# Use a short extraction path: the MinGW/CMake object tree can exceed the
# Windows filename limit under a deeply nested Downloads/workspace folder.
$source = Resolve-Path .\AeroMirror-native-source-0.12.5\uxplay-windows
& "$source\AeroMirror-build-inputs\build-compatible-core.ps1" `
  -UpstreamRoot $source `
  -Qt610Prefix C:\path\to\Qt-6.10.1 `
  -MsysRoot C:\path\to\msys64
```

The script validates both reviewed patch files, every modified source file,
the bundled Bonjour header and `dnssd.def` against
`source-provenance.json`. It copies the verified header into the prepared
Bonjour SDK layout, generates the x64 `dnssd.lib` import library with MSYS2
`dlltool`, and rejects a resulting executable whose SHA-256 differs from the
reviewed core hash. It fails early with a clear instruction if the extraction
path is too long for the MinGW/CMake object layout. Git metadata is not
required in the prepared archive; when building from Git checkouts, the same
script additionally verifies both pinned commits.

## Source layout

```text
AGENTS.md                   stable entry point for coding agents
src/
  Properties/
    AssemblyInfo.cs          managed assembly metadata
  Application/
    AppVersion.cs            public display version from assembly metadata
    Program.cs               process startup and single-instance behavior
  Configuration/
    AppSettings.cs           settings migration, validation, and atomic save
  Receiver/
    ReceiverContext.cs       tray application context and shared state
    ReceiverContext.Core.cs  native lifecycle and discovery/recovery policy
    ReceiverContext.Rendering.cs renderer-window sizing and Win32 policy
    ReceiverContext.LostConnection.cs fatal-loss placeholder lifecycle
    ReceiverContext.Diagnostics.cs logging and problem-report workflow
  UI/
    SettingsForm.cs          active home/settings/updates window
    DiagnosticsForm.cs       diagnostic text viewer
    LostConnectionForm.cs    softened reconnect placeholder window
    ThemeHelper.cs           light/dark control styling
    AppIcon.cs               embedded application icon loader
    Controls/
      NamedValue.cs
      WheelSafeComboBox.cs
  Updates/
    UpdateInfo.cs
    UpdateService.cs         strict release parsing, download, and verification
  Network/
    NetworkProfileInfo.cs
    NetworkSafety.cs         physical-profile trust and adapter filtering
  Interop/
    NativeMethods.cs         Win32 process and renderer-window interop
assets/
  logo.png                  transparent application logo
  AirPlayReceiver.ico       multi-resolution executable and tray icon
build.ps1                 builds the Windows shell
build-installer.ps1       embeds the thin review payload in the per-user setup
release.ps1               builds/copies versioned release assets and checksums
build-native-source.ps1   packages exact corresponding native source
app.manifest              Windows 10/11, DPI, and asInvoker declarations
package.ps1               combines the shell with the official core bundle
package-review.ps1        makes the thin, pinned network-installer payload
update-repository.txt     public OWNER/REPOSITORY used for release checks
download-core.ps1         fetches and verifies the pinned upstream core
UPSTREAM.lock             exact upstream release, commit, and SHA-256
CHANGELOG.md              user-facing release notes
LICENSE                   license for this project
THIRD_PARTY_NOTICES.md    component and license inventory
native-core/
  README.md                native core pins and build notes
  build-compatible-core.ps1 builds against the pinned Qt 6.10.1 SDK
  dnssd.def                import definition for the bundled mDNS library
  gstreamer-features.txt   exact plug-ins staged for this build
  build-headless-runtime.ps1
  source-provenance.json   reviewed commits, patches, sources, and core hash
  uxplay-windows-headless.patch
  libuxplay-aeromirror.patch
installer/
  AirPlayReceiverSetup.cs  per-user installer and uninstaller
docs/
  ARCHITECTURE.md            integration boundary and next steps
  PROJECT_STATE.md           current release, blockers, and immediate handoff
  DECISIONS.md               durable product and architecture choices
  DOCUMENTATION_POLICY.md    mandatory documentation for every patch
  RELEASE_AND_SIGNING.md     GitHub updates, Store, and signing plan
  TROUBLESHOOTING.md         log collection and first-run reproduction
  TODO.md                    product and protocol roadmap
  releases/
    0.12.5/
      RELEASE_NOTES.md       curated GitHub Release text
      TEST_PLAN.md           Photos-first and recovery acceptance matrix
      BUILD_REPORT.md        published tag, assets, hashes, and test status
    0.12.4/
      RELEASE_NOTES.md       curated GitHub Release text
      TEST_PLAN.md           recovery, frame-pacing, and renderer acceptance
      BUILD_REPORT.md        published tag, assets, hashes, and test status
    0.12.3/
      RELEASE_NOTES.md       curated GitHub Release text
      TEST_PLAN.md           loss, placement, and Photos acceptance matrix
      BUILD_REPORT.md        published tag, assets, hashes, and test status
    0.12.2/
      RELEASE_NOTES.md       curated GitHub Release text
      TEST_PLAN.md           reconnect, orientation, and fitting acceptance matrix
      BUILD_REPORT.md        published tag, assets, hashes, and test status
    0.12.0/
      RELEASE_NOTES.md       curated GitHub Release text
      TEST_PLAN.md           candidate acceptance and physical test matrix
      BUILD_REPORT.md        published tag, assets, hashes, and test status
  BUILD_REPORT*.md           immutable 0.11 release verification history
  TEST_PLAN_0.11.*.md        immutable 0.11 acceptance history
```

The managed files under `src/` still compile into one `AeroMirror.exe`.
Splitting them by responsibility is a maintenance boundary, not a new process,
plugin model, public API, settings location, or native IPC protocol. The
current `SettingsForm` intentionally remains one file in this conservative
pass; deeper UI extraction should be reviewed separately from receiver fixes.

## MVP limitations

- The portable package is x64-only.
- The native receiver is a minimally patched build of `uxplay-windows` 2.0.
  Its `--headless` mode removes the upstream tray, leaving one application
  icon. The remaining Qt UI code is still linked into the core and can be
  split into a smaller dedicated process later.
- The stream is rendered in the GStreamer window, not embedded inside the
  settings window.
- Portrait/landscape rotation is carried by the AirPlay stream and supported
  by UxPlay. The renderer should follow the iPhone automatically; iPhone
  Rotation Lock naturally prevents source rotation. This still requires
  device-by-device testing.
- Renderer-window detection is heuristic. AeroMirror gives a newly opened
  renderer a provisional fit and can retain an early phone-shaped raw marker
  before a later stable media-canvas marker wins the debounce. Later ratios
  within a small tolerance can reshape the client area for real
  portrait/landscape rotation; a Photos `3840x2160` presentation canvas is
  suppressed after a learned `998x2160` device frame. If iOS sends only the
  media canvas and no phone-shaped marker, the physical orientation remains
  ambiguous until another authoritative frame or session.
  Automatic fitting restores the learned aspect after a completed manual
  resize by default, respects an explicit opt-out, and keeps **Restore window
  proportions** as a manual fallback that also uses the learned device frame
  rather than a later non-matching media canvas. Normal renderer bounds and
  their DPI are saved across sessions; stale/off-screen bounds are moved into
  an available Windows work area.
- A Photos `3840x2160` stream can contain the photo and black bars inside the
  encoded canvas itself. AeroMirror can keep the outer phone orientation, but
  it does not yet have native content-rectangle metadata or safe pixel analysis
  with which to crop or zoom that inner canvas. Photos may therefore still look
  very small even when the outer renderer proportions are correct.
- After an abnormal Wi-Fi/client loss, AeroMirror preserves UxPlay's recovered
  process and listening port after completed in-process cleanup. The first
  stale row tapped on iOS may still fail before any request reaches Windows,
  and iOS may take time to refresh its browse cache. Native in-place DNS-SD/BLE
  re-publication with an acknowledged ready state remains future work.
- The continuity placeholder keeps only a softened renderer-client screenshot
  in process memory, writes no mirrored frame to disk, and uses a dark fallback
  whenever another visible window overlaps the renderer. With the patched
  feedback-health marker, a native three-second warning schedules it for a
  four-second local deadline. Recovery before that deadline cancels the view;
  once shown, it hands off only after the real renderer is visible and
  positioned. It does not make iOS discovery or reconnection instantaneous.
- Arbitrary window proportions cannot both fill the window and preserve the
  whole phone image: the alternatives would be black bars, stretching, or
  cropping. This MVP preserves the whole image and changes the window shape.
- The stream window is an external GStreamer HWND. A Mac-style hover-only
  frame, true borderless viewer, and live aspect lock during an edge drag need
  an embedded native rendering surface and versioned IPC; the shell does not
  cross-process-subclass that foreign window.
- "Always on top" or automatic fitting may need to be toggled again with an
  unusual GStreamer sink.
- The shell combines listening sockets with explicit DNS-SD/BLE health
  markers and a legacy Bonjour fallback before reporting readiness. This is
  still a transitional stdout contract rather than versioned native IPC, and
  it does not prove that an iPhone session is active.
- The executables are not yet code-signed, so Windows SmartScreen may warn
  about an unknown publisher.
- GitHub update checking in 0.12.5 uses the former `Nadejny/aeromirror` slug;
  GitHub redirects it to canonical `pyram1da/aeromirror`, and the public latest
  API plus Setup download redirect were verified for this release.
- Bonjour/mDNS and Windows Firewall configuration remain external system
  dependencies. Allow the receiver only on the network categories you intend
  to use. Some managed or guest Wi-Fi networks block device discovery.
- Public-network detection follows active physical Windows network profiles.
  A wrongly classified physical profile can still produce a conservative
  warning; fix the category in Windows or enable PIN.
- DRM-protected playback is not supported.
- No AirDrop, AeroDrop companion, clipboard sync, remote input, recording UI,
  multi-device UI, virtual camera, OBS integration, or `Win+K` integration.
  AirDrop is separate from AirPlay and requires its own Bluetooth/AWDL,
  identity, trust, and encrypted-transfer implementation.
- Phone notifications, SMS, and call handling are not included. The app's
  notification option only covers failures and unsafe network status; a normal
  Windows autostart is silent.
- PIN registration behavior is provided by UxPlay and can vary with iOS
  versions and stored pairing records.

## Quality presets

- **HD 720p / 30 FPS** requests the lowest workload for a weak network or PC.
- **Full HD 1080p / 30 FPS** keeps Full HD while halving the maximum frame rate.
- **Full HD 1080p / 60 FPS** is the default.
- **4K / 60 FPS** enables HEVC and provides the highest requested quality.
  It worked well during testing on the target iPhone/PC, but still requires
  compatible HEVC decoding and substantially increases network, decoder, and
  GPU load.

These are receiver capabilities advertised to the iPhone, not a guarantee.
The source device can send a lower resolution or frame rate. UxPlay accepts a
120 FPS request, but iPhone mirroring is not guaranteed to provide it, so the
main UI does not advertise a misleading 120 FPS preset.

Changing quality, FPS, receiver name, PIN mode, renderer, latency, or raw
UxPlay arguments restarts the native receiver because these capabilities are
advertised when the AirPlay service/session starts. Stop Screen Mirroring on
the iPhone and connect again to guarantee a new quality negotiation. UI-only
settings such as notifications, close-button behavior, window fitting, and
always-on-top save without restarting an otherwise running receiver.

The last saved quality preset is retained. The Save button compares the
controls with the saved settings, so changing a preset and returning to the
original preset disables Save again.

## Latency profiles

- **Balanced** keeps UxPlay's native timestamp synchronization and buffering.
- **Interactive** disables timestamp scheduling with `-vsync no` without the
  former 50 ms audio-buffer request. Motion may feel more immediate, but
  audio/video synchronization can be less exact.
- **Stable** reports a 350 ms audio buffer and adds visible delay.

The receiver defaults to GStreamer's automatic sink and decoder selection.
Earlier builds forced the newer D3D12 H.264 decoder, which can stutter on
some GPU/driver combinations. The explicit D3D11 and D3D12 overrides now pin
both the matching Direct3D decoder family and video sink for a consistent
comparison; UxPlay selects the codec-matched decoder at pipeline creation.

AirPlay itself and the iPhone encoder still add latency. Best results require
the PC on Ethernet, the iPhone on strong 5/6 GHz Wi-Fi, no VPN in the local
path, and no guest-network/client isolation. Public internet speed is not the
AirPlay media path: local packet loss, interference, Wi-Fi scheduling, decode,
and frame pacing matter. AeroMirror's optional Bluetooth beacon helps
discovery only; it does not carry or combine bandwidth with the Wi-Fi video.

## License

The AeroMirror-authored shell, installer, and build scripts are
GPL-3.0-or-later. The patched UxPlay core and every downloaded runtime
component remain under their respective upstream licenses. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The current license inventory is an engineering review, not legal advice.

## Sharing a build

For the 0.12 review, share the GitHub Release page or its network Setup—not a
loose `AeroMirror.exe`. The Release must keep these assets together:

- `AeroMirror-Setup-0.12.5.exe`;
- `AeroMirror-source-0.12.5.zip`;
- `AeroMirror-native-source-0.12.5.zip`;
- `SHA256SUMS.txt`.

The native source archive contains the exact prepared `uxplay-windows` and
`libuxplay` trees, both AeroMirror patches separately and already applied,
`source-provenance.json`, the actual Bonjour interface header, `dnssd.def`,
and the hash-validating build recipe that generates `dnssd.lib`. The offline
portable/full runtime remains unpublished until its complete runtime SBOM and
corresponding source set are ready.
