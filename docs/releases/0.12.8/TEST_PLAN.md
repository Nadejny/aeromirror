# AeroMirror 0.12.8 — evidence-gated reconnect acceptance

## Purpose and release state

This plan verifies that AeroMirror never dismisses same-session feedback-gap
continuity merely because AirPlay feedback returned and an old renderer window
is still visible. The 0.12.8 candidate must distinguish four stages:

1. control feedback recovered;
2. a post-gap video buffer was pushed through the media pipeline;
3. sink/timestamp diagnostics observed the target buffer;
4. a current Direct3D 11 swap-chain present path proved the fresh post-gap
   frame.

Only stage 4 may authorize the automatic fade. The exact marker is
`AEROMIRROR_VIDEO_PRESENT_READY epoch=E gap_seconds=N proof=d3d11-present
pts_delta_ms=D`; it must belong to the current native PID, managed
mirror-session generation, armed recovery epoch, and expected reason/gap. If
that evidence does not arrive, the view must remain visible and change from
**Connection restored / Waiting for image** to an explicit iPhone Screen
Mirroring reconnect hint after the bounded three-second wait.

The 0.12.8 source implementation and independent final code review are complete
with no remaining P0/P1/P2 finding. Managed build/resilience, official native
reproducibility and prepared-source rebuild, runtime/provenance/dependency,
loader, thin-package, and Setup pretag gates pass. The focused final package
review and Setup rebuild after the evidence-doc update also pass. Physical
devices, exact tag, GitHub Release, public hashes, re-download, and
install-from-public verification remain pending. No 0.12.8 asset is public.

## Evidence basis

The public 0.12.7 reporter log contains a longer interruption whose exact
feedback interval is 11 seconds. Feedback recovered and the old external
renderer HWND was still visible, so the shell faded the placeholder without a
fresh-frame marker. The user observed frozen video and a brief latest-frame
flash when ending the session. The log proves neither the source of the freeze
nor a successful displayed-frame recovery.

The 0.12.8 acceptance target is therefore truthful presentation state. It is
not a claim that HTTP feedback alone means video recovered, and it does not
require an unreviewed automatic reset, socket takeover, or clock rebase.

## Retained pretag evidence

- Managed build and the complete receiver resilience suite pass.
- The official native build and extracted prepared native-source rebuild both
  produce core SHA-256
  `eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`.
  The reviewed libuxplay patch SHA-256 is
  `c5be47ee96be25609677103cf85b3d98b07e2752a980d0d6d9fb975d187ad05e`.
- Both native patches reverse-apply. Native source generation produces 143
  archive entries/139 files, and the loader test passes. The retained
  runtime/provenance/dependency audit covers 199 inspected binaries and 148
  copied DLLs.
- The thin review package contains exactly 13 entries. Setup builds,
  `verify-runtime`, shortcut, and update-lifecycle checks exit 0, and its
  embedded payload/provenance comparison passes. Shell, Setup, and core are x64
  `0.12.8.0`.
- Version/default, documentation-link, and diff gates pass. Independent final
  code review reports no P0/P1/P2 finding.

These are pretag source/package gates, not physical or public evidence. A
focused package review and Setup rebuild performed after the evidence-doc
update pass again: exact 13 entries, embedded payload/provenance,
`verify-runtime`, shortcut/update lifecycle, version, link, and diff checks all
pass. Exact container sizes and hashes are retained in the gate handoff for the
eventual `BUILD_REPORT.md`; they are not embedded in these self-referential
source docs.

## Test environment record

Retain the following for every automated package or physical run:

- exact source commit and whether the worktree was clean;
- shell and Setup PE/file versions (`0.12.8.0` expected);
- native executable SHA-256 and source/provenance state;
- install path: clean install, in-place update, or unpackaged engineering run;
- Windows edition/build, x64 architecture, GPU and driver;
- renderer choice and actual selected decoder/video sink;
- iPhone model, iOS version, Wi-Fi band/access point, and PC connection type;
- physical network profile and whether VPN/virtual adapters were active;
- exact local start/failure/recovery times and time zone.

Use Balanced latency and the default Direct3D 11 renderer for the primary
acceptance path. Direct3D 12 and other advanced sinks are negative/fallback
rows until they provide an equivalent reviewed presentation proof. Interactive
`-vsync no` deliberately skips the synchronized proof in this candidate and is
a reconnect-guidance negative row.

## Evidence to retain

- complete `receiver.log` from before connection through the final recovery or
  clean stop, without truncating the first feedback warning;
- a screen recording showing the iPhone action, Windows continuity view, real
  image return or reconnect hint, and elapsed interruption time;
- current core PID, managed mirror-session generation, mirroring start/stop
  transitions, recovery epoch, feedback gap, and all one-shot
  `AEROMIRROR_VIDEO_PUSH_RECOVERED`,
  `AEROMIRROR_VIDEO_PUSH_PENDING`, `AEROMIRROR_VIDEO_SINK_RECOVERED`,
  `AEROMIRROR_VIDEO_PRESENT_ARMED`, and `AEROMIRROR_VIDEO_PRESENT_READY` marker
  lines; retain the shell's accepted/ignored proof line that records core and
  session correlation;
- actual selected GStreamer decoder/sink and AirPlay geometry markers;
- package/build/test command transcripts and exit codes;
- Setup journal for an installed-update row;
- screenshots only when they clarify a UI state; never retain mirrored media
  as an automated diagnostic artifact.

Reporter-estimated wall-clock Wi-Fi-off time and exact log-marker gap are
different measurements. Record both and do not substitute one for the other.

## Automated and source gates

1. Build the managed shell in an isolated output directory. Confirm
   `AeroMirror.exe` reports `0.12.8.0`.
2. Run the combined receiver resilience suite. It must cover:
   - feedback recovery changes the view to waiting but cannot fade it;
   - `AEROMIRROR_VIDEO_PUSH_RECOVERED`, `AEROMIRROR_VIDEO_PUSH_PENDING`,
     `AEROMIRROR_VIDEO_SINK_RECOVERED`,
     renderer visibility, cached HWND, and pixel observations cannot fade it;
   - a repeated mirroring-start/protocol-start marker in the same feedback-gap
     session cannot route through the fatal replacement-renderer handoff;
     manual reselection may arm a new
     `AEROMIRROR_VIDEO_PRESENT_ARMED reason=mirror-start epoch=E` challenge,
     but only while that reason is expected, and only its matching D3D11
     present proof may fade continuity;
   - `gap_seconds=0` is accepted only for a matching epoch explicitly armed by
     `reason=mirror-start`; a feedback-recovery epoch still requires its
     positive bounded gap, and an unarmed zero-gap marker is ignored;
   - a matching current-PID/current-session/current-epoch
     `AEROMIRROR_VIDEO_PRESENT_READY ... proof=d3d11-present` marker authorizes
     exactly one handoff only after the current PID announced
     `AEROMIRROR_VIDEO_PRESENT_PROOF_READY ... videosink=d3d11videosink`;
   - a stale PID, earlier session generation, wrong/zero epoch, duplicate
     marker, malformed proof, and marker received before recovery are ignored;
   - a renewed loss during the fade cancels handoff and restores continuity;
   - no presentation proof reaches the three-second waiting timeout and
     displays reconnect guidance without an automatic reset; an accepted
     mirror-start challenge restarts that wait;
   - Direct3D 12, another advanced sink, Interactive `-vsync no`, and a legacy
     core cannot fall back to visible-window handoff; Interactive must not
     announce the synchronized present-proof capability;
   - explicit user close, clean stop, and application exit still close the
     view immediately.
3. Rebuild any changed native core twice and retain matching SHA-256 evidence.
   Validate both native patches, modified-source hashes, protected files,
   dependencies, exact public-runtime loading, reverse apply, prepared native
   source, and extracted rebuild according to the pinned provenance contract.
4. Confirm the feedback marker carries an epoch and recovery video diagnostics
   are one-shot per epoch. Confirm push flow/target PTS, exact sink PTS, and
   non-OK push markers report only their documented stages. The presentation
   marker must be emitted only from the reviewed Direct3D 11 present path after
   that epoch has both an accepted push and exact sink-PTS match; its exact
   capability marker must identify the selected codec plus `d3d11videosink`.
5. Confirm all diagnostic markers exclude media contents, client secrets,
   receiver keys, and trusted-client data.
6. Build the exact review payload and Setup. Verify:
   - shell and Setup PE/file versions are `0.12.8.0`;
   - Setup's internal comparison version is `0.12.8`;
   - all five release-script defaults are `0.12.8`;
   - the embedded payload equals the reviewed payload;
   - shortcut/update lifecycle, rollback, runtime verification, source and
     documentation links, and exact payload contents pass.
7. Run `git diff --check`. Tag, release, checksums, public API digests, and
   re-download checks remain pending until explicit publication authorization.

## Physical Windows/iPhone matrix

Run every row with retained timestamps, log, and screen recording. Repeat the
priority D3D11 interruption rows at least three times before describing them as
stable.

1. **Baseline session:** connect from the iPhone home screen, mirror a static
   screen, open Photos, open/close a photo and video, and disconnect normally.
   No involuntary session drop, stale continuity view, or shell/core crash.
2. **Short interruption (about 3–4 seconds):** restore Wi-Fi before continuity
   becomes visible. Video resumes or remains on the last frame without a false
   success/failure flash; record whether a recovery epoch was armed.
3. **Visible short/medium interruption (about 5–8 seconds):** continuity becomes
   visible. Feedback recovery changes it to waiting. It fades only after the
   matching present-proof marker and actual moving or deliberately changed
   iPhone content is visible.
4. **Longer interruption (reporter-estimated about 15 seconds):** if a current
   present proof arrives and real video resumes, the view may fade. If video
   remains frozen or no proof arrives, continuity must remain and change to the
   reconnect hint. Merely leaving the old frozen renderer exposed is a failure.
   Select the receiver again: mirror-start alone must keep continuity visible;
   the view may return to waiting while a new challenge is armed, and only its
   matching D3D11 present proof may then hand off.
5. **Static-image recovery:** leave the iPhone on an unchanged screen while
   reconnecting. A genuinely presented fresh frame may authorize handoff even
   when pixels are identical; pixel-change heuristics must not be required.
6. **Repeated loss:** trigger a new interruption during waiting and during the
   180 ms fade. The new epoch invalidates old evidence and continuity remains
   visible until the new epoch has valid proof or reconnect guidance.
7. **Stale marker isolation:** where practical, restart the core or create a new
   mirroring session after a recorded recovery. Late evidence from the old PID,
   session generation, or epoch must not close the new view.
8. **Non-D3D11/legacy negative path:** test Direct3D 12 and one practical
   advanced sink override. Feedback may recover, but without an equivalent
   accepted presentation marker the view stays in waiting/reconnect guidance.
   Renderer visibility must not revive the 0.12.7 shortcut.
9. **Interactive latency:** repeat a visible interruption with `-vsync no`.
   The exact synchronized D3D11 Present capability must not be announced, and
   continuity must remain with reconnect guidance rather than using a
   push/PTS/sink or unsynchronized Present marker as a substitute.
10. **Clean stop and explicit close:** normal iPhone stop does not open a loss
   view. User close, Stop receiver, settings shutdown, and app exit close any
   existing view immediately.
11. **Direct-in-Photos and first tap:** start Screen Mirroring while Photos is
    open. Record separately whether the first iPhone tap reached Windows. A tap
    with no AirPlay request is a discovery/first-contact failure, not a media
    pipeline failure.
12. **Photos inner-media sizing:** test 1080p and HEVC 4K presets. No new exact
    display-capability marker landed, so retain the shell launch preset and raw
    geometry markers, then measure the visible inner photo/video size from the
    screen recording. This row is diagnostic: feature bits remain unchanged,
    and 0.12.8 does not claim to fix small content inside the encoded canvas.
13. **Installed update and persistence:** update public 0.12.7 to the exact
    candidate Setup. Preserve settings, trust state, receiver identity,
    shortcuts, autostart, window placement, runtime cache, and rollback.
14. **Platform coverage:** run the priority rows on Windows 11 x64 and Windows
    10 1809+ x64 with retained iPhone/iOS details. Automated checks alone do
    not accept either platform.

## Failure conditions

The 0.12.8 candidate fails its scoped continuity target if any of these occurs:

- feedback recovery, renderer visibility, cached HWND, pixel sampling, appsrc
  push, PTS, or sink telemetry closes the view without a matching
  Direct3D 11 presentation proof;
- a same-session mirroring-start marker bypasses the feedback recovery epoch by
  queuing the fatal/new-replacement renderer handoff;
- manual reselection closes continuity on mirror-start before the newly armed
  epoch receives matching D3D11 present proof;
- the matching mirror-start present proof is rejected solely because its
  documented `gap_seconds=0` differs from a positive feedback gap, or an
  unarmed zero-gap proof is accepted;
- a marker from the wrong PID, session generation, or epoch authorizes fade;
- a current valid presentation marker is ignored or causes duplicate handoffs;
- no proof arrives but the view disappears instead of showing reconnect
  guidance;
- a renewed loss during fade leaves continuity hidden;
- the shell or core crashes, loops restarts, leaks duplicate receiver
  processes, loses settings/trust state, or weakens the Public-network gate;
- the implementation silently adds an automatic core reset, half-open socket
  replacement, media-clock rebase, or unvalidated Photos crop outside the
  documented candidate scope;
- source, binary, Setup, defaults, payload, provenance, assets, or documentation
  versions disagree.

A still-frozen long-gap stream is a broader recovery failure and must remain
recorded. It does not invalidate the narrower evidence-gated handoff only when
the UI remains truthful and does not expose the frozen renderer as recovered.
Small Photos content and a first tap that sends no request also remain known
separate failures, not accepted 0.12.8 fixes.

## Acceptance and publication gate

The scoped implementation gate requires the automated negative/positive marker
matrix. A retained D3D11 physical run must then prove that the view either hands
off with matching present evidence and real video or stays visible with
reconnect guidance before the behavior is called physically accepted.

Before any public review candidate, preserve the completed managed/native,
provenance, version/default, link, clean-source, and focused final package/Setup
evidence. Any further source or documentation edit requires the focused package
gate to run again. Retain exact container hashes in the gate handoff and carry
them into the eventual `BUILD_REPORT.md`. Obtain explicit publication
authorization. Physical rows may remain pending only when the Release says so
and makes no acceptance claim. After publication, verify the new
immutable tag and all public assets, then add `BUILD_REPORT.md` with exact
commit, tag, Release ID, byte sizes, SHA-256 digests, API state, re-download
results, and still-pending physical rows. Never modify the published 0.12.7
tag or assets.
