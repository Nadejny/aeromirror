# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Latest public release

- Version: `v0.12.1`
- Tag commit: `2f457449653b11bc411982d200241cb82ea90587`
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.12.1
- Published: `2026-08-09T21:19:15Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` cosmetic review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.12.1` tag and its four assets are immutable. Any correction must use
`0.12.2` or a later version; never move the tag or replace a published file.
Exact evidence is recorded in `docs/releases/0.12.1/BUILD_REPORT.md`.

The immutable public 0.12.0 release and its verification remain at
`docs/releases/0.12.0/`. Historical 0.11 tags, assets, plans, and build reports
also remain unchanged release history.

## What 0.12.1 changes

- The network-card text and help control share the same vertical center.
- A custom question-mark glyph uses DPI-aware measurements and remains
  centered and unclipped in focused synthetic rendering.
- On a Private physical network, optional-PIN guidance begins on the tooltip's
  second line below the network summary.
- The receiver-state tooltip is reachable over both the colored status dot and
  adjacent status text.

This is a managed-shell cosmetic patch. The native UxPlay core, receiver
lifecycle, discovery/reconnect supervision, network trust decisions, settings
format, installer behavior, and persistent identity are unchanged.

## Automated and public verification

Accepted for review distribution:

1. managed x64 shell build and receiver regression suite;
2. focused source assertions for card geometry, tooltip line placement and hit
   targets;
3. synthetic custom-glyph rendering in light and dark at 100%, 150%, and 200%
   DPI;
4. unchanged native inputs and source provenance;
5. shell/Setup version, review payload, installer lifecycle, native-source,
   exact-tag packaging, and `git diff --check` gates;
6. public re-download of exactly four assets with matching byte sizes and
   SHA-256 values;
7. all four GitHub API digest fields matching the local and re-downloaded
   SHA-256 values exactly.

GitHub reports `v0.12.1` as the normal latest Release with `draft=false` and
`prerelease=false`. This accepts the tag and public artifacts as a cosmetic
review release only.

## Pending visual verification

The focused synthetic glyph check passed, but the following full-window visual
rows remain **pending** in `docs/releases/0.12.1/TEST_PLAN.md`:

- Windows 11 light and dark themes at 100%;
- Windows 11 light and dark at 125% or 150%;
- Windows 11 glyph clipping/alignment at 200%;
- Windows 10 1809+ compatibility visual smoke;
- mixed-DPI monitor movement when suitable hardware is available.

Retain uncropped screenshots with Windows version, theme, and scale. A visual
failure must be fixed in a later patch; it does not permit replacing 0.12.1
assets.

## Physical AirPlay verification

No physical AirPlay behavior is claimed by 0.12.1. Existing installed-update,
Windows/iPhone, network-profile, reconnect, and Windows 10-before-1.0 gates
remain pending under the current public plans. Cosmetic UI checks do not
satisfy them.

## Immediate next steps

1. Install or update to public 0.12.1 and complete the full-window Windows 11
   theme/DPI matrix with retained screenshots.
2. Run the Windows 10 visual smoke and record the result in the 0.12.1 test
   matrix.
3. Separately complete the physical Windows 11 + iPhone and installed-update
   acceptance, then the Windows 10 AirPlay plan required before 1.0.
4. If any defect is found, prepare 0.12.2 or later; do not modify the 0.12.1
   tag or assets.

## Where information belongs

- mandatory patch documentation: `docs/DOCUMENTATION_POLICY.md`;
- current handoff and immediate next step: this file;
- durable technical/product decisions: `docs/DECISIONS.md`;
- implementation backlog and acceptance targets: `docs/TODO.md`;
- component boundaries: `docs/ARCHITECTURE.md`;
- release/update/signing rules: `docs/RELEASE_AND_SIGNING.md`;
- user-visible release history: `CHANGELOG.md`;
- versioned release evidence and acceptance: `docs/releases/<version>/`;
- troubleshooting and log collection: `docs/TROUBLESHOOTING.md`.
