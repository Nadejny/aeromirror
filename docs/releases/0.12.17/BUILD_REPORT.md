# Build report — AeroMirror 0.12.17

Release `v0.12.17` was built from commit
`16dffd57f7f105e6bdb90ef95137fc00f5282a68` and tree
`2cf7ccb8e2f30eb9e38da0f0178abcbc9b74d8d6`. Its annotated tag object is
`c0a7b97002bbc0ab142d11fd77c5539bfa4073ec`; the tag was created at
`2026-08-20T18:07:16Z`. GitHub Release `373934492` was published at
`2026-08-20T18:09:46Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.17

AeroMirror project policy treats this tag and all four public assets as
immutable release history. Any correction must use a later patch version; do
not move the tag or replace an asset under 0.12.17.

## Release channel

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.17`
- Distribution label: public Photos-presentation review release
- Public asset count: exactly four
- Offline portable package: not published

Canonical `pyram1da/aeromirror` and configured legacy
`Nadejny/aeromirror` latest routes resolve to the same `v0.12.17` Release.
This proves updater-facing release discovery and public asset identity through
both repository slugs. It does not prove Setup execution, installed-state
preservation, iPhone visibility, or physical Photos/Camera behavior.

## Exact-tag verification

The source resolved by annotated tag `v0.12.17` passed:

- managed x64 Release build and complete receiver resilience;
- the fullscreen/scale command grammar, GLib-owner dispatch, selected-renderer
  ownership, session reset, and installer update/reinstall source contracts;
- exact production worker-lifecycle executable checks across eight scenarios;
- source-bound parser, crypto, transport, SETUP, and renderer contracts plus
  the production AES-128-CTR split/reset known-answer test;
- two clean 57/57 compatible native builds reproducing core SHA-256
  `53B13433B9308547D491417F11692361DFC5B6EBFBDA018B8D3EEE7B4436436F`;
- wrapper patch SHA-256
  `8F48A4E72D765B0549119BC6366CB970384BAB8116B4430CE60ED67228213F9C`
  and libuxplay patch SHA-256
  `91AF80A36C7D4ECEB6470A1394722F2EC98312407DFA51A9929FC40E4B220CF5`;
- staged-runtime inspection of 199 binaries and 148 DLLs, mapping 44 requested
  GStreamer features to 27 plug-ins, with loader exit 0;
- prepared native corresponding source with 147 archive entries, pinned-hash
  validation, and a no-Git clean 57/57 rebuild to the same core;
- exact 13-entry local review payload, packaged-shell resilience, x64
  `0.12.17.0` Setup, byte-exact embedded inputs, and
  `/verify-runtime`, `/verify-shortcut-selection`, and
  `/verify-update-lifecycle` all exiting 0;
- clean exact-tag `release.ps1` packaging and source/document/link/UTF-8/
  whitespace audits.

The principal automated entry points were:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\NativeWorkerLifecycle.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\NativeCoreContracts.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\release.ps1 `
  -Version 0.12.17 -SourceRef v0.12.17 `
  -RuntimePath .\artifacts\headless-runtime `
  -UpstreamRoot ..\upstream-uxplay-windows
```

These gates prove deterministic source behavior, build, packaging, installer
logic, corresponding-source completeness, and provenance integrity. They do
not replace a physical Windows/iPhone or real installed-update test.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding final local release file, and GitHub's API
digest matched the same value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.17.exe` | 1,425,408 | `67AB295E8146A8D84EFB09E10E990350C37960922697329E691D621416F873AC` |
| `AeroMirror-source-0.12.17.zip` | 2,188,508 | `9C80931316BBB86CFA5CEBE8B4E8B7B3A655E2D60021C8D43A4EA9D0954228B0` |
| `AeroMirror-native-source-0.12.17.zip` | 828,175 | `369497BB96F94EB2104A9741EDF36638D3EC29AAE17C3B433A95EC7F865AC86C` |
| `SHA256SUMS.txt` | 297 | `B363AC9287D9C18C068B4FF1485F6DE746C2DAE57215E46C701F939549EEE18A` |

`SHA256SUMS.txt` contains exactly the three non-checksum public assets. The
Release contains no unexpected fifth asset. Setup and the packaged shell are
x64 and report file version `0.12.17.0`; the released native core identity is
the frozen hash recorded above.

## Acceptance status

Accepted:

- exact annotated-tag source and clean-tag packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- canonical and configured legacy latest routes resolving to the same Release;
- exact four-asset set, checksum entries, GitHub API digests, and fresh public
  re-download byte sizes and SHA-256 values;
- managed, native contract, package, Setup, corresponding-source,
  documentation, provenance, and whitespace gates.

Pending:

- a real installed update and same-version reinstall, including settings,
  receiver identity, shortcut choices, autostart, relaunch, and rollback;
- the two-hour idle, lock/unlock, sleep/wake, router, and repeated iPhone browse
  visibility matrix;
- physical Photos fullscreen and 100–250% zoom, Camera and home-screen
  rotation, H.264/H.265 motion, audio, Stop, and reconnect checks on Windows
  10/11 and at least two DPI configurations.

The publication run deliberately did not install or replace the existing local
AeroMirror. No physical acceptance is inferred from the source, package, or
public-download checks.
