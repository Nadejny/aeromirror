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
- [ ] Make native-source ZIP metadata and entry ordering deterministic so
  identical validated content produces a stable archive SHA-256. Until then,
  pin only the final generated release asset through `SHA256SUMS.txt`.
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

Version 0.12.3 adds a managed, memory-only continuity placeholder for a
confirmed fatal loss. It deliberately stays separate from readiness: keeping
the last visible frame on screen does not mean discovery or reconnection has
completed.

Version 0.12.4 preserves UxPlay's same-process/same-port socket recovery after
completed cleanup and adds a compact feedback-health capability/recovered
marker pair. This avoids the shell immediately replacing an already recovered
core, but it is still stdout observation rather than acknowledged IPC or
in-place DNS-SD/BLE re-publication.

Version 0.12.5 makes the existing pre-fatal short-gap continuity path
deterministic: the native three-second warning arms a four-second local
deadline, and recovery before that deadline cancels it. Acknowledged recovery
changes the placeholder to connection-restored/waiting-for-image while the
existing renderer-gated handoff waits for visible video. This does not add a
native ready acknowledgement, re-publish discovery in place, or force an
iPhone to refresh a stale browse result.

Version 0.12.6 keeps the continuity view immediately above the external
renderer without activating it, and fatal cleanup replaces generic waiting
with explicit manual Screen Mirroring reconnect guidance. This improves the
truthfulness and visibility of a failed session; it does not claim that iOS
discovery or automatic reconnect has completed.

The same candidate adds explicit native HTTP initial/reset ready and failed
markers. Same-process recovery is preserved only after current-PID, same-port
reset evidence; failure exits into bounded full-process recovery, and
0.12.6 explicitly forced disconnect after a typed `TEARDOWN`. Source review
shows that this could remove the whole control connection. The affected
physical log proves that the shell/core processes stayed healthy while a
software request removed the connection, but does not identify which native
disconnect call site ran.

Version 0.12.7 removes that unconditional server-side disconnect, retains the
upstream typed-stream teardown behavior, and logs client-managed connection
ownership. This is a focused correction to the typed-`TEARDOWN` path; it does
not complete the unchecked DNS-SD/BLE re-publication work below or claim
automatic reconnection.

The 0.12.8 candidate addresses a separate false presentation handoff observed
after a longer feedback gap. HTTP feedback recovery and a still-visible cached
renderer HWND are not evidence that a new frame was displayed. The candidate
correlates one recovery epoch with the current core PID and managed mirroring
session, treats push/PTS/sink markers as diagnostics, and accepts
only a fresh Direct3D 11 present-path proof for automatic fade. Missing proof
keeps continuity visible and changes waiting text to reconnect guidance. This
does not yet repair the underlying half-open transport, decoder, sink, or clock
condition that may leave long-gap video frozen.

The 0.12.9 candidate adds a second, strictly bounded managed idle-discovery
allowance. After the existing first ten-minute renewal, a later Windows unlock
may consume one final refresh only after cooldown and only while core, socket,
discovery-marker, physical-IPv4, mirroring, client-grace, restart, and network
guards are safe. This mitigates one missing-after-idle report but does not prove
its cause, preserve a port across process replacement, or replace the native
same-port re-publication work below.

- [ ] Add a versioned local IPC contract, preferably JSON Lines over a
  per-user Windows named pipe.
- [ ] Emit explicit core states such as `starting`, `mdnsReady`, `ready`,
  `clientConnected`, `streamStarted`, `streamStopped`, `recovering`, and
  `error`.
- [ ] Include stable error codes and a short user-safe explanation with every
  failure event.
- [x] Add a compact native capability and feedback-recovered marker so the
  shell can distinguish acknowledged control recovery from an active gap; the
  current shell schedules its local deadline at four seconds. This marker no
  longer serves as displayed-frame evidence for handoff.
- [x] Implement and automatically verify current-PID/session/recovery-epoch
  presentation proof for continuity handoff. Feedback, appsrc push/PTS, sink
  probes, renderer visibility, cached HWND, and pixel sampling cannot authorize
  fade; physical recovered-frame evidence remains a separate pending gate.
- [ ] Diagnose and correct the underlying longer-gap frozen-video path only
  after socket lifetime, RTP input, appsrc flow, sink PTS, and presentation
  evidence identify the boundary. Do not hot-replace a half-open socket, rebase
  timestamps, or auto-reset the receiver without parser/crypto/physical tests.
- [ ] Add graceful commands such as `shutdown`, `refreshDiscovery`, and
  `getStatus`; do not use process presence or renderer-window discovery as a
  substitute for readiness.
- [ ] Re-publish DNS-SD and BLE on the same listening port after the native
  HTTP reset, then emit an acknowledged ready marker. Refactor the current
  registration ownership first so unregister/register cannot reuse freed
  service-name or hardware-address storage.
- [x] Add one managed final post-renewal SessionUnlock refresh with cooldown,
  readiness/client/network guards, a strict per-idle limit, and activity
  re-arming; keep it documented as a mitigation rather than root-cause proof.
- [ ] Physically validate the long-idle/unlock mitigation on Windows 10 and 11,
  retain first-tap iPhone browse/request evidence, and isolate whether the
  original absence was DNS-SD, BLE, Bonjour service state, iOS browse cache,
  socket/port publication, or another lifecycle boundary.
- [ ] Reproduce the reported Windows 10 first-install-only-after-reboot symptom
  on a clean VM. Retain pre-reboot Setup/receiver logs, Bonjour service state,
  pending-reboot indicators, firewall/network state, and the effect of a
  receiver stop/start. Do not add a generic reboot prompt or machine-wide
  Bonjour mutation without a proven prerequisite and rollback design.
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

### Audio endpoint resilience

Version 0.12.7 makes the normal Windows audio path explicit:
`wasapi2sink continue-on-error=true`. The pinned redistributed GStreamer 1.28.1
runtime supports that property for its documented endpoint-open, device-I/O,
and device-removal failures. Muted output remains separate, and advanced
UxPlay arguments can still replace the managed sink deliberately. This does
not isolate every possible GStreamer bus error or change the shared native
media-pipeline boundary.

- [x] Select the resilient `wasapi2sink` property for normal default audio
  without changing mute or advanced-argument precedence.
- [ ] Physically test playback while changing the Windows default output,
  disabling/re-enabling the active endpoint, and removing a USB/Bluetooth
  endpoint where available.
- [ ] Define session-scoped handling for media errors outside the documented
  `wasapi2sink` device-failure scope before treating every audio bus error as
  nonfatal; do not use a process-lifetime failed latch that can mute later
  sessions.
- [ ] Retain timestamped native markers that distinguish the first media error
  from later teardown side effects without logging audio content.

Acceptance target: a supported Windows output-device failure may interrupt
audio but does not unnecessarily end video or permanently mute later sessions.

### Orientation and photo/video sizing

Version 0.12.3 extends the interim path: a newly discovered renderer receives a
provisional fit, and an early marker with a conservative phone shape is retained
before the stable-size debounce. This covers the observed `998x2160` then
`3840x2160` direct-in-Photos startup sequence. Later normalized ratios within
`0.03` follow physical rotation, while a different media-canvas ratio retains
the learned orientation. Interactive resize completion restores the learned
proportions by default, and normal renderer bounds/DPI persist across sessions
with work-area clamping. The unchecked work below covers richer metadata,
versioned IPC, sessions without any phone-shaped marker, inner encoded-canvas
sizing, device validation, and edge cases still required before this behavior
is considered complete.

Version 0.12.4 adds the complete raw AirPlay geometry header, including the
previously ignored auxiliary pair, and the actual selected GStreamer decoder
and sink. These are diagnostic fields only. The auxiliary pair has not been
validated as a content rectangle, pixel-aspect ratio, or rotation signal and
is not consumed as one.

Version 0.12.5 correlates that raw record with the following encoded-size
record and treats only the complete observed
`3840x2160 aux=0x0 encoded=3840x2160` Photos signature as ambiguous. It cannot
seed or persist a false device orientation; a later phone-shaped marker can
establish portrait in the same session. This is a narrow replay-backed rule,
not a generic interpretation of the auxiliary pair, and it does not crop the
small photo and black bars already encoded inside the canvas.

Version 0.12.6 clears the unimplemented photo, slideshow, and photo-preload
AirPlay feature bits as a mirror-only negotiation experiment. Its effect on
direct-in-Photos startup and inner canvas sizing is physically pending. It
does not provide a content rectangle or justify crop/zoom heuristics.

Version 0.12.9 settings schema 12 adds a default-off A/B that temporarily lets
only the exact recorded ambiguous Photos/media canvas drive the outer window,
similar to the older wide-window presentation. It does not promote that canvas
to device orientation, persist an automatic provisional landscape, modify the
native stream, or enlarge inner media. Its value is specifically to separate
an outer-window regression from the still-unsolved encoded-inner-canvas case.

- [ ] Log source dimensions, pixel aspect ratio, rotation metadata, and
  renderer dimensions for orientation transitions.
- [x] Suppress a different Photos/media canvas ratio after a device-frame
  baseline has been learned for the current session.
- [x] Retain an early phone-shaped raw marker before the debounce so the known
  direct-in-Photos startup sequence cannot lose its device baseline.
- [x] Prevent the exact replayed Photos-first `3840x2160 aux=0x0` canvas from
  becoming the device baseline or replacing a valid saved placement before a
  trustworthy frame or explicit user action exists.
- [x] Add the schema-12 default-off exact-canvas outer-window A/B without a
  native restart, trusted-orientation promotion, or provisional-placement save.
- [ ] Run the same photo/video with the schema-12 A/B off and on, measure outer
  client bounds and inner visible content separately, and retain direct-Photos
  startup/session-stability evidence. Do not call a wider outer window an
  inner-content fix.
- [ ] Resolve sessions that start with only a generic media canvas and no early
  phone-shaped marker, without guessing that the canvas is the physical device
  ratio.
- [ ] Pass source-size/orientation events through native IPC.
- [ ] Expose a trustworthy content rectangle/crop signal or validate a
  conservative pixel-analysis design for Photos canvases that contain their
  own encoded black bars; do not crop real dark content by guesswork.
- [ ] Emit the exact display-capability response selected for each new session
  and retain a physical HEVC 4K-versus-1080p Photos A/B. Treat that marker as
  negotiation evidence only; feature bits remain unchanged, and neither preset
  is a fix unless the visible inner-media measurement improves repeatedly.
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

### Frame pacing and viewer ownership

Version 0.12.4 makes two conservative experiments reviewable: Interactive
latency now applies only `-vsync no`, and explicit Direct3D choices pin matching
decoders and sinks. It also caches unchanged foreign-window policy and applies
saved placement from the early show event. These changes do not turn the
external GStreamer HWND into an AeroMirror-owned viewer.

Version 0.12.6 makes the pinned Direct3D 11 decoder and sink the stability
default. Settings schema 11 migrates legacy automatic selection while
preserving explicit Direct3D 12 as an experimental opt-in. The change is
covered by managed migration and argument tests, but physical Direct3D 11
versus Direct3D 12 Photos and resolution-change evidence remains required.

Version 0.12.7 corrects the headless wrapper boundary so an external `--uxplay`
launch preserves the shell's `-vs` and `-fs` values. This makes the existing
D3D11 default reach UxPlay instead of being silently replaced by the wrapper's
persisted Qt preference. Physical actual-sink and Photos transition evidence
is still required.

The 0.12.8 candidate adds recovery-stage telemetry around video push, target
PTS/sink observation, and the Direct3D 11 present path. Only the correlated
present proof is presentation-ready; earlier markers locate a stall but cannot
close continuity. Direct3D 12 and other advanced sinks require an equivalent
reviewed proof before they can use automatic handoff. Interactive `-vsync no`
deliberately skips synchronized PTS/Present proof in this candidate and retains
reconnect guidance.

- [x] Remove the aggressive 50 ms audio-buffer request from the Interactive
  profile while keeping Balanced as the default.
- [x] Pin both decoder and video sink for explicit Direct3D 11/12 comparisons.
- [ ] Add bounded frame-pacing, decoder QoS/drop, packet-jitter, and render-time
  telemetry that does not contain mirrored content.
- [ ] Retain physical evidence that a correlated D3D11 present marker coincides
  with real recovered video after both short and longer gaps; a successful
  appsrc push or matching PTS is not sufficient acceptance.
- [ ] Benchmark Balanced and Interactive on identical local-network conditions
  across Windows 10/11 and representative GPUs before changing the default.
- [ ] Embed or parent a native D3D surface behind a versioned local IPC contract
  before promising a Mac-style hover-only frame, borderless viewer, seamless
  frozen-frame handoff, or live aspect lock during edge dragging.
- [ ] Define keyboard-accessible move, close, fullscreen, and size controls for
  any hover-only chrome; do not remove the standard frame before those controls
  exist.

Acceptance target: physical evidence distinguishes transport jitter, decode,
and presentation pacing, while viewer chrome and resizing remain accessible
and never require unsafe cross-process window subclassing.

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
- [ ] Prototype a separately named **AeroDrop** path only after defining its
  trust model: an iOS Share Extension or companion can transfer over an
  authenticated local HTTPS session, default to `Downloads\AeroMirror`, show
  an explicit accept/open-folder notification, sanitize and deduplicate names,
  apply size limits, and never auto-open executable/archive content.
- [ ] Keep genuine AirDrop/AWDL interoperability as a separate feasibility
  track; appearing as an AirPlay/Apple TV receiver does not make AeroMirror an
  AirDrop target.
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
