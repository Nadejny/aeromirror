# Build report — AeroMirror 0.12.5

Release `v0.12.5` was built from commit
`22ec7536062679b2e90f47d5174c970f3f6b587f` and published at
`2026-08-10T10:32:59Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.5

The tag and all four assets are immutable release history. Any correction must
use `0.12.6` or a later version; do not move the tag or replace an asset under
0.12.5.

## Release channel and repository redirect

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.5`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

The checked-in updater slug remains `Nadejny/aeromirror` for this immutable
release. GitHub redirects that former repository to the canonical repository.
An unauthenticated request to the old `releases/latest` API followed the
redirect and returned `v0.12.5` with `draft=false`, `prerelease=false`, and the
canonical Setup asset URL. The old Setup download URL also followed redirects
and returned HTTP 200 with `Content-Length: 1267712`.

This proves updater-facing release discovery and download reachability through
the configured legacy slug. It does not prove the complete installed
0.12.4-to-0.12.5 update, Setup execution, state preservation, or rollback.

## Pre-tag and exact-tag verification

The exact source that became the release tag passed:

- managed x64 shell build and receiver resilience suite;
- shell and Setup PE/file version `0.12.5.0`;
- source defaults, internal Setup version, asset-name, documentation-version,
  changed-file, local-link, and `git diff --check` audits;
- thin review payload with exactly 13 expected entries;
- network Setup build, embedded review-payload SHA-256 comparison, and
  shortcut/update lifecycle self-checks;
- prepared native corresponding-source build with 139 files and all 12
  provenance hashes validated;
- released native core byte-identical to the reviewed 0.12.4 core;
- clean exact-tag `release.ps1` packaging from `v0.12.5`.

These gates accept source, managed behavior replays, build, packaging,
installer, and provenance integrity. They do not substitute for a physical
Windows 10/11 and iPhone test.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding local release file. GitHub's API digest for
all four assets exactly matched the same local and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.5.exe` | 1,267,712 | `143fa403c0e144c5dd3f33fbe5d150162b051860b77d30da4283b2db69546638` |
| `AeroMirror-source-0.12.5.zip` | 1,836,129 | `cb19ac598f3ffc687ad8b3556fa952cad8d80db4e3d3d0d530811ab4a030fa83` |
| `AeroMirror-native-source-0.12.5.zip` | 691,327 | `ee499216805e9c633f39986526eb776e0de1ee79495d129ae4768ed1b1ba4c36` |
| `SHA256SUMS.txt` | 294 | `4a42ca22445cdfe337598074343337f1e8cffea74fb7983e19cb8ccec83dcdbf` |

The Release contains no unexpected fifth asset. The native-source archive
contains the prepared pinned source, both reviewed AeroMirror patches, build
inputs, and provenance required to reproduce and validate the reused native
core.

## Acceptance status

Accepted:

- exact-tag source and `release.ps1` packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- updater API and Setup-download redirect from the configured former
  `Nadejny/aeromirror` slug to canonical `pyram1da/aeromirror`;
- exact public asset set, byte sizes, local and re-downloaded hashes, checksum
  file, and all GitHub API digest fields;
- managed build, resilience, version/document/link, package-content, and
  whitespace gates;
- review payload, Setup build and lifecycle checks, embedded-payload hash,
  native corresponding-source, and provenance gates.

Pending:

- installed in-place update through AeroMirror from public 0.12.4 to 0.12.5,
  including settings, receiver identity/trust, shortcuts, autostart,
  runtime-cache reuse, digest verification, Setup launch, and rollback;
- physical 3–4 second, 5–8 second, and longer-than-15-second Wi-Fi loss,
  transient and fatal continuity, same-process recovery, normal disconnect,
  delayed Wi-Fi join, idle discovery, VPN-over-Private-LAN, and repeated
  reconnect timing on Windows 11 and Windows 10 1809+ with an iPhone;
- physical Photos-first startup, portrait/landscape rotation, ambiguous-canvas
  handling, valid saved-placement preservation, explicit move/resize/manual
  fit persistence, mixed-DPI and multi-monitor restoration, and actual inner
  photo size;
- physical Balanced/Interactive and Automatic/Direct3D 11/Direct3D 12
  smoothness, audio drift, decoder/sink, feedback-gap, and CPU/GPU evidence;
- discovery-list visibility and first-tap behavior after delayed iPhone Wi-Fi
  join, Wi-Fi loss, normal stop, idle time, and manual discovery refresh.

The inner Photos `3840x2160` encoded canvas remains a known limitation: it may
contain the small photo and black bars as pixels. This release protects the
outer orientation and saved placement for the exact observed ambiguous
signature, but it has no validated content rectangle or pixel-analysis crop
and does not fix those inner pixels. Raw auxiliary geometry remains diagnostic
only and is not interpreted as crop, PAR, or rotation metadata.

Use `TEST_PLAN.md` for the remaining scenarios. No physical Windows/iPhone
compatibility claim is made by this public review release or build report. A
failed pending scenario must be corrected in 0.12.6 or later without modifying
the 0.12.5 tag or assets.
