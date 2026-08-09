# Build report — AeroMirror 0.11.3

Release `v0.11.3` was built from commit
`aba4c98277f965ce8cf52cea46ff08c26605a03f` and published as a normal GitHub
review release on 2026-08-09. It is not a draft or GitHub Pre-release.

Release URL:
https://github.com/Nadejny/aeromirror/releases/tag/v0.11.3

## Verified build and regression checks

- managed x64 shell build;
- receiver resilience suite, including normal disconnect without a restart,
  incoming request and PIN-entry maintenance guards, bounded lost-client
  recovery, benign feedback warnings, a shared readiness/discovery recovery
  budget, physical-network deferral, and bounded idle discovery renewal;
- installer x64 compilation and version verification;
- review-package validation and exact four-file public release inventory;
- prepared corresponding-source validation against the pinned provenance,
  including the staged `libuxplay/uxplay.cpp` and
  `libuxplay/renderers/video_renderer.c` hashes before archive creation;
- unchanged reviewed native receiver executable and pinned runtime from
  0.11.2;
- PowerShell syntax, release-version consistency, and `git diff --check`;
- `SHA256SUMS.txt` verification;
- post-publication download of all four GitHub assets and byte-for-byte
  SHA-256 comparison with the published release files;
- GitHub `releases/latest` returned `v0.11.3` with `draft=false` and
  `prerelease=false`.

## Published artifacts

| File | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.11.3.exe` | 1,250,816 | `b52cdd52e85c0317a72ed67ce321e6682af697568900c0f9b43d3b0dc220aadd` |
| `AeroMirror-source-0.11.3.zip` | 1,721,259 | `f855df6f7594ada9667b3b814dbc904bf387db61eb6057d75344fc097d660569` |
| `AeroMirror-native-source-0.11.3.zip` | 687,941 | `6bcafab574a7145b67b4448a5654426d5bd3bb8f7c87bcf07d2a911980a630dd` |
| `SHA256SUMS.txt` | 294 | `ef58c14a96ff3a5a58d257fd4cdcc9c2a3974af3953c60d5eef0199469fd5ffd` |

## Remaining manual acceptance

The automated and public-asset verification above accepts 0.11.3 for review
distribution only. The physical Windows 11 + iPhone reconnect and discovery
scenarios in `TEST_PLAN_0.11.3.md` remain pending and must pass before the
patch is described as accepted. The same plan on physical Windows 10 1809+
x64, the remaining 0.11.2 update cases, and the broader receiver acceptance
remain mandatory before the project can be labelled 1.0.

The `v0.11.3` tag and its four assets are immutable. Any correction must use a
new patch version rather than moving the tag or replacing a published asset.
