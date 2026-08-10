# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Latest public release

- Version: `v0.12.5`
- Tag commit: `22ec7536062679b2e90f47d5174c970f3f6b587f`
- Release URL: https://github.com/pyram1da/aeromirror/releases/tag/v0.12.5
- Published: `2026-08-10T10:32:59Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` public review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.12.5` tag and its four assets are immutable. Any correction must use
0.12.6 or later; never move the tag or replace a published file. Exact evidence
is recorded in `docs/releases/0.12.5/BUILD_REPORT.md`.

The immutable 0.12.4, 0.12.3, 0.12.2, 0.12.1, 0.12.0, and 0.11 releases and
their verification remain under `docs/releases/` or the historical 0.11
report paths.

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

Passed against the exact source published as `v0.12.5`:

1. managed x64 shell build and receiver resilience suite;
2. prepared native source with 139 files and all 12 provenance hashes, with
   the released native core byte-identical to 0.12.4;
3. exact 13-entry thin review payload, Setup build, embedded-payload SHA-256,
   and shortcut/update lifecycle verification;
4. shell, Setup PE, internal Setup version, script-default, asset-name,
   documentation-version, local-link, changed-file, and `git diff --check`
   audits;
5. clean exact-tag release packaging;
6. normal latest GitHub channel with `draft=false`, `prerelease=false`, and
   exactly four expected assets;
7. public re-download byte sizes and SHA-256 values match local release files,
   and all four GitHub API digest fields match;
8. the configured old updater API and Setup download URLs redirect to the
   canonical repository and expose/download 0.12.5 successfully.

No physical Windows/iPhone result is claimed by these gates. Exact asset
evidence is in `docs/releases/0.12.5/BUILD_REPORT.md`.

## Pending physical verification and known limitations

- the installed updater path from public 0.12.4 to public 0.12.5, including
  settings, trust state, shortcuts, autostart, runtime-cache reuse, digest
  verification, Setup launch, and rollback;
- Windows 11 x64 and Windows 10 1809+ x64 with an iPhone: 3–4 second,
  5–8 second, and longer-than-15-second Wi-Fi interruptions; native in-place
  recovery; fatal recovery; normal disconnect; immediate and repeated
  reconnect; delayed Wi-Fi join; idle discovery; and VPN-over-Private-LAN;
- saved placement at first show, handoff fade, mixed-DPI/multi-monitor restore,
  taskbar/topmost settings, manual resize, safe snapshot, privacy fallback,
  and no focus theft or Z-order flicker;
- Balanced versus Interactive plus Automatic, Direct3D 11, and Direct3D 12
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
- genuine AirDrop interoperability remains separate Bluetooth/AWDL, identity,
  and encrypted-transfer research. A staged AeroDrop companion/share-extension
  path is a separate future product decision, not part of 0.12.5;
- localization is not included. D-006 remains the planned resource-based
  system-language and manual override design.

## Immediate next steps

1. Install public 0.12.4 and use its in-app updater to discover, download, and
   install public 0.12.5; record persistence, Setup, and rollback evidence.
2. Run the physical Windows 11 and Windows 10/iPhone matrix in
   `docs/releases/0.12.5/TEST_PLAN.md`, preserving redacted log intervals,
   screenshots, and recordings.
3. Correct any defect in 0.12.6 or later; never modify the immutable 0.12.5
   tag or assets, and do not use a 1.0 designation until D-008 physical
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
