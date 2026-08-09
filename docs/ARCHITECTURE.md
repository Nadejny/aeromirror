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
  and logging;
- `UI` owns the active settings window, diagnostic viewer, theme helpers,
  application icon, and custom controls;
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
   stop, and lost-client observations. A bounded watchdog restarts the native
   process tree when a fatal loss marker is not followed by normal shutdown.
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
native size marker has not arrived yet. The first stable exact encoded size
then replaces that provisional fit. Later changes between portrait and
landscape reshape the client area while preserving the user's manually chosen
scale between rotations. Holding the left mouse button postpones an automatic
fit instead of discarding it.

The marker reports the encoded stream dimensions; it is not remote-control
input, pixel-aspect metadata, or a guarantee that an iPhone application itself
has not letterboxed content inside the video frame. A future versioned IPC
contract should replace stdout parsing and expose explicit stream and
orientation events.

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
7. Test with current iOS releases on Intel, AMD, and ARM64 Windows devices.

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
