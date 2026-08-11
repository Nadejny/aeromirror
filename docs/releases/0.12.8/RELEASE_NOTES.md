# AeroMirror 0.12.8 — evidence-gated reconnect handoff candidate

## Summary

AeroMirror 0.12.8 is a continuity-correctness candidate for a longer Wi-Fi
interruption. Public 0.12.7 could receive a healthy AirPlay feedback heartbeat,
find the old renderer window still visible, and close **Connection lost** even
though no fresh image had been presented and video remained frozen.

The 0.12.8 contract separates control recovery from displayed-video recovery.
The view may say **Connection restored / Waiting for image** after feedback
returns, but it closes only after current process, session, and recovery-epoch
evidence proves that fresh post-gap media reached the Direct3D 11 swap-chain
present path. Without that proof, AeroMirror keeps the view visible and gives
an explicit Screen Mirroring reconnect hint.

## Should I update?

- **Yes, for review**, if 0.12.7 removes the connection-loss view after Wi-Fi
  returns while the picture remains frozen.
- **Yes, for review**, if you can retain a log and screen recording from short
  and longer Wi-Fi interruptions using the default Direct3D 11 renderer.
- **Optional**, if ordinary 0.12.7 mirroring is stable and you do not need to
  test reconnect behavior. This candidate does not yet claim to repair the
  underlying long-gap video freeze.

Existing per-user settings, receiver identity, pairing trust, logs, shortcuts,
and the pinned runtime cache are designed to survive an in-place update.

## What changed

### Feedback recovery no longer proves that an image returned

`AEROMIRROR_CLIENT_FEEDBACK_RECOVERED gap_seconds=N epoch=E` identifies a
recovered AirPlay control heartbeat and carries a recovery epoch. It may
advance the view to connection-restored/waiting state, but it cannot dismiss
the view.

The only automatic fade authorization for this same-session feedback-recovery
path is a matching
`AEROMIRROR_VIDEO_PRESENT_READY epoch=E gap_seconds=N proof=d3d11-present
pts_delta_ms=D` marker. The shell accepts it only from the current native PID,
for the current managed mirror-session generation, for the currently armed
recovery epoch, and with the challenge's exact expected gap. Feedback recovery
expects its positive stored gap. Late markers from an earlier process, session,
or interruption are ignored. The current PID must first announce
`AEROMIRROR_VIDEO_PRESENT_PROOF_READY codec=h264|h265
videosink=d3d11videosink` for its selected codec.

### Media-path markers remain diagnostic

One-shot `AEROMIRROR_VIDEO_PUSH_RECOVERED` telemetry records the successful
appsrc flow, target PTS, and PTS delta. `AEROMIRROR_VIDEO_PUSH_PENDING` records a
non-OK push, and `AEROMIRROR_VIDEO_SINK_RECOVERED` records an exact target-PTS
match at the sink probe. These markers narrow the location of a freeze but do
not prove that the swap chain presented a fresh frame. A visible renderer
window, cached HWND, pixel sample, appsrc push, PTS match, or sink observation
cannot close the view by itself.

`pts_delta_ms` describes the first matching post-recovery frame. It is
instrumentation, not a timestamp-rebase command and not presentation proof by
itself.

### Missing proof fails visibly

If feedback returns in that path but current presentation proof does not arrive
within the bounded three-second wait, AeroMirror keeps the continuity view and
replaces the waiting message with explicit guidance to select the receiver
again in iPhone Screen Mirroring. It does not hide a frozen picture behind a
successful-reconnect claim.

Selecting the receiver again may emit
`AEROMIRROR_VIDEO_PRESENT_ARMED reason=mirror-start epoch=E`, but the shell
accepts it only while the current process/session is explicitly expecting that
reason. An accepted challenge restarts the three-second proof wait and expects
exactly `gap_seconds=0`; an unarmed zero-gap proof is rejected. The
mirroring-start marker alone does not close continuity. The view may return to
waiting state while the new challenge is armed; it closes only after that epoch
receives matching Direct3D 11 present proof.

This candidate deliberately does not add an automatic full receiver reset,
hot replacement of a half-open video socket, or media-clock rebasing. Those
changes require separate protocol and physical-device evidence.

## Verification status

- Source implementation and independent final code review: **pass**, with no
  remaining P0/P1/P2 finding.
- Managed build and receiver resilience checks: **pass**.
- Official native core reproducibility and extracted prepared-source rebuild:
  **pass**, both producing SHA-256
  `eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`.
  The reviewed libuxplay patch SHA-256 is
  `c5be47ee96be25609677103cf85b3d98b07e2752a980d0d6d9fb975d187ad05e`.
- Native source generation, loader test, and the
  runtime/provenance/dependency audit: **pass**. Both native patches
  reverse-apply; the source archive has 143 entries/139 files; the audit covers
  199 inspected binaries and 148 copied DLLs.
- Thin package review: **pass**, with exactly 13 entries. Setup build,
  `verify-runtime`, shortcut, and update-lifecycle exit 0, embedded
  payload/provenance match, x64 shell/Setup/core `0.12.8.0`, version/default,
  documentation-link, and diff checks: **pass**.
- Focused final package review and Setup rebuild after the evidence-doc update:
  **pass**. The exact 13 entries, embedded payload/provenance,
  `verify-runtime`, shortcut/update lifecycle, version, documentation-link, and
  diff checks pass again. Container byte sizes and hashes are retained in the
  gate handoff for the eventual `BUILD_REPORT.md`; they are intentionally not
  embedded in these self-referential source docs.
- Physical Windows 10/11 and iPhone interruption tests: **pending**.
- Exact tag, GitHub Release, checksums, API digests, public re-download, and
  install-from-public checks: **pending**. No 0.12.8 asset is public yet.

The evidence procedure and failure conditions are in
[`TEST_PLAN.md`](TEST_PLAN.md). A post-publication `BUILD_REPORT.md` will be
created only after authorized publication and public-asset verification.

## Known limitations

- This candidate corrects the handoff decision; it does not yet prove that the
  native video transport, decoder, sink, or iPhone resumes after every longer
  interruption. Manual Screen Mirroring reselection may still be required.
- Loss detection and the existing native-warning/local-continuity threshold are
  unchanged. A short interruption may recover before the view appears, and the
  view is not promised to appear immediately when Wi-Fi is disabled.
- Direct3D 12, other advanced sinks, and a legacy core do not provide the exact
  D3D11 proof. Interactive `-vsync no` deliberately skips the synchronized
  PTS/Present capability. These paths remain in waiting/reconnect guidance
  instead of using the old visible-window shortcut.
- Delayed discovery, a stale iOS browse row, and a first tap that sends no
  AirPlay request to Windows remain separate pending problems.
- Photos may still encode a small photo or video with black bars inside a
  `3840x2160` presentation canvas. AeroMirror still has no trustworthy content
  rectangle and does not crop or zoom those pixels by guesswork.
- The mirror-only AirPlay feature advertisement is unchanged. This release
  does not claim that 4K-versus-1080p capability selection fixes inner Photos
  sizing. No new exact display-capability marker is included; the comparison
  remains a physical A/B using existing launch and geometry evidence.
- Setup is unsigned, so Windows SmartScreen may warn about an unknown
  publisher.

Published `v0.12.7` and its four assets remain immutable under AeroMirror
project policy. A future public 0.12.8 must use a new tag and new assets; never
move or replace the 0.12.7 release.
