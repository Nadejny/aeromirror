# Build report — AeroMirror 0.12.4

Release `v0.12.4` was built from commit
`31042ffa50773eb053239ab5ed687f44b4f35d94` and published at
`2026-08-10T00:17:54Z`:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.4

The tag and all four assets are immutable release history. Any correction must
use `0.12.5` or a later version; do not move the tag or replace an asset under
0.12.4.

## Release channel

- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.4`
- Distribution label: public review release
- Public asset count: exactly four
- Offline portable package: not published

Publication makes this patch available through the normal in-app update
channel. It does not complete the installed updater path or physical
Windows/iPhone acceptance.

## Pre-tag and exact-tag verification

The exact source that became the release tag passed:

- managed x64 shell build with shell PE/file version `0.12.4.0`;
- receiver resilience suite, including feedback-health capability/recovery,
  same-process/same-port cleanup, fatal-versus-transient continuity, renderer
  show/placement/handoff, unobscured client capture, policy caching, resize-end
  fitting, latency arguments, Direct3D decoder/sink pairing, and existing
  lifecycle/network/update regressions;
- shell and Setup PE version, internal Setup version, script-default,
  asset-name, documentation-version, changed-file, and local-link audits;
- review-payload packaging;
- Setup build and installer lifecycle self-check;
- native rebuild and prepared corresponding-source packaging;
- `UPSTREAM.lock` commit/patch/core-hash consistency and native patch,
  modified-source, build-input, and executable provenance validation;
- clean exact-tag `release.ps1` packaging from `v0.12.4`;
- `git diff --check`.

These gates accept source, build, packaging, installer, and provenance
integrity. They do not substitute for a real Windows 10/11 and iPhone test.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding local release file. GitHub's API digest for
all four assets exactly matched the same local and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.4.exe` | 1,265,664 | `53f286e3c10c5377f4cc4cfe001568d9b87ce6392f8267f08a8546103f215723` |
| `AeroMirror-source-0.12.4.zip` | 1,818,259 | `fd9c985e440f4354ab27aefd53d5508570f6350fd47e3b928237997227503a69` |
| `AeroMirror-native-source-0.12.4.zip` | 691,327 | `d896028a5a6618b16ac6aa3eed9ed6ff69e91b6293692005f6de5275d75bdc26` |
| `SHA256SUMS.txt` | 294 | `ee026a8a13a2a3dd28a74fedb3b67ffcac1fcff098aec7bf12d104b5a9db0376` |

The Release contains no unexpected fifth asset. The native-source archive
contains the prepared pinned source, both reviewed AeroMirror patches, raw
geometry and feedback-health changes, build inputs, and provenance needed to
reproduce and validate the released native core.

## Acceptance status

Accepted:

- exact-tag source and release packaging;
- normal latest-channel visibility with `draft=false` and
  `prerelease=false`;
- exact public asset set, byte sizes, local and re-downloaded hashes, checksum
  file, and updater-facing GitHub API digest fields;
- managed build, resilience, version/link, privacy/source, and whitespace
  gates;
- review payload, Setup build, installer lifecycle, native rebuild,
  corresponding-source, `UPSTREAM.lock`, and provenance gates.

Pending:

- installed in-place update through the AeroMirror updater from public 0.12.3
  to 0.12.4, including settings, receiver identity/trust, shortcuts, autostart,
  runtime-cache reuse, digest verification, Setup launch, and rollback;
- physical 3–4 second, 5–8 second, and longer-than-15-second Wi-Fi loss,
  transient and fatal continuity, same-process recovery, normal disconnect,
  delayed Wi-Fi join, idle discovery, VPN-over-Private-LAN, and repeated
  reconnect timing on Windows 11 and Windows 10 1809+ with an iPhone;
- physical saved placement at first show, fade handoff, mixed-DPI and
  multi-monitor restoration, resize-end fitting, taskbar/topmost behavior,
  unobscured snapshot, dark privacy fallback, focus, and Z-order behavior;
- physical Balanced/Interactive and Automatic/Direct3D 11/Direct3D 12
  smoothness, audio drift, decoder/sink, feedback-gap, and CPU/GPU evidence;
- physical direct-in-Photos startup, real device rotation, fullscreen media,
  raw geometry evidence, and actual inner image size.

The inner Photos `3840x2160` encoded canvas remains a known limitation: it may
contain the small photo and black bars as pixels, and this release has no
validated content rectangle or pixel-analysis crop. Raw auxiliary geometry is
diagnostic only and is not interpreted as crop, PAR, or rotation metadata.
The external GStreamer window also prevents a true embedded borderless viewer
or live aspect lock during edge dragging. Continuity does not make stale iOS
discovery rows reconnect instantly.

Use `TEST_PLAN.md` for the remaining scenarios. No physical Windows/iPhone
compatibility claim is made by this public review release or build report. A
failed pending scenario must be corrected in 0.12.5 or later without modifying
the 0.12.4 tag or assets.
