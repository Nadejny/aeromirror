# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Latest public release

- Version: `v0.12.3`
- Tag commit: `334001a8fa896c8e072465e624fda4f150ffa666`
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.12.3
- Published: `2026-08-09T23:10:49Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` public review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn

The `v0.12.3` tag and its four public assets are immutable. Exact evidence is
in `docs/releases/0.12.3/BUILD_REPORT.md`. Historical 0.12.2, 0.12.1, 0.12.0,
and 0.11 release documents remain unchanged evidence.

## Current candidate

- Version: `0.12.4`
- Status: candidate implementation, mandatory documentation, managed/native
  builds, provenance, review payload, and Setup verification pass; not tagged
  or published yet
- Publication authorization: a normal updater-visible review Release is
  authorized after the remaining clean exact-tag packaging gate passes
- Physical acceptance: pending on Windows 10/11 plus iPhone; this candidate is
  not accepted, stable, or 1.0 based on automated checks alone
- Release notes: `docs/releases/0.12.4/RELEASE_NOTES.md`
- Test plan: `docs/releases/0.12.4/TEST_PLAN.md`

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

The upstream revision and third-party runtime remain pinned. The candidate's
reviewed native patch, rebuilt core, modified-source hashes, build inputs,
updated provenance, and prepared corresponding source validate together.

## Verification status

Passed against the current 0.12.4 candidate source:

1. managed x64 build and receiver resilience suite;
2. native rebuild plus `UPSTREAM.lock` commit/patch/core-hash consistency and
   patch/source/input/core-hash provenance validation;
3. thin review payload, Setup build, and installer lifecycle verification;
4. shell, Setup PE, internal Setup version, script-default, asset-name,
   documentation-version, local-link, and changed-file audits;
5. `git diff --check`.

Still pending:

1. a clean exact `v0.12.4` tag and release package with exactly four permitted
   assets;
2. GitHub channel, public re-download, byte-size, SHA-256, and API digest
   verification after publication;
3. installed update and all physical Windows/iPhone tests.

No physical Windows/iPhone result is claimed by the current automated work.

## Pending physical verification and known limitations

- Windows 11 x64 and Windows 10 1809+ x64 with an iPhone: 3–4 second,
  5–8 second, and longer-than-15-second Wi-Fi interruptions; native in-place
  recovery; fatal recovery; normal disconnect; immediate and repeated
  reconnect; delayed Wi-Fi join; idle discovery; and VPN-over-Private-LAN;
- saved placement at first show, handoff fade, mixed-DPI/multi-monitor restore,
  taskbar/topmost settings, manual resize, safe snapshot, privacy fallback,
  and no focus theft or Z-order flicker;
- Balanced versus Interactive plus Automatic, Direct3D 11, and Direct3D 12
  frame-pacing, audio drift, CPU/GPU, feedback-gap, and decoder/sink evidence;
- direct-in-Photos startup, portrait/landscape rotation, fullscreen media, and
  actual inner photo size;
- Photos may still place a small image and black bars inside a `3840x2160`
  encoded canvas. Raw geometry diagnostics do not provide a validated content
  rectangle, so this candidate does not crop or zoom those pixels;
- an external GStreamer window cannot yet provide a Mac-style hover-only frame,
  true borderless surface, or live aspect lock while dragging. Those require a
  native embedded renderer plus versioned IPC;
- continuity does not make iOS browse-cache refresh instantaneous, and a dark
  fallback remains necessary when safe renderer capture is unavailable;
- genuine AirDrop interoperability remains separate Bluetooth/AWDL, identity,
  and encrypted-transfer research. A staged AeroDrop companion/share-extension
  path is a separate future product decision, not part of 0.12.4;
- localization is not included. D-006 remains the planned resource-based
  system-language and manual override design.

## Immediate next steps

1. Commit the reviewed candidate, create an exact `v0.12.4` tag, and run the
   clean exact-tag packaging gate in `docs/releases/0.12.4/TEST_PLAN.md`.
2. Publish `v0.12.4` only if that remaining gate passes, verify every public
   asset, then
   add `docs/releases/0.12.4/BUILD_REPORT.md` and update this file.
3. Run the installed 0.12.3-to-0.12.4 update and complete the physical Windows
   10/11 plus iPhone matrix. Correct any defect in 0.12.5 or later; never move
   a published tag or replace an existing release asset.

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
