# AeroMirror roadmap

This file records product work that is intentionally outside the current
review build. It is not a promise that every item will ship. Protocol-facing
features must be validated against current iOS behavior, compatible hardware,
upstream licenses, and applicable platform rules before implementation.

## Reliability foundation

### Native core IPC and a real ready state

Version 0.11.1 adds explicit DNS-SD/BLE stdout markers, listening-socket
checks, and bounded recovery. This is still a transitional one-way contract:
it is not versioned IPC and cannot provide commands, acknowledgements, or a
fully authoritative AirPlay session state.

- [ ] Add a versioned local IPC contract, preferably JSON Lines over a
  per-user Windows named pipe.
- [ ] Emit explicit core states such as `starting`, `mdnsReady`, `ready`,
  `clientConnected`, `streamStarted`, `streamStopped`, `recovering`, and
  `error`.
- [ ] Include stable error codes and a short user-safe explanation with every
  failure event.
- [ ] Add graceful commands such as `shutdown`, `refreshDiscovery`, and
  `getStatus`; do not use process presence or renderer-window discovery as a
  substitute for readiness.
- [ ] Give every core launch and AirPlay session a correlation ID so shell and
  native logs can be matched.
- [ ] Define protocol version negotiation so an older shell can fail safely
  with a newer core and vice versa.

Acceptance target: the UI says “ready” only after the native core confirms
that its network advertisement and listening services are active.

### Crash diagnostics

- [x] Capture the native core's standard output and standard error in a
  rotating local log.
- [x] Add top-level exception reporting for the Windows shell and termination
  metadata for the native core.
- [ ] Produce opt-in minidumps for unexpected crashes using Windows Error
  Reporting LocalDumps or `MiniDumpWriteDump`.
- [ ] Extend the existing application/core version, Windows, renderer, and
  lifecycle logging with GPU details and explicit AirPlay session phases,
  without recording mirrored content.
- [ ] Add a “Create diagnostic package” action with preview, redaction, size
  limit, and explicit user consent before sharing.
- [ ] Never include a PIN, receiver key, trusted-client register, media
  payload, or unrelated personal files in a diagnostic package.
- [x] Rotate the log at 5 MB and retain one previous log file.

Acceptance target: a tester can report a crash with its exact time and attach
one redacted package that identifies whether the shell, native core, decoder,
renderer, or discovery layer failed.

## Streaming experience

### Live quality switching

The current quality values are advertised to the iPhone during AirPlay session
setup. Changing a selector in the Windows shell cannot by itself change the
already incoming encoded stream.

- [ ] Research whether the active AirPlay session supports safe display
  capability renegotiation with current iOS versions.
- [ ] Add an IPC command and acknowledgement only if the native core can
  perform a real renegotiation.
- [ ] Preserve the current preset and explain when a reconnect is required if
  the sender rejects a live change.
- [ ] Avoid silently rescaling the renderer and presenting that as a quality
  change.
- [ ] Test resolution, codec, frame rate, latency, audio continuity, and
  fallback behavior on multiple iPhone generations.

Acceptance target: the UI reports the quality actually acknowledged by the
sender, not merely the requested preset.

### Orientation and photo/video sizing

Version 0.11 provides an interim path: a newly discovered renderer receives a
provisional fit, then the first stable exact encoded size reported through the
reviewed native log marker refines it. Later portrait/landscape changes preserve
the user's manually chosen scale. The unchecked work below covers the richer
metadata, versioned IPC, device matrix, and edge cases still required before
this behavior is considered complete.

- [ ] Log source dimensions, pixel aspect ratio, rotation metadata, and
  renderer dimensions for orientation transitions.
- [ ] Distinguish an iPhone orientation change from an app displaying
  portrait media inside a landscape stream.
- [ ] Pass source-size/orientation events through native IPC.
- [ ] Resize or letterbox the viewer without cropping content, repeatedly
  shrinking the window, or creating a resize feedback loop.
- [ ] Respect iPhone orientation lock: AeroMirror should follow the stream
  metadata it receives rather than guessing from the displayed image.
- [ ] Keep a user option for fixed window size versus automatic fitting.
- [ ] Test Photos, fullscreen video, Camera, home-screen rotation, and rapid
  portrait/landscape transitions on displays with different DPI scaling.

Acceptance target: photos and videos keep their correct proportions and remain
legible while the viewer changes orientation only when the incoming stream
does.

## Future capabilities

### Remote taps and swipes

Standard AirPlay screen mirroring is a receiver/output path and does not expose
a documented, general-purpose channel for injecting taps or swipes into iOS.
Apple's iPhone Mirroring integration on macOS should not be assumed to be part
of public AirPlay; it relies on Apple-controlled platform integration and
private capabilities.

- [ ] Treat arbitrary iPhone control from Windows as research, not an MVP
  commitment.
- [ ] Verify current public Apple APIs, iOS security boundaries, App Store
  rules, accessibility constraints, and device-pairing requirements before
  designing a control channel.
- [ ] Do not simulate support by drawing a pointer over the mirrored video.
- [ ] If a companion iOS app is considered, clearly document that it could
  control only content and actions exposed by that companion app, not the
  iOS home screen or arbitrary third-party apps.
- [ ] Consider limited receiver-side controls—mute, window sizing, pause where
  the sender protocol supports it—separately from iOS input injection.

Acceptance target: no control feature is advertised unless it performs a real,
authorized action on supported iOS versions and has a clear security model.

### AirDrop-like file transfer

AirDrop is separate from AirPlay and combines discovery, peer-to-peer
networking, identity, and encrypted transfer behavior. It must not be treated
as a small extension of screen mirroring.

- [ ] Research AWDL/Bluetooth/Wi-Fi hardware and driver constraints on
  supported Windows devices.
- [ ] Review protocol implementations and licenses independently from the
  GPL-licensed receiver stack.
- [ ] Define threat modeling, sender confirmation, destination selection,
  quarantine/Mark-of-the-Web behavior, duplicate names, and transfer limits.
- [ ] Evaluate a standards-based or companion-app transfer mode as a separate
  product path if native AirDrop interoperability is not reliable.
- [ ] Keep file transfer isolated from the receiver process and its firewall
  surface.

Acceptance target: transfers are encrypted, explicitly accepted, safely
stored, and tested on representative Wi-Fi/Bluetooth chipsets.

### Smart TV receiver research

Commercial Smart TV receivers are useful behavioral references, but their
firmware and proprietary applications are not reusable source code.

- [ ] Build a comparison matrix of connection time, discovery reliability,
  orientation changes, photo/video sizing, codec negotiation, buffering,
  reconnect behavior, and network changes.
- [ ] Prefer published standards, vendor documentation, and license-compatible
  open-source receiver implementations.
- [ ] Use black-box interoperability observations only where legally
  appropriate; do not copy proprietary firmware, keys, certificates, or
  decompiled code.
- [ ] Separate behavior caused by AirPlay negotiation from TV-specific
  hardware decoders, display pipelines, and vendor optimizations.
- [ ] Turn every useful observation into a reproducible test before changing
  AeroMirror.

Acceptance target: the research produces source-linked hypotheses and
repeatable tests, not claims based only on subjective visual comparison.

## Release gates for these items

Before any roadmap item is marked complete:

1. document its supported Windows and iOS versions;
2. add a failure and rollback path;
3. add automated tests where the boundary can be simulated;
4. complete manual interoperability tests on at least two physical PCs and
   two iPhone/iOS combinations;
5. update the privacy, security, third-party notice, and release-note
   documentation where applicable.
