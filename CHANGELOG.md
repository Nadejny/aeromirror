# Changelog

## 0.12.4 — smoother recovery, renderer handoff, and diagnostics

### Fixed

- Temporary AirPlay feedback gaps no longer force the shell to replace a core
  that has already recovered its listening socket. AeroMirror keeps the same
  native process and AirPlay port after completed in-process cleanup, and the
  UxPlay reset tolerance returns to its upstream 15-second default instead of
  declaring a six-second network interruption fatal.
- A patched core now announces feedback-health support and recovery. After a
  five-second feedback gap, AeroMirror can show continuity without ending the
  active session; the placeholder closes if feedback resumes and remains
  gated off for older cores that cannot report recovery.
- A reconnect no longer dismisses continuity on the protocol-start line alone.
  AeroMirror waits until the replacement renderer exists and has been placed,
  then fades the placeholder over 180 ms. Saved bounds are also applied from
  the renderer's early Windows show event, reducing the visible jump from the
  default position.
- The continuity snapshot now uses only the renderer client area and is
  rejected when another visible window overlaps it. This captures more useful
  last frames than the former foreground-only rule without copying unrelated
  foreground content.
- Repeated supervision no longer rewrites an unchanged renderer title,
  taskbar style, or topmost state four times per second. Automatic proportion
  fitting is queued after interactive resize completion rather than mutating
  the external window during the drag.

### Changed

- The former Minimal latency profile is now **Interactive**. It disables
  timestamp scheduling with `-vsync no` but no longer forces the aggressive
  50 ms audio-buffer request that caused extra stutter on some networks. Audio
  and video synchronization can be less exact in this mode; Balanced remains
  the default.
- Selecting Direct3D 11 or Direct3D 12 now pins both the matching Direct3D
  decoder family and video sink, with codec matching performed when the
  pipeline is created.
- Support diagnostics record feedback-gap episode count, longest duration,
  native capability state, the raw AirPlay geometry header (including its
  previously ignored auxiliary pair), and the decoder/video sink selected by
  GStreamer. The auxiliary fields are evidence only and are not treated as a
  crop, pixel-aspect-ratio, or rotation signal.
- The settings Back button is larger.

### Compatibility and verification status

- This patch changes both the managed shell and the reviewed native UxPlay
  patch. The pinned upstream revisions and third-party runtime stay unchanged;
  the rebuilt core, reviewed patch, modified source, build inputs, and prepared
  corresponding source match the locked native provenance.
- The managed build, resilience suite, review payload, Setup build and
  lifecycle verifier, native-source/provenance validation, version/link audit,
  `git diff --check`, clean exact-tag packaging, normal latest-channel, and
  public re-download/API digest verification pass for the published review
  release.
- Physical Windows 10/11 plus iPhone recovery, smoothness, Photos, placement,
  and installed-update tests remain pending and must not be inferred from the
  automated checks.
- The published `v0.12.4` tag and its four assets are immutable. Any correction
  must use 0.12.5 or later.
- Photos can still place a small image and black bars inside a
  `3840x2160` encoded canvas. This patch adds geometry evidence but does not
  guess a crop or fix that inner layout.
- The renderer still belongs to the external GStreamer process. A Mac-style
  hover-only frame, true borderless viewer, live aspect lock during dragging,
  and a single embedded surface require a separate native renderer/IPC design.
- AirDrop interoperability and localization are not included. Genuine AirDrop
  requires separate Bluetooth/AWDL, identity, and encrypted-transfer research;
  the resource-based language design remains tracked by decision D-006.

## 0.12.3 — connection-loss continuity and remembered stream windows

### Added

- After a confirmed fatal stream loss, AeroMirror can keep a softened view of
  the last visible renderer frame at the same bounds while the receiver renews
  discovery. The placeholder stays available through core replacement, offers
  an explicit close action, and disappears when a new mirroring session starts,
  the receiver is stopped, or AeroMirror exits. The captured frame remains in
  process memory and is never written to disk.
- The renderer's last normal position, outer size, and DPI are saved after a
  valid fit, move, or resize and restored for the next stream. Bounds from a
  disconnected monitor are clamped into an available Windows work area, and
  size follows a changed monitor DPI.

### Fixed

- When mirroring starts directly inside Photos, a phone-shaped raw size marker
  that arrives before the 350 ms debounce is retained as the device-frame
  candidate. A later `3840x2160` Photos canvas in the same startup burst no
  longer steals that portrait baseline.
- Automatic fitting now preserves the restored window center and approximate
  client area while applying the learned stream proportions.
- The tray fallback is labelled **Restore window proportions**, and the
  settings-page Back control has a larger arrow and hit target.

### Compatibility and verification status

- This patch changes the managed shell and settings schema only. The pinned
  UxPlay executable, third-party runtime, receiver identity and trust state,
  update path, and physical-network protection policy are unchanged.
- The managed build, resilience, installer, packaging, exact-tag, checksum,
  and public re-download/API digest gates pass. The installed updater path and
  physical Windows 10/11 plus iPhone acceptance remain pending for this public
  review release.
- This does **not** fully fix Photos content sizing. iOS can send a
  `3840x2160` encoded canvas with the photo and black bars already inside it;
  the shell can preserve the outer phone orientation but cannot safely crop or
  zoom those inner pixels without native content metadata or validated pixel
  analysis. A session that exposes only a generic media canvas and no early
  phone-shaped marker also remains ambiguous.
- Localization is not included in this patch. The current UI remains Russian;
  the planned resource-based `System / English / Russian` design is tracked by
  decision D-006.

## 0.12.2 — reconnect recovery, media orientation, and automatic fitting

### Fixed

- An abnormal Wi-Fi/client loss no longer loses its recovery decision when the
  native core completes mirror cleanup quickly. AeroMirror now performs one
  bounded discovery renewal after that cleanup; an ordinary clean disconnect
  still keeps the healthy receiver running without a restart.
- A Photos `3840x2160` presentation canvas no longer forces the renderer into
  landscape after AeroMirror has learned a `998x2160` iPhone device frame for
  the session, including when the manual tray fit is used. Physical rotation
  remains accepted when the normalized device aspect matches, including
  `1080x1920` and `1920x1080` devices.
- With automatic fitting enabled, completing a manual renderer resize now
  restores the learned stream proportions after a short delay. Moving,
  minimizing, or maximizing the window does not trigger the fit, and an
  explicit disabled setting remains authoritative.

### Changed

- The first exact video frame in each mirroring session now seeds the device
  aspect instead of requiring a modern tall-iPhone ratio. This fixes physical
  16:9 compatibility while retaining conservative suppression for later
  non-matching media canvases.
- The normal setting is now labelled **Automatically preserve stream-window
  proportions**, and the tray fallback is **Fit window now**.

### Compatibility and verification status

- The managed x64 shell build and receiver resilience suite pass, including
  one-shot abnormal-loss recovery, clean-disconnect, Photos-canvas,
  16:9-rotation, resize-end, and explicit-opt-out coverage.
- The pinned UxPlay core, third-party runtime, persisted settings format,
  receiver identity, and network-safety policy are unchanged.
- Physical Windows 10/11 and iPhone validation is pending. An iPhone may still
  expose a stale discovery row whose first tap never reaches Windows, and a
  session that starts directly in a media canvas can seed the wrong aspect
  until the next session. Same-port native DNS-SD/BLE re-publication remains
  future work.

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
