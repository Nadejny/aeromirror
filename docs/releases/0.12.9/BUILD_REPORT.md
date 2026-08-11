# Build report — AeroMirror 0.12.9

Release `v0.12.9` was built from commit
`b807d5dece26e972c58a3a2f7e5585dc8075672e` and tree
`a2f49d66039c79bdc72907a9cefe6833d4e0257d`. Its annotated tag object is
`10deba1d48482da3500cf0bd7c796c87c7fce736`. The tag and GitHub Release were
created at `2026-08-11T19:14:44Z`; the Release was published at
`2026-08-11T19:25:27Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.9

GitHub Release ID: `368804215`.

AeroMirror project policy treats the published tag and all four assets as
immutable release history. GitHub reports API `immutable=false`, so this is a
project guarantee rather than a platform-enforced lock. Any correction must
use a later patch version; do not move the tag or replace an asset under
0.12.9. Version 0.12.8 remains untagged and unpublished. Published 0.12.7 and
its four assets remain immutable historical evidence.

## Release channel

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- GitHub API `immutable`: `false`; immutability is AeroMirror project policy
- Latest updater-visible Release: `v0.12.9`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Both canonical `pyram1da/aeromirror` and configured legacy
`Nadejny/aeromirror` latest API, HTML, and Setup routes resolved to Release ID
`368804215` and tag `v0.12.9`. Setup bytes downloaded through those routes
matched the final local Setup below. This proves updater-facing release
discovery and public asset identity through both repository slugs. It does not
prove Setup execution, installed-state preservation, rollback, iPhone
discovery, Photos behavior, or reconnect behavior.

At publication, the GitHub Release body matched the exact curated release
notes stored in the tagged source at
`docs/releases/0.12.9/RELEASE_NOTES.md`.

## Pre-tag and exact-tag verification

The exact source resolved by annotated tag `v0.12.9` passed:

- final managed x64 shell build and complete receiver resilience suite;
- independent source review with no P0/P1/P2 finding;
- shell and Setup PE/file version `0.12.9.0`, Setup internal comparison
  version `0.12.9`, five release-script defaults, settings schema 12, and the
  default-false Photos/media option migration;
- bounded idle/SessionUnlock discovery cases, exact Photos/media canvas A/B
  cases, and inherited current-PID/session/epoch/reason/gap Direct3D 11
  presentation-proof cases;
- reused native core SHA-256
  `eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`;
- reviewed patch/current-source/protected-audio hashes, both reverse-apply
  checks, runtime dependency inspection and collection, native-source
  provenance, and loader test;
- redistributed GStreamer 1.28.1 runtime contract recorded separately from
  the GStreamer 1.28.5 native build toolchain;
- prepared native corresponding source with exactly 143 archive entries and
  139 files; a rebuild from the extracted archive reproduced the same native
  core;
- thin review payload with exactly 13 expected entries;
- network Setup build, embedded-payload comparison, `/verify-runtime`, and
  shortcut/update lifecycle self-checks;
- source/default/documentation/local-link/strict-UTF-8/changed-file and
  `git diff --check` audits;
- clean exact-tag `release.ps1` packaging from annotated tag object
  `10deba1d48482da3500cf0bd7c796c87c7fce736`, resolving to commit
  `b807d5dece26e972c58a3a2f7e5585dc8075672e`.

The principal automated entry points were:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\release.ps1 `
  -Version 0.12.9 -SourceRef v0.12.9
```

These gates prove source, deterministic behavior replays, build, packaging,
installer logic, corresponding-source completeness, and provenance integrity.
They do not replace a physical Windows 10/11 and iPhone test.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding final local release file. GitHub's API
digest for every asset matched the same local and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.9.exe` | 1,291,264 | `0598d1026a27fd3f0513e33b6e98ed48ba103ba713b61988abbeeb5a70b4493f` |
| `AeroMirror-source-0.12.9.zip` | 1,942,380 | `3ac07b3d7c2eba2dd5185cd42d2e2c9f22d7d77e152d33df895cdf0e719f12e5` |
| `AeroMirror-native-source-0.12.9.zip` | 707,743 | `7d21d26e294a22a396f935e5ac4669ca253547b84746b56582b2855ebc4b2bdb` |
| `SHA256SUMS.txt` | 294 | `444d5e0bc168004ac7b00f61220061b5ba4c2b2c6c35b0a539a311611592ce77` |

`SHA256SUMS.txt` contains exactly the three non-checksum public assets. The
Release contains no unexpected fifth asset. The AeroMirror source archive is
the exact tagged project source and includes its license, third-party notices,
upstream lock, native patches, and provenance records. The native-source
archive contains the prepared pinned upstream source, both reviewed AeroMirror
patches separately and already applied, build inputs, licenses, and provenance
needed to reproduce and validate the released native core.

## Acceptance status

Accepted:

- exact annotated-tag source, tree, and `release.ps1` packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- canonical and configured legacy latest API, HTML, and Setup routes resolving
  to the same `v0.12.9` Release ID, tag, and Setup bytes;
- exact four-asset set, byte sizes, local and fresh re-download hashes,
  checksum file entries, and all GitHub API digest fields;
- GitHub Release body matching the exact tagged release notes at publication;
- managed build, resilience, independent review, version/document/link,
  package-content, strict-UTF-8, and whitespace gates;
- review payload, Setup build and lifecycle checks, embedded-payload hash,
  native corresponding-source, extracted rebuild, loader, and provenance
  gates.

Pending:

- actual installed in-place update from public 0.12.7 to public 0.12.9,
  including settings, receiver identity/trust, shortcuts, autostart,
  runtime-cache reuse, digest verification, Setup launch, and rollback;
- Windows 11 and Windows 10 1809+ long-idle discovery: first ten-minute
  renewal, later SessionUnlock, one guarded final refresh, repeated-unlock
  limit, iPhone browse, first-tap behavior, and any manual workaround;
- the schema-12 Photos/media outer-window A/B with identical content, measured
  outer client bounds and inner visible content, saved-placement behavior, and
  session stability;
- short and longer Wi-Fi interruptions, current presentation proof, manual
  Screen Mirroring reselection, real resumed video, and persistent reconnect
  guidance when proof is absent;
- clean Windows 10 first install without reboot, retaining pre-reboot Setup and
  receiver logs plus Bonjour service/process state before any workaround;
- the complete repeated Windows 10/11 and iPhone matrix in
  [`TEST_PLAN.md`](TEST_PLAN.md).

The bounded unlock refresh is a symptom mitigation, not proof of the original
discovery cause, stable-port re-publication, or iOS browse-cache invalidation.
The experimental Photos option changes only the outer renderer window; inner
media may remain small. The inherited presentation-proof gate prevents a false
continuity handoff but does not repair the underlying longer-gap frozen-video
path. The Windows 10 reboot report and stopped/stale Bonjour hypothesis remain
unverified.

No new physical Windows/iPhone acceptance is inferred from the public build,
asset checks, or prior 0.12.7 observations. A failed pending scenario must be
corrected in a later patch without modifying the 0.12.9 tag or assets.
