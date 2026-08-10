# Security

## Supported versions

Only the latest published AeroMirror release receives security fixes.

## Reporting a vulnerability

Do not publish receiver keys, trusted-client records, settings files, or a log
that has not been reviewed for personal data.

For an ordinary crash or discovery failure, use the GitHub bug-report template
and follow `docs/TROUBLESHOOTING.md`.

For a vulnerability that could expose another user's device, pairing material,
or local files, first try GitHub's private
[Report a vulnerability](https://github.com/Nadejny/aeromirror/security/advisories/new)
route. Availability of that form depends on the repository's GitHub security
settings. If GitHub reports that private vulnerability reporting is
unavailable, do not put sensitive details in a public issue; contact the
repository owner through a private contact method listed on the owner's GitHub
profile.

Include the AeroMirror version, Windows version, affected network profile, and
the smallest reproducible description. Do not attach an active receiver key or
a real PIN.

## Scope

AeroMirror is a local-network receiver built on UxPlay. Reports about UxPlay,
GStreamer, Qt, Bonjour/mDNS, or bundled codec libraries may need coordinated
disclosure to their upstream maintainers as well.

The connection-loss continuity view may copy unobscured renderer client pixels
from the Windows desktop into process memory. It rejects capture when another
visible higher window overlaps the renderer and never intentionally writes the
bitmap to settings, logs, diagnostics, or temporary files. Treat capture of an
unrelated window, persistence of a mirrored frame, or inclusion of frame pixels
in a diagnostic package as a privacy vulnerability and use the private report
path above.
