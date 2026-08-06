# Build report — 0.11.0 review build

Build date: 2026-08-06
Target: Windows 10 1809+ / Windows 11, x64
Shell: .NET Framework WinForms, x64
Native receiver: patched uxplay-windows/libuxplay
Pinned native runtime: uxplay-windows 2.0.0.1736 with Qt 6.10.1

## Distribution model

The public review build uses a thin network installer. The setup contains the
AeroMirror shell, patched native core, manifests, documentation, and license
files, but it does not redistribute the complete third-party Qt/GStreamer
runtime.

During installation, setup downloads the exact pinned upstream runtime:

`https://github.com/leapbtw/uxplay-windows/releases/download/2.0.0.1736/uxplay-windows.zip`

Expected upstream archive SHA-256:
`9D3A51C15FC9DB857351195E7EB7BBB21700D9AE25D936A54BCF8536B62CCA18`.

Setup verifies the archive hash, overlays the AeroMirror core, and runs the
native loader compatibility test before replacing an existing installation.
The complete offline portable package is intentionally withheld until its
third-party runtime has a complete, release-grade SBOM and license audit.

## Produced artifacts

### Public installer

`AeroMirror-Setup-0.11.0.exe`

- embedded setup version: `0.11.0`;
- executable file version: `0.11.0.0`;
- final size and SHA-256: recorded in the release asset metadata and the
  adjacent `SHA256SUMS.txt`.

### Application shell

`AeroMirror.exe`

- executable file version: `0.11.0.0`;
- architecture: x64;
- the shell is embedded in Setup rather than published as a loose executable.

### Patched native receiver

`uxplay-windows.exe`

- stripped size: 867,677 bytes;
- SHA-256:
  `B8A0C3687249CDC9925D54DC42DB539F6B6186F955DFE78F5A0A4033DCC405E6`.

### Native source archive

`AeroMirror-native-source-0.11.0.zip`

- final size and SHA-256: recorded in `SHA256SUMS.txt`.

The archive contains prepared pinned upstream source trees with the exact
AeroMirror launcher and libuxplay marker patches both separately and already
applied, `source-provenance.json`, native build scripts and inputs, and the
applicable source licenses. Its rebuild entrypoint does not require Git
metadata: it verifies both patch hashes, all reviewed modified-source and
build-input hashes, generates the x64 `dnssd.lib` import library from the
verified `dnssd.def`, and requires the resulting core to match the reviewed
SHA-256.

### Local review payload

`AeroMirror-review-payload-x64-0.11.0.zip`

- publication status: local build input only; not a public release asset.

The final installer, repository source archive, native source archive, and
checksum manifest are produced only from the clean tagged commit. Their
artifact hashes are deliberately kept in the generated `SHA256SUMS.txt`
instead of copied into this pre-tag source document: rebuilding the C#
executables changes PE timestamps even when the source is identical.

## Reliability and diagnostics changes

- Fixed an intermittent native first-start failure caused by invalidated
  `argv` pointers in `airplayworker.cpp`.
- Removed blind timed Bonjour restarts and debounced physical-network profile
  changes, avoiding the restart storm seen in the tester log.
- Added readiness checks for both the receiver sockets and Bonjour service,
  with one bounded recovery attempt and a fail-closed result.
- Added asynchronous rotating application and native-core logs, including
  start/stop reasons, process IDs, signed and hexadecimal exit codes, and
  readiness state.
- Added bounded crash-loop suppression and immediate diagnostics for permanent
  Windows loader failures.
- Attached the native receiver to a Windows Job Object so an unexpected shell
  exit also cleans up the child receiver and its helper processes.
- Made startup network handling fail closed: PIN-free discovery is allowed
  only on a private Windows network, while public or unknown profiles pause the
  receiver until the network is safe or PIN protection is enabled.
- Added one bounded discovery renewal after a completed mirroring session and
  one renewal after ten idle minutes. A reconnect cancels the pending renewal,
  and cooldowns prevent a restart loop.
- Core-argument changes made during mirroring are saved immediately but the
  receiver restart is deferred until the iPhone disconnects, so changing PIN
  or quality no longer terminates the active picture without warning.

The supplied tester log showed repeated timed/network-triggered restarts, but
it did not contain evidence of a confirmed uxplay-windows process crash. The
restart storm was still actionable and the corresponding blind restart paths
were removed.

## User-interface changes

- Suppressed routine receiver-started notifications during Windows autostart.
- Made a single tray-icon click restore the application window.
- Added Save, Discard, and Cancel handling when leaving settings with pending
  changes.
- Prevented the mouse wheel from changing inactive combo-box selections while
  the settings page is being scrolled.
- Made the Save state track the effective settings, including returning a
  changed value to its original value.
- Compacted the main page, replaced the long status with a coloured state dot,
  and moved detailed physical-network/VPN explanations into a help tooltip.
- Removed the marketing footer and replaced the settings glyph with the
  Windows Segoe MDL2 settings icon.
- Made theme selection transactional: the running UI changes only after
  **Save**, and returning to the original choice disables **Save** again.
- Replaced the native bright ComboBox arrow surface with a theme-aware glyph,
  while keeping normal keyboard and open-list wheel behaviour.
- Made the first-run PIN guidance dismissible and hide it automatically after
  PIN setup.
- Intercepted native mouse-wheel messages before WinForms can change a
  ComboBox value, and close any open popup when its scrolling page moves.
- Reused the cached renderer HWND for manual window fitting, with bounded
  retries when the renderer window is being recreated. A new renderer receives
  a provisional fit, the first stable exact size from the reviewed native
  marker refines it, and later real portrait/landscape changes preserve the
  manually chosen scale between rotations.
- Moved Updates into the main action row, replaced the large Settings button
  with a compact gear, and added the set-up-once/tray value proposition.
- Added a Report a problem action that prepares a separately redacted local
  snapshot, opens a pre-filled GitHub Issue, and requires manual review and
  attachment.

## Checks completed

- The shell and installer C# sources compile successfully for x64.
- A reflection-based UI smoke probe verified save/revert state, deferred theme
  application, closed/open ComboBox wheel routing, popup closure when the
  settings page scrolls, non-overlapping save feedback, compact network
  summary, native size-marker parsing, and 16:9 renderer fitting.
- The thin setup contains exactly 13 entries and no bundled Qt or GStreamer
  runtime DLLs.
- The pinned upstream runtime URL and SHA-256 were verified.
- Setup `/verify-runtime` completed with exit code 0, including archive
  verification, extraction, core overlay, and the loader test.
- A first verification downloaded and stored the 113 MB pinned archive under
  a SHA-256 content-addressed cache; subsequent verification and installation
  reused it, rechecked SHA-256, and completed the loader test without another
  network download.
- The patched receiver loader test passed against the pinned Qt 6.10.1
  runtime.
- Two clean compatible native builds produced the identical stripped-core
  SHA-256 shown above.
- The stripped native core contains no debug sections or embedded local build
  path.
- Both exact native patch gates passed, and the prepared native source ZIP was
  generated from the gated source trees and build inputs. The archive includes
  the provenance document and the verified inputs needed for its rebuild
  script to generate `dnssd.lib` without a pre-bundled import library.
- The prepared native source ZIP was extracted without Git metadata and built
  from a short Windows temporary path. The rebuilt stripped executable matched
  the reviewed core SHA-256 exactly. The script now fails early with a clear
  short-path instruction before MinGW/CMake can hit Windows object-file path
  limits.
- Silent installation and in-place upgrade over a running shell and receiver
  completed with exit code 0. Upgrade from installed `0.10.0.0` to
  `0.11.0.0` preserved the settings file byte-for-byte. A final same-version
  reinstall also preserved both the settings hash and the existing shortcut
  selection.
- An installed `--startup` launch reached `Bonjour Running` and
  `sockets ready: True`; both the 0.11 shell and patched native receiver
  remained alive afterward.
- An installer run blocked by a still-closing receiver left the previous
  installation intact; after adding an explicit process-exit wait, the
  following retry completed successfully. The post-move transactional
  rollback paths for the application directory, shortcuts, uninstall entry,
  and owned autostart values were reviewed in source.
- Job Object cleanup was exercised in an earlier 0.10.0 validation run.
- Log redaction tests covered PINs, passwords, tokens, secrets, MAC addresses,
  PEM blocks, and cryptographic material.
- Crash-window behavior and reflection-based log-redaction checks passed.
- ComboBox wheel handling and settings dirty/revert behavior passed the
  targeted audit tests.
- The real host with a Private physical Ethernet profile plus one Public
  virtual tunnel was classified as Private, while the tunnel was counted only
  as an overlay and excluded from the receiver restart signature.
- Malformed, incomplete, and unknown network-profile JSON remained Unknown
  and fail-closed for no-PIN operation.
- Support-snapshot redaction preserved event timestamps while removing IPv4,
  IPv6, PIN, receiver name, `-n` name, and requesting-device name.

## Known limitations and unverified scenarios

- Windows 10 1809+ is the declared dependency target, but this build was not
  physically launched on a separate Windows 10 machine.
- AirPlay discovery, PIN trust, rotation, video scaling, audio, and quality
  still require end-to-end testing with real iPhones and different networks;
  there is no automated iPhone integration test.
- Quality, PIN, renderer, and latency changes made during an active stream are
  applied by a deferred receiver restart after the iPhone disconnects; UxPlay
  cannot renegotiate these launch arguments inside the existing AirPlay
  session.
- Managed, guest, or client-isolated Wi-Fi networks may block mDNS discovery
  even when both devices appear to use the same network.
- Remote touch control, AirDrop-compatible file transfer, and phone-call
  integration are not implemented.
- The public installer requires internet access to download the pinned native
  runtime.
- The installer and executables are unsigned, so Microsoft Defender
  SmartScreen may display a warning.
- ARM64, 32-bit Windows, Microsoft Store packaging, and signed-update
  verification are not included in this review build.
