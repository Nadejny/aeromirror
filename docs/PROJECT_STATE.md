# Project state

Last updated: 2026-08-09

This is the single current-state handoff for AeroMirror. Keep it concise and
update it when release status, accepted tests, blockers, or the immediate next
step changes.

## Current release

- Latest public release: `v0.11.2`
- Release type: normal GitHub Release labelled as a review candidate
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.11.2
- Supported target: Windows 10 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Update channel: `Nadejny/aeromirror` through GitHub `releases/latest`
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.11.2` tag is immutable project history. Any correction discovered
after publication must use `0.11.3` or a later version; do not replace the
published 0.11.2 files.

## Published 0.11.2 review patch

- Release commit: `f9fd5c48ef24435a08da5c6ee438410fd6e19aed`
- Root cause: an update launched from AeroMirror 0.11.0 or 0.11.1 could
  start Setup with the installed application directory as its inherited
  working directory. Setup then fails while moving that directory with a
  "file is being used by another process" error.
- Failure point: before the old installation is replaced; the existing
  installation remains intact.
- Fix: move Setup's working directory outside the installation before
  replacement, launch future Setup versions with an explicit safe working
  directory, bound path-scoped process shutdown, and retry short-lived
  directory locks.
- Acceptance plan: `docs/TEST_PLAN_0.11.2.md`

## Pending 0.11.3 reconnect patch

- Candidate version: `0.11.3` (local development; not yet public)
- Confirmed blocker: after a normal disconnect, or after iPhone Wi-Fi is
  turned off and on, the first reconnect can wait for 20–30 seconds and fail
  while a second attempt succeeds.
- Root cause: the shell schedules a full native-core restart after session
  completion even when the receiver has already recovered and is healthy.
  Restarting changes the listening endpoints while the iPhone may still hold
  the previous DNS-SD advertisement.
- Patch scope: keep a healthy receiver registered across normal disconnects;
  re-arm its single bounded ten-minute idle-discovery fallback and postpone
  deferred settings maintenance on a high-level AirPlay request; cancel
  pending post-session maintenance when mirroring actually starts; retain
  bounded recovery for confirmed fatal failures; and retain a separate,
  at-most-once ten-minute idle discovery renewal.
- Native core: the reviewed 0.11.1 executable and pinned runtime are reused
  unchanged.
- Acceptance plan: `docs/TEST_PLAN_0.11.3.md`

## What 0.11.1 addresses

- bounded recovery after a lost or stalled iPhone mirroring session;
- bounded native process-tree shutdown instead of indefinite waits;
- delayed startup until a physical Wi-Fi/Ethernet IPv4 is usable;
- BLE discovery bound to the physical LAN rather than a VPN route;
- explicit DNS-SD/BLE diagnostics and deferred discovery refresh;
- stable receiver identity across starts;
- clearer Report a problem flow and smaller tooltip hit areas;
- preservation of existing shortcut choices during Setup updates.

## Verified automatically

- C# shell build;
- native loader/self tests and reviewed core provenance;
- receiver resilience checks, including lost-session recovery and network
  event handling;
- installer shortcut-selection scenarios;
- UI smoke and renderer-sizing probes;
- exact public asset names, sizes, and GitHub SHA-256 digests.

See `docs/BUILD_REPORT_0.11.2.md` for the release build record.

The 0.11.2 shell build, receiver resilience checks, installer build, shortcut
selection verifier, update-lifecycle verifier, and an explicit candidate run
with Setup's inherited working directory inside the installed AeroMirror tree
all pass locally on Windows 11. GitHub `releases/latest` returns `v0.11.2`, and
all four downloaded public assets match the files built from the release tag.
The physical Windows 10 acceptance run remains pending.

The local 0.11.3 candidate passes the C# shell build, receiver resilience
checks, package review, installer build, and `git diff --check`. A candidate
Setup executable was built locally. These automated gates do not establish
iPhone interoperability: the physical Windows 11 and iPhone reconnect cases
in `docs/TEST_PLAN_0.11.3.md` remain pending. No 0.11.3 tag, GitHub Release,
or public asset has been created or accepted.

## Manual acceptance still required

The automated and provenance gates allow the still-unpublished 0.11.3 build to
be published only as an explicitly labelled review candidate and only with
explicit user authorization. Use that candidate to run
`docs/TEST_PLAN_0.11.3.md` on a physical Windows 11 PC before accepting the
reconnect patch, then repeat it on a physical Windows 10 PC before 1.0. The
published 0.11.2 update regression plan and the broader receiver acceptance in
`docs/TEST_PLAN_0.11.1.md` also remain required. The highest-priority scenarios
are:

1. Five clean disconnect/immediate-reconnect cycles without a core restart.
2. First-attempt recovery after iPhone Wi-Fi is turned off and on.
3. Weak Wi-Fi without a false full-core reset.
4. Discovery after ten minutes idle, before and after a completed session.
5. Private/Public physical-network and optional/required PIN behavior, with
   VPN enabled and disabled.
6. In-app updates without the 0.11.2 installed-directory lock regression.

A crash, missing rediscovery, or recovery substantially slower than the
documented bound blocks the 1.0 designation and should include a redacted log.

## Immediate next steps

1. Publish a new immutable normal `v0.11.3` Release only as an explicitly
   labelled review candidate, with explicit user authorization, now that the
   automated and provenance gates pass; never replace the public 0.11.2 assets.
2. Run `docs/TEST_PLAN_0.11.3.md` with the user's iPhone on physical Windows
   11, including exact reconnect timings and a redacted log.
3. Repeat the plan on physical Windows 10 and complete the remaining 0.11.2
   in-place-update acceptance cases before 1.0.
4. If the stability gate passes, begin 0.12 development with an explicit
   repository-structure plan before moving files.
5. Introduce resource-based UI localization in 0.12: follow the Windows
   display language by default and offer `System / English / Russian` in
   settings.
6. Keep AirDrop-style file transfer and iPhone remote control as later, separate
   research tracks after the receiver is reliable.

## Where information belongs

- current handoff and immediate next step: this file;
- durable technical/product decisions: `docs/DECISIONS.md`;
- implementation backlog and acceptance targets: `docs/TODO.md`;
- component boundaries: `docs/ARCHITECTURE.md`;
- release/update/signing rules: `docs/RELEASE_AND_SIGNING.md`;
- user-visible release history: `CHANGELOG.md`;
- troubleshooting and log collection: `docs/TROUBLESHOOTING.md`.
