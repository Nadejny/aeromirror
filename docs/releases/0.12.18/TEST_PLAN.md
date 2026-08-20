# AeroMirror 0.12.18 — gallery and fullscreen acceptance

## Purpose

This plan verifies the reported Photos layout and fullscreen-state failures.
Automated geometry/state checks do not prove that a real iPhone photo is framed
correctly; physical acceptance remains mandatory.

0.12.18 is approved for a normal-channel review publication before physical
acceptance. Public `v0.12.17` assets remain immutable, and no physical result is
inferred from publication.

## Current evidence status

| Gate | Status | Evidence |
|---|---|---|
| Version/default surfaces | PASS | Shell/Setup `0.12.18.0`, Setup comparison and exactly five defaults `0.12.18` |
| Managed Release | PASS | Current x64 source compiles |
| Complete receiver resilience | PASS | Existing regressions plus automatic Photos/fullscreen contracts |
| Native worker/core contracts | PASS | Eight worker scenarios plus parser, transport, SETUP, renderer, and crypto checks |
| Reproducible native build | PASS | Two clean 57/57 builds reproduce `C217386CBC916F8889A9C03774390FE7EC7D8C7EE0B6F64358215CACEEB35118` |
| Staged runtime and loader | PASS | 199 binaries, 148 DLLs, 44 features to 27 plug-ins, loader exit 0 |
| Corresponding source | PASS | Final 147-entry public asset, 829,835 bytes, SHA-256 `F4B7F53CABB67E45E6497A8109A87841ED7FE06DBE3409F0E1EC95FF06EFDDFE`; all pinned hashes and extracted 57/57 no-Git rebuild pass |
| Review payload and Setup | PASS | Exact 13 entries, packaged-shell resilience, embedded shell/core/provenance equality, x64 `0.12.18.0`, and all three self-checks |
| Physical portrait Photos | PENDING | Vertical phone plus vertical photo produces a portrait normal window and usable fill |
| Physical fullscreen lifecycle | PENDING | Tray/Alt+Enter/Esc and Photos entry/exit never leave a stuck borderless window |
| Landscape and rotation | PENDING | Trusted landscape stays unscaled; rotation inside/outside Photos is documented accurately |
| Installed update | PENDING | Settings, identity, shortcuts, autostart, runtime, launch, rollback |
| Tag and publication | PASS | Annotated `v0.12.18`, normal latest Release `373984443`, exact four assets, checksums, API digests, canonical/legacy latest routes, and fresh public re-download equality |

## Automated contract

- The exact Photos canvas cannot become a trusted device baseline. It resolves
  to the learned device shape or the non-authoritative `900x1950` fallback.
- Automatic scale is 3848 permille for the observed `998x2160` target, 3852 for
  the fallback, and 1000 for trusted landscape or non-Photos input.
- The tray has no incremental zoom controls. Scale remains equal on both axes,
  is bounded to 1000–5000, and resets on renderer lifecycle boundaries.
- Actual fullscreen recognition requires monitor-sized outer bounds and a
  matching borderless client area. Fit, restore, persistence, continuity
  capture, and policy paths are guarded from that state.
- Esc is accepted only while the renderer is foreground and actually
  fullscreen. The command is marshalled through the same bounded native path;
  Windows keyboard-message injection is absent.

## Physical test A — normal portrait gallery

1. Start mirroring with the phone vertical on the home screen and record the
   renderer client bounds.
2. Open Photos and a vertical photo. Require one automatic transition to a
   portrait normal window; no repeated resize loop and no manual zoom clicks.
3. Confirm the useful photo region is materially larger than in 0.12.17 and
   note which Photos chrome or canvas edges are cropped.
4. Return to the home screen. Require 100% scale, a movable/resizable framed
   window, and the original device aspect.
5. Repeat from a session that begins directly inside Photos. Record whether the
   fallback is appropriate until a phone-shaped marker appears.

## Physical test B — fullscreen state

1. Enter fullscreen from the tray, then exit with Esc. Repeat five times.
2. Repeat with native Alt+Enter in both directions.
3. While fullscreen, enter Photos, change photos, leave Photos, and rotate the
   phone. Require the renderer to remain truly fullscreen and borderless.
4. Exit fullscreen. Require the title bar/buttons to return immediately; move
   and resize the normal window, then use **Восстановить пропорции окна**.
5. Repeat by entering fullscreen while already in Photos. No transition may
   require a first toggle merely to restore the normal frame and a second
   toggle to enter fullscreen.

## Physical test C — landscape and ambiguity

1. Establish a trusted landscape phone frame before opening Photos. Require no
   automatic portrait fill.
2. Rotate portrait to landscape and back outside Photos, then repeat entirely
   inside Photos. Record every raw/encoded geometry and scale result.
3. If an inside-Photos rotation has no phone-shaped marker, report it as an
   unresolved protocol ambiguity rather than guessing from pixels.

## Acceptance boundary

Package, installed update, physical behavior, and publication are independent
gates. Publication is now recorded in `BUILD_REPORT.md`; installed and physical
rows remain pending.
