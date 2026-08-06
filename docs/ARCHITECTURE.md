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

## Integration contract

The shell only depends on three behaviors:

1. The core executable is located at `core/uxplay-windows.exe`.
2. The shell starts it with `--headless --uxplay <arguments>`.
3. Renderer windows belong to the core process.

The patched core receives its receiver arguments directly from the shell.
AeroMirror does not write the PIN or the current launch configuration to
uxplay-windows' legacy `arguments.txt` file.

This deliberately keeps protocol code out of the shell. A later native build
can replace the binary boundary with a dedicated `receiver-core.exe` or stable
local IPC API while preserving the settings UX.

## Quality changes during an active session

Source inspection of the bundled UxPlay core confirms that the requested
width, height, refresh rate, and maximum FPS are written into the AirPlay
display-capability response during session setup. The current core exposes no
runtime command or IPC method that renegotiates those fields with an already
connected iPhone.

Version 0.10 therefore saves the new preset and restarts the receiver process,
but the iPhone must reconnect before the new session is guaranteed to use the
new capabilities. Pretending that the existing stream changed quality would
only change the UI, not the incoming encoded video. True live switching needs
a native-core change: an AirPlay renegotiation path plus an IPC command from
the Windows shell.

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
- Advanced arguments are written as plain text. Do not place a reusable secret
  there.
- Logs intentionally avoid video/audio content, but may contain local paths,
  PIDs, receiver names, and arguments.
