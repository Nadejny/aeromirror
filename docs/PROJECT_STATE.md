# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Latest public release

- Version: `v0.12.2`
- Tag commit: `36de759c5f8a9443a60b46b87392fed445eb76c3`
- Release URL: https://github.com/Nadejny/aeromirror/releases/tag/v0.12.2
- Published: `2026-08-09T22:16:12Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` public review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

The `v0.12.2` tag and its four assets are immutable. Any correction must use
`0.12.3` or a later version; never move the tag or replace a published file.
Exact evidence is recorded in `docs/releases/0.12.2/BUILD_REPORT.md`.

The immutable public 0.12.1 and 0.12.0 releases and their verification remain
under `docs/releases/`. Historical 0.11 tags, assets, plans, and build reports
also remain unchanged release history.

## What 0.12.2 changes

- A fatal lost-client marker survives quick native mirror cleanup and selects
  exactly one bounded discovery renewal. A clean disconnect still leaves the
  healthy receiver running without a restart.
- The first exact video size seeds a per-session device-frame aspect. Later
  matching ratios drive physical rotation; a non-matching Photos
  `3840x2160` canvas retains a learned `998x2160` device orientation.
- Interactive renderer resize completion queues a short aspect-preserving fit
  on the supervision thread. Move-only/minimized/maximized states and an
  explicit automatic-fit opt-out are respected.
- The fitting setting and tray fallback have clearer Russian labels.

The pinned native UxPlay core, third-party runtime, receiver identity and trust
state, settings format, update path, and Public/Unknown network fail-closed
policy are unchanged.

## Automated verification

Passed against the exact source published as `v0.12.2`:

1. managed x64 shell build;
2. receiver resilience suite, including clean versus abnormal disconnect,
   one-shot recovery consumption, reconnect cancellation, Photos-canvas
   suppression, physical 16:9 rotation, resize-end classification, and
   explicit automatic-fit opt-out;
3. existing settings, update-parser, network-policy, diagnostics-redaction,
   lifecycle, and source assertions within the same resilience suite.
4. the versioned review payload built successfully with `package-review.ps1`;
5. Setup built successfully and its installer lifecycle self-check passed;
6. the prepared native corresponding-source archive built and passed pinned
   source-provenance validation.

Shell/Setup source-version consistency, current release-link targets,
`git diff --check`, exact-tag `release.ps1` packaging, and final checksums pass.
All four public assets were downloaded again with matching byte sizes and
SHA-256 values, and all GitHub API digest fields match. Installed-update
acceptance and all physical Windows/iPhone gates remain pending.

## Pending physical verification and known limitations

- Windows 11 x64 + iPhone: abnormal Wi-Fi loss, disappearance/reappearance,
  first reconnect attempt, clean disconnect, and repeated reconnect timing;
- Windows 10 1809+ x64 + iPhone: the same reconnect matrix plus renderer resize
  and Photos/fullscreen-video orientation behavior;
- Windows 10/11: default automatic fit, explicit off, move-only, minimize,
  maximize, taskbar, and mixed-DPI behavior;
- a session that starts directly inside a media canvas may seed the wrong
  device aspect until a new mirroring session;
- an iOS stale-row tap may fail before any request reaches Windows, and iOS may
  delay browse-cache refresh even after the receiver is ready;
- native same-port DNS-SD/BLE re-publication after internal reset remains a
  TODO; 0.12.2 uses one bounded managed process renewal instead.

No physical Windows/iPhone result is claimed by the automated gates.

## Immediate next steps

1. Install or update to public 0.12.2 and verify the complete in-place update
   path from 0.12.1, including settings, trust state, shortcuts, and autostart.
2. Run and record the physical matrix in
   `docs/releases/0.12.2/TEST_PLAN.md` on Windows 11 and Windows 10.
3. If a defect is found, use 0.12.3 or later; never modify the immutable
   0.12.2 tag or assets.

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
