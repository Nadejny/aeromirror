# Build report — 0.11.1 stability candidate

Build date: 2026-08-09
Target: Windows 10 1809+ / Windows 11, x64
Publication status: local candidate; not tagged or uploaded

## Scope

This candidate fixes the Windows 10 lost-client stall, waits for a usable IPv4
on the physical Wi-Fi/Ethernet profile before starting the receiver, binds BLE
discovery to that physical address when a VPN is present, and records explicit
DNS-SD/BLE readiness markers. It also preserves the user's shortcut selection
during an installer update and simplifies the problem-report hand-off.

## Automated verification

- The patched native core was rebuilt twice from the pinned sources and Qt
  6.10.1/MSYS2 inputs. Both builds produced the same SHA-256.
- Native `--loader-test` and `--self-test` completed successfully.
- `tests/ReceiverResilience.Tests.ps1` passed, including lost-client recovery,
  non-extendable network debounce, stable receiver identity, discovery marker,
  and bounded recovery checks.
- The installer shortcut-selection resolver passed all five fresh/update
  scenarios during `build-installer.ps1`.
- The UI smoke probe and renderer-sizing probe passed.
- PowerShell syntax checks and `git diff --check` passed.

## Local candidate artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `AeroMirror-Setup-0.11.1.exe` | 1,230,336 | `39d7564254dbba4af478f391e7f0d145ee0b514df791cbd5c6db57516df963fc` |
| `AeroMirror-portable-x64-0.11.1.zip` | 114,998,984 | `c499119ac34af3076eec9fed2e922fe64ac8fd1ae34134e7f43d9f759f3dfd70` |
| `AeroMirror-review-payload-x64-0.11.1.zip` | 1,028,662 | `196d80df10a26b40b7eaaadd3105175aaf777aba05118879645531453ebbbadf` |
| `AeroMirror-native-source-0.11.1.zip` | 687,807 | `8d5839738e36917ab5237be1638ec7663823472b72ae2b1fc515518c4b39c037` |
| `AeroMirror.exe` | 706,048 | `dc7ffc09300356ec60f1103f93d13344a283950cb393aa677dadbc2a4b20c12f` |
| patched `uxplay-windows.exe` | 872,007 | `984f58c053631005145b07dab44ee0cfb7cd637a0ca5e67f5b61500284e2d5b9` |

The setup is intentionally unsigned while the project has no trusted code
signing certificate. The complete public release assets and their final
`SHA256SUMS.txt` must be regenerated from a clean `v0.11.1` tag; PE timestamps
mean the final Setup hash can differ from this local candidate.

## Remaining release gate

The real-machine scenarios in `TEST_PLAN_0.11.1.md` are still required on one
Windows 10 computer and one Windows 11 computer. In particular, test booting
before Wi-Fi is ready, VPN on/off, three consecutive sessions, and physical
network loss during mirroring. Do not label the project 1.0 until those checks
pass.
