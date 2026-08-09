# AeroMirror 0.11.3 — reconnect and discovery regression plan

Version 0.11.3 is a focused shell-supervision patch. A normal completed
session must leave a healthy native receiver registered and listening, while
real lost-client failures must still recover within a bounded time. The
reviewed native UxPlay executable and pinned runtime are unchanged.

Publishing 0.11.3 as an explicitly labelled review candidate is allowed after
the automated checks and native-source provenance gates pass and explicit user
authorization is given, so the normal update channel can be used for physical
testing. Do not describe the patch as accepted until the Windows 11 baseline
below passes. Do not call the project 1.0 until the same plan also passes on a
physical Windows 10 1809+ x64 PC and the broader acceptance plan is complete.

## Test setup and evidence

Use the exact candidate Setup and record:

- AeroMirror version, Windows edition/build, PC network adapter and driver;
- iPhone model, iOS version, and the physical access point/router;
- whether a VPN or virtual adapter is present and whether it is active;
- the PC-clock start and end time for every scenario;
- the relevant redacted `receiver.log` section.

Keep the AeroMirror window closed or in the tray unless a step explicitly
opens it. Do not press **Restart discovery** or restart AeroMirror during a
scenario. A manual restart is a workaround to record after a failure, not a
passing result.

Before each network-policy case, confirm the physical Windows network profile
in Windows Settings. A VPN or virtual adapter must not redefine the trust
category of the physical Wi-Fi/Ethernet connection.

## Automated gates

1. Build the shell and Setup with public version `0.11.3` and internal PE
   version `0.11.3.0`.
2. Run `tests/ReceiverResilience.Tests.ps1`, including deterministic coverage
   for normal session completion; a low-level accepted socket being ignored;
   a high-level request re-arming the bounded ten-minute idle fallback and
   postponing deferred settings maintenance; actual mirror start cancelling
   pending post-session maintenance; fatal lost-client recovery; and idle
   discovery maintenance.
3. Feed the supervised core-output path the representative warning
   `*** ERROR: 3 seconds since last client feedback request; client may be offline`
   while a session is active. The automated check must prove that this warning
   leaves `lostConnectionRecoveryPending` clear and does not schedule a
   restart, while the later explicit `lost connection with client` marker and
   the existing fatal mirror-receive marker still do.
4. Run installer verification and confirm that the 0.11.2 in-place-update
   lock regression remains fixed.
5. Run `git diff --check` and verify that release packaging contains only the
   four allowed public assets.

Automated simulation does not replace the physical iPhone/Windows cases below.

## Physical reconnect scenarios

### 1. Clean immediate reconnect

1. Start AeroMirror and wait until it reports that the receiver is ready.
2. Connect from iPhone **Screen Mirroring** and stream visible motion for at
   least 30 seconds.
3. Stop mirroring from the iPhone normally.
4. Immediately reopen **Screen Mirroring**, select AeroMirror as soon as it is
   listed, and wait for video.
5. Repeat the disconnect/reconnect sequence five times without opening the
   AeroMirror window.

Pass criteria:

- AeroMirror remains listed without a manual discovery refresh;
- every selection reaches a new stream on the first attempt, with a target of
  five seconds or less from selection to visible video;
- the incoming high-level request re-arms the bounded ten-minute idle fallback
  and postpones deferred settings maintenance; neither action interrupts the
  new handshake, and actual mirror start cancels pending post-session
  maintenance for the active session;
- the native receiver PID and listening endpoints remain stable between
  normal sessions, and the log contains no full core restart caused only by a
  normal disconnect.

Record every selection-to-video duration even if the case passes.

### 2. iPhone Wi-Fi off and on

1. Start an active stream and confirm stable motion for 30 seconds.
2. Turn iPhone Wi-Fi off for 10 seconds without stopping AeroMirror.
3. Turn Wi-Fi on and wait for the iPhone to rejoin the same physical LAN.
4. Open **Screen Mirroring** immediately and select AeroMirror as soon as it
   appears.
5. Repeat three times, including one attempt made while the previous lost
   session is still being cleaned up.

Pass criteria:

- discovery returns automatically; no application or receiver restart is
  required;
- the first selection after AeroMirror is listed reaches video within ten
  seconds and does not end in the previous 20–30 second failed attempt;
- cleanup of the lost session is bounded and cannot restart a newly active
  handshake or stream;
- after recovery, a normal disconnect also passes the clean immediate
  reconnect scenario.

### 3. Weak Wi-Fi must not cause a false reset

1. Begin a stream with strong Wi-Fi and record the receiver PID.
2. Move the iPhone to a reproducibly weak but still connected location for at
   least two minutes. Generate motion and audio throughout the interval.
3. Return to strong coverage without restarting either device.
4. Stop mirroring normally and reconnect immediately.

Pass criteria:

- temporary stalls or dropped frames may be visible, but AeroMirror does not
  perform a full receiver restart solely because traffic was briefly weak or
  the core emitted a benign feedback warning;
- the shell does not report a false fatal state while listening/discovery is
  still healthy;
- streaming either resumes when coverage improves or performs one bounded,
  logged recovery after a confirmed fatal loss;
- the next connection succeeds on its first attempt without manual recovery.

If the access point exposes RSSI or packet-loss data, record it. Do not claim
this case passed from subjective smoothness alone.

### 4. Discovery after ten minutes idle

Run both variants:

1. Start AeroMirror, do not connect an iPhone, and leave it in the tray for at
   least ten minutes. Allow the single bounded idle-discovery fallback to
   complete if it becomes due, then open **Screen Mirroring** and connect.
2. Complete one normal streaming session and disconnect.
3. Near the next ten-minute idle boundary, open **Screen Mirroring** and select
   AeroMirror before any fallback begins. Keep the picker open long enough for
   the high-level request to be recorded, then wait for video.

Pass criteria:

- AeroMirror becomes visible within ten seconds of opening the iPhone picker;
- both connections succeed on the first attempt without opening AeroMirror or
  refreshing discovery;
- at most one bounded discovery renewal occurs for an uninterrupted idle
  period; it completes without changing the persistent receiver identity and
  does not become a periodic restart loop;
- a high-level incoming request re-arms the fallback for another ten minutes
  and postpones deferred settings maintenance, so no restart occurs between
  that request and actual mirror start;
- actual mirror start cancels pending post-session maintenance for the active
  session, while confirmed fatal failures still retain bounded recovery.

## Physical network and PIN regression

Run each case with VPN disabled, then repeat the policy check with a VPN
enabled over the same physical LAN.

1. **Private physical network, no PIN.** The receiver is advertised and the
   iPhone connects without a PIN prompt.
2. **Private physical network, PIN enabled.** The user may choose stronger
   protection; the first untrusted connection prompts for the visible PIN and
   succeeds after the correct value is entered.
3. **Public physical network, no PIN.** AeroMirror fails closed: the
   unprotected receiver is paused/not advertised and the UI explains that a
   PIN is required. A VPN must not make this network trusted.
4. **Public physical network, PIN enabled.** The protected receiver is
   advertised and accepts the correct PIN. An incorrect PIN must not connect.
5. **Return from Public to Private.** Network detection updates automatically,
   and the private-network policy becomes usable without restarting the app.

The reconnect changes fail this regression if they bypass the Public-network
gate, remove optional PIN support on a Private network, change the persistent
receiver identity, or expose PIN values in logs.

## Release decision

The candidate passes only when every scenario above passes on a physical
Windows 11 x64 PC, with no crash, manual receiver restart, first-attempt
reconnect failure, false weak-Wi-Fi reset, or security-policy regression.
Record Windows 10 results separately; they remain mandatory before 1.0.

If any public 0.11.3 asset is later found defective, do not replace it under
the same tag. Keep the published files immutable and prepare a new patch
version.
