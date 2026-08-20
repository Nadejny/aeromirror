# Build report — AeroMirror 0.12.18

Release `v0.12.18` was built from commit
`419ed6b199e89cf3c01efa6728f64423d9f049ed` and tree
`d7775e1f605eed4aea902574f031cb5d0bf788f9`. Its annotated tag object is
`d711d3700e81656fe397952082fbfa5986373c47`; the tag was created at
`2026-08-20T19:34:50Z`. GitHub Release `373984443` was published at
`2026-08-20T19:38:05Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.18

AeroMirror project policy treats this tag and all four public assets as
immutable release history. Any correction must use a later patch version; do
not move the tag or replace an asset under 0.12.18.

## Release channel

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.18`
- Distribution label: public gallery/fullscreen review release
- Public asset count: exactly four
- Offline portable package: not published

Canonical `pyram1da/aeromirror` and configured legacy
`Nadejny/aeromirror` latest API routes resolve to the same Release
`373984443` and tag `v0.12.18`. This proves updater-facing release discovery
and public asset identity through both repository slugs. It does not prove
Setup execution, installed-state preservation, iPhone visibility, or physical
Photos/Camera behavior.

## Exact-tag verification

The source resolved by annotated tag `v0.12.18` passed:

- managed x64 Release build and complete receiver resilience, including
  automatic portrait Photos presentation, removal of incremental zoom, actual
  fullscreen-state guards, and foreground Esc exit contracts;
- exact production worker-lifecycle executable checks across eight scenarios;
- source-bound parser, crypto, transport, SETUP, and renderer contracts plus
  the production AES-128-CTR split/reset known-answer test;
- two clean 57/57 compatible native builds reproducing core SHA-256
  `C217386CBC916F8889A9C03774390FE7EC7D8C7EE0B6F64358215CACEEB35118`;
- wrapper patch SHA-256
  `8F48A4E72D765B0549119BC6366CB970384BAB8116B4430CE60ED67228213F9C`
  and libuxplay patch SHA-256
  `11330A0D905CF4480958DAA59B950F3A2CE2B4AD51A18563EBCC77924DD782C4`;
- staged-runtime inspection of 199 binaries and 148 DLLs, mapping 44 requested
  GStreamer features to 27 plug-ins, with loader exit 0;
- final prepared native corresponding source with 147 archive entries,
  pinned-hash validation, and a no-Git clean 57/57 rebuild to the same core;
- exact 13-entry tagged review payload, packaged-shell resilience, x64
  `0.12.18.0` Setup, byte-exact embedded shell/core/provenance, and
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
  -Version 0.12.18 -SourceRef v0.12.18 `
  -RuntimePath .\artifacts\headless-runtime `
  -UpstreamRoot ..\upstream-uxplay-windows
```

These gates prove deterministic source behavior, build, packaging, installer
logic, corresponding-source completeness, and provenance integrity. They do
not replace a physical Windows/iPhone or real installed-update test.

## Published assets

Every public asset was downloaded again after publication through its normal
unauthenticated GitHub URL. Its byte size and SHA-256 matched the corresponding
final local release file, and GitHub's API digest matched the same value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.18.exe` | 1,412,608 | `93AA1A871A4A3AC0FC22A6960F4B4EC6D577DE5F32B42002656FB14E153E0174` |
| `AeroMirror-source-0.12.18.zip` | 2,201,829 | `4ADB630D7754AAB96D6A0FCF50864DA61511FA6FC5349BC0BF1701C82FFB130C` |
| `AeroMirror-native-source-0.12.18.zip` | 829,835 | `F4B7F53CABB67E45E6497A8109A87841ED7FE06DBE3409F0E1EC95FF06EFDDFE` |
| `SHA256SUMS.txt` | 297 | `F538F165E2BD41B6E30DDA58E606003796A28211891C9C9CA577B6F94FBECDF4` |

`SHA256SUMS.txt` contains exactly the three non-checksum public assets. The
Release contains no unexpected fifth asset. Setup and the packaged shell are
x64 and report file version `0.12.18.0`; the released native core identity is
the hash recorded above.

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
- physical portrait and landscape Photos presentation, repeated tray/
  Alt+Enter/Esc fullscreen transitions, entry and exit from Photos while
  fullscreen, Camera and home-screen rotation, H.264/H.265 motion, audio,
  Stop, and reconnect checks;
- the two-hour idle, lock/unlock, sleep/wake, router, and repeated iPhone browse
  visibility matrix.

The publication run deliberately did not install or replace the existing local
AeroMirror. No physical acceptance is inferred from the source, package, or
public-download checks.
