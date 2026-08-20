# AeroMirror 0.12.17 — Photos presentation acceptance

## Purpose

This plan verifies that fullscreen and opt-in Photos zoom act on the selected
native renderer without restarting the receiver, corrupting geometry state, or
claiming an automatic orientation/crop fix.

0.12.17 is a normal-channel review release for physical validation. Public
`v0.12.16` assets remain immutable, and no physical result is inferred from
publication.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Version/default surfaces | PASS | Shell/Setup `0.12.17.0`, Setup comparison and exactly five defaults `0.12.17` |
| Managed Release build | PASS | Current x64 source compiles |
| Complete receiver resilience | PASS | Existing lifecycle/discovery/install regressions and new presentation source contracts pass |
| Native presentation source contract | PASS | Narrow command grammar, GLib-owner dispatch, property-backed fullscreen, uniform 100–250% scale, and lifecycle reset |
| Native worker/core contracts | PASS | Eight worker scenarios plus parser, transport, SETUP, renderer, and crypto checks |
| Reproducible native build | PASS | Two clean 57/57 builds reproduce core SHA-256 `53B13433B9308547D491417F11692361DFC5B6EBFBDA018B8D3EEE7B4436436F` |
| Staged runtime and loader | PASS | 199 binaries, 148 DLLs, 44 features to 27 plug-ins, loader exit 0 |
| Corresponding source | PASS | 147-entry ZIP, all pinned hashes, no-Git validation, and extracted clean 57/57 rebuild reproduce the reviewed core |
| Review payload and Setup | PASS | Exact 13-entry package, packaged-shell resilience, embedded equality, x64 `0.12.17.0`, and all three self-checks |
| Physical Photos fullscreen | PENDING | Fullscreen enters/exits repeatedly without focus tricks, process restart, or stale state |
| Physical Photos zoom | PENDING | 100–250% steps enlarge the inner image, crop predictably, reset on exit/new session, and never apply to normal phone-shaped mirroring |
| Camera and rotation | PENDING | Portrait/landscape, orientation lock, Camera, home screen, and Photos transitions on at least two DPI configurations |
| Installed update | PENDING | Settings, identity, shortcuts, autostart, runtime, launch, and rollback |
| Tag and publication | PASS | Annotated `v0.12.17`, Release `373934492`, exact four assets, checksums, API digests, canonical/legacy latest routes, and fresh public re-download equality |

## Automated contract

- Managed standard-input writes are serialized, reject line breaks, and target
  only the current ready core process.
- The wrapper accepts only exact `video-fullscreen-toggle` or four-digit
  `video-scale permille=N` commands; the native API independently restricts
  scale to 1000–2500.
- Presentation work is attached to the active GLib main context. Renderer
  access takes a retained selected-sink reference before reading or changing
  properties.
- Fullscreen enables the D3D11 property toggle mode and changes the `fullscreen`
  property; no Windows keyboard-message injection is present.
- Scale changes `scale-x` and `scale-y` to the same value. Renderer start and
  managed media-class exit restore 1000 permille.
- The shell exposes zoom only for the exact replay-backed Photos media-canvas
  class. Normal portrait/landscape device frames remain unscaled.
- Installer shortcut/update self-verification derives its newer-version case
  from the current Setup version, so a patch-number bump cannot turn the
  downgrade guard into a stale same-version assertion.

## Physical test A — fullscreen

1. Install only the exact gated 0.12.17 candidate and record shell/core hashes.
2. Start Screen Mirroring and open Photos with both portrait and landscape
   media.
3. From the tray, toggle **Полный экран** on and off ten times, including once
   after a rotation and once after changing photo/video.
4. Require the same shell/core PID, continued motion, working audio where
   present, and immediate iPhone Stop. Retain every
   `AEROMIRROR_VIDEO_FULLSCREEN` result.

## Physical test B — manual Photos zoom

1. Capture the renderer client bounds and visible image bounds at 100% for the
   exact `3840x2160 aux=0x0 encoded=3840x2160` Photos canvas.
2. Increase zoom through 110%, 150%, 200%, and 250%. Confirm that the image
   grows uniformly and record which edges/UI are cropped.
3. Decrease and reset to 100%. Switch back to a phone-shaped home-screen or
   Camera frame and require automatic reset.
4. End mirroring while zoomed, reconnect, and require the new session to start
   at 100%.
5. Attempt zoom outside the exact media canvas and require no native scale
   command or visual change.

Zoom passes only as an explicit user crop. Black-bar detection, automatic crop,
and reconstruction of an original photo are not acceptance criteria because
the receiver does not possess a validated content rectangle.

## Physical test C — orientation regression

Repeat Photos, Camera, home screen, video fullscreen, orientation lock, and
rapid portrait/landscape changes. Record raw geometry, encoded size, renderer
client bounds, fullscreen/scale results, and visible motion. Run on two Windows
DPI settings when available. A wide outer window alone is not evidence that
the inner photo is correctly sized.

## Discovery carry-forward

The 0.12.16 long-lived listener and recurring same-process DNS-SD maintenance
must remain green. The finite two-hour test is retained as a practical network
and iPhone-cache soak; deterministic tests separately prove that the schedule
continues beyond any fixed number of renewals.

## Acceptance boundary

Automated acceptance does not prove physical Photos sizing or rotation.
Publication is complete and is not physical acceptance. Installation remains a
separately authorized action; exact tag and public-asset evidence is recorded
in [BUILD_REPORT.md](BUILD_REPORT.md).
