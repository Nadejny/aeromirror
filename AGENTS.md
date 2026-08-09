# AeroMirror agent guide

This file applies to the entire repository. It is the stable entry point for
coding agents and maintainers; volatile project status belongs in
`docs/PROJECT_STATE.md`, not here.

## Start every task here

1. Resolve and confirm the repository root instead of assuming the current
   working directory. `update-repository.txt` must contain
   `Nadejny/aeromirror`.
2. Read, in order:
   - `docs/PROJECT_STATE.md`
   - `docs/ARCHITECTURE.md`
   - the relevant section of `docs/TODO.md`
   - `docs/DECISIONS.md`
   - `docs/RELEASE_AND_SIGNING.md` for version, installer, or publication work
3. Inspect `git status` before editing. Preserve user changes and unrelated
   work.
4. Treat generated files under `artifacts/` as build outputs, not source.

## Product and architecture invariants

- AeroMirror targets Windows 10 version 1809+ x64 and Windows 11 x64.
- `AeroMirror.exe` is the C# WinForms shell for UI, tray behavior, settings,
  network policy, lifecycle management, updates, and diagnostics.
- `core/uxplay-windows.exe` is the native AirPlay receiver. Bonjour and the
  optional BLE beacon remain separate processes by design.
- Do not merge the shell and native receiver merely to reduce the Task Manager
  process count. A boundary change requires a documented IPC/crash-isolation
  design and real-device benchmarks.
- A Windows Public or unknown physical network must fail closed without PIN
  protection. VPN and virtual adapters must not redefine the trust category of
  the physical LAN.
- Receiver identity, keys, trusted-client state, settings, and logs live in
  per-user local application data and must survive an in-place update.
- Native-source provenance is part of the deliverable. Never replace a pinned
  core, patch, runtime, or hash without updating and validating
  `UPSTREAM.lock`, `THIRD_PARTY_NOTICES.md`, and
  `native-core/source-provenance.json`.

## Change discipline

- Keep user-facing release notes, `CHANGELOG.md`, release plans, and new
  maintainer documentation in English.
- The current application UI is Russian. Do not add isolated English literals
  as a substitute for localization; follow the localization decision recorded
  in `docs/DECISIONS.md`.
- Use three-part semantic versions publicly, for example `0.11.2`; four-part
  PE versions are an internal Windows requirement.
- Never replace an already published asset under the same version. A fix after
  publication receives a new patch version.
- Do not create, move, or delete broad source directories as part of a bugfix.
  Repository reorganization is planned as an explicit 0.12 development step.
- Update `docs/PROJECT_STATE.md` after any material change to release status,
  accepted tests, active blockers, or the next planned step.
- Record durable product or architecture choices in `docs/DECISIONS.md`;
  put implementation tasks in `docs/TODO.md`.

## Verification

Run checks in proportion to the change:

- shell build: `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`
- resilience checks:
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1`
- installer verification is run by `build-installer.ps1`
- release packaging must use a clean, exact tag through `release.ps1`
- always run `git diff --check` before committing

Do not claim Windows 10/11 or iPhone interoperability from automated checks
alone. Record physical-device results against the latest test plan.

## Publication safety

- Pushing source, creating tags, and publishing GitHub Releases are separate
  actions.
- The updater reads GitHub's normal `releases/latest` channel; a GitHub
  Pre-release is intentionally invisible to installed clients.
- A public review release contains only Setup, AeroMirror source, prepared
  native corresponding source, and `SHA256SUMS.txt`. Do not publish the
  offline portable package until its complete runtime SBOM and corresponding
  source review are finished.
- Do not publish, replace assets, rewrite tags, or mark a release as 1.0
  without explicit user authorization and the gates in
  `docs/RELEASE_AND_SIGNING.md`.
