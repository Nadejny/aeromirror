# AeroMirror 0.12.16 — persistent idle discovery maintenance

## Status

0.12.16 is an internal pretag candidate. It has no Git tag, GitHub Release,
public asset, public installer, or `BUILD_REPORT.md`. Public `v0.12.9` remains
the immutable normal latest Release. The frozen 0.12.15 candidate and its
artifacts are retained as internal history rather than relabelled.

## Should I update?

- Yes, as a review candidate if AeroMirror disappears from the iPhone Screen
  Mirroring list after the PC has been idle, or if repeated installer option
  prompts made updates inconvenient.
- Optional if public 0.12.9 stays visible and stable on your network. Long-idle
  iPhone visibility and the frozen-frame correction still require physical
  validation, so this is not a claim of full acceptance.

## What changed

AeroMirror is intended to behave like a long-lived receiver in the Windows
tray. Previous managed policy performed one automatic discovery renewal after
ten minutes idle, one more 20 minutes later, and then disabled the schedule for
that idle epoch. The receiver process and Bonjour registrations could still be
locally healthy while an iPhone stopped listing the stale browse row much
later.

0.12.16 keeps maintenance active:

- the first eligible automatic re-registration remains ten minutes after a
  fresh idle epoch;
- every later terminal result schedules another attempt 20 minutes later;
- the normal path refreshes the paired `_raop._tcp` and `_airplay._tcp`
  registration generation in the same native process and on the same ports;
- active mirroring and current AirPlay/PIN/client grace defer due maintenance;
- a guarded Windows unlock may refresh after any completed idle renewal,
  subject to the existing cooldown and readiness/network checks;
- incoming AirPlay activity or a real network-profile change starts a new
  ten-minute epoch.

To avoid replacing a healthy listener indefinitely, only automatic renewal one
or two may use the historical full-process fallback when the native command is
unavailable, rejected, timed out, or failed. Renewal three and later leave the
core alive and rearm the next 20-minute attempt. Manual **Restart discovery**
and a physical IPv4 change remain deliberate full DNS-SD-and-BLE restarts.

Once an installed user confirms an update in AeroMirror, the verified Setup
runs without showing the Start menu, desktop, and launch options again. It
preserves the exact shortcut state already chosen and starts AeroMirror after
replacement. Manually opening a newer Setup or reinstalling the same version
uses the same unattended path. A clean first install remains interactive, and
a newer installed version cannot be downgraded automatically.

## Compatibility and evidence

- Application and Setup source versions are `0.12.16.0`; Setup comparison and
  exactly five release-script defaults are `0.12.16`.
- The managed Release build and complete `ReceiverResilience` suite pass.
- Deterministic tests cover the 10-minute first delay, indefinite 20-minute
  recurrence, a saturating lifetime counter, Windows unlock, cooldown,
  anti-churn, readiness, active-session/client-grace deferral, and the legacy
  fallback boundary. Installer checks cover the automatic update/reinstall
  decision, exact shortcut preservation, relaunch intent, clean-install
  interactivity, and downgrade refusal.
- The live redirected-pipe case refreshes request 98569 in PID 30188 on
  unchanged RAOP/AirPlay port 45023.
- The earlier 0.12.16 package identities were superseded by the unattended-
  update change. Exact final public asset sizes, checksums, and re-download
  evidence will be recorded in the post-publication `BUILD_REPORT.md` rather
  than embedded into the assets whose bytes they describe.
- Native code is unchanged from frozen 0.12.15. The reviewed core remains
  SHA-256
  `38C6A63CE3CA40D3D1E23E5ECB5E0D152F9978986C4384A780C5767EAE0650A4`;
  the libuxplay patch remains SHA-256
  `E8233FFD59BFC49181D32BBD64A6C94A338FD31939B28A18C7FC7A3B5F14195D`.

## What this does not prove

A successful Bonjour callback proves that the local paired registration
generation completed. It does not prove that a particular iPhone currently
lists the receiver, force iOS to discard a cached row, refresh the separate BLE
helper in place, or implement AWDL/peer-to-peer AirPlay. Physical long-idle,
lock/unlock, sleep/wake, router, and repeated iPhone browse testing are required
before continuous practical visibility can be accepted.

This candidate also does not add a new media, Photos crop, Camera rotation, or
AirDrop correction. The frozen 0.12.15 native hardening and its remaining
physical frozen-frame plan are carried forward unchanged. A real installed
update/reinstall, physical visibility/media checks, and public re-download
verification remain pending until their respective gates run.

See [TEST_PLAN.md](TEST_PLAN.md) for exact automated and physical gates.
