# Project decisions

This file records durable choices and their rationale. Update it when a
decision changes; do not use it as a task list.

## D-001 — Keep the Windows shell and native receiver in separate processes

**Status:** accepted

`AeroMirror.exe` owns the Windows UI, settings, network safety, updates,
diagnostics, and process supervision. The native UxPlay-based executable owns
AirPlay protocol handling, decode, audio, and rendering.

The boundary provides crash isolation and allows the native core to restart
without losing the tray application. Combining them would require a major
native UI or interop rewrite and would not inherently reduce media latency.
A future change should introduce versioned local IPC before reconsidering the
process boundary.

## D-002 — Derive trust from the physical Windows network

**Status:** accepted

A Windows Private physical Wi-Fi/Ethernet network may receive without a PIN,
while PIN protection remains optional. A Public or unknown physical network
fails closed without a PIN. VPN, tunnel, Hyper-V, and other virtual adapters
do not override the physical network category.

This is conservative by design: a wrongly classified network should block an
unprotected receiver rather than expose it.

## D-003 — Use physical IPv4 for receiver startup and discovery

**Status:** accepted

The core waits for a preferred, non-APIPA, non-SkipAsSource IPv4 on the active
physical adapter. DNS-SD remains the primary LAN discovery path; the optional
BLE beacon advertises the same physical address instead of selecting a route
through a VPN.

Readiness requires listening sockets and at least one viable discovery signal.
Explicit failure of both DNS-SD and BLE must not produce a false ready state.

## D-004 — Use normal GitHub Releases for the review update channel

**Status:** accepted

Installed clients read GitHub `releases/latest`, so a testable review build
is published as a normal Release and labelled as a review candidate in its
title/body. GitHub's Pre-release flag is not used because clients would not
see it.

Updates download the complete small Setup instead of applying line-level or
binary deltas. The large pinned runtime is stored in a verified
content-addressed cache and reused when unchanged.

Never replace an asset under an already published version. Post-release fixes
receive a new patch version.

## D-005 — Keep public release communication in English

**Status:** accepted

`CHANGELOG.md`, GitHub Release bodies, release plans, test plans, and new
maintainer documentation are written in English. The existing Russian UI is
not partially translated through scattered literals.

## D-006 — Localize from resources with a system default and manual override

**Status:** planned for 0.12

At first launch, AeroMirror should follow the Windows display language. Users
can override it through a `System / English / Russian` setting. `System`
continues following Windows after later OS language changes.

All user-visible strings should move to typed resource sets with English as
the invariant fallback. Settings store a stable culture choice rather than a
translated display label. Changing language should update the shell without
changing receiver identity, pairing, or network state.

## D-007 — Separate documentation scaffolding from source reorganization

**Status:** accepted

The 0.11.1 stability tag keeps the existing source layout. Agent guidance,
current state, and decisions are added as post-release documentation. Any
directory moves, project splits, or namespace changes begin in an explicit
0.12 development change with a migration map and build verification.

## D-008 — Do not call the project 1.0 before physical acceptance

**Status:** accepted

Automated tests cannot prove AirPlay interoperability. A 1.0 designation
requires the current manual test plan to pass on at least one physical
Windows 10 PC and one physical Windows 11 PC, including delayed Wi-Fi, VPN,
sequential sessions, and connection loss.

## D-009 — Keep one managed assembly and organize stateful classes with partial source files

**Status:** accepted for 0.12

The managed shell remains one .NET Framework `AeroMirror.exe` assembly. Source
is grouped by responsibility, and the stateful `ReceiverContext` is divided
across partial-class files for core lifecycle, rendering, and diagnostics while
retaining one private state owner.

This keeps the 0.12 move mechanical: it does not introduce another managed
process, plugin model, public API, serialization boundary, dependency-injection
container, or new runtime requirement. Existing namespace, mutex/event names,
settings and log paths, autostart and update identities, receiver key and trust
state, native process contract, and installed core path remain unchanged.

The active `SettingsForm` stays in one file during this pass because splitting
its tightly coupled WinForms construction and navigation at the same time would
add review risk without changing product behavior. Further service extraction
or UI decomposition requires a separate design, tests, and migration plan.

## D-010 — Keep file transfer separate from the AirPlay receiver boundary

**Status:** accepted

Appearing as an AirPlay/Apple TV receiver does not make AeroMirror an AirDrop
target. Genuine AirDrop interoperability requires a separate Bluetooth/AWDL,
identity, trust, and encrypted-transfer implementation with independent
hardware, driver, license, privacy, and security review. It must not be added
to the UxPlay receiver process or its firewall surface merely because AirPlay
discovery already works.

The lower-risk staged alternative is a separately named **AeroDrop** product
path using an iOS Share Extension or companion and an authenticated local
transfer. It still requires explicit acceptance, safe destination and filename
rules, transfer limits, quarantine policy, and physical-device tests. This
decision defines the architecture boundary; it does not commit 0.12.4 or 1.0
to either transfer implementation.

## D-011 — Keep unpublished candidate numbers as internal history

**Status:** accepted

A version number identifies the exact source and artifact candidate that was
built and tested, even when that candidate is never published. Superseded
internal candidates are recorded in the changelog and versioned plans but do
not receive reconstructed tags, draft Releases, prereleases, or relabelled
assets. The next public Release may therefore skip one or more patch numbers.

Do not rename a later candidate to fill a public numbering gap. Doing so would
collide with existing local artifacts, invalidate provenance and test evidence,
and make numeric update comparisons wrong for machines already running an
intermediate build. A corrective change after a frozen candidate always gets a
newer version; a published tag and its assets remain immutable under D-004.
