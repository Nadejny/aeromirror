# AeroMirror 0.12.6 — D3D11 stability and clearer reconnect guidance

## Summary

AeroMirror now uses a pinned Direct3D 11 video pipeline by default for more
predictable resolution changes, and its connection-loss view gives clearer
manual reconnect guidance without stealing focus.

## Should I update?

- **Yes, for testing**, if mirroring froze when entering Photos, opening a
  photo, or reconnecting to a stream whose encoded resolution changed.
- **Yes, for testing**, if the connection-loss view appeared behind the video
  window or continued to imply that a fatal session would recover by itself.
- **Optional**, if 0.12.5 works reliably for you. This remains a public review
  Release: physical Windows 10/11 and iPhone acceptance is pending.

## What changed

### Direct3D 11 stability default

- New profiles explicitly pin the Direct3D 11 decoder family and video sink.
  This avoids relying on GStreamer's automatic ranking, which selected
  Direct3D 12 in the observed Photos session.
- Existing profiles that still use the legacy `auto` renderer migrate to
  Direct3D 11 through settings schema 11. An explicit Direct3D 12 choice is
  preserved as an experimental opt-in.
- Advanced settings now recommend Direct3D 11 and no longer offer automatic
  GStreamer selection. Advanced UxPlay arguments remain later on the command
  line, so an experienced tester can still make an explicit diagnostic
  override.

### Connection-loss presentation

- The continuity view is inserted immediately above the external renderer
  without activating itself. Ordinary streams do not acquire a permanent
  topmost policy, while the user's explicit **Always on top** choice remains
  respected.
- After fatal native cleanup, the view names the receiver and asks the user to
  select it again in iPhone Screen Mirroring. A clean **Stop Mirroring** still
  closes transient continuity instead of showing a false failure.
- A renewed or fatal loss during the 180 ms renderer handoff cancels the fade,
  restores full opacity, and leaves continuity visible.

### Explicit native reset state

- Native HTTP startup and fatal reset emit explicit ready or failed markers.
  AeroMirror accepts them only from the current core process and preserves
  same-process recovery only when the reset rebinds the exact original
  advertised AirPlay port.
- A bind failure or port mismatch now cleans up and exits instead of falling
  through to a false ready state, allowing the shell's bounded full-process
  recovery path to take over.
- An AirPlay `TEARDOWN` request explicitly closes the client connection so a
  normal end does not remain half-open.

### Mirror-only feature experiment

- The native receiver clears unused AirPlay photo, slideshow, and photo-
  preload feature bits and logs a mirror-only capability marker. AeroMirror
  still advertises and accepts screen mirroring, audio, authentication, and
  supported metadata capabilities.
- This is an isolated negotiation experiment. Its effect on direct-in-Photos
  startup and iOS's inner presentation canvas remains a physical A/B test; it
  is not described as a Photos sizing fix.

## Known limitations

- Direct3D 11 is a stability candidate, not a proven universal fix. The
  Direct3D 11 versus Direct3D 12 Photos and resolution-change matrix remains a
  physical-device gate.
- Photos may still encode a small image and black bars *inside* its
  `3840x2160` presentation canvas. This release does not crop, zoom, infer a
  content rectangle, or reconstruct those pixels.
- Receiver discovery and automatic reconnect are not claimed as fixed. iOS
  may retain a stale browse result, and a manual refresh cannot manufacture a
  connection request that never reaches Windows.
- Explicit HTTP reset readiness confirms the listening port, not DNS-SD/BLE
  re-publication or iOS browse-cache refresh.
- The external GStreamer renderer, raw geometry markers, and saved-placement
  heuristics retain the limitations documented for 0.12.5.
- Windows 10 version 1809+ x64, Windows 11 x64, current iPhone/iOS, Photos,
  interruption, reconnect, delayed Wi-Fi, and installed-update tests remain
  pending.
- Setup remains unsigned, so Windows SmartScreen may warn about an unknown
  publisher.

## Verification status

The managed build, settings migration and renderer argument coverage,
combined resilience suite, shell and Setup `0.12.6.0` x64 PE checks, exact
13-entry review payload, Setup embedded-payload SHA-256 comparison,
shortcut/update lifecycle self-checks, version/link audits, and
`git diff --check` pass for the exact tagged source. The native
core rebuild is reproducible at SHA-256
`9f1fb168c882b1531400d2edbb4abd1277803c1971a20e9d5c4d7eff3e8498fc`;
patch/provenance, dependency, loader, reverse-apply, archive-content, and
prepared native-source checks pass. Clean exact-tag packaging also passes.

`v0.12.6` is published from commit
`c860909ad9b6a1098d524142b111857e522a7104` as the normal latest,
non-draft, non-prerelease public review Release:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.6

All four public assets were downloaded again with matching byte sizes and
SHA-256 values, and every GitHub API digest matched. Canonical and configured
legacy `releases/latest` API routes returned the same Release ID `367881011`.
Exact evidence is in `BUILD_REPORT.md`.

The installed 0.12.5-to-0.12.6 update and every physical Windows/iPhone row in
`TEST_PLAN.md` remain pending. Passing release gates does not prove the inner
Photos canvas, discovery, or automatic reconnect is fixed and does not make
this a physically accepted or 1.0 release.

AeroMirror project policy treats the published `v0.12.6` tag and four assets
as immutable. Any correction uses 0.12.7 or later and must not replace a
0.12.6 file.
