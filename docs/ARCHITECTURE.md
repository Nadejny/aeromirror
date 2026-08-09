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
   recovery decision: an active stalled session restarts, while completed
   native cleanup triggers exactly one discovery renewal. A normal clean
   disconnect does not restart the receiver. The same confirmed fatal marker
   can open a managed continuity placeholder; a benign feedback warning or
   clean disconnect cannot.
6. The reviewed libuxplay patch writes a stable
   `AEROMIRROR_VIDEO_SIZE source=<w>x<h> encoded=<w>x<h>` line when the
   incoming video size changes.
7. A high-level connection request or PIN prompt establishes a bounded client
   activity grace. A later end marker belonging to the previous session must
   not erase that newer grace or allow deferred settings/network maintenance
   to interrupt the new handshake.

The patched core receives its receiver arguments directly from the shell.
AeroMirror does not write the PIN or the current launch configuration to
uxplay-windows' legacy `arguments.txt` file.

This deliberately keeps protocol code out of the shell. A later native build
can replace the binary boundary with a dedicated `receiver-core.exe` or stable
local IPC API while preserving the settings UX.

The current markers are a reviewed transitional stdout contract, not a
versioned bidirectional IPC protocol. Compatibility code still supports a
legacy core without those markers, but explicit failure of both DNS-SD and BLE
must never produce a false ready state.

## Renderer-window fitting

Renderer-window discovery is still a heuristic Win32 boundary. When a new
renderer is found, the shell applies a provisional iPhone-aspect fit if the
native size marker has not arrived yet. Raw markers continue through a 350 ms
stability debounce, but the first marker with a conservative modern-iPhone
shape is retained immediately as an early device-frame candidate. This covers
the recorded direct-in-Photos sequence in which `998x2160` arrives about
130 ms before the stable `3840x2160` presentation canvas. A generic 16:9
marker is never promoted through this early path.

The first stable exact size uses that early candidate when available; otherwise
the existing conservative baseline rules apply. Later sizes whose normalized
aspect matches within `0.03` are authoritative rotation events, while other
ratios retain the learned device orientation. This prevents a Photos
`3840x2160` presentation canvas from reshaping a window after a `998x2160`
device frame and still allows physical `1080x1920`/`1920x1080` devices. A
session that exposes only a generic media canvas remains ambiguous because
stdout still provides no independent device-orientation metadata.

The shell installs an out-of-context WinEvent hook scoped to the active native
core process and watches interactive move/size completion. A real resize queues
a short delayed fit on the normal supervision thread; move-only activity,
minimized/maximized windows, core replacement, and an explicit automatic-fit
opt-out do not queue or apply it. The callback itself never resizes the foreign
window. The resulting fit preserves the user's chosen client area while
restoring the learned stream proportions. The tray action remains a manual
one-shot fallback and resolves through the same learned device-frame baseline,
so invoking it during a later Photos canvas does not recreate a false
landscape fit.

Normal renderer outer bounds and their DPI are persisted through the existing
atomic settings path after a queued initial, manual, or automatic fit, or after
move/resize work reaches the supervision timer. A new renderer first restores
those bounds, scales them for its target DPI, and clamps stale, oversized, or
disconnected-monitor coordinates into an available Windows work area. The
subsequent provisional and exact-size fits preserve the restored center and
approximate client area. Minimized/maximized states are not saved, and the
out-of-context WinEvent callback performs no window mutation or file I/O.

The marker reports the encoded stream dimensions; it is not remote-control
input, pixel-aspect metadata, or a guarantee that an iPhone application itself
has not letterboxed content inside the video frame. In particular, Photos may
place a small image and black bars inside the encoded `3840x2160` canvas. The
managed shell can choose the outer window aspect but cannot safely crop or zoom
that inner content without a native content rectangle or validated pixel
analysis. A future versioned IPC contract should replace stdout parsing and
expose explicit stream, orientation, and content-layout events.

## Fatal-loss presentation continuity

The native renderer remains an external window owned by the core process, so
it closes when bounded fatal-loss recovery replaces that process. Before that
cleanup completes, the managed shell remembers its bounds and may copy the
visible foreground pixels inside those bounds. The copy is softened and
darkened in process memory; it is never written to settings, logs, diagnostics,
or a temporary file. If foreground capture is unsafe or unavailable, the form
uses a dark fallback.

This managed placeholder is presentation continuity, not protocol state or a
second renderer. It remains through native process renewal and a reconnect
handshake, then closes only on a new mirroring-start marker, explicit user
close, manual receiver stop, settings-driven shutdown, or application exit.
Its taskbar and always-on-top policy follow the stream-window settings. A clean
disconnect and benign client-feedback warnings never open it. Discovery speed
and stale iOS browse rows remain properties of the native/network path.

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
7. Re-publish DNS-SD and BLE on the same native listening port after internal
   lost-client reset, with an explicit ready marker, so iOS does not need to
   discover a new process/port after abnormal Wi-Fi loss.
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
