# Project state

Last updated: 2026-08-09

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Latest public release

- Version: `v0.12.0`
- Tag commit: `1a22d175810ff618e0f8c16102f1988d82a5fe10`
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.12.0
- Published: `2026-08-09T20:46:54Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The tag and its four assets are immutable. Any correction must use `0.12.1` or
a later version; never move `v0.12.0` or replace one of its published files.
Exact public evidence is recorded in
`docs/releases/0.12.0/BUILD_REPORT.md`.

Historical 0.11 tags, assets, test plans, and build reports remain unchanged
release history. The previous public verification is retained in
`docs/BUILD_REPORT_0.11.3.md`.

## What 0.12.0 changes

- Persisted pairing values are normalized so unknown, obsolete, and malformed
  PIN states become unprotected and therefore fail closed on a Public or
  Unknown physical Windows network.
- Unsupported quality, renderer, latency, audio, and theme values return to
  documented safe defaults.
- `settings.ini` is published through same-directory atomic replacement rather
  than a partially visible direct write.
- A stale end marker from the previous AirPlay session preserves the grace
  established by a newer request or PIN prompt, keeping deferred settings and
  network maintenance out of the reconnect handshake.
- The updater accepts only exact three-part public release tags.
- The managed shell is split into focused source files while remaining one
  `AeroMirror.exe` assembly with unchanged runtime identities and boundaries.
- Three unreachable legacy settings forms are removed; the active settings UI
  remains intact.

The native UxPlay executable, reviewed patches, runtime pins, provenance,
installed `core/uxplay-windows.exe` path, and separate-process boundary are
unchanged.

## Automated and public verification

Accepted for review distribution:

1. managed x64 shell build;
2. receiver resilience checks, including settings normalization, atomic save,
   strict tags, stale-end reconnect ordering, and recursive source layout;
3. review-payload packaging and Setup build, including shortcut-selection and
   update-lifecycle verifiers;
4. native corresponding-source and provenance validation;
5. exact PE, payload, tag, and public asset version checks;
6. `release.ps1` clean exact-tag packaging;
7. `git diff --check`;
8. independent review with no P0 or P1 findings;
9. public re-download of exactly four assets with matching byte sizes and
   SHA-256 values;
10. GitHub API digest fields for all four assets matching the local and
    re-downloaded SHA-256 values exactly.

GitHub reports `v0.12.0` as a normal latest Release with `draft=false` and
`prerelease=false`. This accepts the tag and public artifacts as a review
release only; it does not establish physical AirPlay interoperability.

## Physical verification status

All physical-device and installed-update gates for 0.12.0 remain **pending**.
Use `docs/releases/0.12.0/TEST_PLAN.md` and retain exact timings plus a short
redacted log for failures.

Required next environments:

- update an installed public 0.11.3 through the normal channel to 0.12.0;
- physical Windows 11 x64 + iPhone on Private and Public physical profiles,
  with VPN off and on;
- repeated clean immediate reconnect and iPhone Wi-Fi off/on recovery;
- installed settings normalization, PIN fail-closed behavior, and atomic-save
  regression;
- physical Windows 10 1809+ x64 + iPhone before a 1.0 designation.

A settings regression, incomplete save, receiver exposure on a Public/Unknown
network, reconnect interruption, updater failure, crash, or missing discovery
blocks physical acceptance and must be fixed in a new version.

## Immediate next steps

1. Use the public updater or Setup to update a real 0.11.3 installation to
   0.12.0 and confirm settings, trust state, shortcuts, and runtime cache are
   preserved.
2. Complete the Windows 11 + iPhone plan, including exact reconnect timings
   and VPN/network-profile cases, then update this file and the test matrix.
3. Repeat the physical plan on Windows 10 before describing AeroMirror as 1.0.
4. If a defect is found, prepare 0.12.1 or later; do not modify the 0.12.0 tag
   or assets.

## Where information belongs

- mandatory patch documentation: `docs/DOCUMENTATION_POLICY.md`;
- current handoff and immediate next step: this file;
- durable technical/product decisions: `docs/DECISIONS.md`;
- implementation backlog and acceptance targets: `docs/TODO.md`;
- component boundaries: `docs/ARCHITECTURE.md`;
- release/update/signing rules: `docs/RELEASE_AND_SIGNING.md`;
- user-visible release history: `CHANGELOG.md`;
- 0.12.0 release evidence and remaining acceptance:
  `docs/releases/0.12.0/`;
- troubleshooting and log collection: `docs/TROUBLESHOOTING.md`.
