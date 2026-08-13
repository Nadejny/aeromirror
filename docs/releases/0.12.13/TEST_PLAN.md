# AeroMirror 0.12.13 — persistent discovery acceptance

## Purpose

This plan verifies that AeroMirror 0.12.13:

1. refreshes the paired RAOP/AirPlay DNS-SD generation in the running process
   and on the existing ports during normal automatic maintenance;
2. safely defers active clients, correlates every command/result, and retains
   a bounded full-process fallback;
3. keeps manual discovery and physical-IPv4 changes as full DNS-SD-plus-BLE
   restarts; and
4. publishes one Bonjour-safe effective receiver name without claiming AWDL,
   continuous iPhone visibility, or a Photos fix.

Public `v0.12.9` remains the immutable normal latest review release. Version
0.12.13 is a local pretag candidate with no tag, GitHub Release, public asset,
or `BUILD_REPORT.md`.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Two clean official native builds | PASS | Both reproduce core SHA-256 `AD59F33907980122551458E5B97CE600D6AB8DBFF923B7BEE5EB30A26F521698` |
| Extracted prepared-source rebuild | PASS | Same executable hash from the archive without Git metadata |
| Native patch/provenance/runtime audits | PASS | Exact patches/sources/inputs, reverse apply, loader, process lifetime, dependencies, and diff agree |
| Redirected command-pipe integration | PASS | Four cases cover same PID/ports and ASCII, Cyrillic, and fallback names |
| Fresh managed build and full resilience | PASS | x64 shell build and complete suite pass |
| Persistent-discovery frozen-source review | PASS | No blocker in that bounded implementation scope; later media audit is tracked separately |
| Source version/default surfaces | PASS | Shell/Setup `0.12.13.0`, Setup 0.12.13, exactly five script defaults |
| Documentation link/UTF-8/diff audit | PASS | 59 source Markdown files resolve locally; changed text is strict UTF-8 without an added BOM; version and diff checks pass |
| Prepared native source | PASS | Exactly 143 archive entries/139 files; content, provenance, patches, and extracted rebuild agree; volatile ZIP container hash is not embedded |
| Runtime/dependency stage | PASS | Exact reviewed core; 199 binaries inspected and 148 DLLs staged |
| Thin review payload | PASS | Exactly 13 entries; complete resilience suite passes against its exact packaged shell |
| Initial Setup and lifecycle gate | PASS | Build and embedded input equality pass; all three verification modes exit 0 |
| Focused post-evidence payload/Setup rebuild | PASS | Exact payload, packaged-shell resilience, embedded equality, runtime, shortcut, update-lifecycle, version, link, UTF-8, diff, and fingerprint gates pass |
| Physical mirroring media liveness | FAIL | Last rendered frame froze while the core/control session stayed alive; continuous VCL/appsrc/decode/Present evidence is absent |
| Physical 30–40 minute iPhone idle | PENDING | Same-PID/port generations plus browse and first-tap evidence |
| Manual and physical-network restart | PENDING | Replacement process plus fresh DNS-SD and BLE startup evidence |
| Installed update and persistence | PENDING | Exact public 0.12.9-to-candidate lifecycle |
| Exact tag and GitHub Release | PENDING | Separate explicit authorization and immutable public-asset gates |

Automated local registration evidence does not establish remote iPhone
visibility. The failed media-liveness row blocks publication independently of
the discovery rows. Keep every remaining physical row pending until its own
evidence is retained.

## Environment and evidence to retain

For automated work, retain the exact source diff, command, source/provenance
hashes, produced executable identity, start/end time, exit code, and complete
failure text.

For every physical run, retain:

- exact candidate Setup/shell/core identity and PE/file version;
- Windows edition/build, x64 architecture, power/lock/sleep state, physical
  adapter/category/IPv4, VPN/virtual-adapter state, and Bonjour service state;
- iPhone model and iOS version, access point/band, Screen Mirroring list state,
  and synchronized timestamps;
- current core PID, RAOP/AirPlay ports, capability marker, each command request,
  deferred/accepted/ready/failed generation, fallback, and first inbound request;
- BLE helper start/ready/failure lines, every manual action and physical
  network signature change, plus a redacted `receiver.log` and screen recording.

Never upload PINs, receiver keys, trusted-client state, settings containing
private values, private media, or an unreviewed diagnostic archive.

## Automated acceptance

1. Audit version sources:
   - shell and Setup assembly/file versions are `0.12.13.0`;
   - Setup comparison version is `0.12.13`;
   - exactly five release-script defaults are `0.12.13`;
   - public 0.12.9 and local 0.12.10–0.12.12 history is not relabeled;
   - `docs/releases/0.12.13/BUILD_REPORT.md` does not exist.
2. Verify native provenance and reproducibility:
   - both complete Git diffs equal their reviewed patches;
   - every patched source/build input and executable hash matches provenance;
   - two clean builds and the extracted source archive reproduce the exact
     reviewed executable;
   - reverse apply, loader, architecture/import, path/debug, dependency, and
     protected unchanged-audio-source checks pass.
3. Verify DNS-SD lifetime and paired-generation behavior:
   - service names, hardware identity, and both TXT records outlive every
     registration generation;
   - RAOP and AirPlay both reach current-generation callbacks before ready;
   - partial failure deallocates both service refs before bounded retry;
   - callbacks and `DNSServiceProcessResult` remain on the owning GLib context.
4. Verify the version-1 command boundary:
   - capability precedes command use;
   - a command survives transient internal GLib-loop replacement;
   - active clients report deferred without destroying listeners;
   - accepted starts a fresh bounded terminal deadline;
   - terminal ready/failed is single, line-framed, and carries exact request,
     generation, PID, RAOP port, and AirPlay port.
5. Verify managed correlation and races:
   - pending state is published before the write and process replacement is
     revalidated under the command lock;
   - wrong request/PID/port, embedded marker text, and stale-process lines do
     not settle or erase the pending request;
   - deferred suspends fallback, accepted cannot regress to deferred, and the
     timeout rechecks current phase/deadline before fallback.
6. Verify automatic maintenance:
   - idle, eligible SessionUnlock, and persistent native health failure first
     request same-process DNS-SD refresh;
   - the existing ten-minute then 20-minute/shared-unlock allowance remains
     bounded and active mirroring/client grace preserves due work;
   - unsupported, rejected, timed-out, or repeated failed commands use at most
     the existing bounded full-process recovery path.
7. Verify strong recovery boundaries:
   - **Restart discovery** never uses the narrow in-place command and performs
     a full process restart after the latest network check;
   - physical IPv4 change performs a full restart so the BLE helper receives
     the new address;
   - intentional BLE shutdown is not failure, while unexpected start failure
     or exit is reported once on stderr without corrupting stdout framing.
8. Verify receiver-name canonicalization:
   - managed normalization is at most 50 UTF-8 bytes, preserves complete text
     elements, strips C0/DEL, replaces unpaired UTF-16, trims, and falls back
     to `AeroMirror`;
   - the save UI informs only when the effective value changes, updates the
     field, and persists it; legacy long values canonicalize silently;
   - native defense truncates at a complete UTF-8 code point and keeps
     `MAC@name` at no more than 63 bytes;
   - AirPlay, RAOP, and `/info` share the canonical name; diagnostics expose
     only byte lengths and a truncation flag.
9. Resolve all local Markdown links, decode changed text as strict UTF-8
   without an accidental BOM, audit current version references, and run
   `git diff --check`.

## Physical test A — uninterrupted 40-minute idle

1. Start the exact candidate on the reporter machine with sleep disabled.
   Confirm initial DNS-SD generation ready, BLE startup, iPhone visibility,
   current PID, and both ports. Do not start mirroring.
2. Observe the first automatic stage near ten minutes. Require a correlated
   accepted/ready generation while PID and both ports remain unchanged.
3. Observe the later timed stage around 20 minutes after stage 1, or exercise
   the eligible SessionUnlock path in a separate run. Require the shared limit,
   another current-generation ready result, and no third maintenance action.
4. Record iPhone visibility immediately before/during/after each refresh and at
   minutes 35 and 40. Tap once at minute 40 and require an inbound request and
   working mirroring without manual discovery restart.
5. Repeat three times. A success is evidence for those runs, not a guarantee
   of continuous visibility on every network or iOS browse cache.

## Physical test B — active-client deferral and fallback

1. Start connecting, PIN entry, audio/video, and full mirroring separately
   before an automatic refresh deadline. Require deferred markers, unchanged
   PID/ports, and no interruption.
2. End the client normally. Require one accepted/ready generation after every
   active/grace guard clears, without a tight retry loop.
3. In an isolated test environment, make the command unavailable or force a
   bounded registration failure. Require the documented full-process fallback
   once, never concurrent listener generations or repeated restarts.
4. Do not mutate the machine-wide Bonjour service on a daily-use PC merely to
   manufacture this case.

## Physical test C — manual and physical-network recovery

1. Record PID, ports, DNS-SD, BLE, and iPhone list state, then choose
   **Restart discovery**. Require a replacement receiver process after the
   network check, fresh DNS-SD and BLE startup evidence, and usable first tap.
2. Confirm the manual path did not report an in-place refresh result. A port
   change is allowed because this is deliberately the strong recovery path.
3. Change the real physical Wi-Fi/Ethernet IPv4. Require a full replacement,
   new cached/advertised address, new BLE helper startup, and no stale-address
   continuation. VPN-only or virtual-adapter changes must not redefine it.

## Physical test D — names and regression matrix

1. Save names at, below, and above 50 UTF-8 bytes using ASCII, Cyrillic,
   emoji/combining text, controls, whitespace-only text, and malformed legacy
   settings in an isolated profile. Confirm the notice, persisted effective
   value, and exact iPhone-visible name where applicable.
2. Confirm the RAOP label never exceeds 63 bytes, no invalid UTF-8 or split
   text element appears, `/info` agrees, and diagnostics never print the name.
3. Repeat Photos/gallery/video, Camera, a rotation-capable app, audio, PIN and
   trust, normal disconnect, short/long Wi-Fi gaps, sleep/resume, settings
   restart, and public 0.12.9 installed-update persistence. Treat Photos inner
   content and Camera rotation as pending separate issues, not discovery proof.

## Failure and acceptance conditions

The candidate fails if any of these occurs:

- automatic maintenance replaces a healthy capable receiver before attempting
  the correlated in-process operation, or changes PID/listener ports after a
  successful ready result;
- only one DNS-SD record is current, ready precedes both current callbacks, an
  old service ref remains active, or retries become unbounded;
- active client work is interrupted, deferred work is lost, stale output
  settles a request, stdout markers become chunk-corrupted, or fallback loops;
- manual discovery or a physical IPv4 change leaves the BLE helper/address
  stale because it used only the narrow DNS-SD command;
- receiver-name handling exceeds Bonjour limits, splits UTF-8/text elements,
  persists a different value from the UI/iPhone name, or logs the original;
- documentation claims continuous visibility, physical acceptance, root cause,
  AWDL/AirDrop, BLE in-place refresh, Photos crop, full-core audit completion,
  focused post-evidence package/Setup completion, tag, or public assets without
  direct evidence.

Source, documentation, native-source, payload, and Setup automated local
acceptance pass, including the focused post-evidence rebuild. Physical
acceptance still needs every physical row above. Publication requires separate
explicit authorization plus clean exact-
tag, four-asset, checksum/API, release-body, and fresh-download verification;
only then add `BUILD_REPORT.md`.
