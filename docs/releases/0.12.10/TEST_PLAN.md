# AeroMirror 0.12.10 — geometry and test-isolation acceptance

> Historical local plan: 0.12.10 was never tagged or published and was
> superseded by 0.12.11. Completed rows below remain 0.12.10 evidence; pending
> physical work continues under the 0.12.11 plan, and artifacts are not
> relabelled between versions.

## Purpose

This plan verifies that AeroMirror 0.12.10:

1. orders correlated geometry events without allowing duplicate traffic to
   starve the 350 ms stable-size debounce;
2. refits the outer renderer when the selected target class or exact aspect
   changes, including same-orientation transitions;
3. keeps reflection-based tests inside one validated temporary storage root,
   drains asynchronous logging deterministically, and leaves the real user log
   untouched; and
4. preserves the 0.12.9 settings, native, discovery, reconnect, persistence,
   installer, and release contracts outside that managed scope.

Public `v0.12.9` remains the immutable normal latest review release. Version
0.12.10 is a local candidate with an automation-verified initial review
payload and Setup but no tag, GitHub Release, public asset, or
`BUILD_REPORT.md`.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Managed implementation build | PASS | Current managed source compiles after the geometry and test-isolation changes |
| Complete receiver resilience suite | PASS | Deterministic debounce/refit/reset/persistence and temporary-root/log-drain cases pass |
| Shell/Setup/source version surfaces | PASS | Source declares 0.12.10/0.12.10.0 and exactly five script defaults; strict audit retained |
| Settings schema/default | PASS | Schema remains 12 and clean/migrated `FollowPhotosMediaCanvas` remains false |
| Documentation links/strict UTF-8/diff | PASS | Local link, UTF-8, version, and `git diff --check` audits pass |
| Final independent source review | PASS | Post-fix review reports no unresolved P0/P1/P2 finding |
| Candidate native reuse/provenance | PASS | No native delta; provenance, reverse-apply, prepared-source, exact core, runtime, and loader checks pass |
| Initial 0.12.10 thin package | PASS | Exact 13-entry payload, version, runtime, and provenance checks pass |
| Initial 0.12.10 Setup and lifecycle | PASS | Build, PE version, embedded payload/provenance, `/verify-runtime`, shortcut and update lifecycle pass |
| Focused post-evidence package/Setup freeze | PASS | Exact 13-entry payload, embedded resources, runtime loader, shortcut, update lifecycle, version, link and diff checks pass after evidence stabilization |
| Physical iPhone on Windows 10/11 | PENDING | Photos, video, Camera, rotation, reconnect, discovery, placement, and logs |
| Installed update and persistence | PENDING | Exact public 0.12.9-to-candidate update plus settings/trust/key/shortcut lifecycle |
| Exact tag and GitHub Release | PENDING | Explicit authorization, immutable tag, expected assets, checksums, API and fresh-download match |

The managed build and resilience results do not substitute for exact candidate
packaging or physical Windows/iPhone behavior. Keep every pending row pending
until its own evidence is retained.

## Environment and evidence to retain

For automated work, retain the exact commit or dirty-tree diff, shell used,
test command, start/end time, exit code, and full failure text. Confirm the
test process starts without an earlier `AppSettings`/logger initialization.

For each physical row, record:

- exact candidate shell and Setup SHA-256, PE/file version, and package source;
- Windows edition/build, x64 architecture, GPU/renderer, display scale, and
  clean-install versus update state;
- iPhone model, iOS version, Rotation Lock, and the exact app/photo/video;
- network adapter/category, access point/band, VPN/virtual-adapter state, and
  exact local timestamps;
- outer renderer client bounds, visible inner-content bounds, native geometry
  and encoded-size markers, and before/after screenshots or a privacy-safe
  recording;
- reviewed `receiver.log` plus `setup.log` for installation work.

Never upload settings, PINs, receiver keys, trust records, private media, or an
unreviewed diagnostic artifact.

## Automated acceptance

1. Build the complete managed source set and verify the candidate executable
   metadata reports `0.12.10.0` when the exact release build is produced.
2. Run the complete receiver resilience suite and retain these deterministic
   cases:
   - an identical pending candidate advances its event sequence but retains the
     original deadline;
   - the candidate commits at or after that deadline even while duplicates
     continue;
   - a duplicate of the stable current value does not reopen the debounce;
   - a target-class change with identical dimensions remains a distinct event;
   - a new mirror session clears candidates/baselines but preserves the core-
     lifetime sequence, while full core reset clears it;
   - `3840x1776 DeviceFrame` to `3840x2160 MediaCanvas` refits;
   - same-class exact-aspect change refits, scaled same-class/same-aspect does
     not, and a class change at the same aspect refits;
   - toggling the Photos option re-evaluates the stable geometry without a new
     marker, native restart, trusted-orientation promotion, or provisional-
     placement save;
   - if the setting-change pass is blocked by active resize/mouse state or a
     fit failure, the same-sequence class/aspect mismatch remains pending and
     the next eligible supervision pass still applies it.
3. Before any reflection context creates persistent state, create one GUID-
   named direct child of the process temporary directory and call the one-shot
   test storage override. Verify:
   - all settings, key, trust, log, and diagnostic paths resolve below it;
   - repeating the same override is harmless and a different root is rejected;
   - unique test/log markers and a fake-core diagnostic appear only after a
     successful bounded logger drain;
   - the production `%LOCALAPPDATA%\AirPlayReceiverMvp\receiver.log` timestamp,
     length, and hash are unchanged when it exists;
   - the exact isolated root is removed only after a successful final drain;
   - a setup/runtime failure preserves the exact GUID root and emits its path
     through a warning instead of deleting evidence silently.
4. Audit candidate contracts:
   - shell and Setup assembly/file versions are `0.12.10.0`;
   - Setup comparison version is `0.12.10`;
   - exactly five release-script defaults are `0.12.10`;
   - settings schema is 12 and the Photos option remains default-false;
   - no native source/runtime/provenance input changed;
   - local Markdown links resolve, changed text is strict UTF-8, and
     `git diff --check` passes;
   - `docs/releases/0.12.10/BUILD_REPORT.md` does not exist before publication.

## Physical test A — geometry sequence and renderer refitting

Run on Windows 11 first, then Windows 10, using the same iPhone and fixed
display scale.

1. Start mirroring from the home screen and record the initial device-frame
   geometry, outer client bounds, and stable-fit marker.
2. Open Photos directly, then the same portrait photo, landscape photo,
   Full HD/30 video, and HEVC 4K/60 video. Record every geometry/size pair and
   whether repeated values delay the first stable fit beyond the intended
   debounce.
3. Exercise a same-orientation exact-aspect change. Include the observed
   `3840x1776` device-frame to `3840x2160` media-canvas transition when the
   phone produces it. Confirm the outer window refits once for the new class or
   aspect and does not oscillate on repeated/scaled equivalent markers.
4. Toggle **Make the window wide for photos and videos from Photos
   (experimental)** while the stable Photos canvas is current. Confirm an
   immediate outer-window re-evaluation without native restart or a new marker.
   Repeat off/on and confirm no resize loop.
5. Rotate through home screen, Photos, fullscreen video, Camera, and a game.
   Test rapid portrait/landscape changes with Rotation Lock both relevantly off
   and on. The outer renderer must follow received geometry without guessing
   from inner pixels.
6. End a session after an automatic provisional media-canvas fit, reconnect,
   and confirm it did not overwrite a previously valid placement. Repeat after
   an explicit user move/resize to distinguish user-owned persistence.

Measure outer-window correctness separately from visible media inside the
encoded canvas. This row does not pass merely because a small inner photo is
made wider, and it does not require unsafe crop/zoom.

## Physical test B — log isolation and production diagnostics

1. Before the automated suite, record existence, last-write time, length, and
   SHA-256 of the real per-user `receiver.log` without opening AeroMirror.
2. Run the full reflection suite in a fresh test process and retain its reported
   isolated root, successful drain markers, and cleanup result.
3. Verify the real log and other real per-user persistent files are byte- and
   metadata-unchanged. The GUID test root must be absent after success.
4. Launch the normal candidate, reproduce one harmless diagnostic event, and
   confirm production logging still uses
   `%LOCALAPPDATA%\AirPlayReceiverMvp\receiver.log`.

## Physical test C — regression matrix

1. Repeat Photos A/B off/on, Camera, fullscreen video, rapid rotation, manual
   resize, **Restore window proportions**, minimized/maximized handling, and
   multi-DPI monitor placement.
2. Repeat normal disconnect, short Wi-Fi interruption, longer-gap reconnect,
   and manual Screen Mirroring reselection. Preserve the 0.12.9 Direct3D 11
   presentation-proof rules; do not report a frozen frame as recovered.
3. Exercise normal idle/unlock discovery behavior, but treat same-process,
   same-port DNS-SD/BLE re-publication as out of scope. No new
   `refreshDiscovery` command or acknowledged ready marker should be claimed.
4. On clean Windows 10 and Windows 11 environments, run install, launch,
   restart, update from exact public 0.12.9, uninstall, and settings/trust/key/
   shortcut persistence checks. Retain pre-reboot Bonjour evidence for any
   recurrence of the Windows 10 first-install report.

## Failure and acceptance conditions

The candidate fails its scoped target if any of these occurs:

- repeated identical geometry postpones a pending stable decision indefinitely
  or causes recurring window movement after the stable target is consumed;
- a target-class or exact-aspect change is missed merely because orientation
  remains portrait or landscape;
- a scaled same-class/same-aspect marker causes repeated refits;
- a Photos toggle needs a native restart/new marker, promotes an ambiguous
  canvas to trusted device orientation, or persists provisional placement;
- reflection tests create, append, rotate, truncate, or delete any production
  user setting, trust, key, diagnostic, or log file;
- the temporary-root override accepts an unsafe path, silently changes roots,
  inspects logs before a successful drain, or leaves its root after success;
- schema/default/native/discovery behavior changes beyond the documented scope;
- any document describes same-port discovery refresh, a package, Setup, tag,
  GitHub Release, public asset, or physical Windows/iPhone result as complete
  before its independent gate passes.

The completed source/package rows remain historical 0.12.10 evidence. This
candidate was not tagged or published and receives no `BUILD_REPORT.md`.
Current source, packaging, physical Windows/iPhone, installed-update, and any
future publication gates are defined independently by the 0.12.11 plan.
