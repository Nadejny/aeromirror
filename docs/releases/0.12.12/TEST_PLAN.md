# AeroMirror 0.12.12 — idle-discovery renewal acceptance

## Purpose

This plan verifies that AeroMirror 0.12.12:

1. retains the existing first idle discovery renewal after ten minutes and
   schedules one additional timed renewal 20 minutes after the replacement
   core;
2. shares a strict two-renewal allowance between the second timed stage and
   the existing post-renewal Windows `SessionUnlock` path;
3. preserves a due stage during active mirroring and high-level client grace,
   while retaining existing anti-churn and epoch reset/re-arm boundaries; and
4. does not claim same-port re-publication, continuous iPhone visibility, or a
   DNS-SD/BLE/iOS-cache root cause without physical evidence.

Public `v0.12.9` remains the immutable normal latest review release. Version
0.12.12 is a local pretag candidate with no tag, GitHub Release, public asset,
or `BUILD_REPORT.md`.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Fresh exact 0.12.12 managed build | PASS | x64 shell compiles with PE/file version 0.12.12.0 |
| Complete receiver resilience suite | PASS | Full suite passes from the fresh build and repeats against the exact packaged shell |
| Discovery-focused independent review | PASS | No P0/P1/P2 finding remains in the bounded managed patch |
| Version/default surfaces | PASS | Shell/Setup PE source, Setup comparison, and exactly five script defaults target 0.12.12 |
| Native/runtime/provenance delta | PASS | No native, BLE-helper, patch, runtime, dependency, or provenance input changed |
| Prepared native source | PASS | Unchanged reviewed core/provenance; 143 archive entries/139 files |
| Thin review payload | PASS | Exactly 13 entries and exact packaged-shell resilience repeat |
| Setup embedded equality and verification | PASS | Embedded payload/provenance matches; all three Setup verification modes exit 0 |
| Architecture/version/docs/fingerprint audit | PASS | x64, PE/version/five defaults, 57 Markdown files/29 local links, strict UTF-8, diff, and input fingerprints pass |
| Physical 30–40 minute iPhone idle | PENDING | Continuous observations across both timed stages and first post-idle browse |
| Physical Windows 10/11 regression | PENDING | Idle, active-session, reconnect, sleep/unlock, network, and Photos matrix |
| Installed update and persistence | PENDING | Exact public 0.12.9-to-candidate lifecycle |
| Exact tag and GitHub Release | PENDING | Explicit authorization, immutable tag/assets, checksums/API, and fresh-download match |

Automated timer and source tests do not establish iPhone visibility. Keep each
pending row pending until its own evidence is retained.

## Reporter-machine 0.12.11 baseline

Retain this exact timeline as the comparison case:

| Local time | Evidence |
|---|---|
| 12:09:14 | 0.12.11 shell started |
| 12:09:20.771 | Core PID 19780, port 61272, DNS-SD/BLE startup readiness complete |
| 12:14 | Windows `SessionUnlock`, before the first renewal |
| 12:19:16 | First ten-minute idle renewal began |
| 12:19:20.053 | Replacement PID 39968, port 52197, startup readiness complete |
| about 12:39 | Due time the 0.12.12 second stage would target |
| 12:40 | Windows `InputHid`, not `SessionUnlock` |
| 12:42:35 | User manually requested discovery refresh after receiver was absent |
| +4.776 seconds | PID 36292, port 53867, local startup readiness complete |
| 12:43:05 | iPhone connection reached Windows, at most 30.717 seconds after manual action |

There was no recorded sleep, physical-network change, inbound AirPlay probe,
application failure, or other app event between the first renewal and manual
refresh. Treat the timeline as reporter-machine physical evidence for choosing
a bounded interval, not as protocol root-cause proof. Startup-ready markers do
not continuously attest advertisement visibility.

## Environment and evidence to retain

For automated work, retain the exact source diff, shell used, command,
start/end time, exit code, and complete failure text.

For every physical run, retain:

- exact candidate Setup/shell identity and PE/file version;
- Windows edition/build, x64 architecture, power plan, lock/sleep state,
  relevant Windows session events, and whether the desktop remained active;
- iPhone model and iOS version, Wi-Fi access point/band, Screen Mirroring list
  state, and synchronized local timestamps;
- physical adapter/category/IPv4, VPN and virtual-adapter state, Bonjour
  service/process state, and any real network-signature change;
- ordered shell/core PIDs and advertised ports, every automatic/manual restart
  reason, readiness marker, inbound connection marker, mirroring start/end,
  client-grace decision, and first iPhone browse/tap result;
- redacted `receiver.log`, relevant Windows event evidence, and screenshots or
  screen recording of the iPhone list at planned checkpoints.

Never upload PINs, receiver keys, trust records, settings containing private
values, private media, or an unreviewed diagnostic archive.

## Automated acceptance

1. Audit version sources:
   - shell and Setup assembly/file versions are `0.12.12.0`;
   - Setup's internal comparison version is `0.12.12`;
   - exactly five release-script defaults are `0.12.12`;
   - public 0.12.9 and untagged 0.12.10/0.12.11 history is not relabeled;
   - `docs/releases/0.12.12/BUILD_REPORT.md` does not exist.
2. Verify deterministic delay mapping:
   - allowance 0 maps to ten minutes;
   - allowance 1 maps to 20 minutes;
   - allowance 2 maps to no further timed stage.
3. Verify a due healthy idle evaluation consumes exactly 0→1 or 1→2 and
   requests at most one restart in that supervision pass. A future deadline
   remains unchanged; an exhausted allowance clears obsolete work.
4. Verify the timed stage and `SessionUnlock` path share the final allowance:
   - timed 1→2 makes a later unlock ineligible;
   - unlock 1→2 makes a later timed pass ineligible;
   - repeated unlock/input events cannot produce a third restart.
5. Verify mirroring and client-grace safety:
   - active mirroring preserves the due timestamp and allowance;
   - unexpired high-level client grace does the same;
   - a later idle supervision pass may consume the still-due stage;
   - low-level accepted-socket evidence alone does not re-arm the sequence.
6. Verify anti-churn behavior: if the last automatic refresh is less than two
   minutes old, postpone the current stage using its stage-specific delay and
   do not consume its allowance.
7. Verify reset/re-arm boundaries independently:
   - fresh/manual discovery refresh and high-level AirPlay activity begin at
     allowance 0 with a ten-minute first stage;
   - mirroring start re-arms the same bounded sequence;
   - a replacement core after stage 1 retains allowance 1 and arms 20 minutes;
   - a replacement core after stage 2 does not arm another stage;
   - session end, physical-network maintenance, readiness recovery, and client
     grace retain their established guards without expanding the allowance.
8. Confirm the patch changes no native source, DNS-SD/BLE registration
   ownership, BLE helper, native capability/argument, dependency, runtime,
   patch, or provenance input.
9. Run the full pretag package/Setup gate. Resolve all local Markdown links,
   decode changed text as strict UTF-8 without an accidental BOM, audit current
   version references, and run `git diff --check`.

## Physical test A — uninterrupted 40-minute idle

Run first on the reporter machine with Windows sleep disabled for the interval.

1. Start the exact 0.12.12 receiver and confirm it is visible on the iPhone.
   Do not start mirroring. Record shell/core PID, port, readiness markers, and
   iPhone list at minute 0.
2. Keep the desktop session and physical network unchanged. Check and record
   iPhone visibility immediately before and after minute 10. Confirm one
   renewal, a replacement PID, a readiness transition, and allowance 0→1.
3. Check at minutes 15, 20, 25, and immediately before the second due time.
   Do not unlock Windows, restart AeroMirror, toggle Wi-Fi, or reopen settings.
4. Around 20 minutes after stage 1 completes (approximately minute 30 from
   initial start), confirm the single stage-2 renewal, allowance 1→2, a healthy
   replacement, and no third stage armed.
5. Check iPhone visibility immediately after stage 2 and at minutes 35 and 40.
   Tap the receiver at minute 40 and confirm an inbound request reaches Windows
   and mirroring starts without manual discovery refresh.
6. Repeat three times. A single successful run is useful evidence but does not
   establish a continuous-visibility guarantee.

## Physical test B — active/client-grace deferral

1. Start mirroring before a timed deadline and keep it active beyond the due
   time. Confirm no receiver restart interrupts the session and the stage is
   not consumed.
2. Stop mirroring normally. During reconnect/client grace, repeatedly inspect
   logs and attempt a normal reconnection. Confirm the pending discovery stage
   cannot interrupt the handshake.
3. After all active/grace guards clear, leave the receiver idle. Confirm the
   overdue stage can run once and consumes only its existing allowance.
4. Repeat with an AirPlay request/PIN marker just before the deadline. Confirm
   high-level activity re-arms the epoch at its first ten-minute stage.

## Physical test C — timed/unlock shared limit

1. After stage 1, unlock Windows after the existing cooldown but before the
   timed second stage. Confirm a guarded unlock refresh may consume allowance
   1→2 and the later timer does not restart again.
2. In a separate fresh epoch, let the timed second stage consume 1→2, then
   lock/unlock Windows. Confirm no additional discovery restart.
3. Repeat unlock while local readiness is temporarily unavailable and while
   restart/network maintenance is busy. Confirm retry/cancel behavior remains
   bounded and does not duplicate a timed restart.
4. Confirm `InputHid`, ordinary keyboard/mouse input, and unlocks before stage
   1 do not substitute for the eligible post-renewal `SessionUnlock` path.

## Physical test D — reset and regression matrix

1. At each stage, use **Restart discovery** and confirm the new manual epoch
   starts with a ten-minute first stage and no stale second-stage timer.
2. Repeat across a real physical IPv4/network-signature change, Wi-Fi loss and
   return, normal session end, abnormal client loss, and shell restart. Retain
   exact reset/re-arm evidence; do not infer it from process presence.
3. Repeat on Windows 10 and Windows 11, including lock/unlock and sleep/resume.
4. Exercise automatic Photos fitting, gallery photo/video, Camera, a rotation-
   capable app, audio, PIN/trust, settings persistence, and update from exact
   public 0.12.9. These paths must not regress because of discovery maintenance.
5. If the receiver is absent, record iPhone browse state before manual action,
   whether the first tap reaches Windows, and the effect and latency of
   **Restart discovery**, **Restart receiver**, and full Stop/Start separately.

## Failure and acceptance conditions

The candidate fails if any of these occurs:

- stage 1 is not near ten minutes or stage 2 is not about 20 minutes after the
  stage-1 replacement is launched and supervised;
- any epoch consumes more than two managed discovery renewals;
- timer and unlock paths each consume a separate final allowance;
- a renewal interrupts active mirroring or a current high-level client grace;
- deferral consumes the allowance, silently loses the due stage, or creates a
  tight retry/restart loop;
- normal high-level activity, mirroring start, manual refresh, core restart, or
  network/session boundaries corrupt the documented reset/re-arm state;
- the patch changes native/BLE/provenance inputs or claims acknowledged
  same-port re-publication without that implementation;
- documentation claims root cause, continuous visibility, physical acceptance,
  package/Setup completion, tag, or public asset without independent evidence;
- public 0.12.9 or local 0.12.10/0.12.11 history is replaced or relabeled.

Local automated pretag acceptance passes: fresh and exact packaged-shell
resilience, independent review, unchanged-native provenance, prepared source,
exact payload, Setup embedded equality and all three verification modes,
x64/version/five-default, 57-Markdown/29-local-link, strict-UTF-8, diff, and
release-input fingerprint gates are complete. Exact container sizes/hashes are
retained in the gate handoff rather than this packaging input. Physical
acceptance still requires the uninterrupted 40-minute test, deferral, shared-
limit, reset, Windows 10/11, iPhone, and installed-update rows to pass.
Publication requires explicit authorization and the normal immutable tag/four-
asset/checksum/API/fresh-download gates; only then add `BUILD_REPORT.md`.
