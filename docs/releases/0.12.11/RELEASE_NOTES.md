# AeroMirror 0.12.11 — automatic Photos outer-window fitting candidate

## Summary

AeroMirror 0.12.11 removes the separate experimental Photos window switch.
When the iPhone sends the exact observed `3840x2160` Photos/media canvas,
AeroMirror now fits the outer renderer to that landscape canvas automatically
while keeping the result provisional and safe to discard.

This is a verified local pretag candidate, not a public release. Its local
shell, thin payload, prepared native source, and Setup pass the automated gates
below, but they are not public downloads. Public `v0.12.9` remains the
immutable normal latest review release. There is no 0.12.11 tag, GitHub
Release, public asset, or build report.

## Should I update?

- **Not yet for normal use.** No 0.12.11 installer has been published.
- Use the verified local 0.12.11 candidate only for the focused physical test if
  Photos currently leaves the outer renderer at the wrong proportions or you
  had to enable the former experimental wide-window option manually.
- Stay on public `v0.12.9` until an explicitly verified later release is
  published. Automated geometry tests do not prove behavior on a physical
  iPhone or on Windows 10/11.

## What changed

### Photos behavior is automatic

- Only the complete correlated signature with primary, source, and encoded
  dimensions all `3840x2160` and auxiliary dimensions `0x0` enters the narrow
  Photos/media rule.
- That exact canvas automatically becomes a provisional `MediaCanvas` target
  for the outer renderer. Opening ordinary media no longer requires a separate
  Photos-specific option.
- A later phone-shaped `998x2160` device frame returns the outer renderer to
  portrait. Generic `1920x1080` media and signatures that differ in source,
  encoded, or auxiliary dimensions do not enter this exact rule.
- The general **Automatically fit the stream window** setting remains the
  user-controlled opt-out for automatic window movement.

### Temporary setting retired without a schema change

- The `FollowPhotosMediaCanvas` field and its Advanced checkbox are removed.
- Settings schema remains 12. Existing `FollowPhotosMediaCanvas=True`,
  `False`, or malformed lines are ignored while loading and are omitted on the
  next canonical settings save. Unrelated settings are preserved.
- Removing the temporary switch does not restart the native receiver or change
  receiver arguments.

### Provisional placement remains protected

- The exact media canvas cannot become the trusted device-frame baseline.
- An automatic media-canvas fit cannot make provisional placement persistable
  or replace an already valid saved placement. Explicit user move/resize
  behavior remains separate.
- The monotonic geometry sequence, non-starving 350 ms debounce,
  target-class/exact-aspect fitting, blocked/failed-fit retry, and scaled-
  duplicate suppression from the untagged 0.12.10 candidate are retained.

## Verification status

- A fresh managed x64 build passes. The complete receiver resilience suite
  passes from that build and again against the exact shell placed in the thin
  review payload. Independent source and evidence-document review found no
  P0/P1/P2 issue. The suite covers legacy-key retirement and canonical
  omission, unconditional exact-signature targeting, return to a phone frame,
  near-miss exclusion, retry behavior, and provisional-placement protection.
- The source targets app/Setup version `0.12.11` and Windows PE/file version
  `0.12.11.0`; Setup's comparison version and exactly five release-script
  defaults target 0.12.11.
- Prepared native source retains the reviewed core/provenance and contains
  exactly 143 archive entries/139 files. The thin payload contains exactly 13
  entries. Setup builds with matching embedded payload/provenance;
  `/verify-runtime`, `/verify-shortcut-selection`, and
  `/verify-update-lifecycle` each exit 0. x64 PE, version/default, local-link,
  strict-UTF-8, diff, and release-input fingerprint-stability audits pass.
- Exact local container identities are retained in the final gate handoff and
  are not embedded here because release documents are packaging inputs.
  Installed update, Windows 10/11 and iPhone, exact-tag, GitHub Release, and
  public-download checks remain pending. A `BUILD_REPORT.md` is intentionally
  absent before publication.
- No native source, patch, capability, runtime, dependency, discovery,
  reconnect, BLE, or media-pipeline input changes in this patch.

The candidate acceptance matrix is in [`TEST_PLAN.md`](TEST_PLAN.md).

## Known limitations

- Fitting the outer renderer to a landscape canvas does not crop, zoom, or
  enlarge a smaller photo/video already encoded with black bars by the iPhone.
- Camera can rotate its controls without emitting a different stream geometry.
  AeroMirror still has no independent native orientation event for that case
  and does not guess orientation from private pixels.
- A session that exposes a generic media canvas but not the exact correlated
  signature or a phone-shaped frame remains ambiguous.
- Short feedback gaps, longer-gap frozen video, delayed/stale discovery,
  Windows 10 first-install/reboot evidence, Bluetooth research, and
  borderless/rounded viewer UX remain separate pending work.

Published `v0.12.9` and its four assets remain immutable under AeroMirror
project policy. The untagged 0.12.10 candidate remains local history and is
superseded by 0.12.11; its artifacts must not be relabelled.
