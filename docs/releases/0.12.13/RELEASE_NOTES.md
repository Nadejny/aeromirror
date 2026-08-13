# AeroMirror 0.12.13 — persistent LAN discovery candidate

## Summary

AeroMirror 0.12.13 can refresh its paired AirPlay Bonjour advertisements in
the running receiver, preserving the native process and listener ports during
normal automatic discovery maintenance.

This is a local pretag candidate, not a public release. Public `v0.12.9`
remains the immutable normal latest review release. There is no 0.12.13 tag,
GitHub Release, public asset, or build report.

Physical testing on 2026-08-13 found an unresolved frozen-last-frame defect
after mirroring began. The control session remained alive and handled the
iPhone's later Stop action, so this is currently bounded to media liveness,
not receiver discovery. Publication is blocked while native VCL/appsrc/
decoded-sink/D3D11-Present evidence is added and the exact boundary is fixed.

## Should I update?

- **Not yet for normal use.** No 0.12.13 installer has been published.
- Use the exact local candidate for focused testing if the receiver disappears
  from the iPhone Screen Mirroring list after idle and returns only after
  **Restart discovery**.
- Stay on public `v0.12.9` until a later explicitly verified release is
  published. Automated registration checks cannot prove iPhone visibility.

## What changed

### Persistent paired DNS-SD refresh

- The automatic ten-minute idle stage, the bounded later idle/unlock stage,
  and native discovery-health recovery now prefer a same-process refresh of
  the `_raop._tcp` and `_airplay._tcp` records.
- A successful refresh keeps the operating-system PID and both RAOP/AirPlay
  listener ports unchanged. It does not reset an otherwise healthy receiver.
- The two records are one registration generation. The core owns their names
  and TXT records for the service lifetime, pumps Bonjour callbacks on the
  owning thread, rolls back both records after partial failure, and retries
  with bounded 1, 2, 5, 10, and 30 second delays.
- Active connection setup, PIN, audio/video clients, and mirroring defer the
  refresh. Listener teardown is never used merely to service a deferred
  command.

### Correlated maintenance protocol and recovery

- A narrow version-1 command protocol uses redirected stdin and framed stdout
  lines. Capability, deferred/accepted progress, and ready/failed results carry
  the request ID, generation, current PID, and both ports.
- The shell accepts a result only for its current receiver and exact pending
  request. A stale, malformed, wrong-PID, or wrong-port line cannot complete
  maintenance.
- If the command is unavailable, rejected, times out, or repeatedly fails,
  AeroMirror retains the existing bounded full-process fallback.
- **Restart discovery** remains a deliberate full restart so it refreshes both
  Bonjour and the separate BLE beacon. A physical IPv4 change also remains a
  full restart because the unchanged BLE helper receives its IP at startup.
- BLE helper diagnostics are line-buffered on stderr, separate from command
  stdout. Unexpected start failure or exit is reported once; intentional
  maintenance shutdown is not reported as a failure.

### Bonjour-safe receiver names

- The effective receiver name is limited to 50 UTF-8 bytes so the RAOP
  `12-character-device-ID@name` label stays within Bonjour's 63-byte limit.
- Managed normalization preserves complete text elements, removes C0/DEL
  controls, replaces invalid unpaired UTF-16, trims whitespace, and uses
  `AeroMirror` when nothing usable remains. The native core independently
  enforces a complete-code-point UTF-8 boundary.
- When an interactive save changes the name, AeroMirror informs the user,
  updates the field, and persists exactly the name the iPhone will see. Legacy
  long stored names are normalized silently during load/save.
- AirPlay, RAOP, and the receiver `/info` response use the same canonical name.
  Diagnostics record only input/registered/RAOP byte counts and a truncation
  flag, never the original name.

## Verification status

- Two clean official native builds and an extracted prepared-source rebuild
  reproduce core SHA-256
  `AD59F33907980122551458E5B97CE600D6AB8DBFF923B7BEE5EB30A26F521698`.
- Patch/provenance, reverse-apply, process-lifetime, runtime/dependency, loader,
  and complete source-diff checks pass.
- Four real redirected-pipe integration cases pass, including correlated
  same-PID/same-port refresh and ASCII, Cyrillic, and fallback name boundaries.
- The fresh managed x64 build and complete receiver resilience suite pass.
  Independent final review found no blocker in the bounded persistent-
  discovery implementation; the later physical media failure and full core
  audit are separate and block publication.
- Source targets app/Setup `0.12.13`, PE/file `0.12.13.0`, Setup comparison
  0.12.13, and exactly five 0.12.13 release-script defaults.
- All 59 source Markdown files pass the local-link audit; changed text passes
  strict UTF-8/no-added-BOM, current-version, and `git diff --check` gates.
- The initial full package gate passes. The final staged runtime contains the
  reviewed core; dependency inspection covers 199 binaries and 148 staged
  DLLs. Prepared corresponding source contains exactly 143 archive entries/139
  files, and content/provenance/patch/extracted-rebuild checks pass. The
  `Compress-Archive` ZIP container hash is intentionally omitted because its
  timestamps are volatile while the validated content is unchanged.
- The thin review payload has exactly 13 entries, and the complete resilience
  suite passes against its exact packaged shell. Setup builds with exact
  embedded-payload/provenance equality; `/verify-runtime`,
  `/verify-shortcut-selection`, and `/verify-update-lifecycle` each exit 0.
  x64 architecture, version/five-default, link, UTF-8, diff, and release-input
  fingerprint gates pass. Volatile shell/payload/Setup sizes and hashes remain
  in the gate handoff rather than these package inputs.
- The focused post-evidence payload/Setup rebuild also passes: exact payload,
  packaged-shell resilience, embedded equality, all three Setup verification
  modes, version/link/UTF-8/diff, and input fingerprints remain green.
  Installed update, physical Windows/iPhone acceptance, exact tag, GitHub
  Release, and public re-download remain pending. `BUILD_REPORT.md` is
  intentionally absent before publication.

The acceptance matrix is in [`TEST_PLAN.md`](TEST_PLAN.md).

## Known limitations

- Bonjour registration callbacks prove that the local paired generation was
  accepted; they do not continuously prove that an iPhone lists the receiver
  or force iOS to discard a stale browse result.
- Automatic same-process maintenance refreshes DNS-SD only. The separate BLE
  helper is unchanged and is refreshed by manual or physical-network full
  restart, not by the in-place command.
- A bounded full receiver restart remains the compatibility and failure
  fallback and may select another AirPlay port.
- Physical 30–40 minute idle visibility, first-tap connection, Windows 10/11,
  sleep/resume, network transitions, installed update, and real Bonjour/BLE
  failure recovery remain pending.
- AWDL/peer-to-peer AirPlay, AirDrop, the full native-core audit, long-gap
  frozen video, Camera rotation without geometry, Photos inner-content
  detection/crop, borderless viewer UX, Windows 10 first-install/reboot proof,
  and code signing are separate work.

The untagged 0.12.10, 0.12.11, and 0.12.12 artifacts remain local history and
must not be relabeled. Published `v0.12.9` and its assets remain immutable.
