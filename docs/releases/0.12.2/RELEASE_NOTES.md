# AeroMirror 0.12.2 — reconnect recovery and steadier stream windows

## Summary

This patch renews AirPlay discovery once after an abnormal Wi-Fi/client loss,
stops Photos presentation canvases from causing a false orientation change
after the iPhone frame is known, and restores stream proportions after a
manual window resize.

## Should I update?

- Yes, if AeroMirror disappeared from Screen Mirroring after Wi-Fi was toggled
  during an active stream.
- Yes, if opening a photo caused the Windows stream window to switch to an
  incorrect landscape shape.
- Yes, if you want a manually resized renderer to return automatically to the
  iPhone proportions when resizing ends.
- Optional if 0.12.1 is stable for your workflow and none of these cases apply.

## What changed

### Abnormal-loss discovery recovery

- A fatal lost-client marker now remains armed when UxPlay completes mirror
  cleanup before AeroMirror's three-second deadline.
- Once cleanup is complete, AeroMirror performs exactly one bounded receiver
  discovery renewal. A new connection request or authentication step cancels
  the pending renewal.
- A normal clean disconnect still keeps the healthy receiver process and its
  existing advertisement running; it does not trigger this recovery.
- If the stream is still active at the deadline, the existing stalled-session
  restart remains in effect.

### Orientation and Photos canvases

- The first exact video size in each mirroring session becomes the device-frame
  baseline, regardless of whether the iPhone uses a tall or 16:9 display ratio.
- Later sizes are authoritative rotation events only when their normalized
  aspect matches that baseline within `0.03`.
- After a `998x2160` device frame is learned, a Photos `3840x2160`
  presentation canvas retains the portrait window instead of forcing a false
  landscape change, including when **Fit window now** is used manually.
- Physical `1080x1920` to `1920x1080` rotation remains supported.

### Automatic window fitting

- Automatic fitting remains enabled for a new settings profile.
- Ending a real manual renderer resize queues a short delayed fit that preserves
  the selected client area while restoring the learned stream proportions.
- Moving the window without resizing it, Windows metric noise of four pixels or
  less, minimizing, maximizing, replacing the native core, or turning automatic
  fitting off does not apply the fit.
- The setting is labelled **Automatically preserve stream-window proportions**
  in Russian, and **Fit window now** remains available in the tray as a manual
  fallback.

## Compatibility

- Target: Windows 10 version 1809+ x64 and Windows 11 x64.
- The pinned UxPlay core and third-party runtime are unchanged.
- Existing settings, autostart, receiver identity, trusted-client state, logs,
  update behavior, and the Public/Unknown network protection policy remain
  compatible.
- The managed x64 build and receiver resilience suite pass.

## Known limitations

- If a session starts directly inside a media presentation canvas, that first
  exact frame may seed the wrong device baseline until the next mirroring
  session. The current stdout marker has no independent physical-orientation
  field.
- An iPhone can display a stale Screen Mirroring row whose first tap never
  reaches Windows. AeroMirror cannot accelerate a failed request it never
  receives, and iOS may take time to refresh its browse cache.
- The managed renewal starts a fresh receiver process and may use a new dynamic
  port. Same-port native DNS-SD/BLE re-publication after internal UxPlay reset
  remains future work.
- Physical Windows 10/11 and iPhone acceptance is pending; automated checks do
  not prove real-device timing or compatibility.
- Setup is unsigned, so Windows SmartScreen may warn.

## Distribution status

This is a review release authorized for public testing. The managed automated
suite, versioned review payload, installer lifecycle self-check, and native
corresponding-source provenance validation passed.
Physical Windows 10/11 and iPhone acceptance remains pending, so this release
must not be described as production-ready or as proof of real-device
compatibility.
