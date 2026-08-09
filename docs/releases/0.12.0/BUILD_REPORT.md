# Build report — AeroMirror 0.12.0

Release `v0.12.0` was built from commit
`1a22d175810ff618e0f8c16102f1988d82a5fe10` and published at
`2026-08-09T20:46:54Z`:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.0

The tag and all assets listed below are immutable release history. Any
correction must use `0.12.1` or a later version; do not move the tag or replace
an asset under 0.12.0.

## Release channel

- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.0`
- Distribution label: review release
- Public asset count: exactly four
- Offline portable package: not published

Publication makes the build available to the normal in-app update channel. It
does not mean the remaining physical Windows/iPhone tests have passed.

## Pre-tag verification

All of the following passed on the exact source that became the release tag:

- x64 managed shell build;
- `ReceiverResilience.Tests.ps1`, including persisted-settings normalization,
  atomic settings replacement, stale-end reconnect ordering, strict
  three-part release tags, and recursive managed-source layout checks;
- review-payload packaging;
- Setup build, including shortcut-selection and update-lifecycle verifiers;
- native corresponding-source and provenance validation against the unchanged
  pinned core;
- `release.ps1` clean-worktree and exact-tag packaging requirements;
- version consistency across shell, Setup, source, payload, and public asset
  names;
- `git diff --check`;
- independent code review with no P0 or P1 findings.

These gates verify build and packaging integrity. They do not replace physical
AirPlay, network-profile, or in-place-update testing.

## Published assets

Every public asset was downloaded again from GitHub after publication. Its
downloaded byte size and SHA-256 matched the locally produced release file.
GitHub's API exposed a digest for all four assets, and every API digest exactly
matched the same local and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.0.exe` | 1,247,744 | `ba04f237573290af36f0ccc032723020f442f2828c3f2c57b8c5d16732744df6` |
| `AeroMirror-source-0.12.0.zip` | 1,746,020 | `45038e6a334c0a259a5db586d470e1dc1b937965376b947bc3a1523e29a512ee` |
| `AeroMirror-native-source-0.12.0.zip` | 687,948 | `bc2c7eee10a362b5a041764e3b71cafb63ecd5a1bf6b6b200e6bb96e2055f1bd` |
| `SHA256SUMS.txt` | 294 | `1ce59bbc32d23999a105ef0e85c614d7a1aa57b62a8b12814ce96c0f24987c2e` |

The release contained no unexpected fifth asset. The public native-source ZIP
matched the reviewed unchanged core provenance rather than a reconstructed or
untracked source tree.

## Acceptance status

Accepted:

- exact-tag reproducible review packaging;
- public GitHub channel visibility;
- exact public asset set, sizes, hashes, and updater-facing API digests;
- automated behavior, installer-lifecycle, source-layout, and provenance
  checks listed above.

Pending:

- install/update from public 0.11.3 through the normal updater channel;
- the full Windows 11 x64 + iPhone plan, including Private/Public physical
  network profiles and VPN on/off cases;
- immediate reconnect timing and stale-session-end behavior on a physical
  iPhone;
- persisted-settings and atomic-save regression checks on an installed build;
- the full Windows 10 1809+ x64 + iPhone plan required before 1.0.

Use `TEST_PLAN.md` for the remaining scenarios. A physical failure does not
invalidate or permit replacement of these historical assets; it requires a
new patch release with new notes, tests, tag, and checksums.
