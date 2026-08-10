# AeroMirror 0.12.5 — Photos startup and recovery acceptance

## Purpose and status

This plan verifies the 0.12.5 correction for a session that starts with the
recorded Photos `3840x2160 aux=0x0` presentation canvas, saved stream-window
placement, deterministic short-gap continuity, and same-session recovery.
It also retains delayed-discovery and reconnect as explicit physical gates.

Version `v0.12.5` was published from commit
`22ec7536062679b2e90f47d5174c970f3f6b587f` as the normal latest review
Release:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.5

Automated checks and physical-device checks are separate: a passing build,
replay, package, or public-asset audit does not prove Windows/iPhone
interoperability.

For each physical row, retain the date, Windows build, GPU/driver, iPhone model
and iOS version, network topology, Rotation Lock state, relevant redacted log
interval, and a screenshot or recording where layout is involved.

## Test environments

Retain evidence for at least:

| Environment | Required details |
|---|---|
| Windows 11 x64 | OS build, GPU/driver, Wi-Fi or Ethernet adapter, display DPI |
| Windows 10 1809+ x64 | OS build, GPU/driver, Wi-Fi or Ethernet adapter, display DPI |
| iPhone A | model, iOS version, Rotation Lock state |
| Network A | PC Ethernet plus iPhone 5/6 GHz Wi-Fi, AP model/channel |
| Network B | representative 2.4 GHz or weaker/jittery Wi-Fi path |
| Update path | installed public 0.12.4 updated through AeroMirror |

Internet download/upload speed is not an AirPlay transport measurement. Record
local packet loss, Wi-Fi band/channel, signal, VPN state, client isolation, and
whether the PC is wired.

## Automated and source gates

Run from the repository root against the exact candidate commit:

1. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1`
3. `powershell -NoProfile -ExecutionPolicy Bypass -File .\package-review.ps1 -Version 0.12.5 -HeadlessRuntimePath <verified-runtime>`
4. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build-installer.ps1 -Version 0.12.5 -PortableZip .\artifacts\AeroMirror-review-payload-x64-0.12.5.zip`
5. validate the reused native executable, runtime manifest, `UPSTREAM.lock`,
   source provenance, and prepared corresponding-source archive;
6. run shell/Setup PE, internal Setup, script-default, asset-name,
   documentation-version, local-link, changed-file, and package-content audits;
7. run `git diff --check`;
8. after a clean exact `v0.12.5` tag exists, run the exact-tag release
   packager and verify exactly the four permitted public assets.

Expected automated results:

- shell and Setup report PE/file version `0.12.5.0`; the UI, tag, asset names,
  and release text use `0.12.5`;
- a replayed raw geometry plus video-size pair classifies only the complete
  recorded `3840x2160 aux=0x0` Photos signature as ambiguous;
- a first ambiguous canvas does not establish device orientation or replace a
  saved placement, while a later `998x2160 aux=1421x0` phone frame establishes
  portrait;
- the observed `3840x1776 aux=0x192` landscape signature and unrelated 16:9
  streams are not rejected by the narrow Photos rule;
- explicit user move/resize/manual fit remains persistable, but an unresolved
  automatic/provisional fit is not flushed over a valid saved placement;
- a native three-second warning schedules continuity for a four-second local
  deadline only after feedback-health capability; recovery before that
  deadline cancels it, and acknowledged later recovery queues handoff without
  another user action or dismissing a fatal episode prematurely;
- normal disconnect, network safety, settings persistence, update validation,
  logging redaction, and native provenance regressions remain covered;
- the reused native core and third-party runtime match the locked 0.12.4
  provenance exactly; no native behavior is claimed as newly implemented.

Any failed automated, provenance, Setup, package, version, or diff gate blocks
publication.

### Release results — 2026-08-10

| Gate | Result |
|---|---|
| Managed x64 shell build | PASS |
| Receiver resilience suite | PASS |
| Thin 0.12.5 review payload: exact 13-entry contract | PASS |
| 0.12.5 network Setup build plus shortcut/update lifecycle self-checks | PASS |
| Prepared native source: 139 files and 12 provenance hashes | PASS |
| Reused native core byte-identical to 0.12.4 | PASS |
| Source defaults, shell/Setup/internal literals, documentation, and local-link audit | PASS |
| Built x64 shell and Setup PE/file version `0.12.5.0` | PASS |
| Setup embedded review-payload SHA-256 matches the input ZIP | PASS |
| `git diff --check` | PASS |
| Clean exact `v0.12.5` tag and `release.ps1` packaging | PASS |
| GitHub channel, public re-download, SHA-256, and API digests | PASS |
| Former updater API and Setup URL redirect to canonical repository | PASS |
| Installed 0.12.4-to-0.12.5 update | PENDING |
| Physical Windows 10/11 plus iPhone matrix | PENDING |

The final review payload and Setup were regenerated after the pre-tag evidence
update, and their content, version, embedded-payload SHA, and lifecycle checks
passed again before tagging. Exact-tag packaging then passed. All four public
assets were re-downloaded with matching byte sizes and SHA-256 values, and all
four GitHub API digest fields matched. The former `Nadejny/aeromirror` updater
API and Setup URL followed redirects to canonical `pyram1da/aeromirror` and
returned 0.12.5 successfully.

These results prove release discovery and artifact integrity, not the installed
0.12.4-to-0.12.5 update or any physical Windows/iPhone scenario. Exact public
evidence is in `BUILD_REPORT.md`.

## Photos-first orientation and placement

For each Windows/iPhone environment:

1. Establish and save a normal portrait stream-window position and size.
2. End mirroring, leave the iPhone inside Photos on a portrait item, and start
   a new session that produces the recorded
   `3840x2160 aux=0x0` then `998x2160 aux=1421x0` sequence.
3. Repeat with a true landscape stream that produces the observed
   `3840x1776 aux=0x192` geometry.
4. Start on Home, then enter Photos and alternate portrait photo, landscape
   photo, video, and gallery views with Rotation Lock off; repeat with it on.
5. During an unresolved Photos-first start, close normally without resizing;
   reconnect and confirm the prior valid saved placement was not replaced.
6. Repeat while explicitly moving/resizing the unresolved window, then use the
   manual tray fit and verify those deliberate user actions remain persistable.
7. Repeat on mixed-DPI monitors and after disconnecting the monitor containing
   the saved bounds.

Expected results:

- the exact ambiguous Photos canvas never forces or permanently saves a false
  landscape device orientation;
- the later phone-shaped frame refines the same session to portrait without a
  second connection, resize loop, or repeated shrink;
- real landscape still rotates the outer window when the stream reports the
  matching device geometry;
- a restored saved position is applied early and is not silently rewritten by
  an unresolved automatic fit;
- an explicit user move, resize, or manual fit still saves as expected;
- raw auxiliary values remain labelled as evidence only and never as crop,
  PAR, rotation, or a validated content rectangle;
- a small photo and black bars may remain inside the encoded canvas. Retain a
  screenshot as known-limitation evidence; do not record it as fixed.

Fail on a persistent false-landscape window, loss of a valid saved placement,
placement teleportation after initial show, a resize loop, rejection of real
landscape, crash, or any log containing mirrored pixels or personal media.

## Feedback-gap and reconnect continuity

1. Start a stable stream and interrupt iPhone Wi-Fi for 3–4 seconds, then for
   5–8 seconds, then for longer than 15 seconds.
2. For the short recoverable case, retain capability, warning, recovered, and
   placeholder/handoff log lines plus a screen recording.
3. Repeat when the renderer remains present and when it is recreated after a
   fatal interruption.
4. Repeat the fatal case with an unobscured renderer and with another window
   overlapping it, then reconnect without clicking in the placeholder.
5. Stop Screen Mirroring normally and reconnect immediately five times.

Expected results:

- common very short jitter does not cause a receiver restart or false fatal
  state;
- the three-second warning arms a local deadline and the view appears at four
  seconds when the capable session remains stalled; recovery before four
  seconds cancels the pending view;
- acknowledged recovery changes the text to **Connection restored / Waiting
  for image** and hands off without requiring a click, resize, or another
  iPhone action;
- fatal recovery keeps the memory-only continuity view until a real renderer
  is visible and positioned, then hands off without focus theft;
- a normal disconnect does not open the continuity view or replace a healthy
  core;
- the receiver does not enter an unbounded restart loop.

Fail if live video is back while the recovery view remains indefinitely, the
view closes before a fatal replacement renderer is visible, the core changes
PID/port after successful native in-place cleanup, or three consecutive
reconnect attempts fail.

## Discovery visibility and delayed Wi-Fi

1. Launch AeroMirror before the iPhone joins Wi-Fi; record time from native
   DNS-SD/BLE/socket readiness to the receiver appearing in Screen Mirroring.
2. Toggle iPhone Wi-Fi off/on after a normal stream and record disappearance,
   reappearance, first-tap result, and the first incoming request in the
   Windows log.
3. Repeat after one manual discovery refresh. If still absent, retain evidence
   before trying a second refresh; do not collapse the attempts into one time.
4. Repeat after Windows boot, after ten minutes idle, and with a VPN connected
   over the same Private physical LAN.

Expected results are evidence-driven: readiness markers, listening sockets,
receiver-list visibility, and the first client request are timed separately.
The patch must not report a server-side failure when no iPhone request reached
Windows, and it must not claim that manual refresh can invalidate iOS browse
cache. Receiver visibility and successful first tap remain physical release
gates; any 30–60 second absence or repeated refresh requirement is retained as
an open defect rather than described as fixed.

## Installed update and persistence

1. Install public 0.12.4 and configure receiver name, quality, latency,
   renderer, PIN/trust, autostart, close behavior, taskbar/topmost policy, and
   a saved stream-window placement.
2. Use **Check for updates** to find the normal `v0.12.5` review Release.
3. Review notes, download Setup, verify its GitHub digest, and complete the
   update.
4. Confirm shortcuts, autostart, settings, receiver key/trusted-client state,
   logs, runtime-cache reuse, uninstall identity, and placement survive.
5. Reboot and reconnect on both supported Windows versions.

Fail if Setup reports file-in-use, creates a second installed-app entry, loses
user state, downloads a differently named asset, bypasses digest verification,
or cannot roll back an injected replacement failure.

## Privacy and security regressions

- A Public or unknown physical Windows network still blocks no-PIN reception.
- A VPN/virtual adapter does not redefine a Private physical LAN.
- The continuity bitmap remains in memory only and never enters logs,
  diagnostic exports, settings, or temporary files.
- Logs redact PINs, receiver keys, labelled cryptographic material, profile
  paths, and MAC addresses.
- The updater accepts only an exact three-part tag and exact versioned Setup
  asset with a GitHub SHA-256 digest.

Any privacy or fail-closed regression blocks publication.

## Acceptance gate

0.12.5 is published as a normal updater-visible **review** Release after its
automated, Setup, provenance, package, exact-tag, redirect, and public-asset
gates passed. Exact evidence is in `BUILD_REPORT.md`. It must not be described
as physically accepted, stable, or 1.0 until the installed update and complete
Windows 10 and Windows 11 plus iPhone matrix pass with retained evidence.

Any later correction receives 0.12.6 or later; never move the tag or replace a
published 0.12.5 asset.
