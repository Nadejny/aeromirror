# AeroMirror 0.12.9 — discovery, Photos window, and install acceptance

## Purpose

This plan verifies AeroMirror 0.12.9 without converting hypotheses into
claims. It covers:

1. the final bounded discovery refresh that may follow the existing ten-minute
   idle renewal and a later Windows session unlock;
2. settings-schema-12 migration and the default-off Photos/media outer-window
   experiment;
3. regression coverage for the untagged 0.12.8 Direct3D 11 presentation-proof
   handoff;
4. a clean Windows 10 first-install investigation that determines whether a
   reboot is actually required and retains Bonjour lifecycle evidence before
   any workaround.

Published `v0.12.7` is immutable, and 0.12.8 was never tagged or published.
Version 0.12.9 uses its own tag and assets and is now the normal
updater-visible public review Release. Its publication-readiness gates pass;
the explicitly identified physical and installed-update rows remain pending.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Managed x64 shell build | PASS | Final build reports `0.12.9.0`; independent legacy-compiler build confirms semantics/version, not byte identity |
| Receiver resilience suite | PASS | Complete suite includes schema 12, exact Photos A/B, bounded unlock, and inherited presentation-proof cases |
| Independent source review | PASS | No P0/P1/P2 finding |
| Source version/schema/defaults | PASS | Shell/Setup `0.12.9.0`, SetupVersion 0.12.9, schema 12 default false, five script defaults |
| Native-core reuse/provenance | PASS | Reused core `eb816257...`, provenance, reverse-apply, and extracted-source rebuild |
| Native source/runtime/loader | PASS | 143 archive entries/139 files; 199 binaries inspected/148 DLLs copied; loader passes |
| Thin review package before evidence docs | PASS | Exact 13 entries, version, runtime, and provenance checks |
| Setup and lifecycle before evidence docs | PASS | Build, embedded payload/provenance, `/verify-runtime`, shortcut/update lifecycle |
| Version, local-link, UTF-8, and diff audit | PASS | Post-evidence source/docs audit passes |
| Focused final package and Setup after evidence docs | PASS | Exact payload, embedded data, runtime, lifecycle, version, link, UTF-8, and diff gates pass again |
| Windows 11 long-idle/unlock discovery | PENDING | Timed log plus iPhone browse result |
| Windows 11 Photos/media A/B | PENDING | Same content with option off/on and retained screenshots/logs |
| Windows 10 clean first install | PENDING | Clean VM, pre-reboot Setup/receiver logs and Bonjour service state |
| 0.12.8 reconnect-proof regression | PENDING | Short/long gap and manual-reselection evidence |
| Installed update and persistence | PENDING | Public 0.12.7-to-exact-0.12.9 update, settings/trust/runtime/shortcut lifecycle |
| Exact tag and release packaging | PASS | Annotated tag object `10deba1d...` resolves to commit `b807d5de...` and tree `a2f49d66...` |
| Public Release/channel/assets/API/re-download | PASS | Release `368804215`; normal latest; four exact assets; local/API/fresh-download hashes and canonical/legacy routes match |

The exact reused native-core SHA-256 is
`eb8162577689eed354c4382acfe099665a6d9e14eed466cb4da6ca6e087448d6`.
The independent legacy-compiler shell build verifies source semantics and
`0.12.9.0` metadata. Legacy `csc.exe` output is not byte-deterministic, so
cross-build shell hash equality is not required; the exact packaged shell hash
belongs to the final focused package gate.

Do not turn a physical or installed-update pending row into PASS from source
inspection, automated checks, or public-asset verification. Those gates cannot
substitute for physical Windows/iPhone behavior or actual Setup execution.

## Environment and evidence to retain

For every physical row, record:

- exact AeroMirror/Setup version and SHA-256;
- Windows edition, version, build, x64 architecture, display scale, and whether
  the test is a clean VM, clean user profile, reinstall, or update;
- iPhone model, iOS version, Rotation Lock state, and the exact app/media used;
- physical Wi-Fi/Ethernet adapter, Windows Private/Public category, access
  point/band, and any VPN, Hyper-V, WSL, hotspot, or virtual adapter;
- exact local timestamps and time zone for install, sign-in/unlock, receiver
  start, each iPhone browse attempt, connection, disconnect, and workaround;
- the reviewed `receiver.log` and, for installation work, `setup.log`;
- before and after screenshots or a short recording that does not expose
  private mirrored content;
- for Bonjour investigation, service presence, state, start type, process
  state, and any UAC/installer prompt before restarting Windows.

Never upload `settings.ini`, `receiver-key.pem`, `trusted-clients.txt`, a PIN,
private media, or an unreviewed diagnostic artifact.

## Automated acceptance and recorded result

The following gates passed against the exact tagged source.

1. The final x64 managed shell build passes and `AeroMirror.exe` reports
   `0.12.9.0`. Independent legacy-compiler output confirms behavior/version but
   is not used as a byte-reproducibility claim.
2. The complete receiver resilience suite passes and covers:
   - clean and migrated profiles defaulting
     `FollowPhotosMediaCanvas=False` and ending at settings schema 12;
   - explicit true/false save, load, clone, normalization, and live-settings
     propagation;
   - the exact ambiguous Photos signature versus ordinary 16:9 and real
     landscape/device-frame signatures;
   - option-off suppression, option-on provisional wide fit, immediate
     re-evaluation when toggled, and no persistence of an automatic provisional
     landscape placement;
   - the first ten-minute idle renewal, unlock before that renewal, unlock
     after it, cooldown, repeated unlock, active mirroring, client grace,
     missing sockets/discovery/network readiness, and competing restart/network
     maintenance;
   - at most one final unlock refresh per idle sequence; unlock events
     themselves do not re-arm it, while new client/mirroring activity, an
     explicit manual discovery refresh, or an actual physical-network epoch
     change starts a new eligible sequence;
   - all current-PID/session/epoch/gap/reason Direct3D 11 present-proof and
     stale-event rejection cases inherited from 0.12.8.
3. Exact native reuse/provenance passes: the 0.12.9 additions introduce no
   delta from the fully gated 0.12.8 native core, patches, runtime,
   dependencies, or provenance. Both patches reverse-apply, the extracted
   prepared source rebuilds the exact core, native source contains 143 archive
   entries/139 files, runtime inspection covers 199 binaries/148 copied DLLs,
   and the loader passes.
4. The pre-documentation thin review payload and Setup pass: exact 13 entries,
   embedded payload/provenance, runtime loader, shortcut choices, update
   lifecycle, and version checks are validated.
5. The source/version/document audits pass:
   - shell and Setup PE/file versions are `0.12.9.0`;
   - Setup's internal comparison version is `0.12.9`;
   - all five release-script defaults are `0.12.9`;
   - commands, asset names, local documentation links, and public download
     links identify 0.12.9;
   - all changed text files decode as strict UTF-8 without an added BOM unless
     an existing file contract requires one;
   - `git diff --check` passes.
6. The focused thin package and Setup rebuild after the evidence update passes.
   Exact payload, embedded payload/provenance, `/verify-runtime`, shortcut/
   update lifecycle, PE/version/default/schema, local-link, strict-UTF-8, and
   diff gates pass again. Volatile shell, payload, Setup, and native-source-ZIP
   container hashes are recorded in `BUILD_REPORT.md`. No pre-tag source or
   documentation edit followed this focused gate.
7. Exact-tag and public verification passes. Annotated tag object
   `10deba1d48482da3500cf0bd7c796c87c7fce736` resolves to commit
   `b807d5dece26e972c58a3a2f7e5585dc8075672e` and tree
   `a2f49d66039c79bdc72907a9cefe6833d4e0257d`. GitHub Release
   `368804215` is normal latest, `draft=false`, and `prerelease=false` with
   exactly four expected assets. Final local files, GitHub API digests, and
   fresh public re-downloads match; `SHA256SUMS.txt` contains exactly three
   entries. Canonical and configured legacy latest API, HTML, and Setup routes
   resolve to the same Release, tag, and Setup bytes.

## Physical test A — long idle and Windows unlock

Use Windows 11 first on the reporter's affected PC, then repeat on Windows 10.

1. Start the exact public 0.12.9 build on a ready Private physical network.
   Verify the receiver appears on iPhone and complete one normal mirroring
   session.
2. Disconnect normally and leave the receiver untouched. Retain the log from
   before idle begins.
3. Confirm the existing first idle discovery renewal occurs no earlier than
   its ten-minute deadline and only while no mirroring/client grace is active.
4. After at least the final-refresh cooldown, lock and unlock the Windows
   session. Wait without pressing **Restart discovery**.
5. Verify the shell schedules at most one final bounded refresh only when the
   core, sockets, discovery marker, cached physical IPv4, network state, and
   maintenance guards are ready.
6. Open iPhone Screen Mirroring at fixed intervals and record when the receiver
   appears and whether the first tap reaches Windows.
7. Lock/unlock repeatedly. Confirm no third idle restart occurs and no restart
   loop develops. Unlock events alone must not re-arm either allowance.
8. Repeat controls for:
   - unlock before the first renewal;
   - unlock during active mirroring;
   - unlock during a new request/PIN/client-grace window;
   - temporarily unavailable physical IPv4 or discovery readiness;
   - a concurrent settings/network/manual restart;
   - an explicit manual discovery refresh after the prior idle allowance was
     consumed;
   - an actual physical-network signature change after the prior idle
     allowance was consumed.
   Confirm that the last two explicit epoch boundaries can re-arm the normal
   bounded sequence while repeated unlock alone cannot.
9. Record whether a manual discovery restart is still needed. That outcome is
   a valid failure signal; do not hide it by restarting early.

Passing this row proves only that the bounded mitigation improves the tested
scenario. It does not prove the original discovery root cause or native
same-port re-publication.

## Physical test B — Photos/media window A/B

Use the same iPhone, network, quality preset, display, photo, and video for both
states.

1. Update a normal existing profile and separately start from clean per-user
   settings. Confirm the new Advanced option is off in both cases.
2. With the option off, start Screen Mirroring from the home screen and from
   Photos. Open the same portrait photo, landscape photo, 1080p/30 video, and
   HEVC 4K/60 video. Record raw geometry, encoded size, outer client size, and
   measured visible inner-content bounds.
3. Enable the option while the exact ambiguous Photos canvas is already
   debounced. Confirm the native receiver is not restarted and the outer window
   re-evaluates immediately to the wide provisional canvas.
4. Confirm the option changes only the outer window. Inner content is allowed
   to remain small; record that result rather than reporting it as fixed.
5. Move through Photos thumbnails, full-screen photo/video, home screen,
   Camera, portrait/landscape rotation, and back. The renderer must not crash,
   close the AirPlay session, enter a resize loop, or treat the provisional
   media canvas as trusted device orientation.
6. End the session without manually moving or resizing the provisional wide
   window. Turn the option off and reconnect. Confirm the provisional landscape
   did not overwrite the previously valid saved placement.
7. Repeat after an explicit user move/resize and after **Restore window
   proportions** to distinguish user-owned persistence from automatic
   provisional fitting.

This row fails if enabling the option changes AirPlay/native arguments,
persists an automatic ambiguous landscape as trusted placement, destabilizes
Photos/video, or claims to enlarge inner content that remains letterboxed.

## Physical test C — clean Windows 10 first install

A same-machine uninstall/reinstall is useful lifecycle coverage but is not a
clean Bonjour reproduction. Use a disposable Windows 10 1809+ x64 VM or clean
machine that has never had AeroMirror or Bonjour installed.

1. Snapshot the clean VM. Record Windows build, pending-reboot indicators,
   installed .NET state, Bonjour service absence/presence, network category,
   and firewall state.
2. Run exact Setup once. Record every UAC, Bonjour, firewall, download, and
   completion prompt plus `setup.log`. Do not reboot and do not manually start,
   stop, repair, or remove Bonjour.
3. Launch AeroMirror normally. Wait at least 60 seconds, retain
   `receiver.log`, inspect diagnostics and Bonjour service/process state, and
   test iPhone discovery plus one connection.
4. If it fails, collect all evidence before using **Stop receiver** / **Start
   receiver** and before rebooting Windows. Record which workaround changes the
   result.
5. Reboot only after the pre-reboot evidence is complete. Repeat the same
   measurements and compare service/process, sockets, discovery markers, and
   iPhone visibility.
6. Restore the clean snapshot and repeat to distinguish a reproducible Setup
   lifecycle defect from a one-off machine condition.
7. Separately test update, reinstall, normal uninstall with preserved settings,
   and uninstall/reinstall on a machine where Bonjour already exists.

Expected result: no full reboot is required. If only a reboot makes discovery
work, this row fails and blocks any broad claim until the exact prerequisite or
Bonjour lifecycle cause is isolated. Do not add a generic reboot prompt solely
from that outcome.

## Physical test D — reconnect-proof regression

1. On the default Direct3D 11/Balanced path, reproduce short and longer Wi-Fi
   interruptions and manual Screen Mirroring reselection.
2. Confirm feedback alone changes the continuity text but never fades it.
3. Confirm only the matching current PID/session/epoch/reason/gap D3D11 present
   proof starts the bounded fade; a stale HWND, mirror-start, push, or sink PTS
   cannot.
4. If proof does not arrive, confirm the explicit reconnect instruction remains
   visible and the underlying frozen video is not reported as recovered.
5. Repeat one Direct3D 12 or Interactive control and confirm it retains the
   manual guidance rather than using unsupported proof.

## Failure and acceptance conditions

The release fails its scoped target if any of these occurs:

- unlock maintenance can restart an active/connecting session, bypass network
  readiness, run before the first idle renewal, run more than once afterward,
  or enter a retry/restart loop;
- documentation claims the unlock mitigation proves the missing-receiver root
  cause or stable-port discovery;
- schema migration enables the Photos option automatically;
- the exact Photos canvas becomes trusted persisted orientation solely because
  the option is enabled;
- Photos/media opening causes the session drop or crash previously corrected
  in 0.12.7;
- Setup installs an undocumented framework prerequisite, or clean Windows 10
  repeatedly needs a reboot without the failure being retained and diagnosed;
- any machine-wide Bonjour mutation is added without a separate reviewed
  design, rollback, privilege, and clean-machine acceptance plan;
- the inherited 0.12.8 continuity view fades without matching real-presentation
  proof;
- versions, source/provenance, payload, Setup, documentation links, or public
  release status disagree.

Publication readiness passes: the scoped automated, native-reuse,
package/Setup, version/link/UTF-8/diff, exact-tag, corresponding-source, and
authorized public-asset gates are complete. Physical Windows/iPhone and
installed-update rows remain `PENDING` for this normal updater-visible public
review release, and the Release body and post-publication report preserve
those limitations.

Full physical acceptance still requires all scoped physical Windows/iPhone and
installed-update rows to pass. Until that matrix passes, describe 0.12.9 as a
public review release, not as physically accepted, production-complete, or
1.0. Exact public evidence is in [`BUILD_REPORT.md`](BUILD_REPORT.md).
