# AeroMirror 0.12.3 — loss, placement, and Photos acceptance

## Publication status

Version `v0.12.3` was published from commit
`334001a8fa896c8e072465e624fda4f150ffa666` as the normal, non-draft,
non-prerelease latest GitHub Release:

https://github.com/Nadejny/aeromirror/releases/tag/v0.12.3

The automated, exact-tag, and public-asset gates pass. The installed updater
path and every physical Windows/iPhone scenario below remain pending. This plan
must not be used to claim physical interoperability or 1.0 acceptance before
those rows pass.

## Scope and risks

This patch changes the managed shell in four related areas:

1. a persistent, memory-only placeholder after a confirmed fatal stream loss;
2. saved and restored renderer bounds with DPI and work-area normalization;
3. an early phone-shaped marker retained before the video-size debounce;
4. two small Russian UI labels/controls.

The native UxPlay executable and runtime are unchanged. The highest risks are
showing a stale placeholder for a benign disconnect, hiding a real renderer on
reconnect, saving bad/off-screen bounds, resize feedback loops, selecting a
false phone aspect, leaking mirrored pixels to disk, or implying that inner
Photos canvas sizing has been solved when it has not.

## Required environments

- Windows 11 x64 with current display and GPU drivers;
- Windows 10 version 1809 or newer, x64, with current compatible drivers;
- at least one current iPhone and iOS version;
- one trusted Private physical LAN, with VPN enabled for at least one repeat to
  confirm that the virtual overlay does not redefine network trust;
- two monitors if available, including one mixed-DPI arrangement and one test
  after the secondary monitor is disconnected;
- 100%, 150%, and 200% Windows display scale where available.

Record Windows build, iPhone model/iOS, wired or wireless PC path, physical
network category, VPN state, GPU/driver, monitor layout/DPI, test time, and the
relevant redacted `receiver.log` interval. Retain screenshots of the renderer,
placeholder, and restored bounds; screenshots are manual test evidence and
must not be generated or stored by AeroMirror itself.

## Automated gates

| Gate | Expected result | Status |
|---|---|---|
| Managed x64 shell build | `AeroMirror.exe` builds with PE/file version `0.12.3.0` | PASS |
| Receiver resilience suite | Fatal/benign loss, placeholder transitions, early Photos marker, placement normalization, settings migration, and existing regression assertions pass | PASS |
| Settings schema | Existing profiles migrate to schema 10; valid placement copies/saves and malformed partial placement clears as one unit | PASS — resilience suite |
| WinEvent safety | The out-of-context callback only queues placement/fit work; no resize or settings write occurs inside the callback | PASS — resilience suite |
| Privacy/source audit | Placeholder capture is foreground-screen-only or dark fallback; no frame path, upload, diagnostics attachment, or file write exists | PASS |
| Version/link audit | Shell/Setup/script defaults, README examples, notices, release documents, and local links consistently target 0.12.3 | PASS |
| Review payload | Versioned thin review payload builds against the pinned runtime manifest | PASS |
| Setup and lifecycle verifier | Network Setup builds, reports 0.12.3, and passes update/rollback/shortcut checks | PASS |
| Native corresponding source | Prepared 0.12.3 archive validates unchanged pinned commits, patches, inputs, and executable hash | PASS |
| Whitespace/diff audit | `git diff --check` passes and the candidate diff contains no unrelated generated output | PASS |
| Exact-tag release package | Clean `v0.12.3` packages the tag commit and exactly four expected public assets | PASS |
| Public Release and re-download | Normal latest channel; four local/re-downloaded hashes and four GitHub API digest fields match | PASS |

Exact published byte sizes and SHA-256 values are recorded in
`BUILD_REPORT.md`.

## Physical scenario A — fatal loss placeholder

1. Start AeroMirror, connect the iPhone, and keep a recognizable non-sensitive
   screen visible.
2. Disable iPhone Wi-Fi long enough for the log to record the confirmed fatal
   lost-client/mirror-receive marker.
3. Confirm a placeholder opens at the renderer's last bounds. When the renderer
   was safely visible in the foreground it should show a softened/darkened
   frame; when capture is unsafe or unavailable it must show a dark fallback.
4. Leave it open while the native core exits and the bounded discovery renewal
   starts. Confirm it does not disappear merely because the core process was
   replaced or a reconnect handshake began.
5. Re-enable Wi-Fi and start Screen Mirroring again. Confirm the placeholder
   closes only when the log reports a new mirroring start and the real renderer
   becomes usable.
6. Repeat and press the placeholder's explicit Close button. Confirm the
   receiver continues waiting and a later stream can still open normally.
7. Repeat while changing **Always on top** and stream-taskbar behavior. Confirm
   the placeholder follows those settings without creating a duplicate form.
8. Repeat and stop the receiver, exit AeroMirror, and perform any
   settings-driven core shutdown. Confirm the placeholder closes in each case.

Pass criteria: one placeholder at most; it survives only the intended recovery
interval; the new renderer is never covered after mirroring starts; manual
close does not stop the receiver; no unhandled error or UI hang occurs.

Failure criteria: a benign warning opens it, it disappears on core renewal, it
remains over a recovered stream, closing it stops AeroMirror, or any screenshot
is written to disk or attached to diagnostics.

## Physical scenario B — exclusion of benign and clean paths

1. Complete a normal iPhone **Stop Mirroring** disconnect.
2. Produce ordinary feedback-delay warnings without a fatal receive/lost-client
   marker if the environment permits.
3. Perform three normal connect/disconnect cycles.

Pass criteria: no loss placeholder appears; the healthy receiver remains
available; normal discovery and repeated sessions are no worse than 0.12.2.

## Physical scenario C — saved renderer placement

1. On the primary monitor, move and resize the renderer to a distinctive normal
   rectangle. End mirroring, reconnect, and confirm the same position and size
   return.
2. Resize again with automatic fitting enabled. Confirm the learned proportions
   are restored after the short delay while the window center and approximate
   client area remain stable. Repeat with automatic fitting disabled and
   confirm the user's exact normal bounds remain authoritative.
3. Move the renderer without resizing. Reconnect and confirm the new position
   persists even though no automatic fit was queued for move-only activity.
4. Minimize and maximize the renderer before disconnecting. Confirm those
   transient states are not saved as normal bounds.
5. Place the renderer on a mixed-DPI secondary monitor. Reconnect there and
   confirm size follows the monitor DPI without clipping.
6. End mirroring, disconnect that monitor, and reconnect. Confirm the window is
   fully clamped into an available work area rather than opening off-screen.
7. Test negative virtual-screen coordinates and an oversized saved rectangle.

Pass criteria: normal bounds persist atomically; available secondary-monitor
placement is retained; DPI size changes are proportional; stale and oversized
bounds are fully visible; no repeated shrink/expand loop occurs.

## Physical scenario D — Photos and rotation

1. From the iPhone home screen, start mirroring and then open Photos. Record the
   raw video-size marker sequence and confirm later `3840x2160` media canvas
   markers do not replace a learned `998x2160`-style portrait baseline.
2. Stop mirroring. Leave Photos open on a landscape photo and start mirroring
   directly from that state. For the recorded sequence, confirm the early
   phone-shaped marker is logged before debounce and the outer renderer remains
   portrait when the later `3840x2160` canvas stabilizes.
3. Rotate the Photos application/gallery UI and another rotation-capable app.
   Confirm a real authoritative portrait/landscape device ratio still changes
   the outer window once and does not oscillate.
4. Repeat a session whose first observed marker is only generic 16:9 if one can
   be reproduced. Confirm AeroMirror does not label that ratio as an early
   modern-iPhone baseline.
5. Inspect the actual photo inside the renderer. Record its apparent size and
   all black bars separately from the outer window orientation.

Pass criteria: the known `998x2160` then `3840x2160` direct-start sequence keeps
the portrait outer baseline; real device rotation remains functional; generic
16:9 is not blindly promoted.

Known non-failure for this patch: the photo may remain very small because iOS
has already letterboxed it inside the encoded `3840x2160` canvas. Do not mark
inner content sizing as fixed. Retain logs and screenshots for future native
content-metadata or validated pixel-analysis work.

## Physical scenario E — UI and upgrade regression

1. Inspect the tray in the current Russian UI. Confirm **Restore window
   proportions** clearly performs a one-shot manual fit and is translated in
   the tray rather than appearing as an isolated English literal in-app.
2. Open Settings at 100%, 150%, and 200% scale. Confirm the Back arrow and
   target are larger, aligned, keyboard reachable, and unclipped.
3. Confirm no language selector is presented: resource-based localization is
   still planned under D-006 and this patch must not expose a partial setting.
4. Update an installed public 0.12.2 through 0.12.3 Setup. Confirm receiver
   identity, trusted iPhone state, PIN, settings, logs, shortcuts, autostart,
   and the pinned runtime cache survive. Migration should begin with empty
   placement fields; the first valid normal renderer placement produced by an
   initial/manual fit, move, or resize may then populate them.
5. Recheck Private/Public/Unknown physical-network behavior with and without a
   VPN overlay. Public/Unknown without a valid PIN must still fail closed.

## Acceptance gate

The public-review publication gate is complete:

1. every automated gate above passed against the final source;
2. the placeholder source/privacy audit found no persisted mirrored frame;
3. shell and Setup report `0.12.3.0`, while UI, tag, and assets use `0.12.3`;
4. the exact-tag pipeline produced only Setup, AeroMirror source, prepared
   native corresponding source, and `SHA256SUMS.txt`;
5. publication was authorized, and all public re-download/API digest checks
   passed.

Physical acceptance is still pending. Complete the Windows 10/11 and iPhone
scenarios above, including an installed in-app update from public 0.12.2, before
describing the behavior as physically accepted or using the 1.0 designation
required by D-008.

The exact report is `BUILD_REPORT.md`. Any correction must use 0.12.4 or later;
never move the immutable `v0.12.3` tag or replace its assets.
