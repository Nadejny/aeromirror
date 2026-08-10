# AeroMirror 0.12.6 — renderer, Photos, and reconnect acceptance

## Purpose and status

This plan verifies the 0.12.6 Direct3D 11 default and migration, connection-
loss z-order and reconnect guidance, Photos behavior, and affected update and
security regressions.

Version `v0.12.6` was published from commit
`c860909ad9b6a1098d524142b111857e522a7104` at
`2026-08-10T12:06:22Z` as the normal latest public review Release:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.6

It is not physically accepted. Automated checks and physical-device checks
are separate: a passing build, replay, package, exact-tag, or public-asset
audit does not prove Windows/iPhone interoperability.

For every physical row, retain the date, AeroMirror version and redacted log
interval, Windows build, GPU and driver, display/DPI, iPhone model and iOS
version, Rotation Lock state, network topology, and a screenshot or recording
where visual behavior is involved. Logs must not contain mirrored pixels or
personal media.

## Required environments

| Environment | Evidence to retain |
|---|---|
| Windows 11 x64 | OS build, GPU/driver, adapter, display DPI |
| Windows 10 1809+ x64 | OS build, GPU/driver, adapter, display DPI |
| iPhone | model, iOS version, Rotation Lock state |
| Strong LAN | PC Ethernet or stable Wi-Fi plus iPhone 5/6 GHz Wi-Fi |
| Weaker LAN | representative 2.4 GHz or jittery path |
| Update path | public 0.12.5 installation, settings, shortcuts, trust state |

## Automated pre-tag gates

After all managed and native work has stabilized, run:

1. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1`
3. `powershell -NoProfile -ExecutionPolicy Bypass -File .\package-review.ps1 -Version 0.12.6 -HeadlessRuntimePath <verified-runtime>`
4. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build-installer.ps1 -Version 0.12.6 -PortableZip .\artifacts\AeroMirror-review-payload-x64-0.12.6.zip`
5. build and validate the prepared native corresponding-source archive;
6. audit shell and Setup PE/file version `0.12.6.0`, Setup's internal
   comparison version, five script defaults, exact payload entries, runtime
   and native hashes, local links, documentation versions, and
   `git diff --check`;
7. only after a clean exact `v0.12.6` tag exists, run the exact-tag packaging
   gate without changing that tag.

Expected results:

- fresh settings use schema 11 and `Renderer=d3d11`;
- schema-10 `Renderer=auto` migrates to D3D11;
- schema-10 explicit `Renderer=d3d12` remains D3D12;
- unknown renderer values fail to D3D11;
- D3D11 and D3D12 each pin both the codec-matched decoder family and matching
  video sink, while advanced UxPlay arguments remain last;
- shell and Setup report `0.12.6.0`; UI, tag, asset names, and release text use
  `0.12.6`;
- no native binary, patch, provenance record, or prepared-source claim is
  accepted unless final hashes validate together.
- the native patch contains initial/reset HTTP ready and failed markers,
  rejects reset port mismatch without false-ready fallthrough, explicitly
  disconnects `TEARDOWN`, and logs mirror-only feature advertisement;
- the managed shell ignores stale-PID and out-of-sequence HTTP markers and
  preserves same-process recovery only after matching same-port reset evidence.

Any failed build, migration, payload, provenance, version, link, Setup,
lifecycle, or diff check blocks tagging and publication.

Current release evidence:

| Gate | Status |
|---|---|
| Managed build and combined resilience suite | PASS |
| Shell PE/file version `0.12.6.0` | PASS |
| Native reproducible rebuild and corresponding-source/provenance audit | PASS |
| Version, local-link, and `git diff --check` audits | PASS |
| Exact review payload and Setup/lifecycle | PASS |
| Clean exact `v0.12.6` tag | PASS |
| Normal latest channel and exact four public assets | PASS |
| API digests and public re-download byte sizes/SHA-256 | PASS |
| Installed update and Windows/iPhone matrix | PENDING |

The released native core SHA-256 is
`9f1fb168c882b1531400d2edbb4abd1277803c1971a20e9d5c4d7eff3e8498fc`;
the prepared native-source archive-content and provenance validation pass.
Canonical and configured legacy `releases/latest` API routes return the same
Release ID `367881011`. Exact public sizes and hashes are recorded in
`BUILD_REPORT.md`.

## Direct3D resolution-change A/B

Run the same scenario first with migrated/default Direct3D 11 and then with
explicit Direct3D 12. Do not change quality, latency, network, iPhone state,
or application sequence between runs.

1. Select 4K/60 and Balanced latency, start Screen Mirroring on Home, and
   retain the selected decoder/sink marker.
2. Enter Photos; alternate gallery, portrait photo, landscape photo, and video;
   rotate where iOS allows it.
3. Stop mirroring, remain inside Photos on a photo, and start mirroring from
   that state.
4. Repeat at 1080p/60 to separate HEVC/4K from renderer behavior.
5. Repeat three complete sessions per renderer on both Windows environments.

Expected results:

- logs identify the decoder and sink matching the selected renderer;
- video advances after every observed encoded-size transition;
- the shell remains responsive and sessions stop and reconnect normally;
- no run is called fixed merely because the outer window retained portrait.

Fail if the picture freezes while iPhone content changes, selected components
do not match the setting, the core or shell crashes, or three sessions cannot
complete. Record a small image inside a large encoded canvas as the known
inner-Photos limitation, not as a renderer freeze or a fixed crop/zoom result.

## Settings migration and override preservation

1. Install public 0.12.5 with `Renderer=auto`; update to public 0.12.6 and
   open Advanced settings.
2. Confirm Direct3D 11 is selected, save an unrelated setting, restart, and
   confirm it remains selected.
3. Repeat from 0.12.5 with explicit Direct3D 12 and confirm it survives and
   remains labelled experimental.
4. Add a harmless diagnostic advanced argument and confirm it is preserved
   after saving and follows managed renderer arguments in the redacted log.

Fail if migration changes quality, latency, audio, receiver identity, PIN or
trust, autostart, saved placement, or explicit Direct3D 12; if advanced
arguments are discarded; or if the settings form starts dirty.

## Connection-loss view and fatal reconnect guidance

1. Start a stream, leave another ordinary app in the foreground, and
   interrupt iPhone Wi-Fi long enough to show continuity.
2. Confirm continuity appears above the renderer without taking keyboard
   focus from the foreground app. Repeat with **Always on top** off and on.
3. Allow fatal cleanup to complete. Confirm the view names the receiver and
   explicitly requests a manual Screen Mirroring reconnect.
4. Re-select the receiver. Confirm the view remains until a real positioned
   renderer exists, then hands off without a click or focus theft.
5. During the 180 ms renderer fade, trigger a renewed/fatal loss. Confirm the
   fade is cancelled, opacity returns to full, and continuity remains visible.
6. Stop Screen Mirroring normally and confirm no false reconnect instruction.

Fail if continuity stays behind the renderer, steals focus, permanently makes
an ordinary stream topmost, closes before visible replacement video, remains
after visible video, continues fading during a renewed/fatal loss, or reports
a clean stop as a failure.

## Native HTTP reset and TEARDOWN lifecycle

1. Record initial `AEROMIRROR_HTTP_READY stage=initial` and its advertised
   AirPlay port.
2. Trigger fatal lost-client cleanup and retain the reset marker, core PID,
   expected port, actual port, socket readiness, and subsequent discovery
   markers.
3. In a controlled diagnostic build, make the original port unavailable at
   reset and retain the failed marker, native exit, and bounded shell recovery.
4. Send a normal **Stop Mirroring**/AirPlay `TEARDOWN` and confirm the client
   connection closes and the next session is accepted without a half-open
   predecessor.
5. Replay stale-PID, mismatched-port, and out-of-sequence markers through the
   managed resilience tests.

Expected results:

- matching `stage=reset` readiness on the original port may preserve the same
  native PID and AirPlay port;
- reset bind failure or port mismatch emits `AEROMIRROR_HTTP_FAILED`, cleans
  up, exits, and enters bounded full-process recovery without a false ready
  state;
- stale or out-of-sequence markers never establish readiness;
- a clean `TEARDOWN` does not show fatal reconnect guidance or block the next
  session.

Fail on false ready, preservation without exact current-PID/same-port evidence,
an unbounded restart loop, half-open cleanup, or three failed sequential
sessions. HTTP readiness alone does not prove DNS-SD/BLE re-publication or
iOS browse-cache refresh.

## Mirror-only AirPlay feature experiment

1. Confirm the native log contains
   `AEROMIRROR_MIRROR_ONLY_FEATURES_READY` and the advertised feature mask does
   not include photo, slideshow, or photo-preload bits 1, 5, and 13.
2. Verify Home-screen mirroring, H.264, HEVC/4K, PIN/trust, audio, rotation,
   normal stop, and reconnect still negotiate.
3. Run the direct-in-Photos sequence and the D3D11/D3D12 A/B above; retain raw
   geometry, selected pipeline, visible frame progression, and screenshots.
4. Compare against retained 0.12.5 evidence without changing renderer,
   quality, network, or iPhone state.

Expected result: ordinary screen mirroring remains available and unsupported
photo/slideshow capabilities are no longer advertised. The Photos canvas may
remain unchanged; that is a valid experimental result, not a reason to claim
crop/zoom or automatic Photos repair.

Fail if the receiver disappears, Screen Mirroring negotiation regresses,
PIN/trust or audio changes, or photo/slideshow/preload bit 1, 5, or 13 remains
advertised.

## Feedback, reconnect, and discovery regression

1. Interrupt Wi-Fi for 3–4 seconds, 5–8 seconds, and longer than 15 seconds;
   retain warning, recovered, cleanup, placeholder, and handoff markers.
2. After a normal **Stop Mirroring**, attempt immediate reconnect five times.
3. Launch AeroMirror before iPhone joins Wi-Fi and time native readiness,
   receiver-list visibility, first tap, and first request reaching Windows
   separately.
4. Repeat after one manual discovery refresh, ten minutes idle, and a VPN over
   the same Private physical LAN.

A short gap may recover in place; a fatal gap may require explicit manual
reconnect. No server-side result is inferred when no request reaches Windows.
Fail and retain as open if continuity sticks, the receiver is absent for
30–60 seconds, repeated refresh is required, or three reconnects fail. This
release does not claim automatic reconnect or discovery is fixed.

## Photos geometry and saved-placement regression

Repeat the 0.12.5 Photos-first sequence that reports `998x2160`, the exact
ambiguous `3840x2160 aux=0x0` canvas, and a later phone-shaped frame. Confirm
the ambiguous canvas does not become or persist as device orientation, real
landscape remains eligible, saved bounds survive sessions and DPI changes,
and explicit move/resize/manual-fit actions remain persistable.

Fail on false landscape, placement teleportation or poisoning, a resize loop,
or rejection of real landscape. Do not infer crop, rotation, pixel aspect, or
a content rectangle from the auxiliary pair.

## Installed update, privacy, and security

1. From public 0.12.5, use **Check for updates** to discover the normal public
   `v0.12.6` Release.
2. Verify exact Setup naming and GitHub SHA-256, complete the in-place update,
   and retain shortcuts, autostart, settings/migration, receiver key, trusted
   clients, logs, uninstall identity, runtime cache, and saved placement.
3. Inject an installer replacement failure and confirm rollback.
4. Confirm Public or unknown physical networks still block no-PIN reception,
   while VPN does not redefine a Private physical LAN.
5. Confirm continuity imagery remains memory-only and logs contain no PIN,
   key, trusted-client material, profile path, MAC address, or mirrored content.

Any update-integrity, rollback, persistence, privacy, or fail-closed network
regression blocks publication.

## Acceptance gate

The managed/native source, corresponding source, Setup, exact payload,
version/link/diff, clean exact-tag, latest-channel, API-digest, and public
re-download gates pass. The installed update and all physical Windows/iPhone
rows remain pending.

Version 0.12.6 remains a **review** release until the full Windows 10 and
Windows 11 plus iPhone matrix passes. It must not be described as stable,
physically accepted, a complete Photos fix, or 1.0. AeroMirror project policy
treats the published tag and assets as immutable; any correction uses 0.12.7
or later rather than moving the tag or replacing an asset.
