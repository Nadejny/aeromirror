# Troubleshooting review builds

Review builds contain additional local diagnostics for receiver startup,
Bonjour discovery, UxPlay, and GStreamer. They do not upload telemetry. Please
attach a diagnostic log to a bug report when the receiver is missing from the
iPhone, the first connection fails, the stream window closes unexpectedly, or
the application reports that the receiver is running when it is not usable.

## Find the receiver log

Use either method:

1. Right-click the AeroMirror tray icon and choose **Open log**.
2. Press `Win+R`, paste the following path, and press Enter:

   ```text
   %LOCALAPPDATA%\AirPlayReceiverMvp\receiver.log
   ```

The full path normally expands to:

```text
C:\Users\<you>\AppData\Local\AirPlayReceiverMvp\receiver.log
```

Copy the log after reproducing the problem and before reinstalling or cleaning
application data. In the GitHub report, include the exact local time and time
zone of the failure so the relevant section can be identified.

If installation or an in-place update itself fails, attach the reviewed
installer journal from:

```text
%LOCALAPPDATA%\AirPlayReceiverMvp\setup.log
```

## Protect private data before sharing

Review builds mask known PIN and password arguments, but always inspect the
file yourself before uploading it. Older builds may have written the fixed PIN
in plain text.

At minimum, replace:

- a PIN such as `-pin 3669` with `-pin ****`;
- any password or password-like advanced argument with `****`;
- your Windows account name in file paths with `<user>`;
- private receiver, PC, Wi-Fi, or network-profile names with descriptive
  placeholders;
- public IP addresses, MAC addresses, or other identifiers you do not want to
  publish.

Do **not** attach any of these files:

```text
receiver-key.pem
trusted-clients.txt
settings.ini
```

Do not paste an Apple ID, Wi-Fi password, Windows credentials, private key, or
the contents of the trusted-client register into an issue. If a maintainer
needs another diagnostic artifact, share only the specifically requested file
after reviewing it.

## Reproduce a first-run receiver problem

The safest complete first-run test is a clean Windows virtual machine or a
separate Windows user account. Bonjour is installed system-wide, so reinstalling
AeroMirror on the same account is not equivalent to a machine that has never
had Bonjour.

For a normal review test:

1. Record the AeroMirror version, Windows version, iPhone model and iOS
   version, installer/build type, connection type, and network profile.
2. Exit AeroMirror from its tray menu. Closing the window may only hide it.
3. Start the review build and note the exact local time.
4. Accept the Windows Firewall prompt for private/local networks if it appears.
   If Bonjour installation or a UAC prompt appears, record the choice and
   result. Do not remove or modify Bonjour manually on a daily-use PC.
5. Do not restart the receiver yet. Wait 60 seconds, open **Control Center →
   Screen Mirroring** on the iPhone, and record whether AeroMirror appears.
6. Attempt one connection. Record whether the PIN prompt, video window, and
   audio appear and whether any window closes unexpectedly.
7. If the receiver is still unavailable, use **Stop receiver**, wait five
   seconds, then use **Start receiver**. Record the time and whether this
   workaround changes the result.
8. Copy `receiver.log`, review and mask it as described above, then attach it
   to the bug report.

To simulate clean per-user settings without deleting data, exit AeroMirror and
rename `%LOCALAPPDATA%\AirPlayReceiverMvp` to a backup name. This resets the
receiver identity, PIN trust, and application settings for that Windows user.
Restore the folder only while AeroMirror is stopped. Prefer a VM or separate
Windows account if you are not comfortable handling this backup.

For a startup-after-reboot problem, also state whether AeroMirror was launched
by Windows startup or manually. Wait at least 60 seconds after signing in
before applying the stop/start workaround.

## What the review log records

Depending on the review build, the log may include:

- application version, startup mode, timestamps, and unhandled shell errors;
- sanitized receiver arguments and settings changes;
- receiver process IDs, start/stop reasons, shell readiness checks, exit
  codes, and restart backoff;
- Bonjour service presence and running state, plus observed receiver
  server-socket initialization;
- relevant physical-network changes without stream content;
- UxPlay standard output and error messages;
- GStreamer decoder, renderer, pipeline warnings, and errors.

The log is intended not to contain:

- screen, photo, video, or audio content;
- Apple ID or iCloud credentials;
- receiver private-key contents;
- trusted-client register contents;
- unmasked PINs or passwords.

Diagnostics remain on the PC until the user chooses to share them. If a log
does contain a secret, do not publish it: mask the secret first and mention in
the report which field was removed.

## Information that makes a report actionable

Please include:

- the exact failure time and time zone;
- whether it happened on first install, first start after reboot, manual
  start, reconnection, or after changing settings;
- whether **Restart receiver** helped, and whether a full **Stop receiver** /
  **Start receiver** cycle helped;
- whether the receiver process or only the video window disappeared;
- the selected quality, latency, renderer, and audio options;
- Bonjour status from AeroMirror diagnostics, if available;
- whether VPN, Hyper-V, WSL, a mobile hotspot, or a virtual network adapter was
  active;
- a minimal numbered reproduction sequence;
- the reviewed and masked `receiver.log`.

Avoid posting only “it crashed.” A timestamp plus the distinction between the
AeroMirror window, the tray application, the receiver process, and the stream
window is especially useful.
