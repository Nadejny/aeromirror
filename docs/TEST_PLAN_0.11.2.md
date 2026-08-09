# AeroMirror 0.11.2 — in-place update regression plan

Version 0.11.2 is a focused patch for the installed-directory lock that can
block an update launched from AeroMirror 0.11.0 or 0.11.1. This plan verifies
the patch; it does not replace the broader receiver acceptance in
`TEST_PLAN_0.11.1.md`.

Save `%LOCALAPPDATA%\AirPlayReceiverMvp\setup.log` whenever a scenario fails.
Before publishing the review build, the automated update-lifecycle verifier
and the inherited-working-directory candidate check must pass. The normal
GitHub Release is needed to exercise the real update channel; publication does
not by itself mean that the patch has passed the full Windows 10/11 matrix.
Do not publish if either local check hangs, reports a sharing violation,
damages the existing installation, or loses per-user state.

## Test matrix

Run the complete acceptance scenarios on:

- Windows 10 version 1809 or newer, x64;
- Windows 11, x64;
- an installed AeroMirror 0.11.0 baseline;
- an installed AeroMirror 0.11.1 baseline.

For at least one baseline on each Windows version, keep AeroMirror running
with its native receiver and any renderer/helper process active when the
update begins.

## Candidate and acceptance scenarios

1. **Reproduce the old launch environment.** Install the baseline release,
   then launch the 0.11.2 candidate Setup with `/update` while deliberately
   giving it the installed AeroMirror directory as its inherited working
   directory. This reproduces the launch condition from older shells. Setup
   must move to a safe working directory before replacing files and must not
   report that the application folder is in use.
2. **Update from 0.11.0.** Repeat the inherited-working-directory launch from
   an installed 0.11.0 copy. Setup must finish, show 0.11.2 as installed, and
   launch exactly one AeroMirror shell when the launch option is selected.
3. **Update from 0.11.1.** Repeat from an installed 0.11.1 copy. Confirm the
   same successful outcome and that Setup does not need the user to close a
   hidden AeroMirror, UxPlay, or helper process manually.
4. **Active process tree.** Begin an update while the shell, receiver, and a
   receiver helper are running from the installation directory. Shutdown and
   replacement must finish within the documented bounded wait. Unrelated
   same-named processes outside the AeroMirror directory must remain running.
5. **Transient lock.** Introduce a short-lived lock during the directory-move
   phase and release it within the retry window. Setup must recover without
   creating a second installation or losing the previous files.
6. **Permanent external lock; old installation preserved.** Keep an unrelated process's
   working directory inside the installation beyond the retry window. Setup
   must fail in bounded time with an actionable message, leave the previous
   installation launchable, and record the failed attempts in `setup.log`.
   Release the lock and confirm a second update attempt succeeds.
7. **Shortcut preservation.** Test Start-menu-only, desktop-only, both, and
   no-shortcuts configurations. The 0.11.2 update must preserve the existing
   selection and must not create duplicate legacy shortcuts.
8. **Per-user state preservation.** Confirm that settings, autostart choice,
   receiver identity, PIN/trusted-device state, and logs under
   `%LOCALAPPDATA%\AirPlayReceiverMvp` survive the update.
9. **Fresh install and reinstall.** Install 0.11.2 on a PC without AeroMirror,
   then run the same Setup again as a reinstall. Both paths must complete and
   the uninstaller entry must identify 0.11.2.
10. **Setup log review.** Confirm successful runs record the initial working
    directory, any safe-directory change, bounded process shutdown, and each
    installation-directory move attempt. The log must not contain a PIN,
    receiver key, trusted-client secret, or GitHub credential.

## Post-publication update-channel smoke test

Immediately after publishing the immutable normal `v0.11.2` GitHub Release:

1. Install the public 0.11.1 Setup.
2. In AeroMirror, select **Check for updates** and confirm that GitHub
   `releases/latest` reports 0.11.2 with the curated English release notes.
3. Download and start the update from inside AeroMirror. Do not close the old
   shell or receiver manually.
4. Confirm Setup completes without a sharing-violation dialog, AeroMirror
   reports version 0.11.2 after launch, and the selected shortcuts and
   per-user state are unchanged.
5. Compare the downloaded Setup SHA-256 with the GitHub asset digest and
   `SHA256SUMS.txt`.

If this public-channel smoke test fails, do not replace the 0.11.2 asset. Keep
the release immutable, document the failure, and prepare a new patch version.

## Acceptance gate

The focused patch passes only when every candidate and acceptance scenario succeeds on
both supported Windows generations and the post-publication channel smoke
test succeeds. The project still remains below 1.0 until the complete
`TEST_PLAN_0.11.1.md` receiver matrix also passes on physical Windows 10 and
Windows 11 PCs.
