# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Local candidate

- Candidate version: `0.12.3`
- Status: integrated local working tree; not committed, tagged, or published
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Native core: unchanged pinned build first shipped in 0.11.1
- Public channel: still serves immutable `v0.12.2`

The 0.12.3 candidate keeps a persistent managed placeholder after a confirmed
fatal stream loss. It uses a softened screen snapshot only when the renderer
is visibly in the foreground; otherwise it shows a dark fallback. The image is
memory-only, the placeholder survives the bounded native discovery renewal,
and it closes on a new mirroring start, explicit user close, receiver stop, or
application exit. Benign feedback warnings and ordinary clean disconnects do
not open it.

The candidate also persists normal renderer bounds and their DPI, restores
them on the next session, scales for monitor-DPI changes, and clamps a stale or
oversized placement into an available work area. Automatic fitting preserves
the restored center and approximate client area. An early phone-shaped raw
video marker is now retained before the 350 ms stability debounce, preventing
the recorded direct-in-Photos `998x2160` then `3840x2160` startup sequence from
using the media canvas as its device baseline.

The tray fallback is renamed **Restore window proportions**, and the settings
Back control has a larger arrow and hit target. Localization is not part of
this patch; D-006 remains the planned resource-based system-language/manual-
override design.

## Latest public release

- Version: `v0.12.2`
- Tag commit: `36de759c5f8a9443a60b46b87392fed445eb76c3`
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.12.2
- Published: `2026-08-09T22:16:12Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` public review Release
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.12.2` tag and its four assets are immutable. Any correction uses
`0.12.3` or a later version; never move the tag or replace a published file.
Exact 0.12.2 evidence remains in
`docs/releases/0.12.2/BUILD_REPORT.md`.

## Candidate verification

The integrated 0.12.3 managed x64 build and receiver resilience suite pass,
including placeholder state/exclusion, early Photos-marker, renderer-placement,
settings-schema, WinEvent-callback, and existing regression assertions.
The foreground-only/memory-only placeholder source audit, current version/link
audit, `git diff --check`, review packaging, Setup/lifecycle verification, and
native corresponding-source validation also pass. The exact-tag release gate
remains pending. No tag or release asset exists yet. The acceptance matrix is
`docs/releases/0.12.3/TEST_PLAN.md`.

No physical Windows/iPhone result is claimed by source inspection or automated
checks.

## Known limitations and physical blockers

- The inner Photos presentation is not fully fixed. iOS may send a
  `3840x2160` encoded canvas with the photo and black bars already inside it.
  AeroMirror can keep the outer phone-shaped window, but the current stdout
  contract provides no safe content rectangle, crop metadata, or pixel-level
  signal with which to enlarge only the photo. Physical diagnostics and a
  native metadata or validated pixel-analysis design are still required.
- If a session provides only a generic media canvas and never emits an early
  phone-shaped marker, device orientation remains ambiguous; AeroMirror does
  not guess that a generic 16:9 canvas is an iPhone frame.
- The memory-only loss placeholder is a continuity aid, not a reconnection
  accelerator. An iOS stale-row tap may still fail before reaching Windows,
  and iOS may delay browse-cache refresh after the core is ready.
- Native same-port DNS-SD/BLE re-publication after internal reset remains a
  TODO; the managed shell still uses one bounded process renewal.
- Fatal-loss placeholder timing, quick Wi-Fi recovery, manual dismissal,
  clean-disconnect exclusion, saved bounds, offline-monitor clamping,
  mixed-DPI restoration, Photos startup, and physical rotation all require
  Windows 10/11 plus iPhone acceptance.

## Immediate next steps

1. Create and verify the exact immutable `v0.12.3` tag and four release assets.
2. The user has authorized publishing subsequent patch versions. Publish
   0.12.3 as a clearly
   labelled public review candidate; physical rows may remain pending and do
   not permit a 1.0 claim.
3. Run the complete physical matrix in
   `docs/releases/0.12.3/TEST_PLAN.md`, and record hashes and public re-download
   evidence in a post-release `BUILD_REPORT.md`
   without modifying 0.12.2.

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
