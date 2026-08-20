# AeroMirror 0.12.15 — native-core hardening acceptance

## Purpose

This plan verifies that AeroMirror 0.12.15:

1. gives the supported default mirror, HTTP, audio RTP, and NTP workers one
   explicit start/exit/stop/join contract;
2. rejects incomplete, oversized, inconsistent, or failed native protocol and
   crypto operations without false success or process termination;
3. resumes a suspended video renderer only after a complete decrypted and
   NAL-validated access unit, without discarding that same unit;
4. keeps renderer and GStreamer callback ownership valid during concurrent
   render, bus, reset, and teardown paths; and
5. preserves the established shell, discovery, renderer, audio, privacy, and
   update boundaries while physical evidence remains pending.

Public `v0.12.9` remains the immutable normal latest review Release. Internal
0.12.10–0.12.14 history is not reconstructed or relabelled. Version 0.12.15
has no tag, GitHub Release, public asset, public installer, or
`BUILD_REPORT.md`.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Fresh complete native build | PASS | CMake/Ninja links the supported default core from the current audit tree |
| Production AES-CTR happy path | PASS | Exact `crypto.c`, NIST vector, 5+11-byte split, and reset all agree |
| Production worker lifecycle | PASS | Eight executable create/exit/stop/join scenarios pass against the exact helper |
| Source-bound core contracts | PASS | Lifecycle, socket, parser, SETUP, crypto, RTP/NTP, implicit-resume, and renderer ownership assertions pass |
| Independent frozen-source review | PASS | No P0/P1 finding in the supported default mirroring path |
| Reviewed patches and provenance | PASS | Libuxplay patch SHA-256 `E8233FFD59BFC49181D32BBD64A6C94A338FD31939B28A18C7FC7A3B5F14195D`; 37 libuxplay/41 total patched-source hashes and final core agree |
| Two clean compatible native builds | PASS | Both reproduce executable SHA-256 `38C6A63CE3CA40D3D1E23E5ECB5E0D152F9978986C4384A780C5767EAE0650A4` |
| Prepared-source archive workflow | PASS | 147-entry, 826,213-byte ZIP has SHA-256 `DA95EC58A17C37DA53948F770DABEAF29FAD75405CDF69F005F84ACF56362EB7` and validated pinned inputs/hashes |
| Extracted prepared-source rebuild | PASS | No-Git hashes validate and a clean 57/57 build reproduces core SHA-256 `38C6A63CE3CA40D3D1E23E5ECB5E0D152F9978986C4384A780C5767EAE0650A4` |
| Staged runtime and loader | PASS | 199 binaries, 148 DLLs, 44 requested features to 27 plug-ins; manual staged `--loader-test` exits 0 |
| Managed build and resilience | PASS | Fresh managed build and complete `ReceiverResilience` suite pass with the reference-safe D3D11 snapshot contract |
| Live discovery pipe | PASS | Request 98569 completes in process with unchanged PID 38712 and AirPlay port 43214 |
| Initial review payload and packaged shell | PASS | Exact 13-entry ZIP, 1,169,388 bytes, SHA-256 `2123412734FD089F1B65A41DC0451A8105349BED5778B53211340A997500141C`; current/packaged shell is 753,152 bytes, SHA-256 `330EA373212FA0C47B0C25747DACF3F45A27959D56F6643569AD13889E606B81`, and resilience passes |
| Initial Setup | PASS | x64 `0.12.15.0`, 1,397,760 bytes, SHA-256 `BCFFBC8BAE6453A437783A82A6EB307C701CA422A2DBDC5019E3E7F0D6A397E7`; byte-exact payload and all three self-checks exit 0 |
| Focused final package/Setup rebuild | PASS | Exact 13-entry ZIP; built/packaged shell equality and fresh-process resilience; exact embedded payload/provenance hashes; x64 `0.12.15.0` Setup; all three self-checks exit 0 |
| Installed update | PENDING | Settings, identity, shortcuts, autostart, runtime cache, Setup launch, and rollback pass |
| Physical frozen-frame regression | PENDING | Three exact Windows/iPhone runs retain video motion, health, implicit-resume, and Stop evidence |
| Photos and Camera behavior | PENDING | Outer/inner bounds and rotation are measured separately; no crop fix is assumed |
| Exact tag and GitHub Release | PENDING | Separate explicit authorization and immutable public-asset gates |

Automated checks establish source, state-machine, and arithmetic behavior. They
do not prove iPhone interoperability, visible video recovery, Windows version
support, discovery visibility, or a physical root cause.

## Environment and evidence to retain

For automated work, retain the exact source diff, commands, start/end times,
exit codes, compiler/runtime identities, patch/provenance inputs, and complete
failure output.

For every physical run, retain:

- exact shell, Setup, core, patch, and provenance SHA-256 values plus PE/file
  versions;
- Windows edition/build and x64 architecture, GPU/driver, selected renderer,
  latency, quality, audio setting, display scale, and monitor layout;
- iPhone model and iOS version, sending app, orientation, Wi-Fi band/access
  point, and synchronized local timestamps;
- a screen recording showing first motion, any pause/freeze/resume, and the
  iPhone Stop action;
- `receiver.log` from before Screen Mirroring selection through final teardown,
  including complete health intervals and every implicit-resume marker;
- core PID, RAOP/AirPlay ports, mirror-session and geometry generations, codec,
  decoder/sink, SETUP result, and worker start/stop/exit evidence.

Review and redact the log before sharing it. Never share PINs, private keys,
trusted-client state, private media, or an unreviewed diagnostic archive.

## Automated acceptance

### 1. Version and history

- shell and Setup assembly/file versions are `0.12.15.0`;
- Setup comparison version is `0.12.15`;
- exactly five release-script defaults are `0.12.15`;
- public `v0.12.9` and internal 0.12.10–0.12.14 records are not relabelled;
- `docs/releases/0.12.15/BUILD_REPORT.md` does not exist.

### 2. Worker lifecycle and sockets

- compile and run the harness against the exact production lifecycle helper;
- cover create failure, natural exit with join debt, start refusal before join,
  one normal stop, two concurrent stop callers with one join owner, self-stop
  deferral, restart after successful join, and terminal join failure;
- prove mirror, HTTP, audio RTP, and NTP cannot bypass the shared helper;
- prove destruction occurs only after successful join and document the
  process/parent-lifetime requirement when a platform join fails terminally;
- verify accepted mirror and HTTP streams become blocking before publication,
  Windows timeout types are correct, retryable interruption/timeout is not EOF,
  and every bounded loop observes stop state.

### 3. Parsing, SETUP, network, and buffers

- assert all documented mirror and HTTP limits before allocation or copy;
- compile the bounded mirror-payload parser used by production and verify its
  normal H.264/H.265/configuration access-unit contract without executing
  hostile trigger inputs;
- verify SETUP accepts only recognized key/timing and stream forms, rejects
  incomplete or wrong-typed required fields, and cannot return success after a
  failed mirror, NTP, or audio start;
- verify partial ownership rolls back in reverse order and an unattached stream
  response node is freed;
- verify RTP/NTP datagrams require expected lengths and the configured peer,
  metadata and cover-art limits precede allocation, and media-buffer mutation
  is transactional on allocation/decryption failure.

### 4. Crypto and pairing

- compile the exact production crypto implementation with the known-answer
  harness and run AES-CTR as one chunk, 5+11 bytes, and after reset;
- assert checked status for AES, SHA, GCM, X25519, Ed25519, random, and key
  serialization call sites; no crypto error may call `exit` or `abort`;
- verify pairing and FairPlay input lengths and state rollback are checked and
  secrets are excluded from normal log output;
- keep optional PIN/SRP protocol-depth expansion as an explicit P2 row rather
  than claiming full authentication interoperability from this harness.

### 5. Implicit resume and renderer ownership

- source-bind the ordering: complete payload receive, decrypt success, access-
  unit/NAL validation, suspended check, one implicit-resume event/callback,
  then delivery of the same access unit;
- reject any branch that treats encrypted, incomplete, invalid, configuration,
  or report/control data as implicit-resume evidence;
- verify resume is nonblocking and the appsrc pipeline has no candidate-added
  leaky/max properties that could silently discard recovery data;
- prove renderer selection and retained object references precede timestamp
  correction and GStreamer calls;
- map every video/audio bus callback to the bus-owning renderer, retain it
  through the callback, wait for already acquired video callbacks at destroy,
  and keep unused codec renderers alive until final teardown;
- retain existing two-second content-free health and presentation-proof
  behavior. An implicit-resume marker or successful appsrc push is diagnostic,
  not physical proof of a displayed frame.

### 6. Reproducibility, package, and documentation

- materialize the exact wrapper and libuxplay patches and update provenance
  only from their final reviewed inputs;
- require two clean compatible builds plus a rebuild from extracted prepared
  source to reproduce the final reviewed core;
- run runtime/loader, dependency, reverse-apply, protected-source, path/debug,
  thin-payload, packaged-shell, and Setup embedded-input/self-check gates;
- resolve source Markdown links, decode changed text as strict UTF-8 without an
  added BOM, scan current-version/publication/fix claims, and run
  `git diff --check`.

## Physical test A — exact frozen-last-frame regression

1. Install only the exact gated 0.12.15 Setup. Start with Balanced latency,
   Direct3D 11, normal audio, and a stable Private local network. Record PID,
   ports, codec, and start time.
2. Select AeroMirror from iPhone Screen Mirroring while displaying continuous
   motion such as a seconds clock plus scrolling. Require real movement, not
   only a first frame.
3. Run for at least ten minutes. If the picture freezes, leave the session
   untouched for 20 more seconds to retain multiple health intervals.
4. Stop Screen Mirroring on the iPhone and record whether the PC session stops
   immediately. Preserve the failed run before restarting anything.
5. Repeat three times. Acceptance requires continuous visible motion and
   advancing ingress/appsrc/sink/Present evidence; a healthy classifier or
   implicit-resume line alone is insufficient.

## Physical test B — pause, resume, loss, and rapid lifecycle

1. Exercise sender pause/resume or the closest reproducible app transition.
   When a validated type-0 unit resumes a suspended stream, require exactly one
   implicit-resume marker before that unit is delivered and require visible
   motion to return.
2. Run a short Wi-Fi impairment and a separately measured longer impairment.
   Retain control recovery, health, implicit-resume, appsrc, sink, Present, and
   visible-image timing without treating one stage as proof of the next.
3. Perform normal iPhone Stop, immediate reselection, three sequential
   sessions, AeroMirror Stop/Start, and application exit. Require no wedge,
   stale callback, orphaned renderer, duplicate worker, leaked window, or
   unexpected process exit.
4. Repeat with muted and normal audio and with a Windows default-output change.
   Broader audio synchronization remains P2; fail only regressions in the
   supported documented default path.

## Physical test C — protocol and carried boundaries

1. Repeat no-PIN and four-digit PIN connections, trust reuse, rejected PIN,
   normal teardown, and rapid reconnect. Do not call optional PIN/SRP depth
   complete solely because the normal rows work.
2. Repeat same-PID/same-port automatic DNS-SD refresh, manual full
   DNS-SD-plus-BLE restart, long-idle observation, sleep/resume, and physical
   IPv4 change. Native hardening must not change discovery ownership or claim
   continuous iPhone visibility.
3. Change renderer quality/latency/audio settings only at documented session
   boundaries and verify retained settings, receiver identity, trust state,
   shortcuts, and autostart across an installed update and rollback.

## Physical test D — Photos and Camera limitations

1. Open Photos with the same known portrait photo/video and record ordered
   geometry plus outer renderer and inner visible-content bounds separately.
2. Rotate Photos, Camera, the home screen, and a rotation-capable app. Record
   stream geometry and actual outer-window behavior.
3. Do not pass inner sizing merely because the outer window becomes wide, and
   do not pass Camera rotation from a generic landscape canvas. These remain
   unresolved product rows, not acceptance requirements falsely attributed to
   the native hardening itself.

## Failure and acceptance conditions

The candidate fails its source gate if a worker loses join ownership, a new
worker starts over join debt, a callback can outlive its renderer, a protocol
limit follows allocation/copy, failed SETUP publishes partial state, a crypto
failure terminates the process, or implicit resume occurs before full access-
unit validation or drops the triggering unit.

It fails physical media acceptance if any exact run freezes, loses visible
motion while being reported as recovered, drops a normal session, wedges a
restart, or leaves teardown callbacks/resources alive. It also fails release
truthfulness if documentation claims the physical freeze, Photos inner crop,
Camera rotation, package/install, tag, or publication is complete without the
required direct evidence.

Source-level acceptance and the focused local package/Setup gate require all
completed automated rows, final reproducibility, and independent frozen
review. Physical acceptance additionally requires all
three sustained runs and lifecycle transitions with screen/log evidence.
Installed update and publication remain separate later gates and require
explicit authorization. Only after publication may a 0.12.15 `BUILD_REPORT.md`
be added.

The following are accepted P2 backlog, not hidden PASS rows: terminal
join-failure parent lifetime, broader audio/HLS synchronization, remaining
startup assertions, optional PIN/SRP depth, and consolidation of tolerant dual
teardown paths.
