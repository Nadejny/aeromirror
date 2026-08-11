# Build report — AeroMirror 0.12.7

Release `v0.12.7` was built from commit
`dd343a44b0c9b6904815cd78e54a841e9f5ef6be`. Its annotated tag object is
`6154c7f3c3384dcd039b4e1e0c2feceb46b84fad`. The Release was published at
`2026-08-11T12:57:13Z`:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.7

GitHub Release ID: `368571434`.

AeroMirror project policy treats the published tag and all four assets as
immutable release history. GitHub reports API `immutable=false`, so this is a
project guarantee rather than a platform-enforced lock. Any correction must
use `0.12.8` or a later version; do not move the tag or replace an asset under
0.12.7.

## Release channel

- Canonical repository: `pyram1da/aeromirror`
- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- GitHub API `immutable`: `false`; immutability is AeroMirror project policy
- Latest updater-visible Release: `v0.12.7`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Both the canonical `pyram1da/aeromirror` and configured legacy
`Nadejny/aeromirror` unauthenticated `releases/latest` API routes returned tag
`v0.12.7` and Release ID `368571434`. The Setup downloaded through the legacy
latest route matched the final Setup SHA-256 below. This proves updater-facing
release discovery and asset identity through the legacy repository slug. It
does not prove Setup execution, installed-state preservation, rollback,
iPhone discovery, or reconnect behavior.

## Pre-tag and exact-tag verification

The exact source resolved by annotated tag `v0.12.7` passed:

- isolated managed x64 shell build and combined receiver resilience suite;
- shell and Setup PE/file version `0.12.7.0`, Setup internal comparison
  version, and five release-script defaults;
- exact default, mute, explicit-override, unknown-setting, and legacy audio
  argument coverage plus headless external-renderer argument pass-through;
- reproducible native core SHA-256
  `11b65324c83f23503f2d555d0064d1348c884407bf7f9b1c34d27b5d1c05fb9b`;
- reviewed patch/current-source/protected-audio hashes, reverse-apply checks,
  dependency inspection and collection, and native source provenance;
- redistributed GStreamer 1.28.1 runtime contract and loader test, recorded
  separately from the GStreamer 1.28.5 native build toolchain;
- prepared native corresponding source with exactly 143 files; a rebuild from
  the extracted archive reproduced the same native core;
- thin review payload with exactly 13 expected entries;
- network Setup build, embedded-payload comparison, `/verify-runtime`, and
  shortcut/update lifecycle self-checks;
- source/default/documentation/local-link/changed-file and
  `git diff --check` audits;
- clean exact-tag `release.ps1` packaging from annotated `v0.12.7`, resolving
  to commit `dd343a44b0c9b6904815cd78e54a841e9f5ef6be`.

These gates prove source, deterministic behavior replays, build, packaging,
installer logic, and provenance integrity. They do not replace a physical
Windows 10/11 and iPhone test.

## Scoped physical report

On 2026-08-11, the reporter tested public 0.12.7 on the affected Windows 11 PC
and iPhone. Starting mirroring directly from Photos and using a normal
gallery/video session no longer reproduced the prior involuntary session drop;
the reporter described the corrected path as working ideally. The urgent
Photos/video session-continuity hotfix target therefore has a scoped physical
PASS.

The same smoke retained important limitations: one first direct-Photos
connection tap failed before the second succeeded; inner gallery photo/video
content remained small; a reporter-estimated wall-clock Wi-Fi interruption of
about ten seconds recovered automatically, with a five-second feedback gap in
the exact log interval; and a reporter-estimated wall-clock interruption of
about 15 seconds, with an 11-second feedback gap in the exact log interval, was
followed by reconnect that cleared the placeholder but left video frozen.
Closing AeroMirror briefly exposed the latest frame.

This report does not infer the exact installed 0.12.6-to-0.12.7 updater path
from that run. The complete repeated Photos/video plan, the remaining
interruption/handoff matrix, and Windows 10 remain pending.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding final local release file. GitHub's API
digest for every asset matched the same local and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.7.exe` | 1,276,416 | `cb7487d8acf0813fcb64814ee937b59eb71d675eec4b184d48806e9907e1ba90` |
| `AeroMirror-source-0.12.7.zip` | 1,882,862 | `2bd9dc3bacb5ca798529b547f2fbaf1e1e8a55f231e4e4afb8af578e86747576` |
| `AeroMirror-native-source-0.12.7.zip` | 697,401 | `74e2a7e0561973acd29cac9f95a56aea7f9e1b19c379ea03b578d612d637cd87` |
| `SHA256SUMS.txt` | 294 | `f1045b1e5bbb717f43c9da97fe17a2c0a1f3a3858ab1bda49305dadb00acd6f0` |

`SHA256SUMS.txt` contains exactly the three non-checksum public assets. The
Release contains no unexpected fifth asset. The native-source archive contains
the prepared pinned source, reviewed AeroMirror patches, build inputs, and
provenance needed to reproduce and validate the released native core.

## Acceptance status

Accepted:

- exact annotated-tag source and `release.ps1` packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- canonical and configured legacy `releases/latest` API routes returning the
  same `v0.12.7` Release ID, with matching legacy-route Setup bytes;
- exact four-asset set, byte sizes, local and fresh re-download hashes,
  checksum file entries, and all GitHub API digest fields;
- managed build, resilience, version/document/link, package-content, and
  whitespace gates;
- review payload, Setup build and lifecycle checks, embedded-payload hash,
  native corresponding-source, reproducibility, loader, and provenance gates;
- scoped urgent Photos/video involuntary-disconnect smoke on the reporter's
  public 0.12.7 Windows 11/iPhone environment.

Pending:

- installed in-place update through AeroMirror from public 0.12.6 to public
  0.12.7, including settings, receiver identity/trust, shortcuts, autostart,
  runtime-cache reuse, digest verification, Setup launch, and rollback;
- the complete repeated Photos photo/video sequence on Windows 11 and Windows
  10 version 1809+ with an iPhone, including first-tap direct-in-Photos startup,
  gallery/photo/video transitions, playback, and repeated sessions;
- physical default-audio endpoint failure/recovery and Direct3D 11 versus
  Direct3D 12 argument/renderer confirmation;
- short and longer-than-15-second Wi-Fi interruptions, normal disconnect,
  reconnect, delayed Wi-Fi join, idle discovery, VPN-over-Private-LAN,
  receiver-list visibility, first-tap behavior, and manual discovery refresh;
- portrait/landscape behavior, saved placement, continuity view, handoff, and
  actual inner Photos content size.

Photos may still encode a small image and black bars inside its `3840x2160`
presentation canvas. This release has no validated content rectangle or
crop/zoom path and does not claim those inner pixels are fixed. It also does
not claim that delayed discovery or automatic reconnect is fixed.

Use [`TEST_PLAN.md`](TEST_PLAN.md) for the remaining scenarios. No physical
Windows 10 or full Windows/iPhone compatibility claim is made by this public
review Release or build report beyond the scoped Windows 11/iPhone urgent
session-drop smoke above. A failed pending scenario must be corrected in 0.12.8
or later without modifying the 0.12.7 tag or assets.
