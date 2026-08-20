# AeroMirror 0.12.17 — Photos presentation controls

## Status

0.12.17 is a normal-channel review release for physical Photos presentation
testing. It does not replace or mutate any `v0.12.16` asset, and its automated
results are not a claim that the physical Photos/Camera matrix has passed.

## Should I update?

- Update if you want to test native fullscreen and explicit Photos zoom.
- Staying on 0.12.16 is reasonable when those controls are not needed. Physical
  iPhone Photos, Camera, and rotation acceptance remains pending.

## What changed

The tray now has an **Отображение трансляции** submenu for the live renderer:

- **Полный экран** toggles the selected Direct3D 11 sink through its native
  fullscreen property. It does not depend on keyboard focus or simulated
  Alt+Enter input.
- **Увеличить фото**, **Уменьшить фото**, and **Сбросить увеличение** apply a
  uniform 100–250% native scale only while the exact observed Photos
  `3840x2160 aux=0x0 encoded=3840x2160` media canvas is active.
- Manual zoom is session-scoped and returns to 100% when that media-canvas
  class ends or a new renderer session starts.

The commands use the existing redirected standard-input control channel, are
serialized with discovery commands in the managed shell, and are marshalled
to the native GLib/render owner before touching the selected sink. Applied or
unavailable results are logged without media content.

## Evidence

- Managed x64 Release build: PASS.
- Complete `ReceiverResilience` suite: PASS.
- Production worker-lifecycle executable checks: PASS, eight scenarios.
- Native parser, transport, SETUP, renderer, and crypto contracts: PASS.
- Two clean Qt 6.10.1/GStreamer 1.28.5 native builds: PASS, both reproduce
  SHA-256
  `53B13433B9308547D491417F11692361DFC5B6EBFBDA018B8D3EEE7B4436436F`.
- Staged runtime dependency inspection: PASS, 199 binaries and 148 DLLs;
  44 requested GStreamer features resolve to 27 plug-ins; loader test exits 0.
- Wrapper patch SHA-256:
  `8F48A4E72D765B0549119BC6366CB970384BAB8116B4430CE60ED67228213F9C`.
- Libuxplay patch SHA-256:
  `91AF80A36C7D4ECEB6470A1394722F2EC98312407DFA51A9929FC40E4B220CF5`.
- The exact-tag 147-entry corresponding-source ZIP is 828,175 bytes with
  SHA-256
  `369497BB96F94EB2104A9741EDF36638D3EC29AAE17C3B433A95EC7F865AC86C`.
  Its no-Git tree validates every pinned hash and cleanly rebuilds 57/57 to the
  same reviewed core SHA-256.
- The exact 13-entry review payload, packaged-shell resilience, x64
  `0.12.17.0` Setup, byte-exact embedded inputs, and `/verify-runtime`,
  `/verify-shortcut-selection`, and `/verify-update-lifecycle` pass.

Annotated `v0.12.17`, normal latest Release `373934492`, the exact four
public assets, GitHub API digests, canonical/legacy latest routes, and fresh
public re-download equality pass. Installed update and physical-device gates
remain pending. See [BUILD_REPORT.md](BUILD_REPORT.md) for exact evidence.

## Known limitations

Fullscreen enlarges the outer renderer window but cannot remove black bars
already encoded by the iPhone inside its 3840x2160 presentation canvas. Manual
zoom can crop those edges, so it is opt-in and is not saved. AeroMirror still
has no trustworthy inner content rectangle, does not inspect pixels, and does
not enable automatic crop or `rotate-method=auto`.

Camera orientation and sessions that lack an authoritative phone-shaped
geometry marker remain unresolved. The discovery policy is unchanged from
0.12.16: the listener remains alive while low-frequency same-process DNS-SD
re-registration continues as defensive maintenance. Physical two-hour iPhone
visibility evidence is still pending.

See [TEST_PLAN.md](TEST_PLAN.md) for the acceptance matrix.
