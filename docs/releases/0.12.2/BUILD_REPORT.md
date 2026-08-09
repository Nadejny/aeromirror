# Build report — AeroMirror 0.12.2

Release `v0.12.2` was built from commit
`36de759c5f8a9443a60b46b87392fed445eb76c3` and published at
`2026-08-09T22:16:12Z`:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.2

The tag and all four assets are immutable release history. Any correction must
use `0.12.3` or a later version; do not move the tag or replace an asset under
0.12.2.

## Release channel

- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.2`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Publication makes this patch available through the normal in-app update
channel. It does not complete installed-update or physical Windows/iPhone
acceptance.

## Pre-tag and exact-tag verification

The exact source that became the release tag passed:

- managed x64 shell build;
- receiver resilience suite, including clean versus abnormal disconnect,
  one-shot discovery recovery, reconnect cancellation, media-canvas
  suppression, physical 16:9 orientation classification, manual Photos fitting,
  resize-end fitting, and explicit automatic-fit opt-out checks;
- source-version and local release-link audits;
- shell and Setup PE version checks for 0.12.2;
- review-payload packaging;
- Setup build and installer lifecycle self-check;
- native corresponding-source packaging and pinned provenance validation;
- clean exact-tag `release.ps1` packaging;
- `git diff --check`.

These gates accept source, build, packaging, installer, and provenance
integrity. They do not substitute for a real Windows 10/11 and iPhone test.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding local release file. GitHub's API provided a
digest for all four assets, and each API digest exactly matched the same local
and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.2.exe` | 1,251,840 | `cb75f1489ba7596291bf0f3506e054f3047078ae43752d9c633961c5c7a1b6fe` |
| `AeroMirror-source-0.12.2.zip` | 1,772,220 | `12eeac779cc25561bf40a078a1b48bc9b4c0df9e9e14b5f3dab8b482870a6e1f` |
| `AeroMirror-native-source-0.12.2.zip` | 687,952 | `803c97c07fe970918f29ecefb08740fc627571e54e05a213292012441a6503f2` |
| `SHA256SUMS.txt` | 294 | `cd384410eb0bff515d3006a570ef3e16bf3052a62e3c04fcb0b7bb5121094212` |

The Release contains no unexpected fifth asset. The native-source archive
describes the unchanged reviewed native core and its complete pinned
provenance; 0.12.2 changes the managed shell only.

## Acceptance status

Accepted:

- exact-tag source and release packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- exact public asset set, byte sizes, local and re-downloaded hashes, checksum
  file, and updater-facing GitHub API digest fields;
- managed build and resilience gates;
- review payload, Setup build, installer lifecycle, native corresponding-source,
  and provenance gates.

Pending:

- installed in-place update from public 0.12.1 to 0.12.2;
- physical abnormal-loss, discovery, and reconnect timing on Windows 11 and
  Windows 10 1809+ with an iPhone;
- physical Photos/fullscreen-media orientation and manual fitting behavior;
- physical resize-end automatic fitting, explicit opt-out, window-state, and
  DPI behavior.

Use `TEST_PLAN.md` for the remaining scenarios. No physical Windows/iPhone
compatibility claim is made by this review release or build report. A failed
pending scenario must be corrected in 0.12.3 or later without modifying the
0.12.2 tag or assets.
