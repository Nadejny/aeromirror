# AeroMirror 0.11.1 — manual candidate acceptance

Version 0.11.1 is a stability candidate, not the final 1.0 release. Promote the
project to 1.0 only after successful real-device runs on Windows 10 and
Windows 11.

Use Report a problem to save a redacted diagnostic report whenever discovery
or recovery exceeds the expected bounds.

## Test matrix

Repeat the primary scenarios on:

- Windows 10 1809+ x64;
- Windows 11 x64;
- a physical Wi-Fi or Ethernet network without a VPN;
- the same physical network with a VPN enabled, then again after disabling it.

## Scenarios

1. **Normal startup.** Start AeroMirror after the network is ready. The
   receiver should become visible on the iPhone without a manual restart; the
   log should contain a physical IPv4 address and a DNS-SD or BLE readiness
   marker.
2. **Windows starts before Wi-Fi.** Boot the PC with Wi-Fi disabled, wait for
   AeroMirror to autostart, then connect Wi-Fi. The native core must not start
   on a VPN or arbitrary interface before a physical IPv4 is available. After
   Wi-Fi connects, the receiver should appear without a manual stop/start.
3. **Late network reconnection.** With AeroMirror already running, disconnect
   and reconnect the physical network. Confirm that the receiver becomes
   visible again after the network stabilizes.
4. **VPN.** Enable a VPN over a trusted physical home network, start or refresh
   discovery, and connect from the iPhone. BLE must advertise the physical
   LAN IPv4 address, while connection protection must follow the physical
   Windows network category. Repeat after disabling the VPN.
5. **Three sequential sessions.** Connect the iPhone, wait for video, and
   disconnect normally three times. After every disconnect, the receiver
   should become visible and accept the next session without restarting the
   application.
6. **Client loss during mirroring.** While mirroring, disable Wi-Fi on the
   iPhone or disconnect the physical network. The stalled session should be
   cleared and the core process tree restarted in roughly eight seconds or
   less after the loss is detected. After network recovery, the receiver
   should reappear and accept a new connection.
7. **Update from 0.11.0.** Test Start-menu-only, desktop-only, both-shortcuts,
   and no-shortcuts configurations. Updating to 0.11.1 must preserve the
   shortcut selection, `settings.ini`, receiver key, trusted devices, and
   autostart configuration.

## Acceptance gate

Publishing 0.11.1 as an explicitly labelled review candidate is allowed so
the GitHub update path and multiple real PCs can be tested. Do not call the
project 1.0 until every scenario passes on at least one real Windows 10 PC and
one real Windows 11 PC.

A crash, lost rediscovery, or recovery substantially slower than eight seconds
blocks the 1.0 designation and requires an attached redacted diagnostic report.
