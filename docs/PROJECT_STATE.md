# Project state

Last updated: 2026-08-09

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Public release

- Latest public release: `v0.11.3`
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.11.3
- Channel: normal GitHub Release labelled as a review candidate
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Update source: `Nadejny/aeromirror` through GitHub `releases/latest`
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The immutable `v0.11.3` tag points to commit
`aba4c98277f965ce8cf52cea46ff08c26605a03f`. Its public asset verification is
recorded in `docs/BUILD_REPORT_0.11.3.md`. Corrections must use a later version;
never move that tag or replace its assets.

## Local 0.12.0 review candidate

Status: integrated local review candidate; pre-tag automated gates pass; not
tagged, published, or physically accepted.

The candidate scope is:

- normalize persisted pairing values so unknown, obsolete, and malformed PIN
  states become unprotected and therefore fail closed on a Public or Unknown
  physical Windows network;
- normalize unsupported quality, renderer, latency, audio, and theme values
  to documented safe defaults;
- replace `settings.ini` atomically rather than exposing a partially written
  new configuration;
- preserve a newer AirPlay request or PIN-entry grace period when a stale end
  marker arrives from the previous session;
- accept only exact three-part GitHub update tags;
- split the managed shell into focused source files while keeping one
  `AeroMirror.exe` assembly and all runtime identities and boundaries intact;
- remove three unreachable legacy settings forms after the active UI path is
  separated.

The native UxPlay executable, its reviewed patches, runtime pins, provenance,
installed `core/uxplay-windows.exe` path, and process boundary are unchanged.

## Automated verification status

The integrated local 0.12.0 candidate passes:

1. the managed x64 shell build;
2. receiver resilience checks, including settings normalization, atomic save,
   strict update tags, stale-end reconnect ordering, and the recursive source
   layout;
3. review-payload packaging and the 0.12.0 Setup build, including the
   installer's shortcut and update-lifecycle verifiers;
4. native provenance and corresponding-source archive validation with the
   unchanged pinned core;
5. PE version checks for both shell and Setup (`0.12.0.0`);
6. `git diff --check`.

Exact-tag release packaging and public-download verification remain pending
until the candidate is committed, tagged, and published.

No 0.12.0 build report, public asset sizes, SHA-256 digests, re-download
results, or accepted release commit exist yet. Add
`docs/releases/0.12.0/BUILD_REPORT.md` only after publication and public-asset
verification.

## Physical verification status

All physical-device gates for 0.12.0 are **pending**. Automated checks cannot
establish Windows/iPhone interoperability.

The focused plan is `docs/releases/0.12.0/TEST_PLAN.md`. At minimum it must be
run on:

- a physical Windows 11 x64 PC with an iPhone;
- a physical Windows 10 1809+ x64 PC with an iPhone before a 1.0 designation;
- Private and Public physical network profiles, with VPN enabled and disabled;
- an in-place update from the latest public review release.

A settings regression, incomplete or corrupted save, receiver exposure on a
Public/Unknown network, reconnect interruption, updater misclassification,
crash, or missing discovery blocks acceptance.

## Immediate next steps

1. Commit and tag the reviewed 0.12.0 candidate without changing published
   0.11.3 history.
2. Build the exact-tag release assets, publish the explicitly authorized
   review candidate, re-download every asset, and add the versioned build
   report.
3. Install/update through the public channel and complete the Windows 11 +
   iPhone scenarios, then record timings and redacted logs.
4. Complete the Windows 10 physical plan before describing the project as 1.0.

## Where information belongs

- mandatory patch documentation: `docs/DOCUMENTATION_POLICY.md`;
- current handoff and immediate next step: this file;
- durable technical/product decisions: `docs/DECISIONS.md`;
- implementation backlog and acceptance targets: `docs/TODO.md`;
- component boundaries: `docs/ARCHITECTURE.md`;
- release/update/signing rules: `docs/RELEASE_AND_SIGNING.md`;
- user-visible release history: `CHANGELOG.md`;
- versioned release text and acceptance: `docs/releases/<version>/`;
- troubleshooting and log collection: `docs/TROUBLESHOOTING.md`.
