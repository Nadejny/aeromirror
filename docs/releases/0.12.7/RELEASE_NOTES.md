# AeroMirror 0.12.7 — media-session continuity hotfix

## Summary

AeroMirror 0.12.7 is a focused stability correction for an AirPlay session
that could end when iPhone Photos switched into photo or external-media
playback. In the captured 0.12.6 failure, the AeroMirror shell and native core
processes stayed alive; the current AirPlay control connection was removed by
a software request.

The public log did not include the debug request type, and the native server
has other software-disconnect sites. Source review nevertheless found a new
0.12.6 forced-disconnect path in the typed `TEARDOWN` handler whose timing is
consistent with the failure. This patch rolls back that plausible regression,
makes supported Windows audio-device failures nonfatal at the sink, and ensures
the shell's requested Direct3D sink actually reaches UxPlay. It does not claim
to fix the small image that Photos may encode inside a 4K presentation canvas.

## Should I update?

- **Yes**, if 0.12.6 disconnects Screen Mirroring when you open a photo or
  start a video in Photos.
- **Yes**, if the log reports a `wasapi2` endpoint/open/I/O/removal failure or
  the actual renderer marker selects D3D12 despite a D3D11 launch request.
- The update is still recommended as a stability hotfix if ordinary mirroring
  already works, but the exact affected Windows/iPhone sequence remains a
  physical acceptance test rather than a completed claim.

Existing per-user settings, receiver identity, pairing trust, logs, shortcuts,
and the pinned runtime cache are designed to survive the in-place update.

## What changed

### AirPlay teardown no longer forces an immediate control-socket removal

The type-specific AirPlay `TEARDOWN` handler retains upstream's typed-stream
teardown behavior and `Connection: close` response header. It no longer asks
the server to remove the complete control socket
immediately; the iPhone controls whether and when that socket closes. A compact
marker records the typed request and the client-managed close decision without
logging mirrored content. That marker is new evidence for the physical 0.12.7
run; no request-type marker existed in the affected 0.12.6 log.

This reverses only the over-broad 0.12.6 server-side disconnect addition. It
does not change ordinary clean disconnects, fatal lost-client cleanup, receiver
identity, or discovery registration.

### Supported Windows audio-device failures no longer end the media loop

Normal default audio now supplies
`wasapi2sink continue-on-error=true`. The redistributed runtime contains
GStreamer 1.28.1, whose `wasapi2sink` supports this property for its documented
endpoint-open, device-I/O, and device-removal failures. Those failures become
warnings while the sink continues consuming buffers instead of terminating
the shared loop.

Muted output still supplies only UxPlay's mute option. Advanced UxPlay
arguments remain last, so an experienced tester can explicitly replace the
managed audio sink. This is not a generic promise that every decoder, video,
protocol, or audio bus error is isolated from the session. GStreamer 1.28.5 is
the native build toolchain version, not the redistributed runtime version.

### Headless launches preserve the shell's renderer arguments

The uxplay-windows wrapper no longer strips and replaces external `-vs` and
`-fs` values while running in headless/`--uxplay` mode. Its legacy Qt renderer
and fullscreen preferences remain limited to the wrapper's interactive mode.
This allows AeroMirror's D3D11 default, explicit D3D12 diagnostic opt-in, and
fullscreen policy to reach UxPlay unchanged.

## Verification status

- The isolated managed 0.12.7 build and resilience suite pass, including
  default/muted/overridden audio-argument coverage and version normalization.
- Two clean native builds reproduce SHA-256
  `11b65324c83f23503f2d555d0064d1348c884407bf7f9b1c34d27b5d1c05fb9b`.
  Patch/current-source/protected-audio hashes, exact 143-file prepared
  native-source content and provenance, dependency collection, and the
  distinct redistributed GStreamer 1.28.1 versus build-toolchain 1.28.5
  contracts pass. The exact public-runtime loader test and reverse-apply of
  both patches pass as well. A rebuild from the extracted prepared native
  source reproduces the same core.
- The exact 13-entry review payload, shell and Setup `0.12.7.0` versions,
  Setup's internal comparison version and shortcut/update lifecycle checks,
  embedded-payload and `/verify-runtime` verification, all five release-script
  defaults, local links, and `git diff --check` pass. The final pre-tag payload
  and Setup were regenerated after the evidence update, and the
  embedded-payload, lifecycle, version, link, and diff gates passed again.
- Annotated tag `v0.12.7` resolves to commit
  `dd343a44b0c9b6904815cd78e54a841e9f5ef6be`. GitHub Release `368571434` is
  normal, updater-visible latest, `draft=false`, and `prerelease=false`.
  Exactly four assets were published; every API digest, final local file, and
  fresh public re-download matches. `SHA256SUMS.txt` contains exactly the three
  non-checksum assets. Canonical and configured legacy latest routes return
  the same Release ID and tag, and the legacy-route Setup hash matches.
- A public-build Windows 11/iPhone smoke on the reporter's system passes the
  urgent involuntary Photos/video session-drop target: direct Photos launch
  and a normal gallery/video session work without the former drop. The tester
  reported that corrected path working ideally.
- This is scoped evidence, not full physical acceptance. One first
  direct-Photos connection tap failed before the second succeeded; inner photo
  and video content remains small; and an approximately 15-second interruption
  and reconnect cleared the placeholder but left video frozen. The installed
  update from public 0.12.6, Windows 10, and the complete repeated/interrupt
  matrix remain pending.

The acceptance procedure and evidence requirements are in
[`TEST_PLAN.md`](TEST_PLAN.md). Exact tag, asset, hash, API-digest, and public
re-download evidence is in [`BUILD_REPORT.md`](BUILD_REPORT.md).

## Known limitations

- Photos may still place a small image and black bars inside an encoded
  `3840x2160` canvas. AeroMirror does not yet have a trustworthy content
  rectangle and does not crop or zoom those pixels by guesswork.
- A session that starts directly in the generic Photos media canvas can still
  expose ambiguous outer orientation. This hotfix targets session continuity,
  not Photos layout reconstruction.
- Delayed receiver discovery, stale iOS browse rows, and automatic Wi-Fi
  reconnection are not fixed. Manual discovery refresh or a new selection in
  Screen Mirroring may still be required.
- The first public physical smoke recovered automatically after an
  approximately ten-second Wi-Fi interruption. After an approximately
  15-second interruption and reconnect, the placeholder cleared but video
  remained frozen; closing AeroMirror briefly exposed the latest frame. That
  longer reconnect/handoff path remains unresolved.
- The connection-loss view is not guaranteed to appear immediately for every
  short interruption, and recovery is not considered complete until real
  image frames return.
- Audio failures outside the documented
  `wasapi2sink continue-on-error=true` device-failure scope retain the native
  pipeline's existing behavior.
- Direct3D 11 remains a review default pending the complete physical D3D11
  versus D3D12 matrix.
- Setup is unsigned, so Windows SmartScreen may warn about an unknown
  publisher.

Published `v0.12.7` and its four assets are immutable under AeroMirror project
policy even though GitHub reports API `immutable=false`. Any correction uses
0.12.8 or later; never move the tag or replace a published 0.12.7 asset.
