# Build report — AeroMirror 0.12.6

Release `v0.12.6` was built from commit
`c860909ad9b6a1098d524142b111857e522a7104` and published at
`2026-08-10T12:06:22Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.6

GitHub Release ID: `367881011`.

AeroMirror project policy treats the published tag and all four assets as
immutable release history. GitHub does not enforce that policy for this
Release. Any correction must use `0.12.7` or a later version; do not move the
tag or replace an asset under 0.12.6.

## Release channel

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- GitHub API `immutable`: `false`; immutability is AeroMirror project policy
- Latest updater-visible Release: `v0.12.6`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Both the canonical `pyram1da/aeromirror` and configured legacy
`Nadejny/aeromirror` unauthenticated `releases/latest` API routes returned the
same `v0.12.6` Release ID `367881011`. This proves updater-facing release
discovery through the legacy repository slug. It does not prove Setup
execution, installed-state preservation, rollback, iPhone discovery, or
reconnect behavior.

## Pre-tag and exact-tag verification

The exact source that became `v0.12.6` passed:

- managed x64 shell build and combined receiver resilience suite;
- shell and Setup PE/file version `0.12.6.0`, Setup internal comparison
  version, and five release-script defaults;
- settings migration coverage for fresh D3D11, legacy automatic-to-D3D11,
  and preserved explicit D3D12 profiles;
- current-PID/same-port native HTTP reset state, failed-reset fallback,
  `TEARDOWN` disconnect, continuity z-order/fade cancellation, and exact
  feature-bit replay coverage;
- reproducible native core SHA-256
  `9f1fb168c882b1531400d2edbb4abd1277803c1971a20e9d5c4d7eff3e8498fc`;
- reviewed libuxplay patch SHA-256
  `ffdbe63f4944c10c26ea5c0e74fea5b5e4071b287f4bbd9fc2fdcfeafe2893db`
  and provenance SHA-256
  `de27f91e09fad3a2d52c4488c957091e569fa08a3ab44482b5383181e38d071b`;
- prepared native corresponding source with 139 files, provenance validation,
  reverse-apply checks, staged-dependency audit, and hidden loader test;
- thin review payload with exactly 13 expected entries;
- network Setup build, embedded-payload SHA-256 comparison, and
  shortcut/update lifecycle self-checks;
- source/default/asset-name/documentation-version/local-link/changed-file and
  `git diff --check` audits;
- clean exact-tag `release.ps1` packaging from `v0.12.6`.

These gates prove source, deterministic behavior replays, build, packaging,
installer logic, and provenance integrity. They do not replace a physical
Windows 10/11 and iPhone test.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding final local release file. GitHub's API
digest for every asset matched the same local and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.6.exe` | 1,272,320 | `38daf50f2dfe14973991e4eae782e4a97cc08e530639f02510482e99952ab149` |
| `AeroMirror-source-0.12.6.zip` | 1,859,161 | `df401ff877646d9596a797c06a10c08d5b27677def7d8a4b023e00665ddbcab2` |
| `AeroMirror-native-source-0.12.6.zip` | 693,498 | `3d959163ebbb895965750a261ddf19b4bd9767de1e407efc6ffd3c488250b687` |
| `SHA256SUMS.txt` | 294 | `07990a44501724b24ea63ad15a7abbd4366bba53ec8f414d44e5d23aabb807a8` |

The Release contains no unexpected fifth asset. The native-source archive
contains the prepared pinned source, reviewed AeroMirror patches, build
inputs, and provenance needed to reproduce and validate the released native
core.

## Acceptance status

Accepted:

- exact-tag source and `release.ps1` packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- canonical and configured legacy `releases/latest` API routes returning the
  same `v0.12.6` Release ID;
- exact four-asset set, byte sizes, local and re-downloaded hashes, checksum
  file, and all GitHub API digest fields;
- managed build, resilience, version/document/link, package-content, and
  whitespace gates;
- review payload, Setup build and lifecycle checks, embedded-payload hash,
  native corresponding-source, reproducibility, loader, and provenance gates.

Pending:

- installed in-place update through AeroMirror from public 0.12.5 to public
  0.12.6, including D3D11 migration, explicit D3D12 preservation, settings,
  receiver identity/trust, shortcuts, autostart, runtime-cache reuse, digest
  verification, Setup launch, and rollback;
- physical Direct3D 11 versus Direct3D 12 Photos and resolution-change A/B on
  Windows 11 and Windows 10 1809+ with an iPhone;
- direct-in-Photos startup, gallery/photo/video transitions, inner photo size,
  portrait/landscape rotation, and saved-placement behavior;
- 3–4 second, 5–8 second, and longer-than-15-second Wi-Fi interruption,
  continuity z-order and fade cancellation, native same-port reset, failed-
  reset fallback, clean `TEARDOWN`, fatal reconnect guidance, and repeated
  sequential sessions;
- delayed Wi-Fi join, idle discovery, VPN-over-Private-LAN, receiver-list
  visibility, first-tap behavior, and manual discovery refresh;
- physical validation of the mirror-focused feature advertisement experiment.

The small Photos image and black bars may still be encoded inside iOS's
`3840x2160` presentation canvas. This release has no validated content
rectangle or crop/zoom path and does not claim those inner pixels are fixed.
It also does not claim that automatic discovery or reconnect is fixed; no
server-side conclusion is drawn when an iPhone request never reaches Windows.

Use `TEST_PLAN.md` for the remaining scenarios. No physical Windows/iPhone
compatibility claim is made by this public review Release or build report. A
failed pending scenario must be corrected in 0.12.7 or later without modifying
the 0.12.6 tag or assets.
