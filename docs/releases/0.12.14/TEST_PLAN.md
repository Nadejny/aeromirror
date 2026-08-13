# AeroMirror 0.12.14 — media-liveness diagnostic acceptance

## Purpose

This plan verifies that AeroMirror 0.12.14:

1. maps every video retry from one immutable remote timestamp through a signed,
   session/epoch-protected offset;
2. records enough passive media-stage progress to locate a frozen last frame
   without logging content or changing pipeline behavior;
3. preserves the existing shell/native discovery, geometry, renderer, audio,
   and teardown contracts; and
4. remains an internal diagnostic candidate until the exact physical symptom
   is repeated successfully with retained evidence.

Public `v0.12.9` remains the immutable normal latest review release. The failed
0.12.13 physical candidate remains frozen internal history. Version 0.12.14 has
no tag, GitHub Release, public asset, public installer, or `BUILD_REPORT.md`.
A verified local Setup exists only for the focused physical plan.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Two clean compatible native builds | PASS | Both reproduce core SHA-256 `5A6C8AEBC381F6090AD87CBB622A370B1BA0F29923B387C72C2AE07D78605F36` |
| Extracted prepared-source rebuild | PASS | The prepared tree without Git metadata reproduces the same executable |
| Patch and provenance validation | PASS | Reviewed libuxplay patch SHA-256 `4B2AAF2C8B48BD3B993940011678DD25919C16788E1B061D733469463D4217EE`, modified-source inputs, and expected core agree |
| Runtime, loader, and live command pipe | PASS | The reviewed core loads in the pinned runtime and existing redirected protocol cases pass |
| Complete receiver resilience suite | PASS | Timestamp oracle/bounds/epochs, health cadence/schema/privacy/passivity, stage ordering, and legacy geometry checks pass |
| Version/default surfaces | PASS | Shell/Setup `0.12.14.0`, Setup 0.12.14, exactly five 0.12.14 script defaults |
| Documentation link/UTF-8/diff audit | PASS | 61 source Markdown files, 31 local references, strict UTF-8/no-added-BOM, stale-claim scan, and `git diff --check` pass |
| Local package and Setup | PASS | Exact 13-entry payload, packaged-shell resilience, embedded payload/provenance equality, x64/version/default checks, and all three waited Setup self-checks pass |
| Physical reproduction of the 0.12.13 freeze | PENDING | Continuous screen recording plus complete new health sequence around first frame, freeze, and iPhone Stop |
| Ten-minute uninterrupted moving video | PENDING | Three runs without a frozen last frame, with advancing VCL/appsrc/sink/Present evidence |
| Resolution/Photos and pause/resume transitions | PENDING | Geometry/config/action ordering and visible behavior agree; Photos inner content is measured separately |
| Natural worker exit/join lifecycle | PENDING | Separate focused P1 fix and stop/join/rapid-restart evidence; not part of this slice |
| Installed update | PENDING | Install the exact verified local Setup and retain settings/identity/log/update persistence evidence |
| Exact tag and GitHub Release | PENDING | Separate explicit authorization and immutable public-asset gates |

Automated tests establish source and arithmetic behavior only. They do not
identify the physical freeze boundary or prove iPhone/Windows acceptance.

## Environment and evidence to retain

For automated work, retain the exact source diff, commands, start/end times,
exit codes, patch/provenance/core identities, and complete failure text.

For every physical run, retain:

- exact candidate shell, Setup if one is later built, core SHA-256, and
  PE/file versions;
- Windows edition/build, x64 architecture, GPU/driver, renderer, latency,
  quality, audio selection, display scale, and monitor layout;
- iPhone model, iOS version, sending app, phone orientation, Wi-Fi band/access
  point, and synchronized local timestamps;
- a screen recording or second-device video showing first motion, the exact
  freeze or uninterrupted interval, any audio behavior, and the iPhone Stop;
- `receiver.log` from before Screen Mirroring selection until after the final
  native teardown, including every `AEROMIRROR_VIDEO_HEALTH` line;
- current core PID, listener ports, session and geometry generations, codec,
  selected decoder/sink, raw geometry, and mirror start/stop markers.

Never share PINs, receiver keys, trusted-client state, unreviewed settings,
private media, or an unreviewed diagnostic archive. Health lines contain no
media content, but the surrounding legacy log can contain names, paths, local
addresses, and arguments that still require review and redaction.

## Automated acceptance

1. Audit version sources:
   - shell and Setup assembly/file versions are `0.12.14.0`;
   - Setup comparison version is `0.12.14`;
   - exactly five release-script defaults are `0.12.14`;
   - internal 0.12.10–0.12.13 and public 0.12.9 history is not relabelled;
   - `docs/releases/0.12.14/BUILD_REPORT.md` does not exist.
2. Verify native provenance and reproducibility:
   - both complete upstream diffs equal their reviewed patches;
   - every modified source/build input and executable hash matches provenance;
   - two clean builds and the extracted prepared source reproduce the reviewed
     core;
   - loader, architecture/import, path/debug, dependency, protected-source,
     and reverse-apply checks pass.
3. Verify immutable video timestamp mapping:
   - retry zero, one, and multiple use the same raw remote timestamp;
   - positive and negative signed offsets and overflow/underflow boundaries
     produce checked results;
   - an old session or clock epoch cannot correct a newly reset clock;
   - retries remain bounded to ten and never compound a prior candidate PTS;
   - video and audio clock state is independent.
4. Verify health-summary contract:
   - exactly one fixed schema is emitted at a two-second cadence only while a
     mirror session is active;
   - session/geometry generations, totals, deltas, ages, flow/pipeline state,
     PTS outcomes, proof availability, and class are numeric or fixed enums;
   - all documented classes are reachable by deterministic inputs;
   - a session transition is revalidated immediately before logging;
   - counters do not cause an automatic pause, resume, reset, reconnect, crop,
     or content inspection.
5. Verify stage coverage and ordering:
   - mirror VCL/type/config/action evidence is recorded before rendering;
   - delivered codec configuration is counted only after video processing;
   - both appsrc flow paths update health without per-frame log spam;
   - sink and Present callbacks update bounded atomic counters only;
   - the legacy `AEROMIRROR_VIDEO_GEOMETRY` line remains byte-compatible.
6. Resolve all source Markdown links, decode changed text as strict UTF-8
   without an accidental BOM, scan for stale current-version/publication/fix
   claims, and run `git diff --check`.

## Physical test A — exact frozen-last-frame reproduction

1. Start the exact candidate with Balanced latency, Direct3D 11, normal audio,
   and a stable local network. Record PID, ports, codec, and start time.
2. Select AeroMirror from iPhone Screen Mirroring while showing a continuously
   changing source such as a clock or scrolling screen. Do not start in Photos.
3. Require a real moving picture, not only the first frame. Leave the source
   changing for at least 60 seconds. If it freezes, keep the session untouched
   for another 20 seconds so at least ten health intervals are retained.
4. Stop Screen Mirroring on the iPhone. Record whether audio/video and the PC
   window stop immediately even when the picture was frozen.
5. Preserve the complete health sequence. Correlate visible motion/freeze with
   `d_vcl`, `d_input`, `d_push_ok`, `d_sink`, `d_present`, ages, flow/state,
   PTS counters, pause/resume, proof, and class. Do not declare a root cause
   from `class` alone.
6. Repeat three times after a clean normal stop/start of mirroring. Retain a
   failed first attempt instead of erasing it through immediate restart.

## Physical test B — sustained motion and clock correction

1. Run a changing home-screen or browser view for ten minutes. Require visible
   motion and continued VCL, appsrc, sink, and Present progress throughout.
2. Repeat with audio muted and normal audio. Video clock behavior must not
   change because the audio pipeline starts, tears down, or selects an endpoint.
3. Exercise one short Wi-Fi impairment separately. Retain any PTS retry and
   correction counts plus actual visible recovery. A successful push, sink
   callback, or `class=healthy` alone is not proof of a fresh displayed frame.
4. Fail the run on overflow-like timestamps, unbounded retry, multi-second
   future PTS growth, stale-epoch correction, frozen video, or audio teardown
   ending/rebasing video.

## Physical test C — geometry, config, and client actions

1. Rotate a rotation-capable app portrait/landscape, then open and close Photos
   using the same known vertical media. Retain every geometry generation,
   configuration pending/delivered/discarded counter, option/action, and visible
   transition.
2. If the sender emits pause/resume, require the diagnostic action and suspended
   state to agree with visible behavior. Never require AeroMirror to synthesize
   resume automatically in this candidate.
3. Measure outer renderer client bounds and visible inner photo/video bounds
   separately. A landscape 3840x2160 canvas or a wider outer window is not
   evidence that portrait inner media was detected or enlarged.
4. Repeat normal iPhone Stop, immediate reselection, three sequential sessions,
   and application exit. Retain evidence for any worker that exits before the
   normal stop/join path; the known P1 lifecycle gap remains a separate fix.

## Physical test D — carried regression boundaries

1. Run the 0.12.13 same-PID/same-port automatic DNS-SD refresh and the manual
   full DNS-SD-plus-BLE restart controls. Media diagnostics must not change
   discovery ownership or claim continuous iPhone visibility.
2. Repeat PIN/trust, receiver-name normalization, normal disconnect, delayed
   first connection, sleep/resume, and physical IPv4 change. Preserve exact
   existing safety and fallback behavior.
3. Do not combine this acceptance with AWDL, AirDrop, Photos crop, Camera
   orientation, BLE in-process refresh, or a broad core rewrite.

## Failure and acceptance conditions

The candidate fails if any of these occurs:

- any retry uses a previously mapped timestamp as its remote input, an old
  epoch corrects the current clock, or audio and video share mutable offset
  state again;
- health output contains media content or a variable user value, floods at
  frame cadence, survives outside an active session, or triggers recovery;
- legacy geometry output changes incompatibly, stage counters are ordered
  falsely, or a stale session emits a current health line;
- a physical run freezes, drops the session, loses visible motion while
  claiming acceptance, or treats a diagnostic class as root-cause proof;
- documentation claims the 0.12.13 physical defect, Photos/Camera, discovery,
  AWDL, full core audit, package/install, tag, or publication is complete
  without direct evidence.

Source-level implementation acceptance requires every automated row above.
Physical media acceptance additionally requires all three exact-reproduction
runs and the ten-minute sustained runs to pass with screen and log evidence.
Packaging and publication remain separate later gates requiring explicit user
authorization. Only after publication may `BUILD_REPORT.md` be added.
