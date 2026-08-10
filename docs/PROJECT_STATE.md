# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Latest public release

- Version: `v0.12.6`
- Tag commit: `c860909ad9b6a1098d524142b111857e522a7104`
- Release URL: https://github.com/pyram1da/aeromirror/releases/tag/v0.12.6
- GitHub Release ID: `367881011`
- Published: `2026-08-10T12:06:22Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` public review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

AeroMirror project policy treats the published `v0.12.6` tag and its four
assets as immutable, although GitHub does not enforce that state for this
Release. Any correction must use 0.12.7 or later; never move the tag or replace
a published file. Exact evidence is recorded in
`docs/releases/0.12.6/BUILD_REPORT.md`.

Project policy also treats the published 0.12.5, 0.12.4, 0.12.3, 0.12.2,
0.12.1, 0.12.0, and 0.11 releases as immutable history. Their verification
remains under `docs/releases/` or the historical 0.11 report paths.

## What 0.12.6 changes

- Status: published normal updater-visible public review Release.
- Public app/Setup version: `0.12.6`; Windows PE/file version:
  `0.12.6.0`. The five release-script defaults and Setup's internal comparison
  version target 0.12.6.
- New profiles default to an explicitly pinned Direct3D 11 decoder and sink.
  Settings schema 11 migrates only the legacy automatic renderer choice to
  Direct3D 11, preserves an explicit Direct3D 12 opt-in, and normalizes an
  unknown renderer to Direct3D 11. The Advanced UI recommends Direct3D 11 and
  no longer offers automatic GStreamer selection.
- The continuity view is inserted immediately above the external renderer
  without activation. Fatal native cleanup changes its guidance to a manual
  Screen Mirroring reconnect instruction; it does not claim that discovery or
  reconnect completed automatically.
- The released native core emits explicit HTTP ready/failed markers for initial
  bind and fatal reset. The shell accepts them only from the current PID and
  preserves same-process recovery only after a matching reset on the original
  AirPlay port; failure or mismatch exits into full-process recovery. AirPlay
  `TEARDOWN` explicitly requests disconnect.
- AirPlay photo, slideshow, and preload feature bits are cleared and a
  mirror-only capability marker is logged. This is an isolated negotiation
  experiment. Its effect on direct-in-Photos startup and the inner encoded
  canvas remains a pending physical A/B gate.
- The current managed build, settings-migration/renderer arguments coverage,
  combined resilience suite, shell and Setup `0.12.6.0` x64 PE checks, exact
  13-entry review payload, Setup embedded-payload SHA-256 comparison,
  shortcut/update lifecycle self-checks, version/link audits, and
  `git diff --check` pass. The native core rebuild is reproducible at
  SHA-256 `9f1fb168c882b1531400d2edbb4abd1277803c1971a20e9d5c4d7eff3e8498fc`;
  patch/provenance, dependency, loader, reverse-apply, archive-content, and
  prepared native-source checks pass.
  Exact-tag packaging, the normal latest channel, all four GitHub API digests,
  and public re-download byte-size/SHA-256 verification also pass. Canonical
  and legacy `releases/latest` API routes return the same `v0.12.6` Release ID.
  Installed-update and physical Windows/iPhone gates remain pending.

Direct3D 11 is the default in this public review Release, not a physically
accepted Photos fix. The small photo and black bars may still
be encoded inside iOS's `3840x2160` presentation canvas; this release does
not crop, zoom, or reconstruct those pixels. It also does not claim to make a
stale iOS browse result, receiver discovery, or automatic reconnect reliable.

## What 0.12.5 changes

- Status: published normal updater-visible review Release.
- Public/app/Setup version: `0.12.5`; Windows PE/file version: `0.12.5.0`.
- The exact recorded Photos geometry
  `3840x2160 aux=0x0 encoded=3840x2160` is now classified as an ambiguous
  presentation canvas instead of becoming the device-orientation baseline.
  A later `998x2160 aux=1421x0` phone frame can establish portrait in the same
  session, while the observed real-landscape signature and unrelated 16:9
  streams remain eligible.
- An unresolved automatic/provisional fit cannot replace a valid saved
  placement. A trustworthy device frame or explicit user move, resize, or
  manual fit makes the current placement persistable.
- The native three-second feedback warning schedules a four-second local
  continuity deadline for a capable active session. Early recovery cancels it;
  acknowledged recovery changes the view to connection-restored/waiting-for-
  image and queues handoff. Fatal reconnect handoff still waits for a real
  positioned renderer.
- The pinned UxPlay core, native patches, source provenance, and third-party
  runtime are unchanged from 0.12.4. The pre-tag gates confirm that the staged
  native core is byte-identical to 0.12.4 and that the prepared native-source
  package contains 139 files with all 12 provenance hashes validated.
- The managed x64 build, receiver resilience suite, 13-entry thin review
  payload, network Setup build and shortcut/update lifecycle self-checks,
  prepared native-source build, shell/Setup `0.12.5.0` PE audit, Setup embedded-
  payload SHA-256 comparison, source/default/document/link checks, and
  `git diff --check` pass for the tagged source.
- The final payload and Setup were regenerated after the evidence update; the
  embedded payload hash, lifecycle checks, and version audits passed again.
  Exact-tag packaging, the normal latest channel, four API digests, and public
  re-download size/SHA-256 verification also pass.
- GitHub's canonical repository is now `pyram1da/aeromirror`. The checked-in
  updater slug remains `Nadejny/aeromirror` in this immutable release; its old
  API and Setup URLs followed GitHub redirects and successfully reached the
  canonical 0.12.5 Release. The actual installed update remains pending.

This release does not crop or zoom the small photo and black bars that Photos
may already encode inside its `3840x2160` canvas. It also does not claim to fix
delayed iOS browse-cache visibility when no request reaches Windows. Installed
update and physical Windows/iPhone tests remain clearly pending; the release
must not be called physically accepted or 1.0.

## What 0.12.4 changes

- UxPlay's feedback-loss bound returns from six seconds to the upstream
  15-second default. After completed native socket cleanup, the shell preserves
  the recovered core PID and AirPlay port instead of immediately replacing the
  process and publishing a new port.
- The patched core announces feedback-health capability and emits a compact
  recovered marker. AeroMirror can show continuity after a five-second gap and
  dismiss it when the same session recovers; legacy cores cannot enter this
  pre-fatal path.
- Saved renderer placement is applied from the early Windows show event.
  Continuity remains until the real renderer exists and is positioned, then
  fades away. Safe capture uses only unobscured renderer client pixels.
- Unchanged renderer title/taskbar/topmost policy is cached instead of being
  written on every supervision tick. Proportion restoration is queued after
  interactive resize completion.
- The former Minimal latency profile is labelled Interactive and now applies
  only `-vsync no`; it no longer forces `-al 0.05`. Explicit Direct3D 11/12
  choices pin matching decoder families and sinks, with codec matching at
  pipeline creation.
- Diagnostics add feedback-gap totals, native capability state, the full raw
  AirPlay geometry header (including the previously ignored auxiliary pair),
  and actual selected decoder/sink. The raw auxiliary dimensions are not
  interpreted as crop, PAR, or rotation metadata.
- The settings Back control is larger.

The upstream revisions and third-party runtime remain pinned. The reviewed
native patch, rebuilt core, modified-source hashes, build inputs,
`UPSTREAM.lock`, source provenance, and prepared corresponding source validate
together.

## Release verification

Passed against the exact source published as `v0.12.6`:

1. managed x64 shell build and combined receiver resilience suite;
2. reproducible native core, 139-file prepared corresponding source,
   provenance/reverse-apply/dependency/loader checks, and reviewed patch/source
   hashes;
3. exact 13-entry thin review payload, Setup build, embedded-payload SHA-256,
   and shortcut/update lifecycle verification;
4. shell/Setup `0.12.6.0` PE, internal Setup version, five script defaults,
   asset-name, documentation-version, local-link, changed-file, and
   `git diff --check` audits;
5. clean exact-tag release packaging from commit
   `c860909ad9b6a1098d524142b111857e522a7104`;
6. normal latest GitHub channel with Release ID `367881011`, `draft=false`,
   `prerelease=false`, and exactly four expected assets;
7. all public re-download byte sizes and SHA-256 values match final local
   release files, and all four GitHub API digest fields match;
8. canonical and configured legacy `releases/latest` API routes return the
   same `v0.12.6` Release ID.

No physical Windows/iPhone result is claimed by these gates. Exact asset
evidence is in `docs/releases/0.12.6/BUILD_REPORT.md`.

## Pending physical verification and known limitations

- the installed updater path from public 0.12.5 to public 0.12.6, including
  legacy automatic-to-D3D11 migration, explicit D3D12 preservation, settings,
  trust state, shortcuts, autostart, runtime-cache reuse, digest verification,
  Setup launch, and rollback;
- Windows 11 x64 and Windows 10 1809+ x64 with an iPhone: 3–4 second,
  5–8 second, and longer-than-15-second Wi-Fi interruptions; native in-place
  recovery; fatal recovery; normal disconnect; immediate and repeated
  reconnect; delayed Wi-Fi join; idle discovery; and VPN-over-Private-LAN;
- saved placement at first show, handoff fade and renewed-loss cancellation,
  mixed-DPI/multi-monitor restore, taskbar/topmost settings, manual resize,
  safe snapshot, privacy fallback, and no focus theft or Z-order flicker;
- Balanced versus Interactive plus Direct3D 11 and Direct3D 12
  frame-pacing, audio drift, CPU/GPU, feedback-gap, and decoder/sink evidence;
- direct-in-Photos startup where the ambiguous 4K canvas arrives before a
  phone-shaped frame; portrait/landscape rotation; unresolved placement
  persistence; fullscreen media; and actual inner photo size;
- Photos may still place a small image and black bars inside a `3840x2160`
  encoded canvas. Raw geometry diagnostics do not provide a validated content
  rectangle, so this release does not crop or zoom those pixels;
- an external GStreamer window cannot yet provide a Mac-style hover-only frame,
  true borderless surface, or live aspect lock while dragging. Those require a
  native embedded renderer plus versioned IPC;
- continuity does not make iOS browse-cache refresh instantaneous, and a dark
  fallback remains necessary when safe renderer capture is unavailable;
- the mirror-focused feature advertisement remains a physical experiment; its
  effect on direct-in-Photos startup has not been accepted;
- genuine AirDrop interoperability remains separate Bluetooth/AWDL, identity,
  and encrypted-transfer research. A staged AeroDrop companion/share-extension
  path is a separate future product decision, not part of 0.12.6;
- localization is not included. D-006 remains the planned resource-based
  system-language and manual override design.

## Immediate next steps

1. Install public 0.12.5 and use its in-app updater to discover, download, and
   install public 0.12.6; retain migration, persistence, Setup, runtime-cache,
   and rollback evidence.
2. Run the physical Direct3D 11 versus Direct3D 12, Photos, interruption,
   reconnect, delayed-discovery, and Windows 10/11 matrix in
   `docs/releases/0.12.6/TEST_PLAN.md`, preserving redacted log intervals,
   screenshots, and recordings.
3. Correct any failed scenario in 0.12.7 or later. Never modify the immutable
   0.12.6 tag or assets, and do not use a 1.0 designation until D-008 physical
   acceptance is complete.

## Where information belongs

- mandatory patch documentation: `docs/DOCUMENTATION_POLICY.md`;
- current handoff and immediate next step: this file;
- durable technical/product decisions: `docs/DECISIONS.md`;
- implementation backlog and acceptance targets: `docs/TODO.md`;
- component boundaries: `docs/ARCHITECTURE.md`;
- release/update/signing rules: `docs/RELEASE_AND_SIGNING.md`;
- user-visible release history: `CHANGELOG.md`;
- versioned release evidence and acceptance: `docs/releases/<version>/`;
- troubleshooting and log collection: `docs/TROUBLESHOOTING.md`.
