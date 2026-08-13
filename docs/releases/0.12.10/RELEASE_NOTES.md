# AeroMirror 0.12.10 — renderer geometry and test-isolation candidate

> Historical local candidate: 0.12.10 was never tagged or published and was
> superseded by 0.12.11. The evidence below records its final local state; its
> artifacts must not be relabelled as 0.12.11.

## Summary

AeroMirror 0.12.10 is a local managed-shell candidate that makes renderer
geometry decisions deterministic when iPhone applications emit repeated or
same-orientation size changes. It also prevents reflection-based resilience
tests from using the real per-user settings and log directory.

This is not a public release. A local review payload and Setup have passed the
initial automated pretag gates, but there is no 0.12.10 tag, GitHub Release,
public download, or build report. Public `v0.12.9` remains the immutable normal
latest review release, and every physical Windows/iPhone result listed below
remains pending.

## Should I update?

- **Not yet for normal use.** No 0.12.10 installer has been published.
- **Use only as a local candidate after packaging**, if you are testing a
  renderer that stays at an earlier aspect, moves repeatedly while identical
  size markers arrive, or fails to re-evaluate when the experimental Photos
  outer-window option changes.
- Stay on public `v0.12.9` until an explicitly verified later release is
  published. This candidate does not yet have physical iPhone, Windows 10/11,
  installed-update, package, or Setup acceptance.

## What changed

### Non-starving geometry debounce

- Each correlated native geometry/encoded-size event receives a monotonic
  sequence for the lifetime of the running core.
- When an identical candidate repeats during the 350 ms stability window, the
  candidate adopts the newer sequence but keeps the original deadline. A
  continuous duplicate stream can no longer postpone the stable decision
  indefinitely.
- A duplicate of the currently stable candidate does not start a new debounce.
  A device-frame/media-canvas classification change remains a distinct
  candidate even when the dimensions match.
- Starting a new mirroring session clears session candidates and baselines but
  does not rewind the core-lifetime sequence. A full core reset clears it.

### Target-class and exact-aspect fitting

- The renderer records the selected fit target as `DeviceFrame` or
  `MediaCanvas`, plus its exact aspect ratio and the newest consumed event.
- A fresh stable event refits the outer window when either the target class or
  exact aspect changes. This covers same-orientation transitions such as
  `3840x1776` device frame to `3840x2160` media canvas, which a simple
  portrait/landscape check could miss.
- A scaled marker with the same class and exact aspect is consumed without
  moving the renderer on every supervision pass.
- Changing the default-off Photos/media option re-evaluates the already stable
  geometry without waiting for another marker. If that pass is blocked by an
  active resize/mouse gesture, or a fit fails, the target mismatch remains
  pending and is retried. Automatic provisional media-canvas fits still cannot
  become trusted device orientation or overwrite a valid saved placement.

### Reflection-test storage and log isolation

- The resilience harness sets one process-lifetime storage root before
  reflection initializes `AppSettings` or logging. The accepted root must be a
  GUID-named direct child of the system temporary directory; setting the same
  root again is idempotent and a different second root is rejected.
- Settings, receiver key, trust database, logs, and diagnostic snapshots all
  resolve under that isolated root for the test process.
- The asynchronous logger exposes a deterministic drain result. Tests wait for
  the queue before reading markers and before deleting the exact temporary
  root, leaving the production
  `%LOCALAPPDATA%\AirPlayReceiverMvp\receiver.log` untouched.
- A failed run preserves the exact GUID root and prints its path as a warning
  for diagnosis. Only a fully successful run with a drained logger deletes it.

## Compatibility and verification status

- Local app/Setup version is `0.12.10`; Windows PE/file version is
  `0.12.10.0`. Setup's comparison version and exactly five release-script
  defaults target 0.12.10.
- Settings schema remains 12 and `FollowPhotosMediaCanvas` remains false for
  clean and migrated profiles. Existing settings, trust, receiver key, and
  placement contracts are unchanged.
- The managed implementation build and complete receiver resilience suite
  pass, including deterministic geometry/refit and isolated-log cases.
- No native source, AirPlay capability, patch, runtime, or dependency change is
  in scope. Unchanged-native reuse/provenance, prepared-source, exact 13-entry
  review-payload, Setup, embedded-resource, runtime-loader, shortcut, and
  update-lifecycle checks pass in the initial full pretag run. The focused
  payload/Setup rebuild after these evidence documents stabilized also passes;
  exact final container hashes remain in the gate handoff.
- Same-process, same-port DNS-SD/BLE re-publication after native HTTP reset is
  still `DESIGN/NEXT`. Version 0.12.10 adds no `refreshDiscovery` command,
  acknowledged ready marker, or registration-lifetime change.
- Physical iPhone tests on Windows 10 and Windows 11, Photos/Camera/video and
  rapid-orientation testing, long-gap reconnect, discovery, installed update,
  exact tag, GitHub Release, and public downloads are pending.

The candidate acceptance matrix is in [`TEST_PLAN.md`](TEST_PLAN.md). A
`BUILD_REPORT.md` is intentionally absent until publication and public-asset
verification.

## Known limitations

- Correct outer-window refitting does not reveal or crop a smaller photo/video
  already letterboxed inside the encoded iPhone canvas.
- Geometry still arrives through reviewed stdout markers rather than a
  versioned native IPC contract with explicit orientation/content rectangles.
- Discovery can still require a managed process refresh or manual user action;
  in-process same-port DNS-SD/BLE re-publication is not implemented.
- The longer-gap frozen-video path, Windows 10 first-install/reboot report, and
  all physical device behavior retain their 0.12.9 pending status.

Published `v0.12.9` and its four assets remain immutable under AeroMirror
project policy. Version 0.12.10 remained untagged and unpublished; 0.12.11 is
the later local patch candidate and has its own release notes and test plan.
