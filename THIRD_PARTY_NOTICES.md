# Third-party notices

This MVP combines a Windows launcher/settings shell with a minimally patched
build of `leapbtw/uxplay-windows`. The patch adds a headless mode, direct
argument passing, stable native `argv` storage, and a non-streaming loader
compatibility check.

The AeroMirror 0.10 network review installer does **not** mirror the full
third-party runtime. During installation it downloads this unchanged upstream
asset directly from GitHub and verifies it before extraction:

- Asset:
  `https://github.com/leapbtw/uxplay-windows/releases/download/2.0.0.1736/uxplay-windows.zip`
- SHA-256:
  `9D3A51C15FC9DB857351195E7EB7BBB21700D9AE25D936A54BCF8536B62CCA18`
- Exact upstream source:
  `https://github.com/leapbtw/uxplay-windows/tree/8cf3424b438424bc99a89155bd29a789f48a43c0`

The exact AeroMirror and patched native corresponding source are attached
beside Setup as `AeroMirror-source-0.10.0.zip` and
`AeroMirror-native-source-0.10.0.zip`.

## UxPlay

- Project: https://github.com/FDH2/UxPlay
- Integrated release: UxPlay 1.73.6, commit
  `21eef8df25d91e12635c36d8176ad192725baca2`
- License: GNU GPL v3; parts under LGPL 2.1+, MIT, and other compatible
  licenses as documented by the project.
- Copyright: FDH2/UxPlay contributors and the original RPiPlay authors.

## uxplay-windows

- Project: https://github.com/leapbtw/uxplay-windows
- Source baseline: commit
  `8cf3424b438424bc99a89155bd29a789f48a43c0`
- Linked libuxplay commit:
  `437f37514257d9cb513ac7fbdee743b4da85852e`
- Runtime seed: release `2.0.0.1736`, x64 portable ZIP; the Bluetooth beacon
  and mDNS binaries are downloaded unchanged from this release.
- License: GNU GPL v3.
- The project combines UxPlay, Qt, GStreamer, mDNSResponder, and a Bluetooth
  beacon. Its own `LICENSE.rtf` is preserved in `core/`.

## GStreamer and plug-ins

- Project: https://gstreamer.freedesktop.org/
- Runtime version: 1.28.5.
- Predominant license: GNU LGPL 2.1+.
- Individual plug-ins and codec libraries have their own licenses. Anyone
  redistributing the binary bundle must audit the exact staged DLL set and
  provide the corresponding notices and source-code offers where required.

## Qt

- Project: https://www.qt.io/
- Runtime version: Qt 6.10.1, dynamically linked.
- Open-source Qt modules are generally offered under LGPL/GPL terms; exact
  obligations depend on the modules and distribution model.

## Apple mDNSResponder

- Project: https://github.com/apple-oss-distributions/mDNSResponder
- Licenses: Apache License 2.0 and/or BSD-style terms, depending on file.

## Important licensing consequence

The AeroMirror-authored shell and installer are GPL-3.0-or-later. The receiver
core and third-party runtime retain their own upstream license grants; this
notice does not attempt to relicense them. A proprietary closed-source product
cannot simply ship this core as an internal component without satisfying its
GPL source and redistribution requirements. Obtain legal advice before
commercial release.

This notice is an engineering summary, not legal advice.
