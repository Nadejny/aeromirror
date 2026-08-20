# AeroMirror 0.12.15 — native-core hardening candidate

## Summary

AeroMirror 0.12.15 hardens the supported default native AirPlay path from
socket accept and SETUP through worker shutdown, media parsing, crypto, and
GStreamer renderer ownership. It also adds a narrow recovery action: a fully
validated video access unit can release a renderer that remains paused after
the sender has resumed.

This is an internal pretag candidate, not a public release. Public `v0.12.9`
remains the immutable normal latest review Release. Internal 0.12.10–0.12.14
history remains unrelabelled and unpublished. There is no 0.12.15 tag, GitHub
Release, public asset, public installer, or `BUILD_REPORT.md`.

## Should I update?

- **Not yet for normal use.** No 0.12.15 installer has been published.
- Use the exact local candidate only after the focused final package and Setup
  rebuild passes and only for the Windows/iPhone plan in
  [`TEST_PLAN.md`](TEST_PLAN.md).
- Stay on public `v0.12.9` unless a later candidate completes the physical and
  publication gates. Source review and automated tests do not prove that the
  reported frozen-last-frame symptom is fixed.

## What changed

### Explicit worker and socket lifecycle

- Mirror, HTTP, audio RTP, and NTP workers share one lifecycle state machine.
  Natural exit keeps a required join visible; one concurrent caller owns the
  join; a worker cannot join itself; start failure rolls back; and a new start
  cannot overtake an unjoined prior worker.
- Listener sockets remain nonblocking, while accepted mirror and HTTP streams
  are restored to blocking mode before publication. Windows timeout values and
  retryable interrupted/timed operations are handled explicitly.
- Mirror header or payload EOF returns to the accept boundary when appropriate.
  Normal shutdown, peer loss, and fatal media failure no longer collapse into
  one ambiguous worker state.

### Bounded protocol and crypto failures

- Mirror media/configuration/report/control payloads and HTTP URL, header, and
  body fields have explicit size limits and checked allocation paths.
- H.264/H.265 access-unit parsing uses bounded cursors and validates every NAL
  length before the renderer sees it. Encrypted carry handling remains bounded
  across fragmented input.
- SETUP validates its request shape, key material, timing data, stream type,
  ports, and mode before publishing session state. Partial mirror, NTP, or
  audio startup is rolled back and returns an error instead of an empty or
  misleading success response.
- Pairing, FairPlay, RTP, NTP, metadata, cover art, and media-buffer paths now
  propagate invalid length, source, allocation, and crypto failures. Native
  crypto helpers return checked status rather than terminating the receiver.

### Valid-frame implicit resume

- A type-0 video access unit is considered sender-activity evidence only after
  complete receive, decryption, and NAL validation.
- If that valid unit arrives while the mirror stream is still marked
  suspended, the core records
  `AEROMIRROR_VIDEO_IMPLICIT_RESUME reason=valid-type0`, requests a
  nonblocking renderer resume, clears the suspended state, and delivers the
  same access unit normally.
- The candidate does not use the experimental leaky/max appsrc properties and
  does not intentionally drop the access unit that triggered recovery.

### Renderer ownership

- Video render, pause, resume, flush, and bus paths acquire lock-protected
  references to the selected GStreamer objects before operating on them.
  Renderer availability is established before presentation-timestamp work.
- Bus callbacks map the incoming bus to its actual renderer and retain that
  renderer until the callback finishes. Final destruction waits for callbacks
  that already acquired it; an unused codec renderer is retained until final
  teardown rather than being freed while a bus watch can still reach it.
- Audio bus handling maps messages to their owning pipeline and uses retained
  object references. This removes dependence on a process-global current audio
  renderer for bus recovery.

## Verification status

- A fresh complete native CMake/Ninja build passes.
- The exact production `crypto.c` passes the NIST AES-CTR known-answer vector
  across a 5+11-byte streaming split and after reset.
- The exact production worker-lifecycle helper passes eight executable cases
  covering create failure, natural exit, restart exclusion, single and
  concurrent stop, self-stop deferral, and terminal join failure.
- Source-bound checks cover lifecycle consumers, socket mode/timeouts, bounded
  parsers, atomic SETUP ownership, checked crypto, RTP/NTP validation, implicit
  resume ordering, and renderer callback ownership. Independent frozen-source
  review reports no P0/P1 finding in the supported default mirroring path.
- Two clean compatible native builds reproduce executable SHA-256
  `38C6A63CE3CA40D3D1E23E5ECB5E0D152F9978986C4384A780C5767EAE0650A4`.
  Patch/provenance materialization passes with libuxplay patch SHA-256
  `E8233FFD59BFC49181D32BBD64A6C94A338FD31939B28A18C7FC7A3B5F14195D`,
  37 pinned libuxplay files, and 41 patched-source hashes in total.
- The source-archive workflow creates 147 entries and validates their pinned
  inputs and hashes. The final ZIP is 826,213 bytes with SHA-256
  `DA95EC58A17C37DA53948F770DABEAF29FAD75405CDF69F005F84ACF56362EB7`.
  Its no-Git extracted tree validates all pinned hashes, and a clean 57/57
  rebuild reproduces the reviewed core.
- Staged-runtime inspection passes for 199 binaries, 148 DLLs, and 44 requested
  GStreamer features resolving to 27 plug-ins; a manual staged `--loader-test`
  exits 0. The fresh managed build, complete receiver resilience suite, and
  live discovery-pipe refresh also pass. The live case preserves PID 38712 and
  AirPlay port 43214 for request 98569.
- The initial thin review ZIP contains exactly 13 entries, is 1,169,388 bytes,
  and has SHA-256
  `2123412734FD089F1B65A41DC0451A8105349BED5778B53211340A997500141C`.
  Its 753,152-byte packaged shell equals the current shell, has SHA-256
  `330EA373212FA0C47B0C25747DACF3F45A27959D56F6643569AD13889E606B81`,
  and passes the complete resilience suite.
- The initial x64 `0.12.15.0` Setup is 1,397,760 bytes with SHA-256
  `BCFFBC8BAE6453A437783A82A6EB307C701CA422A2DBDC5019E3E7F0D6A397E7`.
  Its embedded payload is byte-exact; `/verify-runtime`,
  `/verify-shortcut-selection`, and `/verify-update-lifecycle` each exit 0.
  The focused final rebuild against the frozen embedded documentation also
  passes: `package-review` produces exactly 13 entries; the packaged shell
  matches the built shell and passes resilience in a fresh PowerShell process;
  Setup embeds byte-exact payload and source-provenance hashes; and all three
  Setup self-checks exit 0. Final focused sizes and SHA-256 values are retained
  in the gate handoff rather than guessed in this update.
- Installed update and physical Windows/iPhone evidence remain pending.

## Known limitations

- No 0.12.15 physical device test has run. The last retained device evidence is
  the installed 0.12.13 run where one H.265 picture appeared and then froze
  while the native process and control session remained alive; iPhone Stop
  still ended the PC session immediately. This candidate has a plausible
  recovery path, not a physically proven freeze correction or root cause.
- `AEROMIRROR_VIDEO_IMPLICIT_RESUME` proves that a validated access unit
  crossed the mirror parser and triggered a resume request. It does not alone
  prove decode, Direct3D 11 Present, or visible motion; correlate it with the
  two-second health sequence and a screen recording.
- Photos may still encode a portrait photo or video inside a landscape
  `3840x2160` canvas with black bars. No trustworthy inner-content rectangle,
  crop, zoom, pixel-analysis rule, or Camera-rotation correction is included.
- Explicit P2 follow-up remains for parent lifetime after a terminal join
  failure, broader audio/HLS synchronization, remaining startup assertions,
  optional PIN/SRP depth, and consolidation of tolerant dual teardown paths.
- Long-idle discovery acceptance, in-process BLE reconfiguration,
  AWDL/peer-to-peer AirPlay, AirDrop, Windows 10 first-install/reboot diagnosis,
  installed update, signing, and publication remain separate work.

Published `v0.12.9` and its assets remain immutable. The internal
0.12.10–0.12.14 candidates are not renamed to fill a public numbering gap.
