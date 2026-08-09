# AeroMirror 0.12.3 — connection-loss continuity and remembered windows

## Summary

This review candidate keeps a clear stream placeholder through fatal
connection recovery, restores the user's last stream-window placement, and
handles the recorded direct-in-Photos startup sequence more conservatively.

## Should I update?

- Yes, if a Wi-Fi interruption currently makes the renderer disappear before
  you can reconnect, or if you repeatedly move and resize the stream window.
- Yes, for testing if starting Screen Mirroring while Photos is already open
  makes the outer AeroMirror window choose the wrong landscape baseline.
- Optional if 0.12.2 is stable for your workflow and none of these cases
  apply. This candidate does not yet enlarge a photo that iOS has already
  letterboxed inside a `3840x2160` encoded canvas.

## What changed

- Added: after a confirmed fatal stream loss, AeroMirror keeps a softened view
  of the last visible renderer frame at its previous bounds while the receiver
  renews discovery. If a safe foreground capture is unavailable, it uses a
  dark fallback instead. The placeholder remains until a new mirroring start,
  explicit user close, receiver stop, or application exit.
- Added: the renderer's last normal position, outer size, and DPI persist
  across sessions. AeroMirror scales the saved size for a changed monitor DPI
  and brings stale or oversized bounds back into an available Windows work
  area.
- Fixed: an early phone-shaped raw marker is retained before the video-size
  debounce. In the recorded direct-in-Photos sequence, `998x2160` therefore
  remains the device baseline when `3840x2160` follows about 130 ms later.
- Changed: automatic fitting preserves the restored center and approximate
  client area instead of treating a restored window as a new default window.
- Changed: the tray command is **Restore window proportions**, and the
  settings Back control has a larger arrow and target.

The placeholder snapshot exists only in process memory and is never written
to a file or included in diagnostics. Benign feedback warnings and a normal
clean Screen Mirroring disconnect do not open it.

## Known limitations

- Photos content sizing is not fully fixed. iOS can send the photo and black
  bars as pixels inside a `3840x2160` encoded canvas. The managed shell can
  preserve the outer phone orientation, but the native stdout contract does
  not expose a content rectangle or crop metadata. Safe automatic crop/zoom
  requires native metadata or validated pixel analysis plus physical-device
  diagnostics.
- If iOS emits only a generic media canvas and no early phone-shaped marker,
  AeroMirror leaves the physical orientation ambiguous rather than guessing.
- The connection-loss placeholder does not make AirPlay discovery or the iOS
  browse cache refresh instant. A stale iPhone row can still fail before a
  request reaches Windows.
- Changing quality and other native startup capabilities still requires the
  iPhone to reconnect before the new setting is guaranteed to apply.
- Setup is unsigned, so Windows SmartScreen may warn about an unknown
  publisher.
- Localization is not included. The current UI remains Russian; the planned
  resource-based `System / English / Russian` choice is tracked by D-006.

## Verification status

The integrated managed build, resilience suite, review package, Setup
lifecycle checks, native corresponding-source validation, and clean exact-tag
release package pass. Version `v0.12.3` is published as the normal latest
GitHub Release:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.3

All four public assets were downloaded again with matching byte sizes and
SHA-256 values, and every GitHub API digest field matches. The installed updater
path and complete physical Windows 10/11 plus iPhone matrix remain pending, so
0.12.3 is a public review release rather than a physically accepted or 1.0
release. Exact evidence is recorded in `BUILD_REPORT.md`.

The pinned UxPlay executable and runtime, receiver identity and trusted-client
state, update protocol, and Public/Unknown physical-network fail-closed policy
are unchanged from 0.12.2.

The `v0.12.3` tag and public assets are immutable. Any correction will use
0.12.4 or later rather than replacing this release's files.
