# AeroMirror 0.12.9 — bounded discovery and Photos-window public review release

## Summary

AeroMirror 0.12.9 is a public review release for two physical
reports: a receiver that was absent after a long idle period until discovery
was restarted, and a Photos photo/video canvas that made the renderer window
the wrong shape. It also carries forward the untagged 0.12.8
presentation-proof correction.

This patch does not claim root-cause proof for either new report. Its discovery
change is a bounded managed-shell mitigation, and its Photos option changes
only the outer Windows renderer shape. The normal updater-visible channel is
being used so installed clients can participate in review; that does not make
the pending physical Windows/iPhone matrix accepted.

## Should I update?

- **Yes, for review**, if AeroMirror sometimes disappears from iPhone Screen
  Mirroring after the PC has been idle and returns only after **Restart
  discovery**.
- **Yes, for an A/B test**, if opening a photo or video in Photos makes the
  AeroMirror window use an obviously wrong narrow shape. The new option is
  deliberately off by default.
- **Optional**, if public 0.12.7 is stable for you and neither report applies.
  This review release has not completed physical Windows/iPhone acceptance.

## What changed

### One final bounded discovery refresh after unlock

- The existing managed ten-minute idle-discovery renewal remains the first and
  normal fallback.
- After that renewal has already completed, a later Windows session unlock may
  schedule at most one final receiver restart and discovery re-registration.
  It waits for a ten-minute cooldown and requires a running core, ready local
  sockets, at least one positive DNS-SD/BLE discovery marker, a usable cached
  physical IPv4 address, no active mirroring session, no current client-grace
  window, and no competing restart or network refresh.
- Temporary socket/discovery/address readiness or competing maintenance makes
  the unlock request wait for a bounded re-evaluation. A stopped core, active
  mirroring/client grace, or an otherwise ineligible idle epoch cancels that
  pending request. It never bypasses the physical-network safety gate. Any real
  incoming AirPlay activity or new mirroring session, an explicit manual
  discovery refresh, or an actual physical-network signature change begins a
  new eligible idle-discovery epoch. Unlock events alone do not re-arm the
  allowance or permit repeated refreshes.
- The final refresh is a mitigation for the reported idle visibility symptom,
  not a proven diagnosis. It does not add native in-place DNS-SD/BLE
  re-publication, acknowledged discovery IPC, a stable AirPlay-port contract,
  or a way to force iOS to discard a stale browse result.

### Optional Photos/media outer-window behavior

- Settings schema 12 adds the Advanced option **Make the window wide for
  photos and videos from Photos (experimental)**. It is `OFF` for clean and
  migrated profiles.
- When enabled, only the exact previously observed ambiguous
  `3840x2160`, source `3840x2160`, auxiliary `0x0`, encoded `3840x2160`
  Photos/media signature may temporarily drive the outer renderer window to a
  wide shape, approximating the 0.12.1 wide outer-window presentation for an
  A/B test.
- That automatic wide fit is provisional. It does not become the trusted
  device-orientation baseline and does not overwrite a valid saved placement.
  Turning the option off restores the conservative device-frame behavior on
  the already debounced frame without restarting the native receiver.
- The option does not alter AirPlay capabilities, feature bits, negotiation,
  decoding, native patches, pixels, crop, zoom, or the content inside the
  iPhone-provided frame. A photo or video letterboxed inside the encoded canvas
  can therefore remain small even when the outer Windows window becomes wide.

### Reconnect truthfulness retained

- The untagged 0.12.8 current-PID/session/recovery-epoch Direct3D 11
  presentation-proof gate remains in this 0.12.9 review release. Feedback,
  appsrc push/PTS, sink observation, mirror-start, a visible old HWND, or a
  cached image cannot by themselves close the continuity view.
- This patch still does not claim to repair the underlying longer-gap frozen
  video transport. Missing proof keeps the reconnect instruction visible.

### Windows 10 first-install investigation

- Setup extracts the pinned portable application runtime, but installs no
  system-wide .NET/VC++ redistributable, driver, or framework prerequisite; a
  full Windows reboot is not an expected normal post-install requirement.
- The strongest current hypothesis for the one reported Windows 10 case is a
  stopped or stale system-wide Bonjour service lifecycle, but the original
  machine had already been rebooted and the cause is not proven. Reinstalling
  AeroMirror on the same PC is not a clean first-install reproduction because
  Bonjour is machine-wide and can remain installed.
- This release does not start, stop, repair, uninstall, or otherwise mutate
  the machine-wide Bonjour service. A clean Windows 10 VM test with retained
  pre-reboot logs and service state is required before changing Setup behavior
  or displaying a reboot instruction.

## Compatibility and verification status

- Public/app/Setup version is `0.12.9`; Windows PE/file version is
  `0.12.9.0`. Setup's internal comparison version and all five
  release-script defaults target 0.12.9. Source-version, settings-schema-12,
  default-false migration, and version/default checks pass.
- The final managed x64 build and complete resilience suite pass. Independent
  source review reports no P0/P1/P2 finding. A separate build with the legacy
  C# compiler confirms semantics and `0.12.9.0` metadata; legacy `csc.exe`
  output is not byte-deterministic, so exact packaged shell bytes are verified
  only by the final focused package gate.
- The 0.12.9 managed additions reuse the fully gated 0.12.8 native core at
  SHA-256
  `eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`.
  Provenance, both patch reverse-apply checks, the extracted prepared-source
  rebuild, native source at 143 archive entries/139 files, the loader test, and
  runtime inspection covering 199 binaries/148 copied DLLs pass.
- The pre-documentation thin review payload has the exact 13 entries. Setup
  builds; `/verify-runtime`, shortcut, update-lifecycle, and embedded payload/
  provenance checks pass; shell and Setup are x64 `0.12.9.0`; and local-link,
  strict-UTF-8, and diff checks pass.
- The focused package review and Setup rebuild after the final pre-tag evidence
  documents passed: exact payload, embedded payload/provenance, runtime,
  shortcut/update lifecycle, version/default, link, UTF-8, and diff checks all
  passed again against the exact tagged source.
  Volatile shell, payload, Setup, and native-source-ZIP container hashes are
  recorded in the versioned `BUILD_REPORT.md`.
- Annotated tag object
  `10deba1d48482da3500cf0bd7c796c87c7fce736` resolves to commit
  `b807d5dece26e972c58a3a2f7e5585dc8075672e`. GitHub Release `368804215`
  is the normal updater-visible latest Release with `draft=false` and
  `prerelease=false`.
- Exactly four public assets were published. Their final local hashes, GitHub
  API digests, and fresh public re-downloads match; `SHA256SUMS.txt` contains
  exactly the three non-checksum assets. Canonical and configured legacy
  latest API, HTML, and Setup routes resolve to the same Release, tag, and
  Setup bytes. At publication, the GitHub body matched the exact tagged form
  of these release notes.
- Windows 10 clean-install/reboot, long-idle discovery, repeated unlock, Photos
  A/B, reconnect regression, the installed update from public 0.12.7, and
  actual discovery/Photos/reconnect acceptance are **pending**.
- Version 0.12.8 was never tagged or published. This 0.12.9 review release uses
  its own tag and four release assets. Published `v0.12.7` and its four assets
  remain immutable.

Exact tag, asset, checksum, route, and public re-download evidence is in
[`BUILD_REPORT.md`](BUILD_REPORT.md). Remaining physical and installed-update
acceptance is defined in [`TEST_PLAN.md`](TEST_PLAN.md).

## Known limitations

- The idle-discovery report may have a different cause than the bounded unlock
  mitigation addresses. The receiver can still be absent from iOS, and a
  manual discovery restart may still be necessary.
- A restart re-registers discovery but does not preserve an advertised stable
  port across process replacement. Native same-port re-publication remains
  future work.
- The experimental Photos option changes only the outer window. Inner media
  may remain small, and no automatic crop/zoom is attempted.
- The Windows 10 reboot report remains unverified. Do not present rebooting as
  a normal installation step unless clean-machine evidence proves a real
  prerequisite or Setup lifecycle requirement.
- Direct3D 12, advanced sinks, and Interactive `-vsync no` still lack the
  synchronized presentation proof used by the default Direct3D 11 reconnect
  handoff.

Published `v0.12.7` and its four assets remain immutable under AeroMirror
project policy. Published `v0.12.9` and its four assets are now immutable by
the same project rule even though GitHub reports API `immutable=false`. Any
correction uses a later patch; never move a tag or replace either Release's
assets.
