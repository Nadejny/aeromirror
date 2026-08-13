# AeroMirror 0.12.11 — automatic Photos fitting acceptance

## Purpose

This plan verifies that AeroMirror 0.12.11:

1. removes the temporary Photos-specific UI and persisted setting without
   changing settings schema 12 or unrelated profile values;
2. automatically fits the outer renderer only for the exact correlated
   `3840x2160`, auxiliary `0x0`, encoded `3840x2160` Photos/media signature;
3. keeps that fit provisional, restores a later device-frame target, and does
   not persist false orientation or placement; and
4. preserves the untagged 0.12.10 geometry ordering/test-isolation behavior and
   the public 0.12.9 native, discovery, reconnect, security, installer, and
   update contracts outside this narrow source change.

Public `v0.12.9` remains the immutable normal latest review release. Version
0.12.11 is a verified local pretag candidate with no tag, GitHub Release,
public asset, or `BUILD_REPORT.md`.

## Current evidence status

| Gate | Status | Required evidence |
|---|---|---|
| Fresh exact 0.12.11 managed build | PASS | x64 shell compiles with PE/file version 0.12.11.0 |
| Complete receiver resilience suite | PASS | Full suite passes from the fresh build and repeats against the exact packaged shell |
| Independent source and evidence-doc review | PASS | No P0/P1/P2 finding after implementation and documentation stabilized |
| Source version surfaces | PASS | Shell/Setup PE source, Setup comparison, and exactly five script defaults consistently target 0.12.11 |
| Documentation links/strict UTF-8/diff | PASS | Local links, changed-text encoding, version-reference, and `git diff --check` pass |
| Native/runtime/provenance delta | PASS | No native, patch, runtime, dependency, or provenance input changed |
| Prepared native source | PASS | Reviewed core/provenance retained; exact 143 archive entries/139 files |
| Thin review payload | PASS | Exact 13 entries and exact packaged-shell resilience repeat |
| Setup embedded payload/provenance | PASS | Setup build and embedded payload/provenance comparison pass |
| Setup verification modes | PASS | `/verify-runtime`, `/verify-shortcut-selection`, and `/verify-update-lifecycle` each exit 0 |
| Architecture/version/default/fingerprint audit | PASS | x64 PE, version/default, and release-input fingerprint stability pass |
| Physical iPhone on Windows 10/11 | PENDING | Photos/gallery/photo/video, rotation, outer/inner bounds, placement, and logs |
| Installed update and persistence | PENDING | Exact public 0.12.9-to-candidate update plus settings/trust/key/shortcut lifecycle |
| Exact tag and GitHub Release | PENDING | Explicit authorization, immutable tag, expected assets, checksums, API, and fresh-download match |

Automated geometry tests do not substitute for physical Photos behavior. Keep
each pending row pending until its own evidence is retained.

Exact shell/payload/Setup/native-source ZIP container sizes and hashes are
retained in the final gate handoff rather than embedded in these source
documents, which are themselves release-package inputs.

## Environment and evidence to retain

For automated work, retain the exact commit or dirty-tree diff, shell used,
command, start/end time, exit code, and complete failure text.

For each physical row, retain:

- exact candidate shell/Setup SHA-256 and PE/file version;
- Windows edition/build, x64 architecture, GPU, selected renderer, display
  scale, monitor layout, and clean-install versus update state;
- iPhone model, iOS version, Rotation Lock state, and exact app/photo/video;
- network adapter/category, access point/band, VPN/virtual-adapter state, and
  synchronized local timestamps;
- the ordered raw geometry and encoded-size markers, outer renderer client
  bounds, separately measured visible inner-media bounds, and privacy-safe
  screenshots or recording;
- reviewed `receiver.log` and, for installation work, `setup.log`.

Never upload settings, PINs, receiver keys, trust records, private media, or an
unreviewed diagnostic artifact.

## Automated acceptance

1. Audit version sources:
   - shell and Setup assembly/file versions are `0.12.11.0`;
   - Setup's internal comparison version is `0.12.11`;
   - exactly five release-script defaults are `0.12.11`;
   - historical public 0.12.9 and untagged 0.12.10 evidence is not rewritten or
     relabelled;
   - `docs/releases/0.12.11/BUILD_REPORT.md` does not exist before publication.
2. Verify settings retirement with clean schema-12 profiles and separate
   profiles containing `FollowPhotosMediaCanvas=True`, `False`, and a malformed
   value:
   - the active settings object and Settings UI expose no Photos-specific
     field or checkbox;
   - all legacy values produce the same automatic behavior and do not change
     unrelated settings;
   - canonical save omits the retired key and remains schema 12;
   - clone/copy and migration tests no longer depend on the removed field.
3. Replay correlated geometry records and verify:
   - only primary/source/encoded `3840x2160` with auxiliary `0x0` is classified
     as the exact provisional media canvas;
   - it is selected automatically without a setting toggle or native restart;
   - it does not seed the trusted device-frame baseline;
   - a following `998x2160` device frame becomes the portrait target;
   - generic `1920x1080`, nonzero auxiliary dimensions, mismatched source or
     encoded dimensions, and other near misses do not enter the exact rule;
   - turning off general automatic window fitting still prevents automatic
     movement while preserving manual **Restore window proportions** behavior.
4. Retain the 0.12.10 regression cases:
   - duplicate pending geometry advances sequence without extending the
     original 350 ms deadline;
   - a stable duplicate does not reopen debounce;
   - target-class or exact-aspect changes refit once, while a scaled equivalent
     does not move repeatedly;
   - a blocked or failed fit remains eligible for a later supervision pass;
   - new-session and full-core reset invariants remain distinct;
   - reflection tests use only their validated GUID temporary root and leave
     production settings/log files untouched.
5. Confirm an automatic media-canvas fit cannot make placement persistable or
   overwrite valid saved bounds. Only a trustworthy device-frame fit or
   explicit user move/resize may enter the existing persistence path.
6. Confirm no native source, capability bit, receiver argument, renderer sink,
   runtime, dependency, patch, provenance, discovery, reconnect, or security
   input changed.
7. Resolve all local Markdown links, decode changed text as strict UTF-8
   without an accidental BOM, audit current version references, and run
   `git diff --check`.

## Physical test A — automatic Photos outer-window behavior

Run first on Windows 11 and repeat on Windows 10 with the same iPhone, media,
renderer, display scale, and Rotation Lock state.

1. Start mirroring on the portrait Home screen. Record the device-frame marker,
   outer client bounds, saved placement state, and screenshot.
2. Open Photos, gallery, a portrait photo, a landscape photo, Full HD/30 video,
   and HEVC 4K/60 video. Do not look for or enable a Photos-specific option; it
   must not exist.
3. When the exact correlated media signature arrives, verify the outer renderer
   adapts once to `MediaCanvas` landscape without a receiver restart, repeated
   movement, or a session drop.
4. Return to a phone-shaped `998x2160` stream and verify the outer renderer
   returns to portrait. Repeat the media/device transition at least five times
   and retain event order plus outer bounds for every pass.
5. Start a new session directly inside Photos so the exact media canvas can
   arrive before a phone-shaped frame. Verify it receives a provisional outer
   fit; if a later device frame arrives, that frame takes over without treating
   the earlier canvas as trusted orientation.
6. Rotate the phone in gallery, photo, and video views. If iOS emits a new
   authoritative geometry, the outer renderer must follow it. If only inner
   pixels rotate while geometry is unchanged, record that separately; this
   patch must not infer orientation from private pixels.
7. Measure the outer window and visible inner photo/video separately. A wide
   outer renderer does not pass an inner-content test if the iPhone still
   encodes a small image and black bars.

## Physical test B — settings upgrade and persistence

1. On separate profile copies, begin with the public 0.12.9 schema-12 setting
   absent, `False`, `True`, and malformed. Preserve unrelated receiver, quality,
   renderer, latency, taskbar, topmost, notification, and window-placement
   values.
2. Launch the candidate and confirm Advanced settings has no Photos-specific
   checkbox and identical media behavior is used for every legacy value.
3. Save one unrelated UI setting. Confirm `SettingsVersion=12`, the legacy key
   is absent, and every unrelated value is preserved.
4. Repeat with general automatic fitting disabled. No automatic media-canvas
   movement should occur; the manual proportion action remains available.
5. Begin with valid saved device-frame placement, end a session while only the
   provisional media canvas is current, and reconnect. Confirm the provisional
   landscape did not replace valid saved placement.
6. Repeat after an explicit user move/resize to distinguish user-owned
   persistence from automatic provisional fitting.

## Physical test C — regression matrix

1. Exercise Home, Photos, fullscreen video, Camera, a rotation-capable game,
   rapid portrait/landscape changes, manual resize, manual proportion restore,
   minimized/maximized handling, and mixed-DPI monitor placement.
2. Feed ordinary `1920x1080` content and any captured near-miss signatures.
   They must not be labelled as the exact Photos rule merely because they are
   landscape.
3. Repeat normal disconnect, short Wi-Fi interruption, longer-gap reconnect,
   and manual Screen Mirroring reselection. Record results, but do not attribute
   discovery/reconnect changes to this patch.
4. On clean Windows 10 and Windows 11, run install, launch, restart, update from
   exact public 0.12.9, uninstall, and settings/trust/key/shortcut persistence
   checks. Retain pre-reboot Bonjour evidence for any Windows 10 first-install
   recurrence.

Camera orientation without a new geometry signal, inner encoded-canvas sizing,
short feedback gaps, long-gap frozen video, same-port discovery refresh, BLE,
and borderless viewer UX remain separate pending work rather than acceptance
claims for this patch.

## Failure and acceptance conditions

The scoped candidate fails if any of these occurs:

- the exact signature still requires a Photos-specific setting or that control
  remains visible/persisted;
- legacy `True`, `False`, or malformed values change behavior, survive a
  canonical save, change schema, or damage unrelated settings;
- a generic/near-miss signature enters the exact Photos rule;
- an exact media canvas becomes trusted device orientation, makes automatic
  placement persistable, or overwrites valid saved bounds;
- a later authoritative phone frame fails to take over, or an equivalent
  geometry stream causes repeated resize movement;
- opening Photos, a photo, or a video crashes the shell/native core or ends the
  session because of this change;
- documentation claims crop, zoom, inner-media enlargement, Camera orientation,
  discovery/reconnect repair, package, Setup, tag, public asset, or physical
  acceptance without its independent evidence;
- public 0.12.9 history or local 0.12.10 artifacts are replaced or relabelled.

Local source and pretag packaging acceptance passes: fresh and packaged-shell
resilience, version/settings/native-source/provenance/link/UTF-8/diff/
fingerprint, exact payload, Setup embedded-resource, and all three Setup verify
modes are complete. Publication still requires explicit authorization, an
immutable tag, four expected assets, checksums/API/fresh-download verification,
and only then a `BUILD_REPORT.md`. Full acceptance still requires every
physical Windows/iPhone and installed-update row above to pass.
