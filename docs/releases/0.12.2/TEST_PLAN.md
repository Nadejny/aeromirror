# AeroMirror 0.12.2 — reconnect, orientation, and fitting acceptance

## Release status

Version `v0.12.2` was published from commit
`36de759c5f8a9443a60b46b87392fed445eb76c3` at
`2026-08-09T22:16:12Z` as the normal latest GitHub Release with `draft=false`
and `prerelease=false`. Managed, pre-tag, exact-tag, publication, and public
re-download gates pass. Installed-update and all physical Windows/iPhone rows
remain pending. Do not treat this plan as a physical compatibility claim.

Exact public evidence is recorded in `BUILD_REPORT.md`.

## Scope

This patch changes only the managed shell:

- one-shot discovery renewal after explicit abnormal client loss and completed
  native cleanup;
- per-session device-frame aspect learning and suppression of later
  non-matching media canvases for automatic and manual fitting;
- interactive resize-end automatic aspect fitting with an explicit opt-out;
- associated Russian setting and tray labels;
- shell, Setup, script defaults, public examples, and release documentation at
  version 0.12.2.

The pinned UxPlay binary, third-party runtime, source provenance, settings
format, persistent receiver identity, updater protocol, and network trust
policy are unchanged.

## Automated gates

| Gate | Environment | Result | Evidence |
|---|---|---:|---|
| Managed x64 shell build | Local Windows build tools | PASS | `build.ps1` produced `artifacts/Release/AeroMirror.exe` |
| Receiver resilience suite | Local PowerShell/.NET | PASS | `tests/ReceiverResilience.Tests.ps1` completed |
| Clean disconnect | Reflection/source regression | PASS | No abnormal renewal or restart is armed |
| Abnormal cleanup | Reflection/source regression | PASS | Fatal-loss state survives cleanup and selects one renewal |
| One-shot/cancellation | Reflection/source regression | PASS | Recovery is consumed once and a reconnect request cancels it |
| Photos canvas | Reflection regression | PASS | `998x2160` then `3840x2160` retains portrait baseline |
| Manual Photos fit | Reflection regression | PASS | Tray fitting resolves the learned portrait baseline, not raw canvas |
| Physical 16:9 classifier | Reflection regression | PASS | `1080x1920` and `1920x1080` are accepted as one device aspect |
| Direct-media-first limitation | Reflection regression | PASS | First exact canvas seeds baseline and later mismatch is suppressed |
| Resize-end classifier | Reflection/source regression | PASS | Move-only/noise/off do not queue; a real enabled resize does |
| New-profile default and opt-out | Settings regression | PASS | Default is on; normalization preserves explicit false |
| Existing network/update/settings/diagnostic gates | Integrated resilience suite | PASS | Suite completed without regression |
| `git diff --check` | Final working tree | PASS | No whitespace or conflict-marker error |
| Version/link audit | Final working tree | PASS | Current versions/defaults and versioned local targets are consistent |
| Review payload | Pre-tag final candidate | PASS | `package-review.ps1` built the versioned 0.12.2 payload |
| Installer build and lifecycle self-check | Pre-tag final candidate | PASS | Versioned Setup built and the lifecycle verifier completed |
| Native corresponding source | Pre-tag final candidate | PASS | 0.12.2 archive built and pinned provenance validation completed |
| Exact-tag release package | Clean exact `v0.12.2` tag | PASS | `release.ps1` packaged commit `36de759c5f8a9443a60b46b87392fed445eb76c3` |
| Public asset download/digests | Normal latest GitHub Release | PASS | Four re-downloads match local bytes/hashes and all API digest fields |

## Windows 11 + iPhone physical matrix

Record Windows build, iPhone model, iOS version, physical adapter, Windows
network category, router/AP, and timestamps from `receiver.log` for every row.

| Scenario | Expected result | Result |
|---|---|---:|
| Clean Stop Mirroring, immediate reconnect | Receiver stays running; device remains/reappears and reconnects without abnormal renewal | PENDING |
| Disable iPhone Wi-Fi during stream, then enable | One bounded renewal occurs after fatal loss and cleanup; no repeated loop | PENDING |
| Tap a stale row before renewal completes | Failure may occur without Windows traffic; later fresh row reconnects | PENDING |
| Reconnect request arrives before deadline | Pending renewal is cancelled and handshake is not interrupted | PENDING |
| Repeated abnormal loss/reconnect cycles | At most one renewal per fatal loss; no 15-minute lockout | PENDING |
| Open Photos after portrait home screen | `3840x2160` media canvas does not reshape learned portrait window | PENDING |
| Use **Fit window now** while Photos canvas is active | Manual fit keeps the learned device orientation | PENDING |
| Rotate a physical 16:9 iPhone/device | Portrait/landscape window change follows real rotation | PENDING |
| Start mirroring while already in media view | Record actual first frame and known baseline limitation | PENDING |
| Resize renderer and release pointer | Proportions snap after the short delay without resize loop | PENDING |
| Move renderer without resizing | Position remains; no automatic fit occurs | PENDING |
| Disable automatic fitting, resize | User's arbitrary proportions remain unchanged | PENDING |
| Minimize/maximize/restore | No fight with Windows state; normal fitting resumes safely | PENDING |

## Windows 10 1809+ x64 physical matrix

Repeat every applicable Windows 11 row on a real supported Windows 10 x64
system. In addition, retain screenshots/logs for:

| Scenario | Expected result | Result |
|---|---|---:|
| WinEvent resize-end hook lifecycle | Interactive resize queues one fit; receiver restart replaces the hook cleanly | PENDING |
| Light/dark application theme | Updated label fits and remains readable | PENDING |
| 100%, 150%, and 200% DPI | Renderer fit and settings label are usable and unclipped | PENDING |
| In-place update from public 0.12.1 | Settings, PIN trust, identity, shortcuts, and autostart survive | PENDING |

## Log acceptance

For abnormal-loss testing, correlate these events in order:

1. an active mirroring marker;
2. `***ERROR lost connection with client`;
3. native mirror cleanup;
4. one log entry announcing bounded discovery renewal;
5. one receiver restart and readiness sequence;
6. either incoming client traffic or an explicitly recorded iOS-side browse
   delay with no accepted Windows socket.

A normal clean disconnect must not contain step 4. Preserve redacted logs and
wall-clock times; never attach receiver keys, trusted-client files, PINs, or
mirrored media.

## Publication verification

The following release gates passed:

1. managed build and resilience tests against the final source;
2. shell and Setup PE version `0.12.2.0` and Setup public version `0.12.2`;
3. version/link and `git diff --check` audits;
4. review payload, Setup build/lifecycle, and native corresponding-source
   provenance validation;
5. exact-tag `release.ps1` packaging from clean `v0.12.2`;
6. publication of exactly Setup, AeroMirror source, prepared native
   corresponding source, and `SHA256SUMS.txt`;
7. public re-download of all four assets with matching byte size, local
   SHA-256, checksum file values, and GitHub API digest fields.

Any correction must use `0.12.3` or later. Never move the immutable `v0.12.2`
tag or replace any of its assets.
