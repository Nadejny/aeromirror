# AeroMirror 0.12.0 — safer settings and cleaner managed source

## Summary

This review candidate makes persisted settings safer, protects immediate
reconnects from stale session cleanup, tightens update-version handling, and
reorganizes the Windows shell without changing its native AirPlay core.

## Should I update?

- Update when 0.12.0 is published if AeroMirror has ever failed to reconnect
  immediately, if a settings file may have been left by an older or interrupted
  build, or if you are helping test Windows 10/11 compatibility.
- The update is optional until physical-device acceptance is complete if
  0.11.3 works reliably for you and none of those cases applies.
- The in-app updater offers 0.12.0 only after it is published as the normal
  latest GitHub Release with the exact versioned Setup asset.

## What changed

### Safer persisted settings

- Pairing state is canonicalized before it is used or saved. Only no-PIN mode
  or PIN mode with exactly four ASCII digits remains valid.
- Obsolete, unknown, and malformed pairing values become unprotected. The
  existing Windows Public/Unknown physical-network rule can then pause the
  receiver instead of accidentally treating an invalid label as protection.
- Unknown quality, renderer, latency, audio, and theme values return to stable
  documented defaults.
- Settings are written to a same-directory temporary file and atomically
  replace the previous file, reducing the risk of a partial `settings.ini`.

### More reliable immediate reconnects

- A late end marker from the old AirPlay session no longer erases the grace
  period established by a newer connection request or PIN prompt.
- Deferred settings and physical-network maintenance remain queued while that
  newer handshake is in progress, then follow the existing safe lifecycle.

### Strict update versions

- The updater accepts only an exact `MAJOR.MINOR.PATCH` release tag, with an
  optional leading `v`.
- Two-part, four-part, suffixed, and malformed tags are rejected rather than
  normalized into an AeroMirror version.

### Maintainable managed source

- The C# shell is separated by responsibility into startup, configuration,
  receiver, rendering, diagnostics, UI, update, network, and interop files.
- It remains one .NET Framework `AeroMirror.exe` assembly with the same
  namespace, settings location, receiver identity, autostart behavior, update
  identity, native process boundary, and installed core path.
- Three unreachable legacy settings forms were removed. The active settings
  experience is unchanged by that removal.

## What remains unchanged

- The pinned UxPlay/uxplay-windows core and third-party runtime.
- AirPlay negotiation, decode, audio, and the separate GStreamer renderer
  window.
- The one-time PIN trust model and physical Windows network safety policy.
- The unsigned network-installer distribution model.

## Verification status

The integrated shell build, resilience checks, review package, Setup build and
lifecycle verifiers, native corresponding-source validation, and whitespace
checks pass locally. Exact-tag packaging and public-download verification run
during publication. All physical Windows/iPhone scenarios remain pending; see
`TEST_PLAN.md`. This candidate must not be described as physically accepted or
production-ready until those results are recorded.

## Known limitations

- Live quality switching still requires an iPhone reconnect because the
  current native core has no session renegotiation command.
- The renderer remains a separate native window and may still expose
  application-specific letterboxing inside the incoming video frame.
- The installer is unsigned and Windows SmartScreen may warn.
- Windows 10 and Windows 11 interoperability require physical testing; source
  organization and automated checks cannot prove it.

## Reporting a problem

Use **Report a problem** in AeroMirror or follow
[`docs/TROUBLESHOOTING.md`](../../TROUBLESHOOTING.md). Include the exact local
failure time and a short redacted log excerpt. Never publish `settings.ini`,
receiver keys, trusted-client data, PINs, personal paths, network names, or IP
addresses.
