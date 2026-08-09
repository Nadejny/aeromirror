# AeroMirror 0.12.1 — network-card and tooltip visual acceptance

Status: published cosmetic review release. Implementation, automation, focused
synthetic rendering, exact-tag packaging, and public asset verification pass.
Physical full-window Windows 11/DPI inspection and the Windows 10 visual smoke
remain pending.

`v0.12.1` was published from commit
`2f457449653b11bc411982d200241cb82ea90587` as the normal, non-draft,
non-prerelease latest Release. Publication does not complete the visual rows
below and makes no physical AirPlay claim.

This plan covers a cosmetic managed-shell patch. It does not accept native
AirPlay, discovery, reconnect, streaming, installer, or physical-network
policy behavior. Record the exact candidate commit, Windows version, theme,
display scale, monitor, and screenshot filename for each visual result.

## Scope and invariants

The candidate may change only:

- vertical layout of the network-card title, detail text, and help control;
- drawing and DPI sizing of the centered question-mark glyph;
- line placement of Private-network PIN guidance inside the network tooltip;
- receiver-state tooltip targets for the status dot and status text.

The native core, receiver lifecycle, discovery/reconnect supervision, network
classification, pairing decisions, settings format, persisted identity,
installer, and update protocol must remain unchanged.

## Test matrix

| Environment | Theme/scale | Required scope | Status |
|---|---|---|---|
| Final 0.12.1 source | N/A | Automated gates | Passed |
| Synthetic custom-glyph render | Light and dark, 100%, 150%, 200% | Centering, clipping, and sharpness | Passed |
| Exact `v0.12.1` packaging | N/A | Clean tag and four expected assets | Passed |
| Public GitHub Release | N/A | Latest state, re-download, sizes, SHA-256, API digests | Passed |
| Windows 11 x64 | Light, 100% | Full visual plan | Pending |
| Windows 11 x64 | Dark, 100% | Full visual plan | Pending |
| Windows 11 x64 | Light and dark, 125% or 150% | Full visual plan | Pending |
| Windows 11 x64 | Light and dark, 200% | Glyph clipping and alignment | Pending |
| Windows 10 1809+ x64 | Available theme and non-100% scale | Compatibility visual smoke | Pending |

If the tester has multiple monitors with different scaling, move AeroMirror
between them and repeat the glyph and tooltip checks after Windows applies the
new DPI. Do not mark Windows 10 or per-monitor behavior passed from source
inspection alone.

## Automated gates

The following gates ran against the final source that became the `v0.12.1`
tag:

1. Build the managed shell:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
   ```

2. Run the receiver regression suite to prove the cosmetic change did not
   alter existing supervised behavior:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ReceiverResilience.Tests.ps1
   ```

3. Confirm the native-core inputs and hashes did not change.
4. Confirm only exact 0.12.1 documentation and intended managed UI/version
   files enter the candidate diff.
5. Run:

   ```powershell
   git diff --check
   ```

The integrated candidate passes the managed build, receiver regression suite,
focused UI/source assertions, unchanged-native-input check, PE version check,
review payload, Setup lifecycle, native-source, exact-tag packaging, and
`git diff --check` gates. Exactly four public assets were then re-downloaded;
their sizes and SHA-256 values matched the local files, and all four GitHub API
digests matched those hashes. See `BUILD_REPORT.md` for exact evidence. A
successful build or synthetic render does not substitute for the remaining
physical full-window matrix.

## Network-card alignment

For every required theme and scale:

1. Open AeroMirror's home page with a Private physical network detected.
2. Capture the entire network card at native screenshot resolution.
3. Compare the title, detail line, and help control against the card's vertical
   center and against one another.
4. Repeat with any available Public or Unknown physical-profile presentation
   so longer status text is exercised.
5. Resize or reopen the window and repeat once to detect stale layout values.

Expected:

- title and detail text form one balanced block centered relative to the help
  control;
- neither line touches a card edge, clips, overlaps, or jumps between themes;
- the help control remains inside the intended card padding;
- longer network text does not move the glyph off center or change its hit
  target unexpectedly.

## DPI-aware question-mark glyph

At 100%, 125/150%, and 200% scaling:

1. Inspect the help control without browser or image-viewer resampling.
2. Capture a native-resolution screenshot.
3. Confirm the question mark is centered horizontally and vertically inside
   its visual control.
4. Move the window between different-DPI monitors when available and inspect
   again after the DPI transition.

Expected:

- the glyph is crisp and legible, with no obvious bitmap stretch;
- it is not clipped at the top, bottom, or sides;
- its center and surrounding padding remain visually stable across scales;
- hover/normal rendering does not leave a duplicate or stale glyph.

## Network tooltip text

1. On a Private physical network, hover the network help control.
2. Capture or transcribe the tooltip with sensitive network names masked.
3. Move the pointer off the help control and confirm the tooltip closes through
   normal Windows behavior.
4. Hover nearby blank card space and ordinary network text to ensure an
   unintended card-wide tooltip target was not introduced.

Expected:

- the first tooltip line contains the network/profile context;
- the sentence explaining optional PIN protection begins at the start of the
  second line;
- there is one deliberate line break rather than accidental wrapping between
  the network summary and PIN sentence;
- tooltip content remains readable and unclipped in both themes and at all
  tested DPI scales.

## Receiver-state tooltip targets

For both receiver-on and receiver-off states when safely available:

1. Hover directly over the colored status dot.
2. Move away, then hover directly over the adjacent receiver-state text.
3. Compare the tooltip text and placement from both targets.
4. Hover blank horizontal space beyond the status text.

Expected:

- the same receiver-state explanation appears over both the dot and the text;
- neither target requires a click and neither hover changes receiver state;
- the tooltip does not flicker continuously when moving between the two
  intended targets;
- blank space outside the status content does not become an unexplained
  full-width tooltip target.

## Regression and non-claims

1. Switch between System, Light, and Dark theme choices as supported and
   repeat the relevant visual checks.
2. Close to tray and reopen the window; verify the card and tooltip targets are
   still laid out correctly.
3. Confirm hover and tooltip activity does not start, stop, or restart the
   receiver and does not save settings.

This plan makes no physical AirPlay acceptance claim. Existing iPhone,
Windows-network, reconnect, and in-place-update scenarios remain pending under
the current public release plans and must be recorded separately.

## Acceptance gate

The 0.12.1 review-publication gate is **passed**:

- all automated gates passed on the exact tagged commit;
- the focused synthetic render passed in light and dark at representative DPI;
- pending physical Windows 11 and Windows 10 visual rows are stated explicitly
  in the release notes;
- source and focused checks confirm the Private-network PIN sentence begins on
  tooltip line two and the receiver-state tooltip targets both dot and text;
- no unintended receiver, native-core, network-policy, persistence, installer,
  or updater change is present;
- exactly four public assets and all updater-facing API digests match;
- publication had explicit authorization.

The release is visually accepted only after every required physical
Windows 11 theme/DPI row passes with retained screenshots and the Windows 10
smoke result is recorded. A failure after review publication must be fixed in
0.12.2 or later; the 0.12.1 tag and assets remain immutable.

Public evidence is recorded in `BUILD_REPORT.md`. Continue updating this test
matrix and `docs/PROJECT_STATE.md` as physical visual results arrive; never
replace the published tag or assets.
