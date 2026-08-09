# AeroMirror roadmap

This file records product work that is intentionally outside the current
review build. It is not a promise that every item will ship. Protocol-facing
features must be validated against current iOS behavior, compatible hardware,
upstream licenses, and applicable platform rules before implementation.

## Reliability foundation

### 0.12 repository restructure

The 0.12 cleanup must be a sequence of reviewable, behavior-preserving
changes. Do not combine directory moves with AirPlay lifecycle fixes or native
protocol work. Preserve the installed executable name, persistent per-user
paths and registry identities, receiver key and trust state, native runtime
layout, public asset names, and source-provenance checks throughout the move.

#### Phase 1: managed application source

- [x] Record a clean build and resilience-test baseline before moving source.
- [x] Split the single managed shell source into focused files for program
  startup, settings, receiver supervision, discovery and recovery, renderer
  policy, networking, updates, diagnostics, UI controls, theming, and Win32
  interop.
- [x] Keep the existing namespace and runtime identifiers during the
  mechanical split; rename or redesign them only in a separate reviewed
  change with migration coverage.
- [x] Update the build to compile all managed source files deterministically.
- [x] Update resilience checks so they no longer assume one source filename.
- [x] Remove unreachable legacy forms only after the split passes the same
  build and tests, as a separately reviewed cleanup step.

Acceptance target: the shell is behaviorally unchanged, its executable still
targets Windows 10 1809+ x64 and Windows 11 x64, and existing settings,
autostart, pairing identity, logs, and update behavior remain compatible.

#### Phase 2: installer and packaging source

- [ ] Split installer UI, paths, logging, runtime acquisition, transaction,
  process shutdown, shortcuts, registry, and verification logic into focused
  files without changing embedded resource names or upgrade identity.
- [ ] Consolidate duplicated PowerShell helpers for safe child paths, PE
  inspection, hashes, manifests, and version validation.
- [ ] Keep stable root build and release entry points as thin wrappers while
  moving implementation scripts into a documented `scripts/` layout.
- [ ] Separate final deliverables, reusable downloaded caches, and temporary
  staging so failed builds cannot leave ambiguous release inputs.
- [ ] Add bounded, preview-first cleanup for generated output; cache deletion
  must remain an explicit separate choice.

Acceptance target: setup and in-place update verification pass with exactly
the same installed paths, registry identity, shortcuts, payload contract, and
rollback behavior.

#### Phase 3: version and documentation enforcement

- [ ] Introduce one checked-in public-version source and generate the required
  four-part Windows assembly versions during build.
- [ ] Make every build, installer, packaging, and release command reject a
  requested version that differs from the checked-in version.
- [ ] Add an automated documentation gate implementing
  `docs/DOCUMENTATION_POLICY.md`.
- [ ] Move historical build reports and test plans into
  `docs/releases/<version>/` with link-preserving documentation updates.
- [ ] Keep curated release notes in the repository and use them as the GitHub
  Release body instead of relying on an ignored local artifact.

Acceptance target: a patch cannot reach the release step with inconsistent
app, installer, asset, changelog, project-state, release-note, or test-plan
versions.

#### Phase 4: continuous verification

- [ ] Add `.editorconfig` and explicit UTF-8/LF rules compatible with Windows
  PowerShell and the current compiler.
- [ ] Add a single local command that runs the shell build, resilience checks,
  installer logic checks where inputs are available, documentation policy,
  and `git diff --check`.
- [ ] Add an isolated temporary-profile integration test that exercises the
  complete `AppSettings.Load()` and `Save()` wiring, including first save and
  an injected replacement failure, without touching a user's real settings.
- [ ] Add a Windows CI workflow for network-free build and test gates; keep
  native/runtime download and public release jobs pinned and separately
  authorized.
- [ ] Document which gates are automated and which still require physical
  Windows and iPhone hardware.

Acceptance target: local and CI checks use the same entry point and cannot
publish, sign, or mutate a GitHub Release as a side effect.

### UI accessibility and physical DPI acceptance

- [ ] Make compact help controls keyboard-focusable without turning blank card
  space into a tooltip target.
- [ ] Draw an explicit focus cue and expose the same help text through keyboard
  interaction as through pointer hover.
- [ ] Add physical Windows 10/11 checks for tooltip hit testing, transparent
  compositing, optical centering, and per-monitor DPI transitions.

Acceptance target: pointer, keyboard, and assistive-technology users reach the
same help content, with retained screenshots at representative Windows display
scales.

### Native core IPC and a real ready state

Version 0.11.1 adds explicit DNS-SD/BLE stdout markers, listening-socket
checks, and bounded recovery. This is still a transitional one-way contract:
it is not versioned IPC and cannot provide commands, acknowledgements, or a
fully authoritative AirPlay session state.

Version 0.12.2 adds a managed one-shot discovery renewal after an explicit
lost-client marker and completed native cleanup. It does not replace the
native service registration in place, and it cannot force an iPhone to discard
a stale browse result that never reaches Windows.

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
- [ ] Re-publish DNS-SD and BLE on the same listening port after the native
  HTTP reset, then emit an acknowledged ready marker. Refactor the current
  registration ownership first so unregister/register cannot reuse freed
  service-name or hardware-address storage.
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

Version 0.12.2 extends the interim path: a newly discovered renderer receives a
provisional fit, then the first stable exact encoded size in the session seeds
a device-frame baseline. Later normalized ratios within `0.03` follow physical
rotation, while a different media-canvas ratio retains the learned orientation.
Interactive resize completion also restores the learned proportions by default
without overriding an explicit opt-out. The unchecked work below covers richer
metadata, versioned IPC, a direct-media-first ambiguity, device validation, and
edge cases still required before this behavior is considered complete.

- [ ] Log source dimensions, pixel aspect ratio, rotation metadata, and
  renderer dimensions for orientation transitions.
- [x] Suppress a different Photos/media canvas ratio after a device-frame
  baseline has been learned for the current session.
- [ ] Resolve sessions that start directly inside a media canvas without
  guessing that the first exact frame is the physical device ratio.
- [ ] Pass source-size/orientation events through native IPC.
- [ ] Resize or letterbox the viewer without cropping content, repeatedly
  shrinking the window, or creating a resize feedback loop.
- [ ] Respect iPhone orientation lock: AeroMirror should follow the stream
  metadata it receives rather than guessing from the displayed image.
- [x] Keep a user option for automatic fitting and preserve an explicit opt-out
  while snapping proportions only after an interactive resize completes.
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
