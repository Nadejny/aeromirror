# AeroMirror 0.12.16 — persistent discovery acceptance

## Purpose

This plan verifies that AeroMirror 0.12.16 keeps a healthy idle receiver
periodically re-announced without interrupting AirPlay activity or repeatedly
restarting the native process. It distinguishes local registration evidence
from actual iPhone visibility.

Public `v0.12.9` remains the immutable normal latest Release. Version 0.12.16
has no tag, GitHub Release, public asset, public installer, or
`BUILD_REPORT.md`.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Version/default surfaces | PASS | Shell and Setup `0.12.16.0`, Setup comparison and exactly five defaults `0.12.16` |
| Managed Release build | PASS | Current managed source compiles as x64 Release |
| Discovery state-machine contracts | PASS | First 10 minutes, recurring 20 minutes, saturation, unlock, deferral, cooldown, and fallback boundary |
| Complete receiver resilience | PASS | Existing lifecycle, privacy, renderer, package-source, and discovery assertions remain green |
| Unattended update/reinstall policy | PASS | Fresh install stays interactive; update/reinstall preserves shortcut state, bypasses the option form, relaunches, and refuses automatic downgrade |
| Native source/runtime identity | PASS | Frozen 0.12.15 patch/provenance/core are unchanged |
| Review payload and packaged shell | PASS | Focused final local ZIP has exact 13 entries; current/packaged shell equality and packaged resilience pass |
| Setup self-checks | PASS | x64 `0.12.16.0`, byte-exact embedded inputs, and all three non-installing modes exit 0 |
| Corresponding source | PASS | Versioned prepared-native-source workflow and archive validation pass; the clean-tag release script will create the public source archives |
| Installed update | PENDING | Settings, identity, shortcuts, autostart, runtime, launch, and rollback |
| Physical long-idle visibility | PENDING | Two-hour idle run with every renewal and repeated iPhone browse observations |
| Sleep/unlock and router behavior | PENDING | Deferred/guarded refreshes preserve PID/ports and return practical visibility |
| Physical mirroring/media regression | PENDING | Connection, motion, audio, Stop, reconnect, and frozen-frame rows pass |
| Exact tag and GitHub Release | PENDING | Publication is authorized; clean-tag packaging, immutable assets, API digest, and public re-download still must pass |

Automated checks prove managed scheduling and state transitions. They cannot
prove remote iPhone browse behavior or continuous visibility.

Run the native redirected-pipe harness only when no installed or test
`uxplay-windows` process is active. The upstream Windows wrapper uses one
machine-wide BLE status file; the harness now fails closed before launch when
another core is present so it cannot replace that receiver's beacon state.

## Automated acceptance

### Version and history

- shell and Setup assembly/file versions are `0.12.16.0`;
- Setup comparison version and exactly five release-script defaults are
  `0.12.16`;
- frozen 0.12.15 native patch, provenance, runtime, and source identities are
  unchanged;
- internal candidates are not relabelled and
  `docs/releases/0.12.16/BUILD_REPORT.md` does not exist.

### Installed update and reinstall contract

- `/update` selects the automatic transaction after the application-level
  confirmation and never creates the options form;
- a detected installed version lower than or equal to Setup selects the same
  automatic path even when Setup was opened manually;
- no detected installation keeps the clean first-install options;
- a detected newer installed version stays outside the automatic path so
  downgrade requires explicit confirmation;
- automatic update/reinstall reads the existing Start menu and desktop
  shortcut state, recreates exactly that state, and starts the installed shell
  after successful replacement;
- source deletion requested by the updater remains scheduled even though the
  automatic path returns before the interactive form.

### Scheduling contract

- completed count 0 maps to a 10-minute delay;
- every positive completed count maps to a 20-minute delay;
- a due eligible pass advances 0 to 1, 1 to 2, 2 to 3, and continues beyond
  the former limit;
- the counter saturates at `Int32.MaxValue` without disabling maintenance;
- a recent refresh moves the next deadline 20 minutes without consuming a
  renewal;
- a future deadline remains unchanged;
- active mirroring and client grace preserve due work for a later idle pass.

### Refresh and fallback contract

- automatic maintenance requests the correlated native same-process refresh
  before considering any process restart;
- success, nonfallback failure, and nonfallback timeout all rearm the recurring
  deadline;
- only next renewal numbers 1 and 2 authorize the legacy process-restart
  fallback;
- next renewal 3 or later cannot schedule that fallback and keeps the core
  running;
- a pending request is not duplicated, and stale PID/port/request output cannot
  settle the current request.

### Unlock, activity, and network contract

- unlock before the first idle renewal does not replace the normal ten-minute
  stage;
- after any completed renewal, unlock may request another refresh only after
  the ten-minute cooldown and only when core readiness, a local discovery
  marker, physical IPv4, restart state, mirroring, and client grace are safe;
- incoming AirPlay activity rearms a fresh ten-minute epoch;
- a real physical-network change resets the schedule and retains its explicit
  full-process/BLE restart behavior;
- manual **Restart discovery** remains a deliberate full process path.

## Physical test A — two-hour idle visibility

1. Install only the exact gated 0.12.16 Setup. Record shell/core hashes, Windows
   version, network adapter, Bonjour status, receiver PID, and AirPlay port.
2. Confirm the receiver is visible from the iPhone and complete one short
   mirroring session. Stop normally and record the stop time.
3. Leave the PC awake and AeroMirror idle for at least two hours. Do not press
   **Restart discovery** during the observation window.
4. Open and close iPhone Screen Mirroring near minutes 5, 15, 35, 55, 75, 95,
   and 115. Record whether the receiver appears, how long it takes, and whether
   tapping it produces an incoming Windows request.
5. Retain every numbered renewal, native request/generation/PID/port accepted
   or deferred marker, and terminal ready/failed result. Require the same PID
   and ports on successful in-process refreshes.
6. At the end, connect and mirror continuous motion for ten minutes, then Stop.

Acceptance requires the recurring schedule to continue past renewal two, no
unexpected process churn after the legacy boundary, and practical receiver
visibility/connection at every recorded browse check.

## Physical test B — lock, unlock, and sleep

1. After at least one completed idle renewal, lock Windows for 15 minutes and
   unlock. Record cooldown/readiness decisions and the iPhone browse result.
2. Repeat with sleep for 30 minutes, then wake. Record network-profile changes,
   receiver PID/ports, Bonjour state, and whether maintenance defers or runs.
3. If mirroring or an incoming connection is active at a due deadline, require
   no interruption. Stop normally and require the preserved work to run later.
4. Repeat once on Windows 10 and once on Windows 11 when hardware is available.

## Physical test C — failure controls

1. If the row disappears, first record the iPhone browse result and logs before
   changing anything.
2. Try another automatic deadline or guarded unlock and record whether the row
   returns without PID/port replacement.
3. Only then press **Restart discovery** and record the replacement PID, ports,
   DNS-SD/BLE startup, and iPhone result.
4. A local `READY` line without a visible/tappable iPhone row is a physical
   failure, not a pass.

## Carried media and install checks

The exact package must also pass packaged-shell resilience, Setup embedded-
input equality, all three Setup self-checks, installed-update preservation, one
same-version reinstall, and one normal H.264/H.265 mirroring run with visible
motion, audio, iPhone Stop, and immediate reconnect. Installed checks must
retain the pre/post Start menu and desktop shortcut state, settings, receiver
identity, autostart registration, relaunch result, and a controlled rollback
result. The 0.12.15 frozen-frame, Photos, and Camera limitations remain pending
until separately proven on hardware.

## Acceptance boundary

Source acceptance requires every automated row above. Package acceptance adds
the exact payload and Setup rows. Physical discovery acceptance additionally
requires the two-hour and sleep/unlock evidence with real iPhone browse and
connection results. Local installation remains separately unauthorized in this
run. GitHub publication is authorized but still requires the clean-tag and
immutable public-asset gates above. Only after publication may a 0.12.16
`BUILD_REPORT.md` be added.
