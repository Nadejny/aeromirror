# Native headless core

The MVP patches `leapbtw/uxplay-windows` so its linked UxPlay engine can run
with `--headless`. In this mode the upstream Qt tray icon is not created; the
single visible tray belongs to `AeroMirror.exe`.

Upstream pins:

- `leapbtw/uxplay-windows`: `8cf3424b438424bc99a89155bd29a789f48a43c0`
- `leapbtw/libuxplay`: `437f37514257d9cb513ac7fbdee743b4da85852e`

`dnssd.def` is generated from the export table of the bundled x64 `dnssd.dll`
and is used to create a MinGW import library for local builds.

The source changes are recorded in `uxplay-windows-headless.patch` and
`libuxplay-aeromirror.patch`. The latter adds only a stable video-size log
marker used by the Windows shell for automatic portrait/landscape adaptation.

## Compatible Qt input

The headless executable must be built against Qt 6.10.1 so it can load with
the unchanged runtime from pinned `uxplay-windows` release `2.0.0.1736`.
The exact official MSYS2 package is:

- file: `mingw-w64-ucrt-x86_64-qt6-base-6.10.1-1-any.pkg.tar.zst`
- URL:
  `https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-qt6-base-6.10.1-1-any.pkg.tar.zst`
- SHA-256:
  `1F7E95DFA1968910460087E8235C274BA5E14365E0F79EDC0C7672D951544D65`
- verified signature key:
  `5F944B027F7FE2091985AA2EFA11531AA0AA7F57`

Extract the package into an isolated directory and pass its `ucrt64`
directory as `Qt610Prefix`. Do not install, update, or downgrade packages in
the normal MSYS2 prefix for this build.

## Local build outline

1. Install MSYS2 UCRT64 with the packages listed by upstream
   `ucrt_x64_dependencies.txt`, except that the Qt build input is the isolated
   package above.
2. Check out the pinned `uxplay-windows` and `libuxplay` commits.
3. Apply `uxplay-windows-headless.patch`, then apply
   `libuxplay-aeromirror.patch` inside the `libuxplay` submodule.
4. Provide the Bonjour SDK header and import library. `dnssd.def` can generate
   the x64 MinGW import library from the redistributed `dnssd.dll`:

   ```powershell
   dlltool -d dnssd.def -D dnssd.dll -l dnssd.lib
   ```

5. Run the isolated compatible-core build without bootstrap or package
   updates:

   ```powershell
   .\build-compatible-core.ps1 `
       -UpstreamRoot C:\src\uxplay-windows `
       -Qt610Prefix C:\inputs\qt610\ucrt64 `
       -MsysRoot C:\msys64
   ```

   The script verifies Qt 6.10.1, configures a clean
   `out\headless-x64-qt610` directory, builds with Ninja, and rejects anything
   except an x64 PE importing `qt_version_tag_6_10` and not
   `qt_version_tag_6_11`. It also pins `SOURCE_DATE_EPOCH=1786008050` so the
   PE timestamp and resulting executable hash are reproducible.
6. Run `build-headless-runtime.ps1` only for a local engineering runtime. It
   deploys Qt and GStreamer 1.28.5 from the selected MSYS2 prefix and records
   the core's Qt 6.10 import contract in its manifest. The public installer
   instead downloads the unchanged pinned runtime from release
   `2.0.0.1736`, verifies it, and runs `--loader-test` before installation.
7. Run upstream `scripts/verify-bundle.ps1` against the staged runtime.

The runtime builder deliberately stages the hardware H.264/H.265 decoders for
both D3D11 and D3D12 because the latency profiles select them explicitly.
The resulting core's `--loader-test` has also passed against the unchanged
runtime from release `2.0.0.1736`.
