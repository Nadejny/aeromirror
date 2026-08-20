# AeroMirror 0.12.18 — automatic Photos layout and safe fullscreen

## Status

0.12.18 is a normal-channel review release for the exact gallery and fullscreen
behavior reported against 0.12.17. It does not move, replace, or mutate any
`v0.12.17` asset, and publication is not evidence that the physical iPhone
matrix has passed.

## Should I update?

- Update if portrait Photos presentation or exiting fullscreen has been a
  problem and you can help test the new behavior.
- Staying on 0.12.17 is reasonable when those paths already work. Physical
  Photos, Camera, and rotation acceptance remains pending.

## What changed

The tray now contains one direct **Полный экран (Esc — выйти)** action. The
incremental **Увеличить фото**, **Уменьшить фото**, and **Сбросить увеличение**
commands are removed.

For the exact observed Photos
`3840x2160 aux=0x0 encoded=3840x2160` transport canvas, the normal framed window
keeps the last trusted portrait phone shape. If a session begins directly in
Photos and no phone-shaped marker exists, it uses a non-authoritative
`900x1950` portrait target. A single centered equal-X/Y scale fills that
portrait target automatically. A trusted landscape target remains unscaled.

Fullscreen is based on the actual native window state, not only on which
command AeroMirror last sent. When the D3D11 renderer is borderless and covers
its monitor, the shell suspends automatic and manual fitting, saved-placement
restore/write, continuity bounds capture, and normal window-policy mutation.
This prevents a Photos geometry change from resizing a fullscreen HWND into an
unmanageable borderless window. Fullscreen uses 100% scale; after exit, normal
window fitting and the current portrait fill resume. Foreground Esc requests
the native fullscreen toggle, while Alt+Enter remains supported.

The existing native scale command is now bounded to 100–500% instead of
100–250%. It still runs on the GLib owner against a retained selected D3D11
sink and resets at renderer start.

## Evidence

- Managed x64 Release build: PASS.
- Complete `ReceiverResilience`: PASS, including direct-in-Photos portrait
  fallback, learned portrait target, 3848/3852-permille fill, landscape/no-class
  reset, removal of manual controls, fullscreen fit/persistence guards, and Esc
  source contract.
- Native worker lifecycle: PASS, eight executable scenarios.
- Native parser, transport, SETUP, renderer, and crypto contracts: PASS.
- Two clean Qt 6.10.1/GStreamer 1.28.5 builds: PASS, both reproduce SHA-256
  `C217386CBC916F8889A9C03774390FE7EC7D8C7EE0B6F64358215CACEEB35118`.
- Runtime staging: PASS, 199 binaries and 148 DLLs; 44 requested GStreamer
  features resolve to 27 plug-ins; loader test exits 0.
- Corresponding source: PASS, 147 entries, 829,835 bytes, SHA-256
  `F4B7F53CABB67E45E6497A8109A87841ED7FE06DBE3409F0E1EC95FF06EFDDFE`;
  the extracted no-Git tree verifies every pinned hash and cleanly rebuilds
  57/57 to the reviewed core hash.
- Wrapper patch SHA-256 remains
  `8F48A4E72D765B0549119BC6366CB970384BAB8116B4430CE60ED67228213F9C`.
- Libuxplay patch SHA-256 is
  `11330A0D905CF4480958DAA59B950F3A2CE2B4AD51A18563EBCC77924DD782C4`.
- Review package: PASS, exact 13 entries, 1,179,937 bytes, SHA-256
  `E9250D3061E01471887E8C061A1E80F45CE203D216B71E6A8E2C6B91D7F1242F`;
  packaged-shell resilience and embedded shell/core/provenance equality pass.
- Setup: PASS, x64 `0.12.18.0`, 1,412,608 bytes, SHA-256
  `93AA1A871A4A3AC0FC22A6960F4B4EC6D577DE5F32B42002656FB14E153E0174`;
  all three non-installing self-checks exit 0.
- Publication: PASS, annotated tag `v0.12.18`, normal latest Release
  `373984443`, exactly four assets, `SHA256SUMS.txt`, API digests,
  canonical/legacy latest routes, and fresh public re-download equality.

Installed update and physical-device gates remain pending. Publication does
not convert those rows into acceptance.

## Limitations

The exact Photos canvas still does not carry a validated content rectangle or
independent orientation event. The centered fill assumes that the trusted
portrait phone region is the intended presentation. A rotation performed
entirely inside Photos may remain ambiguous until another phone-shaped geometry
marker arrives. No pixels are inspected, dark content is not classified, and
AeroMirror does not claim a general Camera/rotation fix.

See [TEST_PLAN.md](TEST_PLAN.md) for the physical acceptance matrix.
