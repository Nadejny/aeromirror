# Build report — AeroMirror 0.11.2

Release `v0.11.2` was built from commit
`f9fd5c48ef24435a08da5c6ee438410fd6e19aed` and published as a normal GitHub
review release on 2026-08-09.

Release URL:
https://github.com/Nadejny/aeromirror/releases/tag/v0.11.2

## Verified build and regression checks

- managed x64 shell build;
- receiver resilience test suite;
- installer x64 compilation and version verification;
- shortcut-selection verifier;
- update-lifecycle verifier, including a real directory move after leaving a
  nested working directory inside a temporary installation tree;
- final Setup launched with its inherited working directory set to the real
  installed AeroMirror directory; Setup changed to the parent directory before
  the verifier ran (`DetachedFromInstallTree=True`);
- no unbounded installer or receiver `WaitForExit()` calls;
- PowerShell syntax and release-version consistency checks;
- exact four-file release inventory and `SHA256SUMS.txt` verification;
- managed and prepared native source archive content checks;
- post-publication download of all four GitHub assets and byte-for-byte SHA-256
  comparison with the local release files;
- GitHub `releases/latest` returned `v0.11.2`.

## Published artifacts

| File | Bytes | SHA-256 |
|---|---:|---|
| `AeroMirror-Setup-0.11.2.exe` | 1,248,256 | `6771afa141c734d26591f2234e398d85a88956b0c16968edd85e1756d0926364` |
| `AeroMirror-source-0.11.2.zip` | 1,709,788 | `966ed0751d54240fc5346ff21ea189547c041b624401705f579e84fcfcd24892` |
| `AeroMirror-native-source-0.11.2.zip` | 687,826 | `8c83e8231e96854584795ffd9568942e46f575f29ce8009fd64fb2357bfbcd3a` |
| `SHA256SUMS.txt` | 294 | `f27ded662c784c3294d61215913f0f6b2c7fc66451c814effc14381a24d27a92` |

## Remaining manual acceptance

The public update must still be exercised from installed 0.11.0 and 0.11.1
baselines on physical Windows 10 and Windows 11 systems. Receiver discovery,
session recovery, VPN, and repeated connect/disconnect acceptance also remain
required before the project can be labelled 1.0. See
`TEST_PLAN_0.11.2.md` and `TEST_PLAN_0.11.1.md`.
