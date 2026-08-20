# Security

## Supported versions

Only the latest published AeroMirror release receives security fixes.

Public `v0.12.9` is currently the latest published release. Internal
0.12.10–0.12.15 candidates are not published supported versions and must not
be presented as security updates. The 0.12.15 source audit hardens bounded
HTTP/RTSP and mirror parsing, SETUP/pairing/FairPlay/RTP/NTP validation,
allocation and buffer rollback, and checked crypto-error propagation in the
supported default native path. Those changes remain pretag and do not expand
the public support statement until a later release completes its required
reproducibility, physical, and publication gates.

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

Do not submit malformed or hostile protocol material to a public receiver or
public issue as a reproduction. Describe the affected boundary privately and
coordinate any executable reproducer with the maintainer and relevant upstream
project before sharing it.

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
