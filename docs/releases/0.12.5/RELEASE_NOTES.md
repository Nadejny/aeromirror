# AeroMirror 0.12.5 — safer Photos startup and recovery feedback

## Summary

AeroMirror no longer lets the recorded Photos `3840x2160` presentation canvas
force a portrait iPhone session and its saved stream-window placement into a
false landscape layout, and short feedback interruptions produce a more
deterministic recovery view.

## Should I update?

- **Yes**, if a session started inside Photos opened as a wide landscape window
  even though the iPhone was portrait, or if that incorrect layout was saved
  for later sessions.
- **Yes**, if the connection-loss view did not clearly indicate that feedback
  had recovered, or did not appear during a four-to-five-second interruption.
- **Optional**, if 0.12.4 already works reliably for your use. This remains a
  review release; Windows 10/11 and iPhone acceptance is still pending.

## What changed

### Photos startup and saved placement

- Correlated each native raw-geometry record with its following encoded-size
  record. Only the exact observed Photos signature—`3840x2160` primary,
  source, and encoded dimensions with `aux=0x0`—is treated as an ambiguous
  presentation canvas.
- Prevented that ambiguous first canvas from becoming the device-orientation
  baseline. A later phone-shaped `998x2160` frame can establish portrait for
  the same session, while the observed real-landscape signature and ordinary
  nonmatching 16:9 streams remain eligible as real stream sizes.
- Prevented unresolved automatic/provisional fits from overwriting a valid
  saved placement. Placement is persisted after a trustworthy device frame or
  an explicit user move, resize, or manual fit.
- Continued to treat the raw auxiliary dimensions as diagnostic evidence, not
  as crop, pixel-aspect-ratio, or rotation metadata.

### Short interruption feedback

- The pre-fatal continuity view is now scheduled from the native three-second
  warning and opens at a bounded four-second threshold if the same capable
  session is still stalled. Recovery before the deadline cancels it, so the
  result no longer depends on whether a later native warning line arrives.
- When feedback or a replacement connection is acknowledged before visible
  video returns, the view now says **Connection restored / Waiting for image**
  while the existing renderer-gated handoff continues to wait for an image.
- Kept handoff conservative: the view still waits for a real positioned
  renderer instead of treating an early protocol request as visible video.

## Known limitations

- Photos may still encode a small photo and black bars *inside* its
  `3840x2160` video canvas. This release prevents that canvas from poisoning
  the outer window orientation and saved placement, but it does not crop,
  zoom, or reconstruct the inner pixels.
- If a session exposes only the ambiguous Photos canvas and never sends a
  phone-shaped frame, AeroMirror keeps the previous or provisional outer
  orientation rather than guessing.
- Receiver visibility in the iPhone Screen Mirroring list remains a physical
  discovery gate. This patch does not claim to make an iPhone discard stale
  browse results, and a manual discovery refresh cannot manufacture a request
  that never reaches Windows.
- Windows 10 version 1809+ x64, Windows 11 x64, current iPhone/iOS, delayed
  Wi-Fi join, reconnect, Photos, and saved-placement tests remain pending.
- The external GStreamer renderer and the memory-only continuity placeholder
  retain the limitations described for 0.12.4. Genuine AirDrop, remote iPhone
  input, and localization are not included.
- Setup remains unsigned, so Windows SmartScreen may warn about an unknown
  publisher.

## Verification status

The pre-tag managed build, resilience suite, exact 13-entry review payload,
network Setup and shortcut/update lifecycle self-checks, shell/Setup
`0.12.5.0` PE checks, embedded-payload SHA comparison, prepared native-source
build, and version/document/link/diff audits pass. The native package contains
139 files with all 12 provenance hashes validated, and its core executable is
byte-identical to 0.12.4. The final payload and Setup were regenerated after
the evidence documentation update and rechecked before tagging.

Clean exact-tag packaging passed, and `v0.12.5` is published as the normal
latest updater-visible **review** Release:

https://github.com/pyram1da/aeromirror/releases/tag/v0.12.5

All four public assets were re-downloaded with matching byte sizes and SHA-256
values, and every GitHub API digest field matched. The configured former
`Nadejny/aeromirror` updater API and Setup URL also followed GitHub redirects
to the canonical repository and returned 0.12.5 successfully. The actual
installed 0.12.4-to-0.12.5 update and all physical Windows/iPhone rows in
`TEST_PLAN.md` remain pending. Passing release gates does not make this a
physically accepted or 1.0 release.

The published `v0.12.5` tag and assets are immutable. Any correction uses
0.12.6 or later and must not replace a 0.12.5 file.
