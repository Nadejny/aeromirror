# Build report — AeroMirror 0.12.16

Release `v0.12.16` was built from commit
`c012d51d5cf3194fd647c4c65c20659386043baf` and tree
`8565fa52257a9934c0d909e40b9cb7bfbe8fd30a`. Its annotated tag object is
`a7955a0d466a1206298c9ad9890429edf8c2a464`; the tag was created at
`2026-08-20T16:22:51Z`. GitHub Release `373875353` was published at
`2026-08-20T16:24:41Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.16

AeroMirror project policy treats this tag and all four public assets as
immutable release history. Any correction must use a later patch version; do
not move the tag or replace an asset under 0.12.16.

## Release channel

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.16`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Canonical `pyram1da/aeromirror` and configured legacy
`Nadejny/aeromirror` latest routes resolve to the same `v0.12.16` Release ID.
This proves updater-facing release discovery and public asset identity through
both repository slugs. It does not prove Setup execution, installed-state
preservation, iPhone visibility, or media recovery.

## Exact-tag verification

The source resolved by annotated tag `v0.12.16` passed:

- managed x64 Release build and the complete receiver resilience suite;
- unattended update/reinstall source contracts and all three non-installing
  Setup self-checks;
- exact production worker-lifecycle executable checks across eight scenarios;
- source-bound parser, crypto, transport, SETUP, and renderer contracts plus
  the production AES-128-CTR split/reset known-answer test;
- the reused native core SHA-256
  `38C6A63CE3CA40D3D1E23E5ECB5E0D152F9978986C4384A780C5767EAE0650A4`;
- libuxplay patch SHA-256
  `E8233FFD59BFC49181D32BBD64A6C94A338FD31939B28A18C7FC7A3B5F14195D`,
  37 libuxplay paths, and 41 total patched-source provenance hashes;
- prepared native corresponding source with 147 archive entries;
- exact 13-entry thin review payload, packaged-shell resilience, x64
  `0.12.16.0` Setup, and byte-exact embedded payload/provenance;
- clean exact-tag `release.ps1` packaging and source/document/link/UTF-8/
  whitespace audits.

The principal automated entry points were:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\NativeWorkerLifecycle.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\NativeCoreContracts.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\release.ps1 `
  -Version 0.12.16 -SourceRef v0.12.16 `
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
| `AeroMirror-Setup-0.12.16.exe` | 1,404,928 | `B540EA47AD38ED41464D9973EEDAE4F64FDB2C5031D16D8B67BAC323C3579B3F` |
| `AeroMirror-source-0.12.16.zip` | 2,172,920 | `110AFD4198DA68351571CBDF2AD10D2F139734AED5BDD0B8D45B53B5BB99D47E` |
| `AeroMirror-native-source-0.12.16.zip` | 826,742 | `E511C9C76F8F6096FEF40AA98D4030D0BA3916547DD6552D392148EA41E4D1BA` |
| `SHA256SUMS.txt` | 297 | `C9DE540744CEF75668AEA9696818DCA59CB6450E7BFE9634E884E0BD71304A09` |

`SHA256SUMS.txt` contains exactly the three non-checksum public assets. The
Release contains no unexpected fifth asset. Setup and the packaged shell are
x64 and report file version `0.12.16.0`; the released native core identity is
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
- physical H.264/H.265 motion, audio, Stop, reconnect, frozen-frame, Photos,
  and Camera checks on Windows 10/11.

The publication run deliberately did not install or replace the existing local
AeroMirror. No physical acceptance is inferred from the source, package, or
public-download checks.
