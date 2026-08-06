# Build report — 0.10.0 review build

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

`AeroMirror-Setup-0.10.0.exe`

- size: 1,191,424 bytes;
- SHA-256:
  `2846171C46B46FF66416787360CD161BEACE5BE5D9B7EA6E7B2367523A41998E`.

### Application shell

`AeroMirror.exe`

- size: 675,840 bytes;
- SHA-256:
  `F86F3C67DCEBFF08592EF6C10EF30F1430B122373197C1A4854E22185F8F57E6`.

### Patched native receiver

`uxplay-windows.exe`

- stripped size: 867,614 bytes;
- SHA-256:
  `2A7708704A1344C85A909D5F549DC74E500DE0A552290812DE490692A5187E09`.

### Native source archive

`AeroMirror-native-source-0.10.0.zip`

- compressed size: 681,168 bytes;
- SHA-256:
  `D24BD526A4E8957ADD776EBDC0736A14B90320434269554FF53AFDA84F378E06`.

The archive contains the pinned upstream source trees, the exact AeroMirror
patch, native build scripts and inputs, and the applicable source licenses.

### Local review payload

`AeroMirror-review-payload-x64-0.10.0.zip`

- compressed size: 1,009,762 bytes;
- SHA-256:
  `7619E3C7DF9EE9C74A8F20CFD4484405D716A405D6FFBDC1E767F0DE136A8C72`;
- publication status: local build input only; not a public release asset.

The repository source archive and final release checksum manifest are produced
from the tagged commit. Their hashes are deliberately not recorded in this
pre-tag build report.

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
- Compacted the main page, moved receiver status beside the product heading,
  and improved dark-theme contrast and typography.
- Made the first-run PIN guidance dismissible and hide it automatically after
  PIN setup.

## Checks completed

- The shell and installer C# sources compile successfully for x64.
- The thin setup contains exactly 12 entries and no bundled Qt or GStreamer
  runtime DLLs.
- The pinned upstream runtime URL and SHA-256 were verified.
- Setup `/verify-runtime` completed with exit code 0, including archive
  verification, extraction, core overlay, and the loader test.
- The patched receiver loader test passed against the pinned Qt 6.10.1
  runtime.
- Two clean compatible native builds produced the identical stripped-core
  SHA-256 shown above.
- The stripped native core contains no debug sections or embedded local build
  path.
- The exact native patch gate passed, and the native source ZIP was generated
  from the gated source trees and build inputs.
- Silent installation and in-place upgrade over a running shell and receiver
  completed with exit code 0 after the process-wait fix.
- An installed `--startup` launch reached `Bonjour Running` and
  `sockets ready: True`; the native receiver remained alive afterward.
- An installer run blocked by a still-closing receiver left the previous
  installation intact; after adding an explicit process-exit wait, the
  following retry completed successfully. The post-move transactional
  rollback paths were reviewed in source.
- Job Object cleanup was exercised in an earlier 0.10.0 validation run.
- Log redaction tests covered PINs, passwords, tokens, secrets, MAC addresses,
  PEM blocks, and cryptographic material.
- Crash-window behavior and reflection-based log-redaction checks passed.
- ComboBox wheel handling and settings dirty/revert behavior passed the
  targeted audit tests.

## Known limitations and unverified scenarios

- Windows 10 1809+ is the declared dependency target, but this build was not
  physically launched on a separate Windows 10 machine.
- AirPlay discovery, PIN trust, rotation, video scaling, audio, and quality
  still require end-to-end testing with real iPhones and different networks;
  there is no automated iPhone integration test.
- A quality preset changed during an active stream may require reconnecting
  the iPhone before the new negotiation takes effect.
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
