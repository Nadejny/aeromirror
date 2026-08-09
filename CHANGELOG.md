# Changelog

## 0.12.1 — network-card alignment and tooltip polish

### Fixed

- The network-card title and detail text are vertically centered with the help
  control instead of sitting unevenly inside the card.
- The network help control uses a crisp, centered, DPI-aware question-mark
  glyph so it remains legible at different Windows display scales.
- On a Private physical network, the PIN guidance begins on the second tooltip
  line, keeping the network summary and optional-protection explanation
  visually separate.
- The receiver-state explanation is available when the pointer is over either
  the colored status dot or the adjacent status text.

### Compatibility and verification status

- This is a cosmetic managed-shell review patch. The native UxPlay core,
  receiver lifecycle, discovery/reconnect behavior, settings format, and
  network-safety decisions are unchanged.
- The final managed build and receiver regression suite pass. A focused
  synthetic render confirms the custom help glyph remains centered, crisp,
  and unclipped in light and dark palettes at 100%, 150%, and 200% DPI.
- Physical inspection of the complete settings window on Windows 11 and the
  Windows 10 compatibility smoke remain pending review checks.
- No physical AirPlay behavior is claimed by these interface-only changes.

## 0.12.0 — safer persisted settings and maintainable managed source

### Fixed

- Persisted pairing and selector values are normalized before use. Only the
  supported `none` mode or `pin` with exactly four ASCII digits remains valid;
  obsolete, unknown, or malformed values become unprotected so the existing
  Public/Unknown physical-network policy fails closed instead of starting a
  receiver under a misleading protection mode.
- Settings are written to a temporary file in the same directory and then
  replaced atomically. An interrupted save can no longer expose a partially
  written `settings.ini` as the new configuration.
- A stale end marker from the previous AirPlay session no longer clears a
  newer connection-request or PIN-entry grace period. Deferred settings and
  physical-network maintenance wait for that reconnect attempt instead of
  interrupting its handshake.
- The updater accepts only exact three-part public release tags such as
  `v0.12.0`. Two-part, four-part, suffixed, or otherwise malformed tags are
  rejected rather than interpreted as AeroMirror update versions.

### Changed

- The managed Windows shell is split into focused source files for startup,
  configuration, receiver supervision, rendering, diagnostics, UI, updates,
  network policy, and Win32 interop. These files still compile into the same
  `AeroMirror.exe` assembly and retain the existing namespace, persistence,
  autostart, update, and native-core contracts.
- Three unreachable legacy settings forms were removed after the active UI
  path was separated. No user-facing settings page was intentionally removed.
- The managed build and resilience checks discover all C# files below `src/`
  instead of assuming a single monolithic source file.

### Verification status

- The integrated shell build, resilience suite, review packaging, Setup
  build and lifecycle verifiers, native corresponding-source validation,
  exact-tag release packaging, and whitespace checks pass. All four public
  assets were re-downloaded with matching sizes, SHA-256 values, and GitHub
  API digest fields.
- Physical Windows/iPhone acceptance remains pending for the review candidate.
- The pinned native UxPlay core and third-party runtime are unchanged.

## 0.11.3 — faster reconnects without needless receiver restarts

### Fixed

- A normal mirroring disconnect no longer schedules a full native-receiver
  restart while the receiver is healthy. Its DNS-SD registration and
  listening endpoints remain stable so the iPhone can reconnect immediately
  instead of following a stale advertisement.
- A high-level incoming AirPlay request re-arms the single bounded ten-minute
  idle-discovery fallback and postpones deferred settings maintenance so
  neither can interrupt the handshake. Once mirroring actually starts,
  pending post-session maintenance is cancelled for that session; saved
  settings remain deferred until the next clean disconnect.
- Normal completion and benign feedback warnings do not trigger a full
  restart. Real fatal lost-client and mirror-receive failures retain bounded
  recovery; separately, at most one discovery renewal remains available after
  ten minutes of uninterrupted idle time.
- After iPhone Wi-Fi loss, UxPlay now uses a default lost-client reset bound of
  about six seconds instead of its upstream wait of about fifteen seconds.
  This bounds stale-session cleanup, not end-to-end discovery or connection
  time. An explicit advanced `-reset` argument can still override the default.

### Compatibility

- The reviewed native UxPlay executable and pinned runtime are unchanged from
  0.11.2; this patch updates the AeroMirror shell supervision behavior.

## 0.11.2 — reliable in-place updates

### Fixed

- In-app updates launched from AeroMirror 0.11.0 or 0.11.1 no longer leave
  Setup inside the installed application's working directory. Setup can now
  replace the previous application folder after AeroMirror exits instead of
  failing with a misleading "file is being used by another process" error.
- Setup shutdown is bounded and covers helper executables running from the
  AeroMirror installation directory, reducing transient locks during an
  update without terminating unrelated processes elsewhere on the PC.
- Moving the previous installation now tolerates short-lived file-system
  locks and records actionable attempts in the Setup log. A permanent failure
  still leaves the existing installation intact.

## 0.11.1 — session recovery and reliable discovery

### Fixed

- A stalled session no longer blocks later connections after an iPhone drops:
  AeroMirror waits a bounded amount of time for a normal shutdown, then
  restarts the native core and Bluetooth-beacon process tree.
- Stopping the core can no longer wait indefinitely for a process with
  redirected output. Forced termination is bounded and covers the full child
  process tree.
- After Windows 10/11 starts, AeroMirror now waits for a usable IPv4 address
  on the active physical Wi-Fi/Ethernet adapter. The core no longer starts
  against an empty interface or binds discovery to a temporary VPN address.
- The Bluetooth beacon receives the physical LAN IPv4 address, while the
  native core reports separate DNS-SD and BLE readiness markers. This makes it
  easier to diagnose cases where Bonjour is running but receiver registration
  did not complete.
- Manual discovery refresh now updates the network profile first, and bursts
  of network events are coalesced without the previous long delay.
- Report a problem no longer stacks a notification, Explorer, and the browser:
  AeroMirror selects the redacted log first, opens the GitHub Issue form next,
  and shows progress inside the application window.
- Status and network tooltips now activate only on their small indicators and
  the `?` button, and spacing on the home page is more consistent.
- Setup updates preserve the user's actual Start menu and desktop shortcut
  choices, including legacy shortcut names and the no-shortcuts configuration.

### Diagnostics and validation

- Diagnostic reports now include a compact snapshot of core, socket, active
  session, lost-client recovery, pending restart, and physical-network wait
  state.
- Stable DNS-SD/BLE readiness markers and automated checks were added for
  lost-session recovery, delayed network startup, and shortcut preservation
  during updates.

## 0.11.0 — interface, orientation, and discovery recovery

### Highlights

- The home page is more compact, with a short color-coded status, a concise
  physical-network row, and help available from a dedicated indicator.
- Settings, including theme and connection protection, are applied only after
  the user selects Save.
- If the PIN or another core setting changes during mirroring, AeroMirror
  saves the choice and restarts the receiver safely after the iPhone
  disconnects instead of interrupting the active session.
- A new stream window receives a provisional fit first and is then refined
  using the first exact video size reported by the native core. AeroMirror
  preserves the user's chosen scale across real portrait/landscape changes.
- AirPlay discovery receives bounded self-recovery after a completed session
  and during long idle periods, without repeated restart loops.

### Limitations

- Automatic rotation follows the video dimensions sent by the iPhone. If an
  iPhone app adds its own bars inside the video frame, AeroMirror preserves
  them to avoid cropping screen content.
- Mouse and gesture control of the iPhone is not part of AirPlay Screen
  Mirroring and is not included in this release.
- Changing UxPlay startup parameters still requires a receiver restart. During
  active mirroring, that restart is deferred until the session ends.

## 0.10.0 — review build: stability and diagnostics

This release was prepared for the first public distribution to testers and
for collecting reproducible reports.

### Fixed

- Removed blind Bonjour restarts 15 and 30 seconds after startup.
- Network events are debounced and restart UxPlay only after an actual change
  of the physical Wi-Fi/Ethernet network.
- An unknown network profile is rechecked for a bounded grace period. Without
  a PIN, the receiver fails closed and returns automatically after a safe
  network becomes available.
- Manual discovery refresh performs a full
  stop → short pause → start cycle.
- If readiness cannot be confirmed after the first start, AeroMirror performs
  one controlled full stop/start. A second failure no longer leaves the
  process running with a false green status.
- The shell waits for the previous process to exit before starting another
  instance, preventing two receivers from competing for the same ports.
- Fixed corruption of native UxPlay arguments during the first launch:
  storage for `argv` is now stabilized before pointers are passed to the
  core. This defect could cause unpredictable stalls or crashes.
- Three abnormal exits in one minute disable automatic restart. Persistent
  Windows loader errors (`0xC0000135`, `0xC0000139`, and `0xC000007B`)
  no longer trigger a useless retry loop.
- A normal Windows autostart no longer displays a receiver-started
  notification.
- Public/unknown-network warnings without a PIN are still shown during hidden
  startup, and the global notification setting now also covers core errors.
- A single left click on the tray icon opens AeroMirror.
- Scrolling over a closed list moves the page instead of changing the
  selection.
- Mouse-wheel handling moved to the Win32 level, so quality, latency, audio,
  protection, and theme values no longer change before WinForms receives the
  event. An open list closes when the page is scrolled instead of floating
  away from its field.
- Leaving a page with unsaved changes now offers Save, Discard, or Continue
  editing.
- Automatic fitting runs once and no longer forces landscape photos and
  videos back into portrait proportions.
- Manual fitting reuses an already detected UxPlay window and retries window
  discovery, so it does not depend on a temporary renderer-title change.
- Network-profile parsing now fails closed: physical Wi-Fi/Ethernet and
  VPN/virtual profiles are separated explicitly, the result is passed as
  JSON, and an unknown or malformed category can no longer be treated as
  trusted.

### Diagnostics

- `receiver.log` records UxPlay stdout/stderr, PID, stop/restart reason,
  shell version, Windows version, and physical-network details.
- PIN values are masked as `****`; the log rotates automatically after 5 MB.
- Added troubleshooting instructions and a GitHub Issue template for testers.
- Report a problem is available on the home page and in the tray. It creates a
  separate redacted log copy, opens a prefilled GitHub Issue, and selects the
  file for manual attachment. Logs are never uploaded automatically.
- Random UxPlay PINs, user-profile paths, MAC addresses, and network names are
  also removed before logs are written; existing logs are sanitized at
  startup.
- A separate `setup.log` records installation and update errors. Labelled
  cryptographic material in detailed UxPlay output is redacted.

### Review distribution

- The public Setup was reduced to a network review installer. It downloads the
  unchanged pinned third-party runtime from the upstream GitHub Release and
  accepts it only when its SHA-256 matches.
- Before replacing an installed version, Setup runs a separate loader test
  against the built core inside the downloaded runtime and cancels the
  installation if its DLL or Qt dependencies are incompatible.
- Setup waits for the shell, core, and Bluetooth beacon to exit fully before
  replacing the application directory, and restores the previous version if
  installation fails.
- Updates preserve the user's shortcut selection. If replacement fails, Setup
  restores the previous shortcuts, uninstall registration, and autostart
  configuration together with the old application directory.
- After SHA-256 verification, Setup stores the pinned upstream runtime in a
  content-addressed cache. Reinstallation and later updates using the same
  runtime reuse the cache, verify it again, and still run the loader test.
- AeroMirror source and the complete modified GPL core source tree are
  published alongside Setup. The offline portable package remains unpublished
  until the complete Qt/GStreamer/FFmpeg/MSYS2 SBOM review is finished.
- The public native core is built with deterministic path rewriting and
  without debug sections, so local user names and build paths are not embedded
  in it.
- The native-source archive includes both patches separately and already
  applied, plus `source-provenance.json`. Its rebuild script verifies patch,
  modified-source, and build-input hashes, generates `dnssd.lib` from the
  reviewed `dnssd.def`, and rejects a core with a different final SHA-256.
- The built-in updater accepts only a Setup asset named exactly
  `AeroMirror-Setup-<MAJOR.MINOR.PATCH>.exe` for the GitHub Release version;
  a similarly named or incorrectly versioned file is not launched.

### Interface

- The home page is more compact: status fits beside the product name, settings
  use a small gear button, and update checking shares a row with receiver
  actions.
- Added a short description of the main workflow: configure AeroMirror once,
  then let it start automatically and wait in the tray.
- The PIN suggestion disappears after configuration and can also be dismissed
  manually.
- Improved dark-theme contrast and readability.

## 0.9.0 — Windows 10, updates, and visual design

### Highlights

This release renamed the application to AeroMirror and prepared it for normal
installation and future updates. It supports Windows 10 1809+, updates an
existing installation in place, and shows a clear description of a new GitHub
Release before downloading it.

### Should I update?

- Yes, if version 0.7 or 0.8 is installed: Setup replaces it, preserves
  settings, and can restore the previous files if updating fails.
- Yes, if you use the Windows dark theme or want to choose light/dark
  appearance manually.
- Optional, if the installed version already works for you and you do not need
  the new features.

### What changed

- Added: Follow Windows, Light, and Dark appearance modes.
- Added: a GitHub update-check page with release notes.
- Added: the official `Nadejny/aeromirror` update channel.
- Added: SHA-256 verification of a downloaded installer before launch.
- Changed: the stream window appears on the taskbar by default again and can
  be hidden through settings.
- Changed: the AirPlay rediscovery action has a clearer name.
- Fixed: Setup detects and updates an earlier installation in place instead of
  creating a second entry in Installed apps.
- Fixed: Setup closes before the main application opens.
- Fixed: lists and fields render correctly in the dark theme.
- Clarified: the selected quality is guaranteed to apply to the next iPhone
  connection.

### Limitations

- Setup is unsigned, so SmartScreen may warn about an unknown publisher.
- Before the first GitHub Release is published, update checking reports that
  no releases are available.
- Instant incoming-quality changes without reconnecting the iPhone are not
  supported by the current UxPlay core.
