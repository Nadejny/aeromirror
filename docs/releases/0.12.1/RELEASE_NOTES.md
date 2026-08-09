# AeroMirror 0.12.1 — network-card alignment and tooltip polish

## Summary

This cosmetic review patch aligns the network card more cleanly, improves
the help glyph at Windows DPI scales, and makes the two status explanations
easier to discover without changing AirPlay behavior.

## Should I update?

- Update if the network-card text or question-mark icon
  looks uneven or blurred at your Windows display scale, or if you expect the
  receiver explanation to appear over both parts of its status line.
- The patch is optional if the current interface looks correct to you. It does
  not contain a native receiver, discovery, reconnect, security-policy, or
  streaming change.

## What changed

- The network-card text and help control share the same vertical center.
- The question-mark glyph is drawn crisply and centered using DPI-aware
  measurements rather than relying on a poorly scaled text symbol.
- On a Private physical network, the optional-PIN guidance begins on the
  tooltip's second line, below the network summary.
- The receiver-state tooltip can be opened by hovering over either the colored
  status dot or the adjacent status text.

## What remains unchanged

- The pinned UxPlay/uxplay-windows core and third-party runtime.
- Receiver startup, shutdown, discovery, reconnect, recovery, and stream
  supervision.
- Physical-network classification, no-PIN/PIN decisions, settings storage,
  trusted-client state, and receiver identity.
- Installer, updater, packaging, and public release contracts.

## Verification status

The final managed build and receiver regression suite pass. Focused structural
checks cover the common network-card geometry, deliberate tooltip line break,
narrow network-help hit target, and both receiver-status tooltip targets. A
synthetic render of the actual custom glyph is centered, crisp, and unclipped
in light and dark palettes at 100%, 150%, and 200% DPI.

Physical inspection of the complete installed settings window on Windows 11
at representative DPI scales and the Windows 10 compatibility smoke remain
pending review checks. See `TEST_PLAN.md` and report any mismatch with an
uncropped screenshot.

These interface checks do not prove or claim physical AirPlay behavior. The
existing Windows/iPhone acceptance work remains separate.

## Known limitations

- This patch does not redesign the rest of the settings window.
- The network help control exposes accessible name, description, and role,
  but its hover tooltip is not yet keyboard-focusable.
- Font rendering can vary slightly with Windows version, display scaling, and
  ClearType configuration; acceptance is based on correct centering,
  clipping, and legibility rather than pixel-identical screenshots.
- The installer remains unsigned and Windows SmartScreen may warn.

## Reporting a problem

Include the Windows version, theme, display scale, and an uncropped screenshot
of the affected card. Mask network and computer names before sharing it. For
general diagnostics, follow
[`docs/TROUBLESHOOTING.md`](../../TROUBLESHOOTING.md).
