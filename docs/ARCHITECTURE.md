# Architecture

```text
iPhone
  │ AirPlay + local network discovery
  ▼
core/uxplay-windows.exe
  ├─ UxPlay protocol and pairing
  ├─ mDNSResponder / Bonjour
  ├─ GStreamer decode and audio
  ├─ GStreamer renderer window
  └─ --headless: no upstream tray icon
          ▲
          │ process lifecycle + command-line arguments + Win32 window policy
          ▼
AeroMirror.exe
  ├─ system tray and settings
  ├─ per-user autostart
  ├─ Windows network-profile safety gate
  ├─ diagnostics and logs
  └─ always-on-top policy
```

## Managed shell organization

The C# source is divided by responsibility but still compiles into one .NET
Framework `AeroMirror.exe` assembly:

- `Application` owns process startup, single-instance activation, and display
  version access;
- `Configuration` owns persisted settings, migration, normalization, and
  atomic replacement of `settings.ini`;
- `Receiver` owns the tray application context, native process lifecycle,
  discovery and reconnect supervision, renderer-window policy, diagnostics,
  fatal-loss presentation continuity, and logging;
- `UI` owns the active settings window, diagnostic viewer, theme helpers,
  application icon, the managed lost-connection placeholder, and custom
  controls;
- `Updates` owns release parsing, update metadata, download, and digest
  verification;
- `Network` owns physical-adapter selection and Private/Public/Unknown trust
  classification while excluding virtual overlays;
- `Interop` contains the Win32 declarations shared by receiver supervision and
  renderer-window handling.

`ReceiverContext` uses partial-class source files so its private lifecycle
state remains inside one object while unrelated code is no longer stored in a
single monolithic file. This is a compile-time organization only: it adds no
new process, assembly, public API, serialization format, or IPC boundary. The
current `SettingsForm` intentionally remains intact during this conservative
split. Three legacy form implementations with no reachable construction path
were removed; the active settings form was not replaced.

The build discovers C# files recursively below `src/` in stable path order.
Tests must target behavior and the complete source set rather than depend on a
single historical filename.

Reflection tests that initialize persistent settings or logging use one
process-lifetime storage override before those classes are touched. The root
must be a GUID-named direct child of the system temporary directory; reusing
the same root is idempotent and selecting a different second root is rejected.
Every `AppSettings` path resolves below it for that process. The logger exposes
a bounded drain result so tests inspect and remove the exact temporary root
only after queued writes complete. Production continues to use
`%LOCALAPPDATA%\AirPlayReceiverMvp`; test reflection never redirects or edits
that directory.

## Integration contract

The current shell depends on these native integration behaviors:

1. The core executable is located at `core/uxplay-windows.exe`.
2. The shell waits for a usable physical IPv4 address and starts the core with
   `--headless --beacon-ipv4 <physical-ipv4> --uxplay <arguments>`.
3. Renderer windows belong to the core process.
4. The reviewed patches write explicit `AEROMIRROR_DNSSD_READY`,
   `AEROMIRROR_DNSSD_DEGRADED`, and `AEROMIRROR_BLE ...` discovery-health
   markers. Listening sockets remain the readiness baseline.
5. Existing native log lines still provide heuristic mirroring start, normal
   stop, and lost-client observations. A fatal loss marker arms one bounded
   recovery decision: an active stalled session can restart, while completed
   native cleanup preserves UxPlay's reinitialized listening socket in the same
   process and on the same AirPlay port. A normal clean disconnect does not
   restart the receiver.
6. The reviewed libuxplay patch writes a stable
   `AEROMIRROR_VIDEO_SIZE source=<w>x<h> encoded=<w>x<h>` line when the
   incoming video size changes. It also writes the full raw header as
   `AEROMIRROR_VIDEO_GEOMETRY ...`, including a previously ignored auxiliary
   width/height pair, and reports the actual GStreamer decoder/video sink as
   `AEROMIRROR_GSTREAMER_SELECTED ...`. The shell correlates one raw-geometry
   record with the following encoded-size record. The auxiliary pair remains
   diagnostic only; it is not treated as crop, pixel-aspect-ratio, or rotation
   metadata.
7. A high-level connection request or PIN prompt establishes a bounded client
   activity grace. A later end marker belonging to the previous session must
   not erase that newer grace or allow deferred settings/network maintenance
   to interrupt the new handshake.
8. A patched core announces `AEROMIRROR_FEEDBACK_HEALTH_READY` and emits
   `AEROMIRROR_CLIENT_FEEDBACK_RECOVERED gap_seconds=<n> epoch=<e>` when
   periodic client feedback resumes. Only after that capability marker may the
   shell use the native three-second warning to arm a four-second local
   continuity deadline. Recovery before the deadline cancels it. Recovery after
   the view appears changes the UI to connection-restored/waiting state but is
   control-health evidence only: it cannot authorize renderer handoff.
   Recovery-scoped `AEROMIRROR_VIDEO_PUSH_RECOVERED`/
   `AEROMIRROR_VIDEO_PUSH_PENDING` appsrc flow/PTS and
   `AEROMIRROR_VIDEO_SINK_RECOVERED` exact-PTS markers are diagnostic stages.
   Only `AEROMIRROR_VIDEO_PRESENT_READY epoch=<e> gap_seconds=<n>
   proof=d3d11-present pts_delta_ms=<d>` from the reviewed Direct3D 11
   swap-chain present path can authorize fade, and the shell accepts it only
   from the current core PID, current managed mirror-session generation,
   currently armed epoch, and exact expected reason/gap. A feedback challenge
   keeps its positive recovered gap; only an accepted mirror-start challenge
   expects zero and restarts the three-second proof wait. A matching
   `AEROMIRROR_VIDEO_PRESENT_PROOF_READY codec=<h264|h265>
   videosink=d3d11videosink` capability marker from that current PID is also
   required. A
   repeated mirroring-start marker within that same feedback-gap recovery
   cannot bypass the proof gate. Manual Screen Mirroring reselection may arm a
   new presentation epoch with `AEROMIRROR_VIDEO_PRESENT_ARMED
   reason=mirror-start epoch=<e>`, but that marker is accepted only when the
   managed session is explicitly expecting a mirror-start challenge. The
   mirror-start marker alone still leaves
   continuity visible until matching D3D11 present proof arrives. A
   legacy core, Direct3D 12 or another advanced sink, stale
   process/session/epoch, visible cached HWND, or media-path diagnostic cannot
   use the handoff shortcut.

   The proof hook also requires synchronized video. Interactive `-vsync no`
   sets the sink path to `sync=false`, so the native renderer deliberately does
   not attach the PTS probe/Present proof capability. That path keeps the
   reconnect guidance; it cannot reinterpret an unsynchronized Present or push
   marker as equivalent evidence.
9. Native HTTP startup emits `AEROMIRROR_HTTP_READY stage=initial port=<n>` or
   an explicit failed marker. Fatal internal reset emits reset readiness only
   after binding the exact original advertised port. The shell accepts markers
   only from the current PID, clears readiness at fatal loss, and preserves the
   native process only after matching same-port evidence. Failure or mismatch
   cleans up and exits for bounded full-process recovery; legacy generic
   readiness remains bounded and cannot claim port identity. For a typed
   AirPlay `TEARDOWN`, the native handler retains upstream's typed-stream
   teardown behavior and `Connection: close` response header, but it no longer
   forces immediate server-side removal of the control socket.
   The client therefore controls whether and when that socket closes. The
   compact `AEROMIRROR_TEARDOWN audio=<0|1> video=<0|1>` marker with
   `disconnect=client-managed` makes that decision observable.
10. The 0.12.6 native candidate clears photo, slideshow, and photo-preload
    feature bits 1, 5, and 13 and emits
    `AEROMIRROR_MIRROR_ONLY_FEATURES_READY`. Supported audio, authentication,
    and metadata capabilities remain advertised. This is an experiment whose
    effect on Photos presentation-canvas negotiation remains a physical gate,
    not a validated crop or content-layout signal.
11. In headless/external-argument mode, the uxplay-windows wrapper leaves the
    shell-provided UxPlay argument vector unchanged and emits
    `AEROMIRROR_ARGUMENTS_PASSTHROUGH mode=external`. Its legacy Qt renderer
    and fullscreen preferences apply only to the wrapper's interactive UI, so
    they cannot silently replace externally supplied `-vs` or `-fs` values.
12. Default Windows audio is explicit rather than automatic: the shell supplies
    `-as "wasapi2sink continue-on-error=true"`. The redistributed GStreamer
    1.28.1 runtime supports that sink property for documented endpoint-open,
    I/O, and device-removal failures. Mute supplies only `-a`; advanced UxPlay
    arguments are appended later and can deliberately override the managed
    sink. Errors outside that property remain native media-pipeline behavior.

The patched core receives its receiver arguments directly from the shell.
AeroMirror does not write the PIN or the current launch configuration to
uxplay-windows' legacy `arguments.txt` file.

This deliberately keeps protocol code out of the shell. A later native build
can replace the binary boundary with a dedicated `receiver-core.exe` or stable
local IPC API while preserving the settings UX.

The patched core exposes a deliberately narrow version-1 discovery-maintenance
protocol, not a general receiver RPC API. The managed shell writes a correlated
refresh command to redirected stdin. The core reports capability, accepted or
deferred progress, and a terminal ready or failed result as dedicated framed
stdout marker lines. Compatibility code still supports a legacy core without
this protocol, but explicit failure of both DNS-SD and BLE must never produce a
false ready state.

## Managed discovery maintenance

Normal automatic discovery maintenance remains bounded around real activity.
Idle, unlock, and native-health recovery prefer an in-process refresh that
preserves the receiver process and HTTP/RAOP/AirPlay ports. The native core
replaces the paired DNS-SD registration generation, pumps Bonjour callbacks,
and retries failed registration with bounded 1, 2, 5, 10, and 30 second delays.
An active AirPlay request, PIN flow, audio/video client, or mirroring session
defers the command rather than interrupting the connection.

The managed request remains correlated to the current process, request ID,
generation, and advertised ports. It waits for the accepted/deferred and
terminal result markers and permits only bounded attempts. If the command is
unsupported, rejected, times out, or repeatedly fails, the existing managed
fallback can perform a full receiver restart. Stale markers from an earlier
process or request cannot settle the current operation.

The settings layer removes ASCII control characters, repairs invalid UTF-16,
and persists a receiver name of at most 50 UTF-8 bytes without splitting a
text element. The settings UI shows the effective name whenever normalization
changes user input. The native DNS-SD layer independently enforces the same
50-byte ceiling at a complete UTF-8 character boundary, which keeps
`MAC@name` within Bonjour's 63-byte label limit even for direct native launches
or advanced argument overrides. AirPlay, RAOP, and `/info` use that one stored
canonical name; blank input falls back to `AeroMirror`.

`Restart Discovery` remains an explicit full DNS-SD-and-BLE process restart.
A physical IPv4 change also uses the full restart because the separate BLE
helper does not yet support in-process reconfiguration. The wrapper buffers
the helper's arbitrary output chunks into complete lines, forwards them to
stderr with an `AEROMIRROR_BLE` prefix, and the managed shell observes those
PID-scoped lines as a second discovery-health path. Unexpected helper start
failure or exit produces one bounded failure line; intentional helper shutdown
during receiver maintenance does not.

An acknowledged DNS-SD ready result proves that the local Bonjour registration
callbacks completed for the new paired generation; it does not continuously
attest that an iPhone can see the advertisement or force a phone to invalidate
a cached browse result. Bonjour remains an external machine-wide service. The
receiver observes its state but does not start, stop, repair, uninstall, or
otherwise mutate that service.

## Renderer-window fitting

Renderer-window discovery is still a heuristic Win32 boundary. When a new
renderer is found, the shell applies a provisional iPhone-aspect fit if the
native size marker has not arrived yet. Each correlated raw-geometry/encoded-
size event receives a monotonic sequence for the lifetime of the running core.
Raw markers continue through a 350 ms stability debounce, but an identical
repeat advances the pending candidate's sequence without moving its original
deadline. This prevents continuous duplicates from starving a decision. A
duplicate of the current stable candidate does not reopen the debounce, while
the same dimensions with a different device-frame/media-canvas classification
remain distinct. Starting a new mirror session clears candidates and baselines
without rewinding that core-lifetime sequence; a full core reset clears it.
The first marker with a conservative modern-iPhone shape is retained
immediately as an early device-frame candidate. This covers
the recorded direct-in-Photos sequence in which `998x2160` arrives about
130 ms before the stable `3840x2160` presentation canvas. A generic 16:9
marker is never promoted through this early path.

The first stable exact size uses that early candidate when available. In
addition, only the complete recorded Photos signature—primary, source, and
encoded `3840x2160` plus `aux=0x0`—is classified as an ambiguous presentation
canvas. It cannot seed the device-frame baseline even when it arrives first. A
later phone-shaped `998x2160 aux=1421x0` marker can establish portrait in the
same session. The observed real-landscape `3840x1776 aux=0x192` signature and
ordinary nonmatching 16:9 streams remain eligible, so the narrow rule does not
turn auxiliary values into general orientation metadata.

Version 0.12.11 makes that exact ambiguous signature an unconditional
provisional `MediaCanvas` target for automatic outer-window fitting. It still
cannot seed `deviceFrameVideoSize`, become an authoritative orientation event,
or make an automatic provisional landscape persistable. The temporary schema-
12 `FollowPhotosMediaCanvas` field and Advanced checkbox are retired: legacy
values are ignored while loading and omitted on canonical save, while the
schema number remains 12 and the general `AutoFitWindow` opt-out remains.
This changes no native arguments, advertised feature bits, negotiation,
decoded pixels, crop, or zoom; inner media can remain letterboxed and small.

The exact-size fit state records the newest consumed event, the target class
(`DeviceFrame` or `MediaCanvas`), and exact aspect. A fresh stable event refits
when the class or exact aspect changes, even when both old and new targets are
landscape or both are portrait. Thus `3840x1776 DeviceFrame` to
`3840x2160 MediaCanvas` is not lost behind an orientation-only comparison. A
scaled target with the same class and exact aspect is consumed without moving
the window again. A class/aspect mismatch remains eligible when an active
resize/mouse gesture blocks the pass or fitting fails; only a successful fit
records the new target. Later refits preserve the current area, while the first
exact fit may preserve restored area, and provisional media-canvas placement
remains non-persistable.

Later sizes whose normalized aspect matches within `0.03` are authoritative
rotation events, while other ratios retain the learned device orientation.
The exact correlated Photos signature is the sole narrow exception: it may
temporarily reshape the outer window after a device frame without replacing
that frame as the trusted baseline. A later `998x2160` frame therefore returns
the window to portrait, and physical `1080x1920`/`1920x1080` devices remain
eligible. A session exposing only the exact canvas receives a provisional
landscape outer fit, but its physical device orientation is still unresolved
because stdout provides no independent orientation metadata.

The shell installs an out-of-context WinEvent hook scoped to the active native
core process and watches both the renderer's early show event and interactive
move/size completion. The show callback applies only validated saved placement
already loaded in memory, reducing the interval in which the foreign window can
appear at its native default position. A real resize queues fitting for the
next normal supervision pass; move-only activity, minimized/maximized windows,
core replacement, and an explicit automatic-fit opt-out do not queue or apply
it. The callback never performs file I/O or a full aspect fit. The resulting
fit preserves the user's chosen client area while restoring the learned stream
proportions. The tray action remains a manual one-shot fallback and resolves
through the same learned device-frame baseline, so invoking it during a later
Photos canvas does not recreate a false landscape fit.

Normal renderer outer bounds and their DPI are persisted through the existing
atomic settings path after a queued initial, manual, or automatic fit, or after
move/resize work reaches the supervision timer. A new renderer first restores
those bounds, scales them for its target DPI, and clamps stale, oversized, or
disconnected-monitor coordinates into an available Windows work area. The
subsequent provisional and exact-size fits preserve the restored center and
approximate client area. Minimized/maximized states are not saved. Applied
title, taskbar style, and topmost state are cached so an unchanged renderer is
not mutated on every 250 ms supervision tick. Restoration alone and an
unresolved automatic/provisional fit do not rewrite the saved bounds. The
current window becomes persistable after a trustworthy device-oriented fit or
an explicit user move, resize, or manual fit, so closing an ambiguous
Photos-first session cannot poison the next session's placement.

The marker reports the encoded stream dimensions; it is not remote-control
input, pixel-aspect metadata, or a guarantee that an iPhone application itself
has not letterboxed content inside the video frame. In particular, Photos may
place a small image and black bars inside the encoded `3840x2160` canvas. The
managed shell can choose the outer window aspect but cannot safely crop or zoom
that inner content without a native content rectangle or validated pixel
analysis. A future versioned IPC contract should replace stdout parsing and
expose explicit stream, orientation, and content-layout events.

## Renderer pipeline selection

Settings schema 11 makes Direct3D 11 the managed stability default. Loading a
legacy profile migrates only `Renderer=auto` to `d3d11`; an explicit `d3d12`
choice is retained. Unknown renderer values normalize to D3D11. Schema 12
remains current and preserves that renderer migration as a separate step; its
former Photos A/B key is ignored and removed on save in 0.12.11. The shell pins
both the codec-family decoder and matching video sink for Direct3D 11 or 12,
and raw advanced UxPlay arguments remain later on the command line so an
experienced tester can make an explicit diagnostic override.

The headless wrapper treats the `--uxplay` vector as authoritative. It does not
strip `-vs` or `-fs` and does not inject its persisted Qt renderer/fullscreen
preferences in that mode. Consequently the actual-selection marker can be
compared directly with the shell launch arguments; a D3D11 request followed by
an actual D3D12 sink is a failed integration check, not an allowed wrapper
fallback.

This is a conservative response to the observed automatic D3D12 selection and
upstream resolution-change risk. It does not change AirPlay negotiation,
decode pixels in the managed shell, or prove that Photos' inner presentation
canvas is fixed. Direct3D 12 remains an experimental A/B option until physical
Windows/iPhone evidence supports a broader conclusion.

## Audio pipeline selection

Normal default audio uses GStreamer's Windows `wasapi2sink` explicitly with
`continue-on-error=true`. In the pinned 1.28.1 runtime, documented endpoint
open, device I/O, and device-removal failures are downgraded to warnings while
the sink continues consuming buffers. This prevents those device failures from
ending the shared media loop merely because `autoaudiosink` selected the same
backend without the resilience property.

This is deliberately narrower than a process-wide audio-error latch. The
renderer still owns the GStreamer pipeline, and unrelated decoder, video,
protocol, or audio bus errors keep their existing native behavior. Muted mode
does not instantiate this sink, and a tester-provided advanced `-as` remains
authoritative because advanced arguments are appended last.

## Fatal-loss presentation continuity

The native renderer remains an external window owned by the core process.
Before cleanup completes, the managed shell remembers its bounds and may copy
the renderer's visible client pixels when no higher visible window overlaps
them. The copy is softened and darkened in process memory; it is never written
to settings, logs, diagnostics, or a temporary file. If unobscured client-area
capture is unsafe or unavailable, the form uses a dark fallback.

This managed placeholder is presentation continuity, not protocol state or a
second renderer. A native three-second feedback warning may schedule it for a
four-second local deadline only after the patched core has announced
recovery-marker capability. If feedback recovers earlier, the pending view is
canceled. If it is already visible, acknowledged feedback or a replacement
connection changes the text to connection-restored/waiting-for-image without
claiming that video presentation resumed.

For the 0.12.8 same-session feedback-gap path, the shell arms one presentation-
proof epoch for the current core PID and managed mirror-session generation.
Successful appsrc push, the target PTS reaching the sink probe,
renderer-window visibility, and cached pixel observations remain
diagnostics only. The view
starts its short nonblocking fade only after the same epoch reports a fresh
Direct3D 11 swap-chain present from a core that announced the exact capability.
If no accepted proof arrives during the bounded three-second wait, the view
remains and changes to explicit Screen Mirroring
reconnect guidance. A new loss cancels an in-progress fade and invalidates the
previous epoch. This contract intentionally avoids an automatic process reset, hot
replacement of a half-open video socket, or media-clock rebasing.
`pts_delta_ms` remains instrumentation for the first matching post-recovery
frame; it is not permission to adjust the clock or dismiss continuity by
itself.

A confirmed fatal loss retains continuity through cleanup and a reconnect
handshake. A protocol-start marker alone is insufficient to close it: the
placeholder stays until a real replacement renderer exists and has been
positioned, then hands off with a short nonblocking opacity fade. This fatal
replacement-session path is separate from the same-session feedback epoch
above. While visible, it is inserted
immediately above the external renderer without activation or an implicit
permanent topmost policy. After fatal cleanup it replaces generic waiting text
with an explicit instruction to select the named receiver again in iPhone
Screen Mirroring. Explicit user close, manual
receiver stop, settings-driven shutdown, and application exit close it
immediately. Its taskbar and always-on-top policy follow the stream-window
settings. A clean disconnect does not open it. Discovery speed and stale iOS
browse rows remain properties of the native/network path.

Explicit HTTP reset readiness proves only that the native HTTP listener
rebound the expected AirPlay port. It does not prove that DNS-SD/BLE was
re-published or that iOS discarded a stale browse-cache entry.

## Native build provenance

`native-core/source-provenance.json` binds the reviewed uxplay-windows and
libuxplay commits, both patch hashes, every modified source hash, the Bonjour
header and `dnssd.def`, and the expected patched executable hash. Release
packaging accepts only a runtime manifest that reproduces those values.

The published native source ZIP is a prepared tree without required Git
metadata: both patches are already applied. Its build script validates the
prepared files against the same provenance document, places the bundled
`dns_sd.h` into the Bonjour SDK layout, generates the x64 `dnssd.lib` import
library from the verified `dnssd.def` with MSYS2 `dlltool`, and rejects an
output executable whose hash differs from the reviewed value. For a build from
Git checkouts, it additionally verifies both pinned commits.

## Quality changes during an active session

Source inspection of the bundled UxPlay core confirms that the requested
width, height, refresh rate, and maximum FPS are written into the AirPlay
display-capability response during session setup. The current core exposes no
runtime command or IPC method that renegotiates those fields with an already
connected iPhone.

AeroMirror therefore saves the new preset and restarts the receiver process.
If an iPhone is currently streaming, the restart is deferred until that
session ends instead of interrupting it. The iPhone must reconnect before the
new session is guaranteed to use the new capabilities. Pretending that the
existing stream changed quality would only change the UI, not the incoming
encoded video. True live switching needs a native-core change: an AirPlay
renegotiation path plus an IPC command from the Windows shell.

## Recommended next iteration

1. Split the remaining unused Qt settings UI from the linked UxPlay receiver
   engine to reduce the native core size.
2. Add JSON-lines IPC over a named pipe:
   `ready`, `clientConnected`, `streamStarted`, `streamStopped`, and `error`.
3. Research and implement safe display-capability renegotiation for live
   quality changes.
4. Embed or parent the D3D11/D3D12 renderer surface into the application
   viewer window.
5. Produce a signed WiX/MSIX installer with explicit firewall rules.
6. Add automated smoke tests for start/stop, crash recovery, settings
   migration, and missing Bonjour.
7. Add in-process BLE address reconfiguration so a physical IPv4 change does
   not require the current full receiver restart.
8. Test with current iOS releases on Intel, AMD, and ARM64 Windows devices.

## Security notes

- No listening service is installed by the shell itself.
- The receiver accepts connections from the local network. A fresh
  installation uses no PIN on a trusted/private profile. When Windows reports
  an active Public profile, the shell pauses an unprotected receiver until a
  four-digit PIN is enabled.
- This gate depends on Windows network classification and is not a substitute
  for correctly scoped firewall rules or network isolation.
- Persisted pairing mode is untrusted input. Only no-PIN mode or PIN mode with
  exactly four ASCII digits is canonical; unknown, obsolete, or malformed
  values become unprotected so a Public/Unknown physical profile fails closed.
- Settings are published through same-directory atomic replacement. Receiver
  keys and trusted-client state remain separate files and are not transaction
  members of an ordinary settings save.
- Advanced arguments are written as plain text. Do not place a reusable secret
  there.
- Logs intentionally avoid video/audio content, but may contain local paths,
  PIDs, receiver names, and arguments.
