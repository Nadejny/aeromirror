# AeroMirror 0.12.7 — media-session continuity acceptance

## Purpose and release state

This plan verifies the focused 0.12.7 correction for AirPlay sessions that can
end during an iPhone Photos photo/video transition. It also verifies the
Windows audio sink and headless renderer-argument paths changed by the patch.

The affected 0.12.6 log proves that the shell/core processes stayed alive and
that the control connection was removed by a software request. It does not
identify which software-disconnect call site ran. The 0.12.7 typed-`TEARDOWN`
marker is therefore required evidence; the rollback is a source-supported
plausible-regression fix whose physical causality remains to be confirmed.

Public `v0.12.7` is the normal updater-visible latest Release and its four
assets have been verified. The release is not physically accepted merely
because automated and publication checks pass. Project policy treats its tag
and assets as immutable; any correction uses 0.12.8 or later.

## Required invariants

1. A typed AirPlay `TEARDOWN` must retain upstream's typed-stream teardown
   behavior and `Connection: close` response header, but the server must not
   force immediate removal of the entire control socket.
2. Normal default audio must select
   `wasapi2sink continue-on-error=true`; mute must not create an audio sink;
   advanced UxPlay arguments must remain authoritative when explicitly set.
3. Headless/`--uxplay` mode must preserve external `-vs` and `-fs` arguments.
   A shell D3D11 request must not become D3D12 because of a hidden wrapper
   preference.
4. A photo/video transition must not terminate the current AirPlay session
   merely because one of the three corrected paths is exercised.
5. Photos content sizing, discovery latency, stale iOS browse rows, and
   automatic reconnect remain separate limitations. A small inner photo is
   evidence for that backlog, but not by itself a failure of this hotfix.

## Test environment and evidence

Record for every physical run:

- exact AeroMirror/Setup version and SHA-256;
- Windows edition, version, build, x64 architecture, and display scale;
- iPhone model and iOS version;
- physical Wi-Fi/Ethernet topology and whether VPN/virtual adapters are
  present;
- selected quality, latency, renderer, audio, fitting, and advanced arguments;
- Windows default audio endpoint and any endpoint change made during the run;
- timestamps for connection, opening Photos, opening a photo, starting/stopping
  video, any apparent stall, and disconnect;
- the corresponding redacted `receiver.log` interval plus a screen recording
  or screenshots that do not expose unrelated personal content.

Priority environment:

1. the same Windows 11 PC, iPhone, network, and Photos sequence that reproduced
   the public 0.12.6 session drop;
2. a second Windows 11 x64 machine or GPU when available;
3. Windows 10 version 1809+ x64 before broader acceptance;
4. at least one removable or disable-able Windows audio endpoint for the
   audio-device rows.

Use a Private physical LAN for the primary run. Repeat the network-safety smoke
on Public/Unknown separately; do not weaken the PIN fail-closed rule to simplify
stream testing.

## Automated pre-publication gates

Run from a clean candidate worktree and retain complete command output:

1. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1`
3. clean native-core rebuild plus patch, reverse-apply, modified-source,
   dependency, loader, and source-provenance validation;
4. runtime contract validation proving that the redistributed runtime is
   GStreamer 1.28.1, contains `libgstwasapi2.dll`, and exposes the required
   `continue-on-error` property; record GStreamer 1.28.5 separately as the
   native build toolchain;
5. `powershell -NoProfile -ExecutionPolicy Bypass -File .\package-review.ps1 -Version 0.12.7 -HeadlessRuntimePath <verified-runtime>`
6. `powershell -NoProfile -ExecutionPolicy Bypass -File .\build-installer.ps1 -Version 0.12.7 -PortableZip .\artifacts\AeroMirror-review-payload-x64-0.12.7.zip`
7. verify shell and Setup PE/file version `0.12.7.0`, Setup's internal
   comparison version, all five script defaults, exact payload entries,
   embedded-payload SHA-256, shortcuts/update lifecycle, documentation links,
   and `git diff --check`;
8. after a clean exact `v0.12.7` tag exists, run exact-tag release packaging
   and verify the four expected public assets before upload.

The source/binary gates must also confirm:

- no typed-`TEARDOWN` path contains the 0.12.6 unconditional
  `http_response_set_disconnect(response, 1)` behavior;
- the built core contains the `AEROMIRROR_TEARDOWN` client-managed marker;
- the built wrapper contains
  `AEROMIRROR_ARGUMENTS_PASSTHROUGH mode=external`;
- default, mute, explicit override, unknown-setting normalization, and legacy
  settings produce the expected exact audio arguments;
- the external-argument pass-through executes before any legacy renderer or
  fullscreen rewriting.

Retained verification status:

| Gate | Status |
|---|---|
| Managed 0.12.7 x64 build | PASS |
| Managed resilience/argument suite | PASS |
| Two clean native rebuilds at SHA-256 `11b65324c83f23503f2d555d0064d1348c884407bf7f9b1c34d27b5d1c05fb9b` | PASS |
| Patch/current-source/protected-audio hashes and source provenance | PASS |
| Redistributed runtime 1.28.1 vs build toolchain 1.28.5 contract | PASS |
| Dependency inspection and collection | PASS |
| Exact public-runtime loader and both reverse-apply checks | PASS |
| Exact 13-entry review payload | PASS |
| Setup `0.12.7.0`, embedded payload, and shortcut/update lifecycle | PASS |
| Setup `/verify-runtime` against the exact public runtime | PASS |
| Exact 143-file native-source content, provenance, and extracted rebuild | PASS |
| Shell/Setup/internal/default versions, links, and diff audit | PASS |
| Exact annotated tag and four public assets | PASS |
| API digests, three-entry checksum file, and fresh public re-downloads | PASS |
| Canonical and legacy latest routes at Release ID `368571434` / `v0.12.7` | PASS |
| Installed update from public 0.12.6 | PENDING |
| Urgent involuntary Photos/video session-drop recheck on reporter's public-build Windows 11/iPhone | PASS — scoped smoke |
| Complete repeated Photos/video acceptance sequence | PENDING |
| Remaining physical Windows 10/11 plus iPhone matrix | PENDING |

Update this table only from retained evidence. Automated PASS does not replace
a physical result. The payload and Setup used for these gates were regenerated
after the evidence-only documentation update and rechecked before the exact tag
was created. Exact published hashes are retained in
[`BUILD_REPORT.md`](BUILD_REPORT.md).

## Retained physical smoke evidence

On 2026-08-11, the reporter tested public 0.12.7 on the affected Windows 11 PC
and iPhone. Starting mirroring directly from Photos and using a normal
gallery/video session no longer reproduced the prior involuntary session drop;
the reporter described the corrected path as working ideally. This is a scoped
PASS for the urgent hotfix target.

The same smoke does not complete this plan:

- one first direct-Photos connection tap failed, while the second succeeded;
- inner gallery photo/video content still rendered small;
- a reporter-estimated wall-clock Wi-Fi interruption of about ten seconds
  recovered automatically; the exact log interval records a five-second
  feedback gap;
- after a reporter-estimated wall-clock interruption of about 15 seconds, whose
  exact log interval records an 11-second feedback gap, reconnect cleared the
  continuity placeholder but video remained frozen. Closing AeroMirror briefly
  exposed the latest frame.

No retained evidence establishes the exact installed 0.12.6-to-0.12.7 updater
path, a complete repeated run, the remaining interruption/handoff rows, or
Windows 10. Those rows remain pending.

## Physical priority test: affected Photos/video sequence

1. Install exact public 0.12.7 over public 0.12.6. Confirm that
   settings, receiver identity, trusted-client state, shortcuts, autostart, and
   the runtime cache remain present.
2. Select normal default audio, Balanced latency, Direct3D 11, and no advanced
   arguments. Start AeroMirror and retain the launch section of the log.
3. Connect from iPhone Control Center while the home screen is visible. Confirm
   moving video and audible output where the source produces audio.
4. Open Photos, open a portrait photo, return to the gallery, open a landscape
   photo, and rotate the phone in both views. Wait at least ten seconds after
   each transition.
5. Open a locally stored video, start playback, scrub once, pause/resume, enter
   and leave fullscreen where iOS offers it, then return to the gallery.
6. Repeat steps 3–5 three times without restarting the receiver. Include one
   run that starts Screen Mirroring while Photos is already open.
7. Stop Screen Mirroring normally, reconnect once from the existing receiver
   row, and repeat one video transition.

Expected result:

- shell and native core processes stay alive;
- the current mirroring session remains usable through photo/video transitions
  unless the iPhone deliberately closes it;
- no transition is followed by the 0.12.6 server-forced disconnect behavior;
- any typed teardown records the audio/video flags and
  `disconnect=client-managed`;
- the launch/selection records show the shell's D3D11 request reaching an
  actual `d3d11videosink` for the D3D11 row;
- real frames continue or resume without requiring the user to stop and
  reselect Screen Mirroring solely because the transition occurred.

Record but do not fail this focused hotfix solely because a photo remains
small inside black bars or because the outer Photos canvas stays ambiguous.
Fail the row if the session drops, freezes permanently, or requires a new iOS
connection after the corrected path is exercised.

## Physical Windows audio-device tests

Run these rows during stable moving video, first on the home screen and then
during local Photos video playback:

1. normal default audio with no device change;
2. change the Windows default output to another active endpoint;
3. disable/re-enable or unplug/replug the active removable endpoint where safe;
4. begin with no usable endpoint, then make one available;
5. mute mode;
6. an explicit advanced `-as` diagnostic override, followed by clearing it.

Expected result for documented `wasapi2sink` endpoint open, I/O, or removal
failures: audio may be absent or interrupted, a warning may be logged, but
video and the AirPlay session continue and a later new session is not
permanently muted. Mute produces no managed sink argument. The explicit
advanced override wins and returns to the managed default after it is cleared.

Do not generalize a PASS to unrelated GStreamer bus errors. Any error outside
the sink property's documented device-failure scope must be classified
separately with its first timestamp and teardown ordering.

## Renderer argument and regression rows

1. D3D11 setting, normal window: requested and actual sink must be D3D11.
2. D3D12 opt-in: requested and actual sink must be D3D12 when supported; an
   unsupported-GPU failure is evidence, not permission to rewrite the request.
3. Fullscreen launch/exit: external `-fs` policy reaches UxPlay without a
   wrapper preference replacing it.
4. Advanced explicit `-vs` override: the last argument remains authoritative
   and the actual-selection marker explains the result.
5. Normal stop, repeated immediate reconnect, a 3–6 second Wi-Fi interruption,
   and a longer-than-15-second interruption: retain results as regression
   evidence, but do not claim discovery or automatic reconnect fixed.
6. Public/Unknown physical network without PIN: the receiver remains paused;
   with a valid PIN it may start according to the existing safety policy.
7. Saved window placement, automatic fitting, taskbar/topmost, and manual fit:
   no regression is introduced by argument pass-through.

## Failure conditions

The public 0.12.7 build fails this plan if any of the following occurs:

- the affected Photos/video transition again ends the AirPlay session through
  an immediate server-forced control-socket removal;
- a documented `wasapi2sink` endpoint failure terminates video/the shared loop
  instead of remaining a warning;
- later sessions remain muted after the endpoint recovers;
- headless mode strips or replaces external `-vs` or `-fs` before UxPlay;
- D3D11 is requested but the wrapper selects D3D12 without an explicit later
  override or a separately classified native fallback;
- shell/core crashes, an unbounded restart loop, duplicate receiver processes,
  settings/trust loss, installer rollback failure, or a Public-network safety
  regression occurs;
- release versions, assets, source/provenance, pinned runtime, or documentation
  disagree.

Small Photos content, slow discovery, a stale iOS receiver row, delayed loss
overlay, or a reconnect requiring manual iPhone selection remain known failures
of broader product acceptance, but they are not evidence that this narrowly
scoped hotfix itself failed unless they coincide with a corrected-path session
termination.

## Acceptance and publication gate

All automated, native-source, runtime-contract, payload, Setup, version, link,
exact-tag, channel, digest, checksum, and public re-download gates passed before
or immediately after publication. Exact evidence is retained in
[`BUILD_REPORT.md`](BUILD_REPORT.md). Physical rows remain pending unless a
retained result is added here. The scoped smoke above is the only retained
physical PASS; all remaining physical rows stay pending. Any later correction
receives 0.12.8 or newer; never move the tag or replace a published 0.12.7
asset.
