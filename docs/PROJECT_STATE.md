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
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.12.3` tag and its four assets are immutable. Any correction must use
`0.12.4` or a later version; never move the tag or replace a published file.
Exact evidence is recorded in `docs/releases/0.12.3/BUILD_REPORT.md`.

The immutable 0.12.2, 0.12.1, and 0.12.0 releases and their verification remain
under `docs/releases/`. Historical 0.11 tags, assets, plans, and build reports
also remain unchanged release history.

## What 0.12.3 changes

- A confirmed fatal stream loss opens a managed continuity placeholder at the
  renderer's last bounds. A safely visible foreground frame is softened and
  kept only in process memory; otherwise a dark fallback is used. The
  placeholder survives bounded native discovery renewal and closes on a new
  mirroring start, explicit user close, receiver stop, or application exit.
  Benign feedback warnings and clean disconnects do not open it.
- Normal renderer bounds and their DPI persist after a valid initial/manual
  fit, move, or resize. A later session scales the saved size for its target DPI
  and clamps stale, oversized, or disconnected-monitor bounds into an available
  Windows work area. Automatic fitting preserves restored center and area.
- An early phone-shaped raw video marker is retained before the 350 ms debounce.
  The recorded direct-in-Photos `998x2160` then `3840x2160` startup sequence no
  longer lets the media canvas steal the portrait device baseline.
- The tray fallback is **Restore window proportions**, and the settings Back
  control has a larger arrow and hit target.

The pinned native UxPlay executable, third-party runtime, receiver identity and
trust state, update protocol, localization status, and Public/Unknown physical-
network fail-closed policy are unchanged.

## Release verification

Passed against the exact source published as `v0.12.3`:

1. managed x64 shell build and receiver resilience suite;
2. placeholder source/privacy, version/link, settings-schema, renderer-window,
   and WinEvent callback audits;
3. review payload, Setup build, and installer lifecycle verification;
4. prepared native corresponding-source packaging and pinned-provenance
   validation;
5. clean exact-tag release packaging and `git diff --check`;
6. normal latest GitHub channel with `draft=false`, `prerelease=false`, and
   exactly four expected assets;
7. public re-download byte sizes and SHA-256 values match local release files,
   and all four GitHub API digest fields match.

No physical Windows/iPhone result is claimed by these gates. Exact asset
evidence is in `docs/releases/0.12.3/BUILD_REPORT.md`.

## Pending physical verification and known limitations

- the installed updater path from public 0.12.2 to 0.12.3, including settings,
  trust state, shortcuts, autostart, runtime-cache reuse, digest verification,
  and Setup launch;
- Windows 11 x64 and Windows 10 1809+ x64 with an iPhone: fatal Wi-Fi loss,
  persistent placeholder, quick recovery, manual dismissal, clean disconnect,
  first reconnect, and repeated reconnect timing;
- saved bounds, initial/manual/automatic fit, move-only persistence,
  minimize/maximize exclusion, taskbar/always-on-top policy, offline-monitor
  clamping, and mixed-DPI restoration;
- direct-in-Photos startup, physical portrait/landscape rotation, fullscreen
  media, and the actual inner photo size;
- a Photos `3840x2160` canvas may contain the photo and black bars inside the
  encoded pixels. AeroMirror can keep the outer phone orientation but has no
  native content rectangle or validated pixel-analysis crop, so the image may
  remain very small;
- a session that emits only a generic media canvas and no early phone-shaped
  marker remains ambiguous;
- the continuity placeholder does not accelerate iOS discovery. A stale row
  can still fail before reaching Windows, and native same-port DNS-SD/BLE
  re-publication remains future work;
- localization is not included. D-006 remains the planned resource-based
  system-language and manual override design.

## Immediate next steps

1. Install public 0.12.2, use its in-app updater to find and install 0.12.3,
   and record the complete upgrade result.
2. Run the physical Windows 11 and Windows 10/iPhone matrix in
   `docs/releases/0.12.3/TEST_PLAN.md`, preserving redacted log intervals and
   screenshots as manual evidence.
3. Correct any defect in 0.12.4 or later; never modify the immutable 0.12.3
   tag or public assets. Do not use a 1.0 designation until D-008 physical
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
