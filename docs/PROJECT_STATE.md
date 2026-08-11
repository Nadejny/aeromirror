# Project state

Last updated: 2026-08-11

This is the single current-state handoff for AeroMirror. Keep it concise and
update it whenever release status, accepted tests, blockers, or the immediate
next step changes.

## Current 0.12.9 candidate

- Status: local and unpublished. The implementation, final managed build,
  complete resilience suite, independent source review, unchanged-native
  reuse/provenance, thin-package, and Setup gates pass, including the focused
  package/Setup rebuild after the final evidence update. Independent review
  reports no P0/P1/P2 finding. Physical Windows/iPhone, installed-update,
  exact-tag, install-from-public, and public verification remain pending.
- Public/app/Setup version: `0.12.9`; Windows PE/file version: `0.12.9.0`.
  Setup's internal comparison version and all five release-script defaults
  target 0.12.9. Source-version, settings-schema-12/default-false, and version-
  default checks pass.
- Discovery scope: retain the existing first ten-minute idle renewal. Only
  after it has completed, a later Windows SessionUnlock may request at most one
  final receiver restart and discovery re-registration after a ten-minute
  cooldown. The core, local sockets, at least one DNS-SD/BLE marker, cached
  physical IPv4, inactive mirroring/client grace, and restart/network guards
  must be ready. Temporary socket/discovery/address readiness or competing
  maintenance defers evaluation. A stopped core, active mirroring/client
  grace, or an otherwise ineligible idle epoch cancels the pending unlock
  request. Unlock events themselves do not re-arm the allowance. New client or
  mirroring activity, an explicit manual discovery refresh, or an actual
  physical-network signature change begins a new eligible discovery epoch.
- The unlock refresh is a bounded mitigation for one reported missing-after-
  idle receiver. It is not a proven root-cause correction, adds no
  acknowledged native discovery IPC or in-place DNS-SD/BLE re-publication,
  cannot force iOS browse-cache invalidation, and provides no stable-port
  contract across process replacement.
- Photos scope: settings schema 12 adds a default-off Advanced A/B option for
  allowing only the exact ambiguous `3840x2160`, source `3840x2160`,
  auxiliary `0x0`, encoded `3840x2160` Photos/media canvas to shape the outer
  renderer window temporarily. The provisional landscape does not become the
  trusted device baseline and does not overwrite a valid saved placement.
- The Photos option changes no native capability, feature bit, negotiation,
  decoder, pixel, crop, or zoom. Inner media can remain small inside the
  iPhone-provided canvas, and Photos/video stability still requires physical
  regression testing.
- The untagged 0.12.8 current-PID/session/recovery-epoch Direct3D 11 Present-
  proof handoff is carried forward unchanged in product behavior. The
  underlying long-gap frozen-video path remains unresolved.
- One Windows 10 first-install report appeared to work only after a full OS
  reboot. Setup extracts the portable app runtime but installs no system-wide
  .NET/VC++ redistributable, driver, or framework prerequisite, so reboot is
  not treated as normal. A stopped/stale system-wide Bonjour service lifecycle
  is the strongest current hypothesis but is unproven; no
  machine-wide Bonjour mutation is authorized. A clean Windows 10 VM with
  pre-reboot Setup/receiver logs and service state is the immediate evidence
  target.
- Managed/pretag evidence: the final x64 shell build and full resilience suite
  pass; shell and Setup are x64 `0.12.9.0`; the exact 13-entry review payload,
  Setup build, `/verify-runtime`, shortcut/update lifecycle, and embedded
  payload/provenance checks pass. Local links, strict UTF-8, and diff checks
  pass.
- Native reuse evidence: core SHA-256 is
  `eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`.
  Provenance, both patch reverse-apply checks, extracted prepared-source
  rebuild, exact 143 archive entries/139 files, runtime inspection of 199
  binaries/148 copied DLLs, and the loader test pass.
- The legacy C# compiler does not produce a byte-deterministic shell across
  independent builds. Its independent build confirms semantics and
  `0.12.9.0`; the exact packaged shell hash is evidence from the final focused
  package gate, not from cross-build byte equality.
- Immediate next step: run long-idle/unlock, Photos off/on, reconnect,
  installed-update, and clean Windows 10 first-install physical plans. Keep
  volatile shell/payload/Setup/native-ZIP container hashes in the final gate
  handoff and eventual `BUILD_REPORT.md`, not in self-referential source docs.
  Any later source or documentation edit requires the focused package/Setup
  gate again. Do not tag or publish without explicit authorization.

## Prior untagged 0.12.8 candidate history

0.12.8 completed its automated, native, package, Setup, and pretag gates but
not physical or public acceptance, and it was never tagged or published. Its
implementation is carried into 0.12.9. The version/default statements in this
historical section describe the former 0.12.8 candidate, not the current
working-tree defaults.

- Status: source implementation and independent final code review are complete
  with no remaining P0/P1/P2 finding. Managed build/resilience, official native
  reproducibility, prepared-source rebuild, runtime/provenance/dependency,
  loader, thin-package, and Setup pretag gates pass. The focused final package
  review and Setup rebuild after the evidence-doc update also pass. Physical,
  tag, install-from-public, and public verification remain pending.
- Public/app/Setup version: `0.12.8`; Windows PE/file version: `0.12.8.0`.
  Setup's internal comparison version and all five release-script defaults
  target 0.12.8.
- Scope: correct the 0.12.7 continuity false handoff. The captured longer-gap
  run proves that HTTP feedback recovered while the old external renderer HWND
  remained visible. The shell then closed the placeholder without evidence of
  a fresh displayed frame, and video remained frozen.
- Candidate same-session gap contract: HTTP feedback recovery may change the
  continuity view to
  **Connection restored / Waiting for image**, but only a current native PID,
  current managed mirror-session generation, and current recovery-epoch
  `AEROMIRROR_VIDEO_PRESENT_READY epoch=E gap_seconds=N
  proof=d3d11-present pts_delta_ms=D` marker may authorize the fade for that
  path. Appsrc push/PTS, sink telemetry, window
  visibility, or a cached HWND are diagnostic evidence only. Manual reselection
  may arm a new epoch with `AEROMIRROR_VIDEO_PRESENT_ARMED
  reason=mirror-start epoch=E`, but only while that reason is expected.
  Feedback proof must repeat the exact positive stored gap; accepted
  mirror-start proof must use `gap_seconds=0`. Either accepted challenge gets a
  fresh three-second proof wait, and mirror-start alone cannot close continuity.
- Balanced Direct3D 11 is the primary proof path. Direct3D 12, advanced sinks,
  and Interactive `-vsync no` keep waiting/reconnect guidance; the Interactive
  path deliberately skips synchronized PTS/Present proof, and none may fall
  back to cached HWND state.
- If current presentation proof does not arrive during the bounded three-second
  wait, the view remains visible and changes to explicit iPhone Screen
  Mirroring reconnect guidance. The candidate does not auto-reset the core,
  hot-replace a half-open video socket, or rebase the media clock.
- This is not yet a fix for the underlying long-gap frozen-video path. The
  small photo/video inside Photos' encoded `3840x2160` canvas is also unchanged;
  the mirror-only feature-bit experiment remains as published in 0.12.7. A
  retained HEVC 4K-versus-Full-HD Photos A/B remains pending. No exact display-
  capability marker landed; any future marker is negotiation evidence, not a
  sizing fix.
- Updated provenance records expect native core SHA-256
  `eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`
  and libuxplay patch SHA-256
  `c5be47ee96be25609677103cf85b3d98b07e2752a980d0d6d9fb975d187ad05e`.
  The official native build and extracted prepared-source rebuild reproduce
  that exact core hash. Both native patches reverse-apply. Native source
  generation produces 143 archive entries/139 files, and the loader test
  passes; the runtime/provenance/dependency audit covers 199 inspected binaries
  and 148 copied DLLs.
- Managed build and receiver resilience pass. The thin package review has the
  exact 13 entries; Setup builds, `verify-runtime` exits 0, and embedded
  payload/provenance matches. Shortcut and update-lifecycle checks also exit 0;
  shell, Setup, and core are x64 `0.12.8.0`. Version/default,
  documentation-link, and diff gates pass. Independent final review reports no
  P0/P1/P2 finding.
- A focused final package review and Setup rebuild after the evidence-doc update
  pass again: exact 13 entries, embedded payload/provenance, `verify-runtime`,
  shortcut/update lifecycle, version, link, and diff checks all pass. Exact
  payload/Setup byte sizes and SHA-256 values are retained in the gate handoff
  for the eventual `BUILD_REPORT.md`; embedding them here would create a
  self-reference. Physical iPhone/Windows 10/Windows 11, exact-tag,
  install-from-public, GitHub Release, checksums, API, and public re-download
  verification remain pending. No 0.12.8 asset is public.

## Latest public release

- Version: `v0.12.7`
- Annotated tag object: `6154c7f3c3384dcd039b4e1e0c2feceb46b84fad`
- Tag commit: `dd343a44b0c9b6904815cd78e54a841e9f5ef6be`
- Release URL: https://github.com/pyram1da/aeromirror/releases/tag/v0.12.7
- GitHub Release ID: `368571434`
- Published: `2026-08-11T12:57:13Z`
- Channel: normal, non-draft, non-prerelease GitHub Release
- Updater status: current `releases/latest` public review Release
- Supported target: Windows 10 version 1809+ x64 and Windows 11 x64
- Installer: unsigned per-user network Setup; SmartScreen may warn
- Public assets: Setup, AeroMirror source, prepared native corresponding
  source, and `SHA256SUMS.txt`
- Offline portable package: engineering-only and not published

AeroMirror project policy treats the published `v0.12.7` tag and its four
assets as immutable, although GitHub reports API `immutable=false`. Any
correction must use 0.12.8 or later; never move the tag or replace a published
file. Exact evidence is recorded in
`docs/releases/0.12.7/BUILD_REPORT.md`.

Project policy also treats the published 0.12.6, 0.12.5, 0.12.4, 0.12.3,
0.12.2, 0.12.1, 0.12.0, and 0.11 releases as immutable history. Their
verification remains under `docs/releases/` or the historical 0.11 report
paths.

## What 0.12.7 changes

- Status: published normal updater-visible public review Release.
- Public app/Setup version: `0.12.7`; Windows PE/file version:
  `0.12.7.0`. The five release-script defaults and Setup's internal comparison
  version target 0.12.7.
- The affected physical 0.12.6 log shows that the managed shell and native core
  processes remained alive while the current AirPlay connection was removed.
  It records `Disconnecting on software request`, but not the debug request
  type, and the native server has more than one software-disconnect site.
  Source review found that 0.12.6 newly forced a full disconnect from the typed
  AirPlay `TEARDOWN` handler; the transition timing is consistent with that
  plausible regression but does not prove it was the logged call site. One
  captured transition also reported a `wasapi2` wrong-format error immediately
  after the software disconnect; that ordering does not prove the audio error
  initiated teardown.
- The 0.12.7 native correction removes only that unconditional server-side
  disconnect request. It retains upstream's `Connection: close` response
  header, lets the client determine whether and when the socket closes, and
  adds a compact typed-`TEARDOWN` diagnostic marker so the next physical run
  can confirm the request type directly.
- Default Windows audio now requests
  `wasapi2sink continue-on-error=true`. The pinned redistributed GStreamer
  1.28.1 runtime supports that property for its documented device-open, I/O,
  and removal failures. Mute behavior is unchanged, and advanced UxPlay
  arguments remain later on the command line for an explicit override. This is
  not generic isolation for every GStreamer bus error.
- The headless wrapper now preserves external `-vs` and `-fs` arguments. This
  prevents hidden wrapper settings from replacing the shell's requested D3D11
  sink or fullscreen policy before UxPlay parses them.
- The isolated managed 0.12.7 build and resilience suite pass. Two clean
  native builds reproduce SHA-256
  `11b65324c83f23503f2d555d0064d1348c884407bf7f9b1c34d27b5d1c05fb9b`.
  Native patch/current-source/protected-audio hashes, x64 PE/Qt import and
  path/debug checks, exact 143-file prepared native-source content and
  provenance, 199-binary dependency inspection, 148-DLL collection, and the
  distinct redistributed GStreamer 1.28.1 versus build-toolchain 1.28.5
  contracts pass. The exact public-runtime loader test and reverse-apply of
  both patches also pass. A rebuild from the extracted prepared native source
  reproduces the same core.
- The exact 13-entry review payload, shell and Setup `0.12.7.0` PE/file
  versions, Setup's internal comparison version, all five release-script
  defaults, Setup embedded-payload and `/verify-runtime` verification,
  shortcut/update lifecycle self-checks, native-source content/provenance
  checks, local links, and `git diff --check` pass. The final pre-tag payload
  and Setup were regenerated after the evidence update, and their
  embedded-payload, lifecycle, version, link, and diff checks passed again.
- Annotated tag `v0.12.7` resolves to commit
  `dd343a44b0c9b6904815cd78e54a841e9f5ef6be`. Exact-tag packaging, the normal
  latest channel, exactly four public assets, the three-entry checksum file,
  all API digests, and fresh public re-download size/SHA-256 verification pass.
  Canonical and configured legacy latest routes return the same `v0.12.7`
  Release ID `368571434`, and the legacy-route Setup hash matches. The actual
  installed update from public 0.12.6 and full physical Windows/iPhone
  acceptance remain pending.
- A public-build Windows 11/iPhone smoke on the reporter's system passes the
  urgent involuntary Photos/video session-drop target: direct Photos launch
  and a normal gallery/video session work without the prior drop, and the user
  described that corrected path as ideal. This does not accept the full
  physical matrix. One first direct-Photos connection tap failed before the
  second succeeded, inner photo/video content remains small, and an
  reporter-estimated wall-clock interruption of about 15 seconds cleared the
  placeholder after reconnect but left video frozen; its exact log interval
  records an 11-second feedback gap, and closing AeroMirror briefly exposed the
  latest frame. A reporter-estimated wall-clock Wi-Fi interruption of about ten
  seconds recovered automatically; its exact log interval records a five-second
  feedback gap.

The urgent physical Windows 11/iPhone session-drop target has a scoped PASS,
but the complete repeated sequence, Windows 10, installed-update, and
interruption matrix remain priority gates in
`docs/releases/0.12.7/TEST_PLAN.md`. This release does not crop or enlarge a
small image already encoded inside the Photos canvas, repair delayed discovery,
or make reconnection reliable.

## What 0.12.6 changes

- Status: published normal updater-visible public review Release.
- Public app/Setup version: `0.12.6`; Windows PE/file version:
  `0.12.6.0`. The five release-script defaults and Setup's internal comparison
  version target 0.12.6.
- New profiles default to an explicitly pinned Direct3D 11 decoder and sink.
  Settings schema 11 migrates only the legacy automatic renderer choice to
  Direct3D 11, preserves an explicit Direct3D 12 opt-in, and normalizes an
  unknown renderer to Direct3D 11. The Advanced UI recommends Direct3D 11 and
  no longer offers automatic GStreamer selection.
- The continuity view is inserted immediately above the external renderer
  without activation. Fatal native cleanup changes its guidance to a manual
  Screen Mirroring reconnect instruction; it does not claim that discovery or
  reconnect completed automatically.
- The released native core emits explicit HTTP ready/failed markers for initial
  bind and fatal reset. The shell accepts them only from the current PID and
  preserves same-process recovery only after a matching reset on the original
  AirPlay port; failure or mismatch exits into full-process recovery. AirPlay
  `TEARDOWN` explicitly requests disconnect.
- AirPlay photo, slideshow, and preload feature bits are cleared and a
  mirror-only capability marker is logged. This is an isolated negotiation
  experiment. Its effect on direct-in-Photos startup and the inner encoded
  canvas remains a pending physical A/B gate.
- The current managed build, settings-migration/renderer arguments coverage,
  combined resilience suite, shell and Setup `0.12.6.0` x64 PE checks, exact
  13-entry review payload, Setup embedded-payload SHA-256 comparison,
  shortcut/update lifecycle self-checks, version/link audits, and
  `git diff --check` pass. The native core rebuild is reproducible at
  SHA-256 `9f1fb168c882b1531400d2edbb4abd1277803c1971a20e9d5c4d7eff3e8498fc`;
  patch/provenance, dependency, loader, reverse-apply, archive-content, and
  prepared native-source checks pass.
  Exact-tag packaging, the normal latest channel, all four GitHub API digests,
  and public re-download byte-size/SHA-256 verification also pass. Canonical
  and legacy `releases/latest` API routes return the same `v0.12.6` Release ID.
  Installed-update and physical Windows/iPhone gates remain pending.

Direct3D 11 is the default in this public review Release, not a physically
accepted Photos fix. The small photo and black bars may still
be encoded inside iOS's `3840x2160` presentation canvas; this release does
not crop, zoom, or reconstruct those pixels. It also does not claim to make a
stale iOS browse result, receiver discovery, or automatic reconnect reliable.

## What 0.12.5 changes

- Status: published normal updater-visible review Release.
- Public/app/Setup version: `0.12.5`; Windows PE/file version: `0.12.5.0`.
- The exact recorded Photos geometry
  `3840x2160 aux=0x0 encoded=3840x2160` is now classified as an ambiguous
  presentation canvas instead of becoming the device-orientation baseline.
  A later `998x2160 aux=1421x0` phone frame can establish portrait in the same
  session, while the observed real-landscape signature and unrelated 16:9
  streams remain eligible.
- An unresolved automatic/provisional fit cannot replace a valid saved
  placement. A trustworthy device frame or explicit user move, resize, or
  manual fit makes the current placement persistable.
- The native three-second feedback warning schedules a four-second local
  continuity deadline for a capable active session. Early recovery cancels it;
  acknowledged recovery changes the view to connection-restored/waiting-for-
  image and queues handoff. Fatal reconnect handoff still waits for a real
  positioned renderer.
- The pinned UxPlay core, native patches, source provenance, and third-party
  runtime are unchanged from 0.12.4. The pre-tag gates confirm that the staged
  native core is byte-identical to 0.12.4 and that the prepared native-source
  package contains 139 files with all 12 provenance hashes validated.
- The managed x64 build, receiver resilience suite, 13-entry thin review
  payload, network Setup build and shortcut/update lifecycle self-checks,
  prepared native-source build, shell/Setup `0.12.5.0` PE audit, Setup embedded-
  payload SHA-256 comparison, source/default/document/link checks, and
  `git diff --check` pass for the tagged source.
- The final payload and Setup were regenerated after the evidence update; the
  embedded payload hash, lifecycle checks, and version audits passed again.
  Exact-tag packaging, the normal latest channel, four API digests, and public
  re-download size/SHA-256 verification also pass.
- GitHub's canonical repository is now `pyram1da/aeromirror`. The checked-in
  updater slug remains `Nadejny/aeromirror` in this immutable release; its old
  API and Setup URLs followed GitHub redirects and successfully reached the
  canonical 0.12.5 Release. The actual installed update remains pending.

This release does not crop or zoom the small photo and black bars that Photos
may already encode inside its `3840x2160` canvas. It also does not claim to fix
delayed iOS browse-cache visibility when no request reaches Windows. Installed
update and physical Windows/iPhone tests remain clearly pending; the release
must not be called physically accepted or 1.0.

## What 0.12.4 changes

- UxPlay's feedback-loss bound returns from six seconds to the upstream
  15-second default. After completed native socket cleanup, the shell preserves
  the recovered core PID and AirPlay port instead of immediately replacing the
  process and publishing a new port.
- The patched core announces feedback-health capability and emits a compact
  recovered marker. AeroMirror can show continuity after a five-second gap and
  dismiss it when the same session recovers; legacy cores cannot enter this
  pre-fatal path.
- Saved renderer placement is applied from the early Windows show event.
  Continuity remains until the real renderer exists and is positioned, then
  fades away. Safe capture uses only unobscured renderer client pixels.
- Unchanged renderer title/taskbar/topmost policy is cached instead of being
  written on every supervision tick. Proportion restoration is queued after
  interactive resize completion.
- The former Minimal latency profile is labelled Interactive and now applies
  only `-vsync no`; it no longer forces `-al 0.05`. Explicit Direct3D 11/12
  choices pin matching decoder families and sinks, with codec matching at
  pipeline creation.
- Diagnostics add feedback-gap totals, native capability state, the full raw
  AirPlay geometry header (including the previously ignored auxiliary pair),
  and actual selected decoder/sink. The raw auxiliary dimensions are not
  interpreted as crop, PAR, or rotation metadata.
- The settings Back control is larger.

The upstream revisions and third-party runtime remain pinned. The reviewed
native patch, rebuilt core, modified-source hashes, build inputs,
`UPSTREAM.lock`, source provenance, and prepared corresponding source validate
together.

## Release verification

Passed against the exact source published as `v0.12.7`:

1. managed x64 shell build and combined receiver resilience suite;
2. reproducible native core SHA-256
   `11b65324c83f23503f2d555d0064d1348c884407bf7f9b1c34d27b5d1c05fb9b`,
   exact 143-file prepared corresponding source and extracted rebuild,
   provenance/reverse-apply/dependency/loader checks, reviewed patch/source
   hashes, and the runtime 1.28.1 versus build-toolchain 1.28.5 contract;
3. exact 13-entry thin review payload, Setup build, embedded-payload SHA-256,
   and shortcut/update lifecycle verification;
4. shell/Setup `0.12.7.0` PE, internal Setup version, five script defaults,
   asset-name, documentation-version, local-link, changed-file, and
   `git diff --check` audits;
5. clean exact-tag release packaging from annotated tag object
   `6154c7f3c3384dcd039b4e1e0c2feceb46b84fad`, resolving to commit
   `dd343a44b0c9b6904815cd78e54a841e9f5ef6be`;
6. normal latest GitHub channel with Release ID `368571434`, `draft=false`,
   `prerelease=false`, and exactly four expected assets;
7. all public re-download byte sizes and SHA-256 values match final local
   release files, and all four GitHub API digest fields match;
8. canonical and configured legacy `releases/latest` API routes return the
   same `v0.12.7` Release ID, and the legacy-route Setup SHA-256 matches.

No physical Windows/iPhone result is claimed by these gates. Exact asset
evidence is in `docs/releases/0.12.7/BUILD_REPORT.md`.

## Pending physical verification and known limitations

- the installed updater path from public 0.12.6 to public 0.12.7, including
  version detection, settings/trust-state preservation, runtime-cache reuse,
  Setup launch and rollback; the public-build smoke does not prove this updater
  path;
- the installed updater path from public 0.12.5 to public 0.12.6, including
  legacy automatic-to-D3D11 migration, explicit D3D12 preservation, settings,
  trust state, shortcuts, autostart, runtime-cache reuse, digest verification,
  Setup launch, and rollback;
- Windows 11 x64 and Windows 10 1809+ x64 with an iPhone: 3–4 second,
  5–8 second, and longer-than-15-second Wi-Fi interruptions; native in-place
  recovery; fatal recovery; normal disconnect; immediate and repeated
  reconnect; delayed Wi-Fi join; idle discovery; and VPN-over-Private-LAN;
- public 0.12.7 already recovered automatically from one reporter-estimated
  wall-clock Wi-Fi interruption of about ten seconds (five-second feedback gap
  in the exact log interval), but reconnect after one reporter-estimated
  wall-clock interruption of about 15 seconds (11-second exact-log feedback
  gap) cleared the placeholder while video stayed frozen; closing AeroMirror
  briefly exposed the latest frame. This observed longer-handoff failure must
  be reproduced and corrected;
- saved placement at first show, handoff fade and renewed-loss cancellation,
  mixed-DPI/multi-monitor restore, taskbar/topmost settings, manual resize,
  safe snapshot, privacy fallback, and no focus theft or Z-order flicker;
- Balanced versus Interactive plus Direct3D 11 and Direct3D 12
  frame-pacing, audio drift, CPU/GPU, feedback-gap, and decoder/sink evidence;
- direct-in-Photos startup where the ambiguous 4K canvas arrives before a
  phone-shaped frame; portrait/landscape rotation; unresolved placement
  persistence; fullscreen media; actual inner photo size; and the schema-12
  default-off outer-window A/B without provisional-landscape persistence;
- Photos may still place a small image and black bars inside a `3840x2160`
  encoded canvas. Raw geometry diagnostics do not provide a validated content
  rectangle, so this release does not crop or zoom those pixels;
- the missing-after-long-idle receiver report: first ten-minute renewal, later
  SessionUnlock, one guarded final refresh, repeated-unlock limit, iPhone browse
  and first-tap evidence, and whether manual discovery restart remains needed;
- the Windows 10 first-install report that became usable only after reboot.
  AeroMirror extracts a portable app runtime but installs no system-wide
  .NET/VC++ redistributable, driver, or framework prerequisite and does not
  normally require reboot; retain clean-VM pre/post-reboot Bonjour
  service/process, Setup/receiver log, pending-reboot, firewall, network, and
  iPhone evidence before considering any Setup message or machine-wide service
  action;
- an external GStreamer window cannot yet provide a Mac-style hover-only frame,
  true borderless surface, or live aspect lock while dragging. Those require a
  native embedded renderer plus versioned IPC;
- continuity does not make iOS browse-cache refresh instantaneous, and a dark
  fallback remains necessary when safe renderer capture is unavailable;
- the mirror-focused feature advertisement remains a physical experiment; its
  effect on direct-in-Photos startup has not been accepted;
- genuine AirDrop interoperability remains separate Bluetooth/AWDL, identity,
  and encrypted-transfer research. A staged AeroDrop companion/share-extension
  path is a separate future product decision, not part of 0.12.7;
- localization is not included. D-006 remains the planned resource-based
  system-language and manual override design.

## Immediate next steps

1. Preserve the passing focused 0.12.9 package/Setup gate and its volatile
   final container hashes in the release handoff for an eventual
   `BUILD_REPORT.md`. Any later source or documentation edit requires that
   focused gate to run again.
2. Leave the receiver idle through its first renewal, then lock/unlock after
   cooldown and retain every guard, refresh, iPhone browse, first-tap, and
   manual-workaround result. Repeat controls for active mirroring, client grace,
   unavailable physical network, competing maintenance, repeated unlock, an
   explicit manual discovery refresh, and an actual physical-network epoch
   change. Unlock alone must not re-arm the allowance.
3. Run the schema-12 Photos A/B off/on with the same media. Measure outer client
   bounds and inner visible content separately, confirm no native restart or
   session drop, and prove provisional landscape does not overwrite a valid
   saved placement.
4. Reproduce first install on a clean Windows 10 VM without rebooting or
   mutating Bonjour until Setup/receiver logs and service/process state are
   retained. Compare receiver Stop/Start and only then a full reboot.
5. Physically repeat short and longer Wi-Fi interruptions on D3D11 with logs
   and a screen recording, using Balanced first and Interactive as a separate
   row. Confirm either a current presentation proof followed by real video or a
   persistent reconnect hint; do not claim that the underlying longer-gap video
   recovery is fixed from overlay behavior alone.
6. Retain public 0.12.7 updater/install and Photos evidence as regression
   coverage. Keep exact tag, Release, checksums, API digests, public re-download,
   and
   install-from-public pending until explicit publication authorization and the
   final rebuilt containers are verified.

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
