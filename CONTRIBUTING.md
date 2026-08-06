# Contributing to AeroMirror

Thanks for testing AeroMirror. Review builds are expected to have rough edges;
a precise report is more useful than a long description without reproduction
details.

## Before reporting a problem

1. Confirm the AeroMirror version in **Updates**.
2. Confirm the iPhone and PC are on the same local network.
3. Search existing GitHub issues for the same symptom.
4. Reproduce the problem once more and note the exact local time.

Do not repeatedly restart or reinstall before collecting the first failure:
the first-run state is often important.

## A useful bug report

Open one GitHub issue per problem and include:

- AeroMirror version and whether it was a fresh install or an update;
- Windows edition/build and Windows display scaling;
- iPhone model and iOS version;
- connection type (Wi-Fi or Ethernet), Windows network profile
  (Private/Public), and whether a VPN, hotspot, or virtual adapter was active;
- GPU and selected renderer, quality, latency, and audio settings;
- exact steps, expected result, actual result, and failure time;
- whether stopping the receiver, starting it again, or restarting the whole
  app changed the result;
- whether an AirPlay session was connecting, active, or disconnecting;
- for layout issues, the phone orientation and the app/media being displayed.

Screenshots or a short screen recording are welcome when they do not expose
private messages, photos, account names, or other personal information.

## Logs and privacy

The current local log is:

```text
%LOCALAPPDATA%\AirPlayReceiverMvp\receiver.log
```

Open it in a text editor and share only the short section around the failure
time. Before attaching it publicly, remove:

- PIN values and command-line fragments containing `-pin`;
- Windows user names and personal folder paths;
- computer, receiver, Wi-Fi, and network-adapter names;
- IP addresses or other identifiers you do not want to publish.

Never upload `receiver-key.pem`, `trusted-clients.txt`, settings containing a
PIN, memory dumps you have not reviewed, or mirrored photo/video content.

## Crash reports

For a crash, report separately whether:

- the AeroMirror settings/tray application disappeared;
- only the mirrored-video window disappeared;
- the receiver returned automatically;
- Windows displayed an error dialog.

Include the exact crash time and the last 50–100 relevant redacted log lines.
If a future build creates a diagnostic package or dump, review its contents
before opting to attach it.

## Pull requests

- Discuss substantial protocol, security, installer, or UI changes in an
  issue first.
- Keep each pull request focused on one problem.
- Preserve Windows 10 1809 x64 compatibility unless the change is explicitly
  approved otherwise.
- Add or update tests and documentation for changed behavior.
- Do not add proprietary Apple/vendor code, keys, certificates, or material
  with an incompatible license.
- By contributing, you agree that your contribution is provided under the
  repository's GPL-3.0-or-later license.

For future ideas and known protocol constraints, see
[`docs/TODO.md`](docs/TODO.md).
