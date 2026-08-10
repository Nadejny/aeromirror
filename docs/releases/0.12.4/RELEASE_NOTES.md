# AeroMirror 0.12.4 — smoother recovery and renderer handoff

## Summary

AeroMirror now gives a temporarily interrupted AirPlay session more time to
recover in place, keeps the same receiver process and port after native socket
recovery, and hands the continuity view back to the real renderer with less
visible jumping.

## Should I update?

- **Yes**, if Screen Mirroring disappeared, took a long time to reconnect, or
  opened in the saved position only after first flashing elsewhere.
- **Yes**, if the former Minimal latency profile stuttered, or an explicit
  Direct3D mode did not provide a useful decoder comparison.
- **Optional**, if 0.12.3 already reconnects reliably and none of these issues
  affects your setup. This is still a review release with physical acceptance
  pending.

## What changed

### Connection recovery

- Restored UxPlay's upstream 15-second feedback-reset tolerance instead of
  treating a six-second Wi-Fi interruption as fatal.
- Kept the existing native receiver PID and AirPlay port when UxPlay finishes
  its own lost-client socket reset. The shell no longer immediately replaces
  that recovered process and publishes a new port.
- Added compact native feedback-health capability and recovered markers. With
  the patched core, AeroMirror can show its continuity view after five seconds
  without feedback and dismiss it if the same active session recovers. Older
  cores remain conservatively gated and cannot use this pre-fatal path.
- Added feedback-gap episode count, longest-gap duration, and capability state
  to the support report.

### Stream-window continuity

- Applied saved renderer bounds from the early Windows show event, reducing
  the visible move from the renderer's default position.
- Kept the continuity placeholder until a real renderer window exists and has
  been positioned. It then fades away over 180 ms instead of disappearing on
  the earlier protocol-start line.
- Captured only the renderer client area and rejected capture if another
  visible higher window overlaps it. The image remains memory-only and is not
  written to logs, settings, diagnostics, or temporary files.
- Cached the last applied renderer title, taskbar, and topmost policy so an
  unchanged renderer is no longer mutated on every supervision tick.
- Queued proportion restoration on the supervision pass after an interactive
  resize ends. The shell still does not interfere while the user is dragging.
- Enlarged the settings Back control.

### Smoothness and renderer diagnostics

- Renamed the former **Minimal** latency profile to **Interactive**. It now
  applies only UxPlay's `-vsync no`; it no longer forces the 50 ms audio-buffer
  request that could make jitter more visible. Balanced remains the default.
- An explicit Direct3D 11 or Direct3D 12 selection now pins both the matching
  Direct3D decoder family and video sink; UxPlay matches H.264 or HEVC when the
  pipeline is created. Automatic selection remains recommended.
- Added the full raw AirPlay geometry header, including the previously ignored
  auxiliary width/height pair, plus the actual decoder and video sink selected
  by GStreamer. These fields are diagnostic evidence only: this release does
  not claim that the auxiliary pair is a crop, pixel-aspect-ratio, or rotation
  signal.

## Known limitations

- This release is not physically accepted yet. Windows 10 version 1809+ x64,
  Windows 11 x64, and current iPhone/iOS reconnect and streaming tests remain
  pending.
- Photos can still send a `3840x2160` canvas that already contains a small
  photo and black bars. The new diagnostics expose more evidence, but this
  release does not crop or zoom unknown inner content and therefore does not
  fix the tiny-photo case.
- The stream window is still owned by an external GStreamer process. A
  Mac-style hover-only frame, true borderless window, live aspect lock during
  edge dragging, and a single embedded rendering surface require a separate
  native renderer plus versioned IPC design.
- The continuity view is presentation only. It cannot force iOS to discard a
  stale browse result, and it uses a dark fallback whenever a safe, unobscured
  renderer snapshot is unavailable.
- Interactive mode can reduce motion delay, but disabling timestamp scheduling
  can make audio/video synchronization less exact. Network quality, local
  packet loss, Wi-Fi interference, decoding, and frame pacing still determine
  actual smoothness.
- AirDrop, remote iPhone input, and localization are not included. AirDrop is
  a separate Bluetooth/AWDL, identity, and encrypted-transfer problem rather
  than an extension of the AirPlay receiver.
- The installer remains unsigned, so Windows SmartScreen may warn about an
  unknown publisher.

## Verification status

The managed build and resilience suite, rebuilt native-core provenance,
`UPSTREAM.lock` commit/patch/core-hash consistency, prepared corresponding
source, review payload, network Setup and lifecycle verification, version/link
audit, `git diff --check`, clean exact-tag packaging, and public re-download/API
digest checks pass for the published review Release. `v0.12.4` is the normal
latest updater-visible Release:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.4

Passing these automated gates does not substitute for the installed-update and
physical matrix in `TEST_PLAN.md` and does not make this a 1.0 release.

The tag and four public assets are immutable. Any correction will use 0.12.5
or later rather than replacing this release's files.
