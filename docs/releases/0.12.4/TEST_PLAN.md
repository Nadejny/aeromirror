# AeroMirror 0.12.4 — recovery, frame pacing, and renderer acceptance

## Purpose and status

This plan verifies the 0.12.4 recovery policy, native feedback-health
contract, continuity handoff, renderer placement/policy caching, latency and
Direct3D arguments, geometry diagnostics, and update compatibility.

Automated checks and physical-device checks are separate gates. A passing
build or source audit does not prove Windows/iPhone interoperability. Record
every completed row with its date, exact Windows build, iPhone/iOS version,
network topology, AeroMirror log interval, and screenshot or screen recording
when relevant.

Version `v0.12.4` was published from commit
`31042ffa50773eb053239ab5ed687f44b4f35d94` as the normal latest review
Release:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.4

Managed/native builds, resilience, provenance, review payload, Setup/lifecycle,
version/link, diff, clean exact-tag, channel, checksum, API digest, and public
re-download gates pass. Installed update and physical-device execution remain
pending.

## Test environments

Retain evidence for at least:

| Environment | Required details |
|---|---|
| Windows 11 x64 | OS build, GPU and driver, Ethernet/Wi-Fi adapter, display DPI |
| Windows 10 1809+ x64 | OS build, GPU and driver, Ethernet/Wi-Fi adapter, display DPI |
| iPhone A | model, iOS version, Rotation Lock state |
| Network A | PC Ethernet plus iPhone 5/6 GHz Wi-Fi, access-point model/channel |
| Network B | representative 2.4 GHz or weaker/jittery Wi-Fi path |
| Update path | installed public 0.12.3 updated through AeroMirror |

Do not use public internet download/upload speed as the AirPlay quality
measurement. Record local packet loss, Wi-Fi band/channel, signal, VPN state,
client isolation, and whether the PC uses Ethernet.

## Automated and source gates

Run from the repository root against the exact candidate commit:

1. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1`
3. `powershell -NoProfile -ExecutionPolicy Bypass -File .\package-review.ps1 -Version 0.12.4 -HeadlessRuntimePath <verified-runtime>`
4. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build-installer.ps1 -Version 0.12.4 -PortableZip .\artifacts\AeroMirror-review-payload-x64-0.12.4.zip`
5. rebuild/validate the prepared native corresponding source and confirm its
   executable hash matches `native-core/source-provenance.json`;
6. `git diff --check` plus version, local-link, changed-file, and package
   content audits;
7. after a clean `v0.12.4` tag exists, run the exact-tag release packager and
   verify exactly the four permitted public assets.

Expected automated results:

- shell and Setup report PE/file version `0.12.4.0`, while UI, tag, asset names,
  and release text use `0.12.4`;
- `-reset 15` precedes advanced arguments, so an explicit expert override
  remains possible;
- Interactive emits `-vsync no` and does not emit `-al 0.05`;
- Direct3D 11 emits matching `d3d11h264dec` and `d3d11videosink`, while
  Direct3D 12 emits matching `d3d12h264dec` and `d3d12videosink`;
- only a core that announces feedback-health capability can open and dismiss
  the five-second pre-fatal continuity path;
- a native recovered marker cannot dismiss an already fatal loss episode;
- completed native cleanup preserves the same recovered process instead of
  scheduling a shell restart;
- renderer show, move/size-end, saved-placement, cached-policy, unobscured
  client capture, and 180 ms nonblocking handoff checks pass;
- raw AirPlay geometry and selected decoder/video-sink markers are present
  without interpreting the auxiliary geometry pair as crop, PAR, or rotation;
- native patch hashes, modified-source hashes, build inputs, expected core
  hash, corresponding-source archive, and third-party notices agree.

Any failure blocks publication.

### Candidate results — 2026-08-10

| Gate | Result |
|---|---|
| Managed x64 shell build | PASS |
| Receiver resilience suite | PASS |
| Thin 0.12.4 review payload | PASS |
| 0.12.4 network Setup build and lifecycle verifier | PASS |
| Native rebuild, `UPSTREAM.lock`, and source-provenance validation | PASS |
| Shell/Setup PE, internal Setup, script, asset, documentation, and link version audit | PASS |
| `git diff --check` | PASS |
| Clean exact `v0.12.4` tag and release packaging | PASS |
| GitHub channel, public re-download, SHA-256, and API digests | PASS |
| Installed 0.12.3-to-0.12.4 update | PENDING |
| Physical Windows 10/11 plus iPhone matrix | PENDING |

## Physical recovery matrix

For each required Windows/iPhone environment:

1. Start Screen Mirroring and confirm stable video/audio.
2. Turn iPhone Wi-Fi off for 3–4 seconds, then restore it.
3. Repeat with a 5–8 second interruption.
4. Repeat with an interruption longer than 15 seconds.
5. Stop mirroring normally, reconnect immediately, and repeat five sequential
   sessions.
6. Rejoin the iPhone to Wi-Fi after AeroMirror was already running; also wake
   the phone after at least ten minutes idle.
7. Repeat once with a VPN connected on Windows while the physical network
   remains Private.

Expected results:

- a short gap does not restart the core or change its PID/listening port;
- after five seconds without feedback, continuity may appear without ending
  the existing native process; it closes when feedback resumes;
- a recovered session resumes in the same renderer handoff without a second
  default-position flash;
- a genuinely fatal interruption follows one bounded recovery path and does
  not enter a restart loop;
- a normal disconnect does not open the loss placeholder or restart a healthy
  core;
- `receiver.log` contains capability, warning/recovered, socket-reset, and
  same-process preservation evidence without PINs or mirrored content;
- Screen Mirroring remains discoverable or returns within a recorded bounded
  time. Retain any stale iOS row or first-tap failure as a release defect.

Fail if the core changes PID/port after successful native cleanup, the
placeholder remains while live video is visibly back, the window reopens in a
different place, discovery takes an unbounded period, or three consecutive
reconnect attempts fail.

## Renderer continuity and placement

1. Place and resize the stream window on each monitor, including a mixed-DPI
   arrangement, then end the session and reconnect.
2. Repeat after moving the taskbar and after disconnecting the monitor that
   held the saved bounds.
3. During a stream, resize by each corner and edge, then release the pointer.
4. Trigger a recoverable feedback gap with the renderer unobscured; repeat
   with another application partially covering the renderer.
5. Test normal, always-on-top, taskbar-visible, taskbar-hidden, minimized, and
   maximized states.

Expected results:

- saved bounds are applied as the renderer appears, without first dwelling at
  the default location and then teleporting approximately one second later;
- stale/offline-monitor bounds are clamped into an available work area;
- the shell does not fight the live resize, and restores learned proportions
  only after release when automatic fitting is enabled;
- an unchanged window does not flicker or reorder from repeated title/style/
  topmost mutations;
- unobscured capture contains only the renderer client pixels, not its native
  titlebar; any overlap forces the dark privacy fallback;
- continuity stays until the real renderer is visible and positioned, then
  fades away without stealing focus.

Fail on persistent position jumping, focus theft, unrelated-window capture,
repeated Z-order flicker, a resize feedback loop, or lost access to an off-screen
window.

## Smoothness and Direct3D profiles

On the same local network and quality preset, retain a 60-second screen
recording and log interval for:

- Balanced with Automatic renderer;
- Interactive with Automatic renderer;
- Balanced with Direct3D 11;
- Balanced with Direct3D 12 where supported.

Exercise home-screen scrolling, a camera pan, Safari scrolling, video with
speech, and rapid app transitions. Record connection time, visible freezes,
microstutters, audio discontinuities, audio/video drift, CPU/GPU utilization,
feedback-gap episodes, and the longest gap.

Expected results:

- Interactive no longer shows the former aggressive-buffer regression and may
  improve motion responsiveness; any audio/video drift is clearly attributable
  and reversible by choosing Balanced;
- each explicit Direct3D mode either starts with its matching decoder/sink or
  fails visibly and safely; H.264 and HEVC may select the codec-matched decoder
  from the same Direct3D family, and the pipeline must not silently mix D3D11
  and D3D12 backends;
- automatic mode remains the default and fallback;
- diagnostics contain enough timing/geometry evidence to distinguish local
  feedback stalls from decoder/render behavior.

No claim that Interactive is universally faster may be made without retained
physical evidence across the required environments.

## Photos, rotation, and raw geometry diagnostics

1. Start mirroring on the Home screen, then open Photos and a portrait photo,
   landscape photo, and video.
2. Start a new session directly inside Photos for each orientation.
3. Rotate the iPhone with Rotation Lock off, then repeat with it on.
4. Capture the full raw AirPlay geometry header, actual selected decoder/sink
   lines, and matched screenshots.

Expected results:

- the outer viewer retains the learned phone orientation unless authoritative
  stream rotation changes it;
- no resize feedback loop or repeated shrinking occurs;
- the logged primary, source, auxiliary, and encoded dimensions plus selected
  decoder/sink are compact and correlate with each transition; the auxiliary
  pair is not labelled or consumed as crop, PAR, or rotation metadata;
- the known small photo inside an encoded `3840x2160` canvas may remain. This
  is an explicit limitation, not a pass claim.

Fail if 0.12.4 regresses a previously stable Home/Camera/video orientation,
crashes, or logs mirrored pixels/personal media content. Tiny inner Photos
content remains a known release limitation but must be recorded.

## Installed update and persistence

1. Install public 0.12.3 and configure receiver name, quality, latency,
   renderer, PIN/trust, autostart, close behavior, window policy, and saved
   renderer position.
2. Use **Check for updates** to find the normal `v0.12.4` Release.
3. Review notes, download Setup, verify digest, and complete the update.
4. Confirm shortcuts, autostart, settings, key/trusted-client register, logs,
   runtime-cache reuse, uninstall identity, and renderer placement survive.
5. Reboot and reconnect on both Windows versions.

Fail if Setup reports file-in-use, creates a second installed-app entry,
loses user state, downloads a differently named asset, bypasses digest
verification, or cannot roll back an injected installation failure.

## Privacy and security regressions

- A Public or unknown physical Windows network still blocks no-PIN reception.
- A VPN/virtual adapter does not redefine a Private physical LAN.
- The continuity bitmap remains in memory only and never enters logs,
  diagnostic exports, settings, or temporary files.
- Logs redact PINs, receiver keys, labelled cryptographic material, profile
  paths, and MAC addresses.
- The updater accepts only exact three-part tags and the exact versioned Setup
  asset with GitHub SHA-256 digest.

Any privacy or fail-closed regression blocks publication.

## Acceptance gate

0.12.4 is published as a normal updater-visible **review** Release after all
automated/package/provenance and public-verification gates passed. Exact asset
evidence is in `BUILD_REPORT.md`. It may not be described as physically
accepted, stable, or 1.0 until the complete Windows 10 and Windows 11 plus
iPhone matrix above passes with retained evidence. A defect found after
publication must be fixed in 0.12.5 or later; never move the tag or replace a
published 0.12.4 asset.
