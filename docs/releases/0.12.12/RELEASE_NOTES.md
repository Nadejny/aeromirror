# AeroMirror 0.12.12 — bounded second idle-discovery renewal candidate

## Summary

AeroMirror 0.12.12 adds one more strictly bounded timed receiver/discovery
renewal for a receiver that can disappear from the iPhone list after 30–40
minutes of otherwise quiet desktop time.

This is a local pretag candidate, not a public release. Public `v0.12.9`
remains the immutable normal latest review release. There is no 0.12.12 tag,
GitHub Release, public asset, or build report.

## Should I update?

- **Not yet for normal use.** No 0.12.12 installer has been published.
- Use the exact local candidate only for the focused 30–40 minute idle test if
  AeroMirror is running but disappears from the iPhone Screen Mirroring list
  until **Restart discovery** is used.
- Stay on public `v0.12.9` until a later explicitly verified release is
  published. Automated timer tests cannot prove iPhone browse visibility.

## What changed

### A second bounded timed stage

- The existing first idle renewal remains due after ten minutes without a
  mirroring session.
- After that renewal launches a healthy replacement core, AeroMirror now arms
  a second timed renewal for 20 minutes later. The two timed stages therefore
  cover approximately ten and thirty minutes from the start of an uninterrupted
  idle epoch, subject to restart/readiness time and supervision scheduling.
- The second timed stage and the existing post-renewal Windows
  `SessionUnlock` fallback share the same limit of two renewals. A timed second
  renewal prevents a later unlock from creating a third restart; an unlock
  that consumes the final allowance prevents the timed stage from doing so.

### Activity and maintenance remain protected

- Active mirroring and a current high-level client grace period do not consume
  a due timed stage. Its deadline and allowance remain available for a later
  idle supervision pass.
- A recent automatic discovery refresh retains the existing anti-churn guard;
  a timed stage is postponed without consuming its allowance.
- Incoming high-level AirPlay activity, mirroring start, manual discovery
  refresh, core launch, and the existing physical-network/session boundaries
  retain their established reset or re-arm behavior. Low-level socket traffic
  alone does not postpone the sequence.

### Evidence that selected the interval

On the reporter machine, the 0.12.11 shell started at 12:09:14. Core PID 19780
advertised port 61272 and emitted DNS-SD/BLE startup-ready markers by
12:09:20.771. The first idle renewal ran at 12:19:16; replacement PID 39968
advertised port 52197 and reached startup readiness by 12:19:20.053.

No application event, inbound AirPlay probe, readiness failure, sleep, or
network change appears before the user found the receiver absent and manually
refreshed discovery at 12:42:35. Windows records one `SessionUnlock` at 12:14,
before the first renewal. Its next relevant event is `InputHid` at 12:40, not
an unlock. Manual refresh launched PID 36292 on port 53867, reached local
startup readiness 4.776 seconds later, and received an iPhone connection at
12:43:05—an upper bound of 30.717 seconds after the action. The new timed stage
would have been due near 12:39, about 58 seconds before the `InputHid` event.

This sequence supports the bounded timing mitigation. It does not prove which
advertisement or browse-cache layer was stale: current ready markers describe
startup and do not acknowledge continuing DNS-SD/BLE visibility.

## Verification status

- A fresh managed x64 build, the complete receiver resilience suite, and its
  repeat against the exact shell in the review payload pass. Independent
  source/evidence review reports no P0/P1/P2 finding.
- Tests cover both timed delay mappings, allowance transitions and exhaustion,
  timed/unlock mutual exclusion, not-yet-due preservation, recent-refresh
  postponement, mirroring/client-grace deferral, and existing reset/re-arm
  boundaries.
- Source targets app/Setup version `0.12.12` and Windows PE/file version
  `0.12.12.0`; Setup's comparison version and exactly five release-script
  defaults target 0.12.12.
- Prepared native source retains the reviewed unchanged core/provenance and
  contains 143 archive entries/139 files. The thin review payload contains
  exactly 13 entries. Setup builds with embedded payload/provenance equality;
  `/verify-runtime`, `/verify-shortcut-selection`, and
  `/verify-update-lifecycle` each exit 0. x64 architecture, version/five-
  default, all 29 local links across 57 Markdown files, strict-UTF-8, diff, and
  release-input fingerprint gates pass. Exact container sizes/hashes are kept
  in the gate handoff rather than these release-package inputs.
- Installed update, physical 30–40 minute idle, Windows 10/11 and iPhone,
  exact-tag, GitHub Release, and public re-download checks remain pending.
  `BUILD_REPORT.md` is intentionally absent before publication.
- No native receiver, BLE helper, dependency, runtime, patch, or provenance
  input changed. Automatic Photos behavior from the untagged 0.12.11 candidate
  is retained.

The acceptance matrix is in [`TEST_PLAN.md`](TEST_PLAN.md).

## Known limitations

- This is a managed full-process restart/re-registration mitigation, not
  same-process or same-port discovery re-publication.
- It cannot force iOS to invalidate a browse cache and does not guarantee that
  the receiver remains continuously visible between or after renewals.
- Startup DNS-SD/BLE markers do not prove continued discoverability. The
  evidence cannot isolate DNS-SD, BLE, Bonjour service state, port publication,
  or iOS cache behavior as the root cause.
- A full-process renewal may choose another AirPlay port.
- Discovery maintenance is intentionally deferred during active mirroring or
  high-level client grace; the actual renewal time may therefore be later than
  its nominal deadline.
- Same-port acknowledged re-publication, long-gap frozen video, Camera
  orientation without geometry, inner Photos content sizing, Windows 10 first-
  install/reboot evidence, Bluetooth work, and borderless viewer UX remain
  separate pending work.

The untagged 0.12.11 and 0.12.10 artifacts remain local history and must not be
relabeled. Published `v0.12.9` and its assets remain immutable.
