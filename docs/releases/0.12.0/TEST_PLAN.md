# AeroMirror 0.12.0 — settings, reconnect, update, and structure acceptance

Status: published review release. Pre-tag automation, exact-tag packaging, and
public-asset verification pass; installed-update and physical results remain
pending.

`v0.12.0` was published from commit
`1a22d175810ff618e0f8c16102f1988d82a5fe10` as a normal, non-draft,
non-prerelease latest review Release. Publication enables updater testing; it
does not mean the physical acceptance cases below have passed.

This plan accepts the integrated 0.12.0 candidate, not an isolated source
fragment. Record the exact candidate commit, AeroMirror/Setup versions, Windows
build, iPhone/iOS version, network profile, VPN state, selected settings, test
time, and relevant redacted log for every failure.

## Test matrix

| Environment | Required scope | Status |
|---|---|---|
| Tagged 0.12.0 source tree | Pre-tag automated gates below | Passed 2026-08-09 |
| Exact `v0.12.0` release packaging | Clean tag, four expected assets | Passed 2026-08-09 |
| Public GitHub Release | Latest-channel state, re-download, sizes, SHA-256, API digests | Passed 2026-08-09 |
| Physical Windows 11 x64 + iPhone | Full functional plan | Pending |
| Physical Windows 10 1809+ x64 + iPhone | Full plan before 1.0 | Pending |
| In-place update from public 0.11.3 | Settings, identity, shortcuts, update lifecycle | Pending |
| Private physical LAN, VPN off/on | No-PIN and optional-PIN behavior | Pending |
| Public or Unknown physical LAN, VPN off/on | Fail-closed behavior and PIN recovery | Pending |

Do not mark a row passed from source inspection or a virtual adapter alone.
The trust category must be the physical Wi-Fi or Ethernet Windows profile.

## Automated gates

The following gates ran against the final clean source that became the
`v0.12.0` tag:

1. Build the x64 managed shell:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
   ```

2. Run the receiver resilience checks:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1
   ```

3. Build the final versioned review payload and Setup using the pinned reviewed
   runtime, then run the installer's shortcut and update-lifecycle verification
   invoked by `build-installer.ps1`.
4. Validate native corresponding-source provenance and hashes even when the
   native executable is unchanged.
5. Verify shell, Setup, payload, tag, asset names, changelog, project state,
   release notes, and this test plan all use the same three-part public version.
6. Run:

   ```powershell
   git diff --check
   ```

All listed automated gates passed. The exact tag then passed `release.ps1`, and
an independent review found no P0/P1 issue. See `BUILD_REPORT.md` for the
published evidence. Any future rebuild fails acceptance on a build/test error,
version mismatch, unexpected native hash, missing mandatory document, or
unreviewed release input.

## Persisted-settings normalization

Close AeroMirror before inspecting or preparing
`%LOCALAPPDATA%\AirPlayReceiverMvp\settings.ini`. Back up the folder locally
and do not attach the unredacted file to an issue.

### Valid settings remain stable

1. On a Private physical network, configure no-PIN mode and save.
2. Restart AeroMirror and confirm no-PIN mode remains selected.
3. Configure PIN mode with a generated four-digit PIN, save, and restart.
4. Confirm PIN mode remains selected and the already trusted iPhone can follow
   the expected trust flow.
5. Change every normal selector to a non-default supported value, save, restart,
   and confirm each value remains selected.

Expected: supported values survive load/save without changing receiver
identity or trusted-client data.

### Unknown and obsolete values fail closed

1. With AeroMirror closed, place an obsolete or unknown pairing value in a
   disposable test copy of `settings.ini`, keeping a syntactically plausible
   PIN beside it.
2. Start AeroMirror on a Public or Unknown physical Windows network.
3. Confirm the value is treated as no PIN and the receiver remains paused.
4. Repeat with PIN mode but a PIN that is not exactly four ASCII digits,
   including full-width Unicode digits.
5. Enable a valid four-ASCII-digit PIN through the UI and confirm the receiver
   can start under the documented Public-network rule.

Expected: no unknown label or malformed PIN can start an unauthenticated
receiver on a Public/Unknown physical network. VPN state does not weaken this
decision.

### Unsupported selectors use stable defaults

Prepare unknown stored values one at a time for quality, renderer, latency,
audio, and theme, then start AeroMirror.

Expected defaults:

- quality: 1080p/60;
- renderer: automatic;
- latency: Balanced;
- audio: Windows default;
- theme: System.

The application must remain usable and save only canonical supported values.

## Atomic settings save

1. Save several different settings combinations and restart after each save.
2. Confirm `settings.ini` always contains one complete, parseable configuration
   and no same-directory AeroMirror settings temporary file remains.
3. Repeat after an in-place update from 0.11.3.
4. Confirm settings, receiver identity, receiver key, and trusted-client state
   survive the update.
5. Use the automated atomic-writer test for interruption-sensitive replacement;
   do not deliberately cut power to a personal machine.

Expected: the old complete file or the new complete file is visible, never a
partially published new file. A failed save must not delete unrelated user
data.

## Immediate reconnect and stale session end

### Clean immediate reconnect

1. Start one mirroring session and wait for stable video/audio.
2. Stop mirroring from the iPhone.
3. Immediately select AeroMirror again.
4. Repeat five times, recording request-to-video timing.

Expected: the first reconnect attempt succeeds, and the log shows no automatic
full-core restart or endpoint change between the newer request and stream start.

### Wi-Fi loss and return

1. While mirroring, turn iPhone Wi-Fi off for ten seconds.
2. Turn Wi-Fi on, wait for the same LAN, and select AeroMirror once.
3. Repeat three times with exact timings.

Expected: stale cleanup from the previous session does not cancel the newer
request/PIN grace or interrupt its handshake. If a fatal recovery is genuinely
required, it remains bounded and is visible in the log.

### Deferred maintenance ordering

1. During an active session, change a receiver setting that requires a later
   core restart and save it.
2. Disconnect and immediately reconnect the iPhone.
3. Repeat with a genuine physical-network event if a controlled test network
   is available.

Expected: deferred settings or network maintenance remains queued throughout
the newer request/PIN grace. A new stream start cancels stale post-session
maintenance; the user's deferred change is not lost.

## Update-version contract

The automated parser test must accept `0.12.0` and `v0.12.0`, and reject:

- `0.12`;
- `v0.12.0.1`;
- `v0.12.0-beta`;
- whitespace, extra text, or non-numeric components.

The published-channel smoke test passed: GitHub exposes `v0.12.0` as the normal
latest Release with the exact `AeroMirror-Setup-0.12.0.exe` asset. All four API
digest fields matched the local and re-downloaded SHA-256 values. Do not create
malformed public Releases merely to exercise rejection.

## Managed-source and compatibility regression

1. Confirm the build discovers all intended `src/**/*.cs` files and no deleted
   legacy form is referenced.
2. Launch the shell, open every current page, change and discard settings, save
   settings, close to tray, reopen from the tray, and exit.
3. Start/stop the receiver, run Diagnostics and Report a problem, and perform
   an update check without downloading an unrelated version.
4. Confirm there remains one managed `AeroMirror.exe`, one separate native
   receiver process while enabled, and no second AeroMirror tray icon.
5. Verify existing settings, autostart, logs, update identity, receiver key,
   trusted-client register, and installed core path are unchanged.

Expected: source organization and legacy-code removal do not alter the active
UI, runtime identities, process boundary, packaging, or in-place update.

## Publication and acceptance gates

The 0.12.0 review-publication gate is **passed**:

- every pre-tag automated and provenance gate passed on the integrated source;
- publication had explicit user authorization;
- exactly four release assets were built from the immutable tag and verified
  after download;
- local files, public downloads, and GitHub API digests matched exactly;
- pending physical Windows/iPhone work is stated prominently.

0.12.0 becomes physically accepted only when:

- the Windows 11 physical plan passes with retained timings and logs;
- no Public/Unknown network can start under an invalid protection state;
- no settings corruption, first-attempt reconnect interruption, crash, missing
  discovery, updater-version ambiguity, or in-place-update regression remains.

Windows 10 physical acceptance remains mandatory before calling the project
1.0. After publication, record the tag, commit, commands, assets, hashes, and
remaining physical status in `BUILD_REPORT.md`. The `v0.12.0` tag and its four
assets are immutable; a failed physical scenario requires a later patch rather
than replacement under the same version.
