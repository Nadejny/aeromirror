# Project state

Last updated: 2026-08-09

This is the single current-state handoff for AeroMirror. Keep it concise and
update it when release status, accepted tests, blockers, or the immediate next
step changes.

## Current release

- Latest public release: `v0.11.1`
- Release type: normal GitHub Release labelled as a review candidate
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.11.1
- Supported target: Windows 10 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Update channel: `Nadejny/aeromirror` through GitHub `releases/latest`
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.11.1` tag is immutable project history. Any correction discovered
after publication must use `0.11.2` or a later version; do not replace the
published 0.11.1 files.

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

See `docs/BUILD_REPORT_0.11.1.md` for the candidate build record.

## Manual acceptance still required

Follow `docs/TEST_PLAN_0.11.1.md` on at least one physical Windows 10 PC and
one physical Windows 11 PC. The highest-priority scenarios are:

1. Windows/AeroMirror starts before Wi-Fi becomes available.
2. VPN enabled and disabled over the same physical LAN.
3. Three consecutive connect/stream/disconnect cycles.
4. iPhone or physical-network loss during active mirroring.
5. In-place update from 0.11.0 with all shortcut combinations.

A crash, missing rediscovery, or recovery substantially slower than the
documented bound blocks the 1.0 designation and should include a redacted log.

## Immediate next steps

1. Collect and record the user's Windows 11 results and the friend's Windows 10
   results for 0.11.1.
2. If a release defect is found, ship a focused `0.11.2` patch.
3. If the stability gate passes, begin 0.12 development with an explicit
   repository-structure plan before moving files.
4. Introduce resource-based UI localization in 0.12: follow the Windows
   display language by default and offer `System / English / Russian` in
   settings.
5. Keep AirDrop-style transfer and iPhone remote control as later, separate
   research tracks after the receiver is reliable.

## Where information belongs

- current handoff and immediate next step: this file;
- durable technical/product decisions: `docs/DECISIONS.md`;
- implementation backlog and acceptance targets: `docs/TODO.md`;
- component boundaries: `docs/ARCHITECTURE.md`;
- release/update/signing rules: `docs/RELEASE_AND_SIGNING.md`;
- user-visible release history: `CHANGELOG.md`;
- troubleshooting and log collection: `docs/TROUBLESHOOTING.md`.
