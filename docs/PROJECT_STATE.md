# Project state

Last updated: 2026-08-10

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Current unpublished candidate

- Version: `0.12.2`
- Status: source, mandatory English release documentation, and pre-tag review
  artifacts prepared locally; no commit, tag, exact-tag release package, or
  GitHub Release has been created
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Native core: unchanged from the reviewed build first shipped in 0.11.1
- Automated status: managed x64 build, receiver resilience suite, version/link
  audit, and `git diff --check` pass
- Pre-tag packaging status: review payload, installer build/lifecycle
  self-check, and native corresponding-source/provenance validation pass
- Publication status: exact-tag packaging and GitHub publication pending

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

Passed against the current unpublished 0.12.2 source:

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

Shell/Setup source-version consistency, current release-link targets, and
`git diff --check` pass. Exact-tag `release.ps1` packaging, final checksums,
GitHub publication, public re-download, installed-update acceptance, and all
physical Windows/iPhone gates remain pending.

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

1. Review the complete 0.12.2 source and documentation diff.
2. Commit the reviewed candidate, create the exact immutable `v0.12.2` tag,
   and run `release.ps1` only from that clean tag after publication is approved.
3. Run and record the physical matrix in
   `docs/releases/0.12.2/TEST_PLAN.md` on Windows 11 and Windows 10.
4. If a defect is found after publication, use 0.12.3 or later; never modify
   the immutable 0.12.1 tag or assets.

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
