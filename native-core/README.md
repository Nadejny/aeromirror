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
`libuxplay-aeromirror.patch`. The latter adds stable video-size and DNS-SD
readiness log markers used by the Windows shell for window adaptation and
discovery diagnostics, plus raw AirPlay geometry, selected GStreamer pipeline,
and feedback-health capability/recovered markers used only for diagnostics and
bounded continuity. It also exposes process-scoped HTTP listener lifecycle
markers, rejects a failed or changed-port in-process reset, logs typed
`TEARDOWN` as client-managed instead of forcing the whole RTSP connection
closed. The upstream `Connection: close` response header remains; only the
additional AeroMirror 0.12.6 server-side disconnect flag is removed. The patch
also stops advertising unimplemented photo presentation features. Its
auxiliary geometry pair is not claimed as crop, PAR, or rotation
metadata. The launcher accepts `--beacon-ipv4 <numeric IPv4>`
before `--uxplay`, passes it to the Windows BLE helper, and forwards helper
output to stdout with an `AEROMIRROR_BLE` prefix.

The wrapper now returns before its legacy settings UI can remove or replace
externally supplied `-vs` and `-fs` arguments in headless/`--uxplay` mode. The
reviewed libuxplay patch does not modify `renderers/audio_renderer.c`; its
unchanged source hash is a protected provenance input.

## Compatible runtime and build inputs

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

The public network installer reuses the unchanged runtime archive from
`uxplay-windows` release `2.0.0.1736`. That archive contains GStreamer 1.28.1,
including `libgstwasapi2.dll` with its `continue-on-error` property. The exact
archive and two DLL hashes are pinned in `UPSTREAM.lock` and
`source-provenance.json`. GStreamer 1.28.5 is the separate engineering
build/staging prefix; it must not be described as the redistributed runtime.

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

   The script verifies Qt 6.10.1 and the build-prefix GStreamer 1.28.5,
   configures a clean
   `out\headless-x64-qt610` directory, builds with Ninja, and rejects anything
   except an x64 PE importing `qt_version_tag_6_10` and not
   `qt_version_tag_6_11`. It also pins `SOURCE_DATE_EPOCH=1786008050` so the
   PE timestamp and resulting executable hash are reproducible.
6. Run `build-headless-runtime.ps1` only for a local engineering runtime. Pass
   both the extracted upstream runtime and its original pinned archive. The
   script verifies the archive SHA-256, the embedded GStreamer 1.28.1 core and
   wasapi2 DLL hashes/version/property, then deploys Qt and GStreamer 1.28.5
   from the selected MSYS2 prefix. Its manifest records both contracts and
   their distinct purpose. The public installer
   instead downloads the unchanged pinned runtime from release
   `2.0.0.1736`, verifies it, and runs `--loader-test` before installation.

   ```powershell
   .\build-headless-runtime.ps1 `
       -UpstreamRoot C:\src\uxplay-windows `
       -OriginalRuntime C:\inputs\uxplay-windows-2.0.0.1736 `
       -OriginalRuntimeArchive C:\inputs\uxplay-windows.zip `
       -HeadlessExecutable C:\src\uxplay-windows\out\headless-x64-qt610\uxplay-windows.exe `
       -MsysRoot C:\msys64
   ```
7. Run upstream `scripts/verify-bundle.ps1` against the staged runtime.

The runtime builder deliberately stages the hardware H.264/H.265 decoders for
both D3D11 and D3D12 because the latency profiles select them explicitly.
The resulting core's `--loader-test` has also passed against the unchanged
runtime from release `2.0.0.1736`.
