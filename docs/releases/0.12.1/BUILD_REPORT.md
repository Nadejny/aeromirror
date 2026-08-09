# Build report — AeroMirror 0.12.1

Release `v0.12.1` was built from commit
`2f457449653b11bc411982d200241cb82ea90587` and published at
`2026-08-09T21:19:15Z`:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.1

The tag and all four assets are immutable release history. Any correction must
use `0.12.2` or a later version; do not move the tag or replace an asset under
0.12.1.

## Release channel

- GitHub state: normal Release
- Draft: `false`
- Pre-release: `false`
- Latest updater-visible Release: `v0.12.1`
- Distribution label: cosmetic review release
- Public asset count: exactly four
- Offline portable package: not published

Publication makes the patch available to the normal in-app update channel. It
does not complete the pending physical full-window visual matrix or establish
physical AirPlay behavior.

## Pre-tag verification

The exact source that became the release tag passed:

- managed x64 shell build;
- receiver regression suite;
- focused UI/source assertions for shared network-card geometry, the deliberate
  Private-network tooltip line break, the narrow network-help hit target, and
  both receiver-status tooltip targets;
- synthetic rendering of the actual custom question-mark glyph in light and
  dark palettes at 100%, 150%, and 200% DPI, centered and unclipped;
- unchanged native-core input and provenance checks;
- shell and Setup PE version checks for 0.12.1;
- review-payload packaging and Setup build, including shortcut-selection and
  update-lifecycle verification;
- native corresponding-source packaging and provenance validation;
- clean exact-tag release packaging;
- `git diff --check`.

These checks accept build, packaging, and focused rendering integrity. A
synthetic glyph surface is not a substitute for inspecting the complete
installed window under real Windows DPI/theme behavior.

## Published assets

Every public asset was downloaded again after publication. Its byte size and
SHA-256 matched the corresponding local release file. GitHub's API provided a
digest for all four assets, and each API digest exactly matched the same local
and re-downloaded SHA-256 value.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.12.1.exe` | 1,248,768 | `98623c5fdbf36509b360614fce9dd83fb91d0a8341bc5b37d0c1edd09a63195e` |
| `AeroMirror-source-0.12.1.zip` | 1,757,546 | `40e953346df5365fcb29b39f028b7d4cd67e024e0f41d48e855c3200eac90105` |
| `AeroMirror-native-source-0.12.1.zip` | 687,950 | `affddbf98a59fe27f0800442cf6a9601a92c85f754bd8f3520f72f9f97a59044` |
| `SHA256SUMS.txt` | 294 | `1775b016df5525323636842dc0b7866e53ab001f54f708c41798bf246bfd82f9` |

The release contains no unexpected fifth asset. The native-source archive
continues to describe the unchanged reviewed core rather than introducing a
native change for this managed cosmetic patch.

## Acceptance status

Accepted:

- exact-tag build and release packaging;
- normal latest-channel visibility;
- exact public asset set, sizes, hashes, and updater-facing API digests;
- focused managed regression, UI-structure, and synthetic glyph checks;
- unchanged native inputs and provenance.

Pending:

- physical inspection of the complete installed AeroMirror window on Windows
  11 in light and dark themes at representative DPI scales;
- the Windows 10 1809+ compatibility visual smoke;
- optional mixed-DPI, multi-monitor movement when suitable hardware is
  available;
- all separately tracked physical Windows/iPhone AirPlay and installed-update
  acceptance inherited from the current public plans.

Use `TEST_PLAN.md` for the visual scenarios. No physical AirPlay claim is made
by this cosmetic release or this build report. A failed pending scenario must
be corrected in a later patch without modifying the 0.12.1 tag or assets.
