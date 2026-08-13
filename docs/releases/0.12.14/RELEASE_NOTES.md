# AeroMirror 0.12.14 — media-liveness diagnostic candidate

## Summary

AeroMirror 0.12.14 corrects one confirmed native video-timestamp retry defect
and adds passive, content-free media-stage health summaries so a frozen last
frame can be located between mirror ingress, appsrc, decode, and Direct3D 11
presentation.

This is an internal pretag diagnostic candidate, not a public release. Public
`v0.12.9` remains the immutable normal latest review release. The physically
failed 0.12.13 candidate remains frozen internal history; it is not renamed,
tagged, published, or replaced. A verified local 0.12.14 Setup exists for the
focused physical plan, but there is no tag, GitHub Release, public asset, public
installer, or `BUILD_REPORT.md`.

## Should I update?

- **Not yet for normal use.** No 0.12.14 installer has been published.
- Use an exact local candidate only for a focused frozen-frame test where the
  first picture appears and then stops while the iPhone still controls the
  session.
- Stay on public `v0.12.9` unless a later explicitly verified release is
  published. Automated source and pipeline checks do not prove that the
  physical 0.12.13 symptom is fixed.

## What changed

### Checked video timestamp mapping

- Every video-render retry now derives its candidate presentation timestamp
  from the same immutable remote timestamp. The prior code mutated that input
  and could apply the full remote-to-local offset again on each retry.
- The remote-to-local offset is signed, overflow-checked, and protected by the
  active mirror session and video clock epoch. A callback from an old epoch
  cannot correct the next session's clock.
- Audio and video keep separate checked clock state. Audio teardown or
  reinitialization cannot rebase the active video clock through shared offset
  storage.
- This is a confirmed source-level arithmetic correction. It is not yet proof
  that cumulative timestamp retry caused the reporter's frozen frame.

### Passive media-stage health summaries

- During an active mirror session, the native core emits one numeric
  `AEROMIRROR_VIDEO_HEALTH` line every two seconds.
- Session and geometry generations correlate mirror VCL/configuration ingress,
  pause/resume options, appsrc input and flow results, decoded-sink progress,
  Direct3D 11 Present progress, timestamp retry outcomes, monotonic ages, and
  per-interval deltas.
- The observational classifier can report `starting`, `pipeline-reset`,
  `client-paused`, `no-vcl`, `pre-appsrc`, `appsrc-error`, `unavailable`,
  `decoder-stall`, `present-stall`, or `healthy`. A class is a diagnostic hint,
  not an automatic recovery decision or physical root-cause verdict.
- The existing `AEROMIRROR_VIDEO_GEOMETRY` record remains byte-compatible for
  the managed shell. A separate diagnostic geometry record carries option,
  action, and suspension evidence.
- Health logging contains counters, ages, enums, and generations only. It does
  not log pixels, encoded payloads, audio, artwork, titles, paths, or URLs.
- The diagnostic slice does not reset or resume a pipeline, restart or
  reconnect the receiver, crop or inspect pixels, or change Photos fitting.

## Verification status

- Two independent clean compatible native builds and a rebuild from extracted
  prepared corresponding source reproduce core SHA-256
  `5A6C8AEBC381F6090AD87CBB622A370B1BA0F29923B387C72C2AE07D78605F36`.
- The reviewed libuxplay patch SHA-256 is
  `4B2AAF2C8B48BD3B993940011678DD25919C16788E1B061D733469463D4217EE`.
- Patch/provenance, runtime and loader, live redirected-pipe, and complete
  receiver resilience checks pass. The suite covers immutable retry input,
  signed overflow boundaries, stale clock epochs, separate audio/video clock
  state, fixed two-second schema/cadence, content exclusions, passive behavior,
  stage ordering, and backward-compatible geometry output.
- Source version surfaces target app/Setup `0.12.14`, Windows PE/file
  `0.12.14.0`, Setup comparison 0.12.14, and exactly five 0.12.14
  release-script defaults.
- The exact local payload contains 13 expected entries; the resilience suite
  passes against its packaged shell. Setup embeds that payload and provenance
  exactly, and `/verify-runtime`, `/verify-shortcut-selection`, and
  `/verify-update-lifecycle` each exit 0. Architecture, link, UTF-8/no-BOM,
  diff, and stable-input gates pass.
- Installed update, physical Windows/iPhone media liveness, exact tag, GitHub
  Release, and public re-download remain pending.

The acceptance matrix is in [`TEST_PLAN.md`](TEST_PLAN.md).

## Known limitations

- The first installed 0.12.13 run displayed an H.265 frame and then froze the
  last picture while the native process, control session, and mirror parser
  stayed alive; stopping Screen Mirroring on the iPhone still ended the PC
  session immediately. Version 0.12.14 has not yet repeated that physical test.
- The audit also identified a separate P1 lifecycle gap: a mirror worker that
  exits naturally can publish `running=false` before its callback tail is
  joined. A focused stop/join/rapid-restart correction is the first native
  follow-up and is not included in this diagnostic slice.
- The health classifier is intentionally passive. It does not automatically
  recover a `no-vcl`, decoder, appsrc, or Present stall.
- Photos may still provide a landscape `3840x2160` encoded canvas containing a
  portrait image and black bars. This candidate adds no validated content
  rectangle, crop, zoom, Camera-orientation fix, or pixel analysis.
- The full native-core audit, physical long-idle discovery acceptance,
  in-process BLE refresh, AWDL/peer-to-peer AirPlay, AirDrop, Windows 10
  first-install/reboot diagnosis, installed update, and signing remain pending.

The internal 0.12.10–0.12.13 candidates remain unrelabelled history. Published
`v0.12.9` and its assets remain immutable.
