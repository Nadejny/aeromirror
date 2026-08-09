# Build report — AeroMirror 0.12.3

Release `v0.12.3` was built from commit
`334001a8fa896c8e072465e624fda4f150ffa666` and published at
`2026-08-09T23:10:49Z`:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.3

The tag and all four assets are immutable release history. Any correction must
use `0.12.4` or a later version; do not move the tag or replace an asset under
0.12.3.

## Release channel

- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.3`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Publication makes this patch available through the normal in-app update
channel. It does not complete the installed updater path or physical
Windows/iPhone acceptance.

## Pre-tag and exact-tag verification

The exact source that became the release tag passed:

- managed x64 shell build with shell PE/file version `0.12.3.0`;
- receiver resilience suite, including fatal versus benign loss, placeholder
  transitions and exclusion, early direct-in-Photos marker retention, renderer
  placement and DPI normalization, settings migration, WinEvent callback
  safety, and existing lifecycle/network/update regressions;
- foreground-only/memory-only placeholder source and privacy audit;
- source-version and local documentation-link audits;
- shell and Setup PE version checks for 0.12.3;
- review-payload packaging;
- Setup build and installer lifecycle self-check;
- native corresponding-source packaging and unchanged pinned-provenance
  validation;
- clean exact-tag `release.ps1` packaging from `v0.12.3`;
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
| `AeroMirror-Setup-0.12.3.exe` | 1,257,984 | `99523584c1231a08f380a151bbfa2392edd94f2befd7b75f93cb595570ed091c` |
| `AeroMirror-source-0.12.3.zip` | 1,794,273 | `0605bebcd3af97fabd1a197a83a847540472923c930046eb85b56b053a4f3076` |
| `AeroMirror-native-source-0.12.3.zip` | 687,955 | `0892fb684a7960c77413d527e29cc9faaae3c2fee73714b10bf6833a90b6798b` |
| `SHA256SUMS.txt` | 294 | `4451c1476358d2b8561f0acba560103116b2d0589d56dcbe80c820e32bfb1f84` |

The Release contains no unexpected fifth asset. The native-source archive
describes the unchanged reviewed native core and its complete pinned
provenance; 0.12.3 changes the managed shell only.

## Acceptance status

Accepted:

- exact-tag source and release packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- exact public asset set, byte sizes, local and re-downloaded hashes, checksum
  file, and updater-facing GitHub API digest fields;
- managed build, resilience, privacy/source, version/link, and whitespace
  gates;
- review payload, Setup build, installer lifecycle, native corresponding-source,
  and provenance gates.

Pending:

- installed in-place update through the AeroMirror updater from public 0.12.2
  to 0.12.3, including settings, receiver identity/trust, shortcuts, autostart,
  runtime-cache reuse, download digest verification, and Setup launch;
- physical fatal-loss placeholder, quick Wi-Fi recovery, manual dismissal,
  clean-disconnect exclusion, and repeated reconnect timing on Windows 11 and
  Windows 10 1809+ with an iPhone;
- physical renderer-bound persistence, offline-monitor clamping, mixed-DPI
  restoration, automatic-fit opt-out, minimize/maximize, taskbar, and
  always-on-top behavior;
- physical direct-in-Photos startup, real device rotation, fullscreen media,
  and inner image-size diagnostics.

The inner Photos `3840x2160` encoded canvas remains a known limitation: it may
contain the small photo and black bars as pixels, and this release has no native
content rectangle or validated pixel-analysis crop. A session that emits only
a generic media canvas and no early phone-shaped marker also remains ambiguous.
The continuity placeholder does not make stale iOS discovery rows reconnect
instantly.

Use `TEST_PLAN.md` for the remaining scenarios. No physical Windows/iPhone
compatibility claim is made by this public review release or build report. A
failed pending scenario must be corrected in 0.12.4 or later without modifying
the 0.12.3 tag or assets.
