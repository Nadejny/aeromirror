using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.ServiceProcess;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using System.Web.Script.Serialization;
using Microsoft.Win32;

namespace AirPlayReceiverMvp
{
    internal sealed partial class ReceiverContext
    {
        private enum LostConnectionRecoveryAction
        {
            None,
            RestartStalledSession,
            RenewDiscovery
        }

        public void StartCore()
        {
            ResetRapidExitWindow();
            ResetSharedAutomaticRecoveryBudget();
            if (!networkProfileKnown)
            {
                startAfterNetworkCheck = true;
                SetState(false, "Проверяем безопасность сети…");
                BeginNetworkProfileRefresh();
                return;
            }
            StartCore(true);
        }

        private void StartCore(bool notify)
        {
            if (Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1)
            {
                restartAfterStop = true;
                return;
            }
            if (coreProcess != null && !IsCoreRunning)
            {
                try
                {
                    int staleCode = coreProcess.ExitCode;
                    CancelCoreOutputReads(coreProcess);
                    Log("Disposing exited core before a new start; code " +
                        staleCode + ".");
                }
                catch { }
                finally
                {
                    coreProcess.Dispose();
                    coreProcess = null;
                    NativeMethods.CloseHandleSafe(ref coreJob);
                    coreReadyPending = false;
                    Interlocked.Exchange(ref coreSocketsReady, 0);
                    Interlocked.Exchange(ref coreSocketsReadyDueTicks, 0);
                    Interlocked.Exchange(ref activeCorePid, 0);
                }
            }
            if (IsCoreRunning)
                return;
            restartPending = false;

            string beaconIpv4 = FirstNumericIpv4(physicalNetworkAddresses);
            if (!networkProfileKnown || beaconIpv4.Length == 0)
            {
                startAfterNetworkCheck = true;
                SetState(false, "Ждём адрес Wi-Fi/Ethernet…");
                Log("Receiver start deferred until the physical " +
                    "Wi-Fi/Ethernet profile has a usable IPv4 address.");
                BeginNetworkProfileRefresh();
                return;
            }

            if (!networkProfileKnown && settings.PairingMode == "none")
            {
                SetState(false, "Не удалось определить сеть · включите PIN");
                if (settings.Notify && notify)
                    tray.ShowBalloonTip(6000, AppTitle,
                        "AeroMirror не смог определить профиль сети. Для безопасного запуска включите PIN или повторите проверку сети.",
                        ToolTipIcon.Warning);
                return;
            }

            if (publicNetwork && settings.PairingMode == "none")
            {
                SetState(false, "Публичная сеть · включите PIN");
                if (settings.Notify && notify)
                    tray.ShowBalloonTip(6000, AppTitle,
                        "Windows считает текущую Wi-Fi/Ethernet-сеть публичной. Включите PIN или измените профиль сети на «Частный» в параметрах Windows.",
                        ToolTipIcon.Warning);
                return;
            }

            if (!File.Exists(CorePath))
            {
                Log("ERROR: Core executable not found: " +
                    MaskSecrets(CorePath));
                SetState(false, "Ядро UxPlay не найдено");
                if (settings.Notify)
                    tray.ShowBalloonTip(5000, AppTitle,
                        "Не найден core\\uxplay-windows.exe. Переустановите AeroMirror.",
                        ToolTipIcon.Error);
                return;
            }

            try
            {
                var start = new ProcessStartInfo();
                start.FileName = CorePath;
                start.Arguments = "--headless --beacon-ipv4 " +
                    QuoteArgument(beaconIpv4) + " --uxplay " +
                    BuildUxPlayArguments();
                start.WorkingDirectory = Path.GetDirectoryName(CorePath);
                start.UseShellExecute = false;
                start.CreateNoWindow = true;
                start.WindowStyle = ProcessWindowStyle.Hidden;
                start.RedirectStandardOutput = true;
                start.RedirectStandardError = true;
                start.StandardOutputEncoding = Encoding.UTF8;
                start.StandardErrorEncoding = Encoding.UTF8;
                var process = new Process();
                process.StartInfo = start;
                Interlocked.Exchange(ref coreSocketsReady, 0);
                Interlocked.Exchange(ref coreSocketsReadyDueTicks, 0);
                if (!process.Start())
                    throw new InvalidOperationException("UxPlay process did not start.");
                Log("BLE discovery bound to physical IPv4 " +
                    beaconIpv4 + ".");
                coreProcess = process;
                coreJob = NativeMethods.CreateKillOnCloseJob(process);
                if (coreJob == IntPtr.Zero)
                    throw new InvalidOperationException(
                        "UxPlay could not be isolated in a Windows Job Object.");
                int processId = process.Id;
                Interlocked.Exchange(ref activeCorePid, processId);
                ResetCoreSessionTracking(true);
                ArmIdleDiscoveryRenewalIfAvailable();
                fittedStreamWindow = IntPtr.Zero;
                lock (postSessionMaintenanceSync)
                {
                    coreReadyPending = true;
                    coreReadyChecks = 0;
                    coreReadyDueUtc = DateTime.UtcNow.AddSeconds(2);
                    coreReadinessPid = processId;
                    Interlocked.Exchange(
                        ref coreClientActivityReadyPending, 0);
                }
                string processPinSnapshot = settings.FixedPin;
                process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e)
                {
                    if (!string.IsNullOrWhiteSpace(e.Data))
                    {
                        if (e.Data.IndexOf(
                                "Initialized server socket",
                                StringComparison.OrdinalIgnoreCase) >= 0 &&
                            Interlocked.CompareExchange(
                                ref activeCorePid, 0, 0) == processId)
                        {
                            Interlocked.Exchange(ref coreSocketsReady, 1);
                            Interlocked.Exchange(
                                ref coreSocketsReadyDueTicks,
                                DateTime.UtcNow.AddMilliseconds(1500).Ticks);
                        }
                        ObserveCoreOutput(processId, e.Data);
                        Log("core[" + processId + "]/stdout: " +
                            RedactSensitiveText(e.Data, processPinSnapshot));
                    }
                };
                process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e)
                {
                    if (!string.IsNullOrWhiteSpace(e.Data))
                        Log("core[" + processId + "]/stderr: " +
                            RedactSensitiveText(e.Data, processPinSnapshot));
                };
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                InstallRendererMoveSizeHook(processId);
                startAfterNetworkCheck = false;
                resumeAfterSafeNetwork = false;
                Log("Core started, PID " + coreProcess.Id +
                    "; arguments: " + BuildSafeUxPlayArguments() + ".");
                SetState(true, "Приёмник запускается…");
            }
            catch (Exception ex)
            {
                Log("ERROR starting core: " + ex);
                if (coreProcess != null)
                {
                    try
                    {
                        if (!coreProcess.HasExited)
                            coreProcess.Kill();
                        coreProcess.WaitForExit(1500);
                        CancelCoreOutputReads(coreProcess);
                    }
                    catch { }
                    coreProcess.Dispose();
                    coreProcess = null;
                }
                NativeMethods.CloseHandleSafe(ref coreJob);
                coreReadyPending = false;
                Interlocked.Exchange(ref coreSocketsReady, 0);
                Interlocked.Exchange(ref coreSocketsReadyDueTicks, 0);
                Interlocked.Exchange(ref activeCorePid, 0);
                ResetRendererMoveSizeTracking();
                SetState(false, "Ошибка запуска");
                if (settings.Notify)
                    tray.ShowBalloonTip(
                        5000, AppTitle, ex.Message, ToolTipIcon.Error);
            }
        }

        public void StopCore()
        {
            startAfterNetworkCheck = false;
            Interlocked.Exchange(
                ref discoveryRefreshAfterNetworkCheck, 0);
            resumeAfterSafeNetwork = false;
            restartPending = false;
            ResetCoreSessionTracking(true);
            if (Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1)
            {
                restartAfterStop = false;
                SetState(false, "Приёмник останавливается…");
                return;
            }
            StopCoreInternal("manual stop", true, true);
        }

        private void StopCoreInternal(
            string reason, bool graceful, bool resetRapidExit)
        {
            Process process = coreProcess;
            coreProcess = null;
            Interlocked.Exchange(ref activeCorePid, 0);
            ResetCoreSessionTracking(true);
            IntPtr job = coreJob;
            coreJob = IntPtr.Zero;
            if (resetRapidExit)
            {
                rapidExitCount = 0;
                rapidExitWindowStartedAt = DateTime.MinValue;
            }
            if (process == null)
            {
                SetState(false, "Приёмник остановлен");
                return;
            }
            StopDetachedCore(process, job, reason, graceful);
            fittedStreamWindow = IntPtr.Zero;
            coreReadyPending = false;
            Interlocked.Exchange(ref coreSocketsReady, 0);
            Interlocked.Exchange(ref coreSocketsReadyDueTicks, 0);
            SetState(false, "Приёмник остановлен");
        }

        public void RestartCore()
        {
            ResetRapidExitWindow();
            RestartCore(true);
        }

        private void RestartCore(bool notify)
        {
            ResetSharedAutomaticRecoveryBudget();
            ScheduleRestart("manual restart", notify, 1000);
        }

        private void ScheduleRestart(
            string reason, bool notify, int delayMilliseconds)
        {
            restartPending = false;
            restartReason = reason;
            if (Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1)
            {
                restartAfterStop = true;
                restartDelayAfterStop = delayMilliseconds;
                Log("Updated pending core restart; reason: " + reason + ".");
                return;
            }
            if (IsCoreRunning)
            {
                Process process = coreProcess;
                coreProcess = null;
                Interlocked.Exchange(ref activeCorePid, 0);
                ResetCoreSessionTracking(true);
                IntPtr job = coreJob;
                coreJob = IntPtr.Zero;
                fittedStreamWindow = IntPtr.Zero;
                coreReadyPending = false;
                Interlocked.Exchange(ref coreSocketsReady, 0);
                Interlocked.Exchange(ref coreSocketsReadyDueTicks, 0);
                restartAfterStop = true;
                restartDelayAfterStop = delayMilliseconds;
                restartStopDone.Reset();
                Interlocked.Exchange(ref restartStopInProgress, 1);
                SetState(false, "Приёмник перезапускается…");
                Log("Asynchronous core stop started; reason: " +
                    reason + ".");
                ThreadPool.QueueUserWorkItem(delegate
                {
                    StopDetachedCore(process, job, reason, true);
                    Interlocked.Exchange(ref restartStopCompleted, 1);
                    restartStopDone.Set();
                });
                return;
            }
            restartDueUtc =
                DateTime.UtcNow.AddMilliseconds(delayMilliseconds);
            restartPending = true;
            Log("Core restart scheduled in " + delayMilliseconds +
                " ms; reason: " + reason + ".");
        }

        private static void StopDetachedCore(
            Process process, IntPtr job, string reason, bool graceful)
        {
            IntPtr jobHandle = job;
            try
            {
                Log("Stopping core PID " + process.Id +
                    "; reason: " + reason + "; graceful: " + graceful + ".");
                bool exited = process.HasExited;
                if (!exited && graceful && process.CloseMainWindow())
                    exited = process.WaitForExit(750);
                if (!exited)
                {
                    if (jobHandle != IntPtr.Zero)
                        NativeMethods.TerminateAndCloseJobSafe(ref jobHandle);
                    else
                        process.Kill();
                    exited = process.WaitForExit(2500);
                }
                if (!exited)
                {
                    Log("Core PID " + process.Id +
                        " did not exit after Job Object termination; " +
                        "using the direct process kill fallback.");
                    try { process.Kill(); }
                    catch { }
                    try { exited = process.WaitForExit(1500); }
                    catch { exited = false; }
                }
                CancelCoreOutputReads(process);
                NativeMethods.CloseHandleSafe(ref jobHandle);
                Log("Core stop completed; exited: " + exited + ".");
            }
            catch (Exception ex)
            {
                Log("ERROR stopping core: " + ex.Message);
                NativeMethods.CloseHandleSafe(ref jobHandle);
            }
            finally
            {
                process.Dispose();
            }
        }

        private static void CancelCoreOutputReads(Process process)
        {
            if (process == null)
                return;
            try { process.CancelOutputRead(); }
            catch { }
            try { process.CancelErrorRead(); }
            catch { }
        }

        public void RefreshDiscovery()
        {
            ResetRapidExitWindow();
            ResetSharedAutomaticRecoveryBudget();
            ResetIdleDiscoveryRenewalLimit();
            Log("Manual AirPlay discovery refresh requested.");
            Interlocked.Exchange(
                ref discoveryRefreshAfterNetworkCheck, 1);
            networkUnknownRetries = 0;
            Log("Discovery refresh will re-register AirPlay after the latest " +
                "physical network profile and IPv4 address are confirmed.");
            BeginNetworkProfileRefresh();
        }

        private void ObserveCoreOutput(int processId, string line)
        {
            if (Interlocked.CompareExchange(
                    ref activeCorePid, 0, 0) != processId)
                return;

            if (IsIncomingAirPlayConnectionRequestMarker(line))
                HandleIncomingAirPlayClientActivity(
                    processId, ConnectionRequestGraceSeconds,
                    "AirPlay connection request");
            else if (IsAirPlayPinEntryMarker(line))
                HandleIncomingAirPlayClientActivity(
                    processId, PinEntryGraceSeconds,
                    "AirPlay authentication progress");

            Match chosenDeviceId = Regex.Match(
                line,
                @"\busing (?:system|user-set|randomly-generated) MAC address " +
                    @"([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})\b",
                RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
            if (chosenDeviceId.Success)
                AppSettings.RememberReceiverDeviceId(
                    chosenDeviceId.Groups[1].Value);

            if (line.IndexOf(
                    "raop_rtp_mirror starting mirroring",
                    StringComparison.OrdinalIgnoreCase) >= 0)
            {
                if (HandleMirroringStartedMaintenance(processId))
                {
                    Interlocked.Increment(ref mirrorSessionGeneration);
                    lock (videoSizeSync)
                    {
                        pendingVideoSize = Size.Empty;
                        pendingVideoSizeDueUtc = DateTime.MinValue;
                        pendingVideoSizeGeneration = 0;
                        currentVideoSize = Size.Empty;
                        currentVideoSizeGeneration = 0;
                        deviceFrameVideoSize = Size.Empty;
                        lastSuppressedVideoSize = Size.Empty;
                    }
                }
            }

            if (line.IndexOf(
                    "raop_rtp_mirror->running is no longer true",
                    StringComparison.OrdinalIgnoreCase) >= 0)
            {
                HandleMirroringEndedMaintenance(processId);
            }

            ObserveCoreDiscoveryMarker(processId, line);

            bool lostClient = line.IndexOf(
                "lost connection with client",
                StringComparison.OrdinalIgnoreCase) >= 0;
            bool mirrorReceiveError = line.IndexOf(
                "raop_rtp_mirror error in recv",
                StringComparison.OrdinalIgnoreCase) >= 0;
            if ((lostClient || mirrorReceiveError) && IsMirrorSessionActive)
                ArmLostConnectionRecovery(
                    processId,
                    lostClient ? "lost mirroring client" :
                        "fatal mirror receive error");

            Match videoSize = Regex.Match(
                line,
                @"^AEROMIRROR_VIDEO_SIZE source=(\d+)x(\d+) encoded=(\d+)x(\d+)$",
                RegexOptions.CultureInvariant);
            if (videoSize.Success)
            {
                int width;
                int height;
                if (int.TryParse(videoSize.Groups[3].Value, out width) &&
                    int.TryParse(videoSize.Groups[4].Value, out height) &&
                    width >= 64 && width <= 8192 &&
                    height >= 64 && height <= 8192)
                {
                    lock (videoSizeSync)
                    {
                        pendingVideoSize = new Size(width, height);
                        pendingVideoSizeGeneration =
                            Interlocked.CompareExchange(
                                ref mirrorSessionGeneration, 0, 0);
                        pendingVideoSizeDueUtc =
                            DateTime.UtcNow.AddMilliseconds(350);
                    }
                }
            }

        }

        private static bool IsIncomingAirPlayConnectionRequestMarker(
            string line)
        {
            if (string.IsNullOrWhiteSpace(line))
                return false;
            return line.TrimStart().StartsWith(
                "connection request from ",
                StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsAirPlayPinEntryMarker(string line)
        {
            return !string.IsNullOrWhiteSpace(line) &&
                line.TrimStart().StartsWith(
                    "*** CLIENT MUST NOW ENTER PIN = ",
                    StringComparison.OrdinalIgnoreCase);
        }

        private void HandleIncomingAirPlayClientActivity(
            int processId, int graceSeconds, string evidence)
        {
            bool deferredSettingsPostponed = false;
            DateTime now = DateTime.UtcNow;
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref activeCorePid, 0, 0) != processId)
                    return;
                ResolveCoreReadinessFromClientActivityLocked(
                    evidence);
                CancelCoreDiscoveryRecovery(true);
                Interlocked.Exchange(ref lostConnectionRecoveryPending, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryPid, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryDueTicks, 0);

                Interlocked.Exchange(
                    ref clientActivityGraceDueTicks,
                    now.AddSeconds(graceSeconds).Ticks);

                if (Interlocked.CompareExchange(
                        ref mirrorSessionEndedPending, 0, 0) == 1)
                {
                    if (IsSettingsRestartDeferred)
                    {
                        Interlocked.Exchange(
                            ref mirrorSessionEndedDueTicks,
                            now.AddSeconds(graceSeconds).Ticks);
                        deferredSettingsPostponed = true;
                    }
                    else
                    {
                        Interlocked.Exchange(
                            ref mirrorSessionEndedPending, 0);
                        Interlocked.Exchange(
                            ref mirrorSessionEndedDueTicks, 0);
                    }
                }

                Interlocked.Exchange(ref idleDiscoveryRenewalUsed, 0);
                Interlocked.Exchange(
                    ref idleDiscoveryRenewalDueTicks,
                    now.AddMinutes(10).Ticks);
            }

            Log("Incoming AirPlay client activity observed; " +
                (deferredSettingsPostponed
                    ? "the deferred settings restart received a new " +
                        graceSeconds + "-second grace period"
                    : "no post-session settings restart was pending") +
                ", and one bounded idle discovery fallback was re-armed " +
                "for ten minutes.");
        }

        private bool HandleMirroringStartedMaintenance(int processId)
        {
            bool canceledDeferredRestart;
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref activeCorePid, 0, 0) != processId)
                    return false;
                ResolveCoreReadinessFromClientActivityLocked(
                    "mirroring start");
                CancelCoreDiscoveryRecovery(true);
                Interlocked.Exchange(ref lostConnectionRecoveryPending, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryPid, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryDueTicks, 0);
                Interlocked.Exchange(ref clientActivityGraceDueTicks, 0);
                Interlocked.Exchange(ref mirrorSessionActive, 1);
                canceledDeferredRestart = Interlocked.Exchange(
                    ref mirrorSessionEndedPending, 0) == 1;
                Interlocked.Exchange(ref mirrorSessionEndedDueTicks, 0);
                Interlocked.Exchange(ref idleDiscoveryRenewalUsed, 0);
                Interlocked.Exchange(
                    ref idleDiscoveryRenewalDueTicks,
                    DateTime.UtcNow.AddMinutes(10).Ticks);
            }
            if (canceledDeferredRestart)
                Log("Mirroring started; pending post-session settings " +
                    "maintenance was canceled and remains deferred until " +
                    "this session ends.");
            return true;
        }

        private void ResolveCoreReadinessFromClientActivityLocked(
            string evidence)
        {
            if (!coreReadyPending && coreReadinessRecoveryAttempts == 0)
                return;
            coreReadyPending = false;
            coreReadyChecks = 0;
            coreReadyDueUtc = DateTime.MinValue;
            coreReadinessRecoveryAttempts = 0;
            coreReadinessPid = 0;
            Interlocked.Exchange(ref coreClientActivityReadyPending, 1);
            Log("Core readiness was confirmed by " + evidence +
                "; automatic readiness recovery was canceled.");
        }

        private void HandleMirroringEndedMaintenance(int processId)
        {
            string message = "";
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref activeCorePid, 0, 0) != processId)
                    return;
                bool abnormalLossRecoveryPending =
                    Interlocked.CompareExchange(
                        ref lostConnectionRecoveryPending, 0, 0) == 1 &&
                    Interlocked.CompareExchange(
                        ref lostConnectionRecoveryPid, 0, 0) == processId;
                if (!abnormalLossRecoveryPending)
                {
                    Interlocked.Exchange(
                        ref lostConnectionRecoveryPending, 0);
                    Interlocked.Exchange(ref lostConnectionRecoveryPid, 0);
                    Interlocked.Exchange(ref lostConnectionRecoveryDueTicks, 0);
                }
                if (Interlocked.Exchange(ref mirrorSessionActive, 0) != 1)
                    return;

                DateTime now = DateTime.UtcNow;
                long reconnectGraceDueTicks = Interlocked.Read(
                    ref clientActivityGraceDueTicks);
                if (reconnectGraceDueTicks <= now.Ticks)
                {
                    reconnectGraceDueTicks = 0;
                    Interlocked.Exchange(ref clientActivityGraceDueTicks, 0);
                }
                if (Interlocked.CompareExchange(
                        ref idleDiscoveryRenewalUsed, 0, 0) == 0)
                {
                    Interlocked.Exchange(
                        ref idleDiscoveryRenewalDueTicks,
                        now.AddMinutes(10).Ticks);
                }
                if (IsSettingsRestartDeferred)
                {
                    Interlocked.Exchange(
                        ref mirrorSessionEndedDueTicks,
                        Math.Max(
                            now.AddSeconds(5).Ticks,
                            reconnectGraceDueTicks));
                    Interlocked.Exchange(ref mirrorSessionEndedPending, 1);
                    message = "Mirroring session cleanup completed; saved " +
                        "receiver settings will be applied after the active " +
                        "reconnect grace period.";
                }
                else
                {
                    Interlocked.Exchange(ref mirrorSessionEndedPending, 0);
                    Interlocked.Exchange(ref mirrorSessionEndedDueTicks, 0);
                    message = abnormalLossRecoveryPending
                        ? "Mirroring session cleanup completed after an abnormal " +
                            "client loss; one bounded discovery renewal remains " +
                            "armed."
                        : "Mirroring session cleanup completed; the receiver " +
                            "stays running and no post-session restart was " +
                            "scheduled. The bounded ten-minute idle discovery " +
                            "fallback remains armed.";
                }
            }
            Log(message);
        }

        private void ObserveCoreDiscoveryMarker(int processId, string line)
        {
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref activeCorePid, 0, 0) != processId)
                    return;
                bool discoveryReady = false;
                bool discoveryDegraded = false;
                if (line.IndexOf(
                        "AEROMIRROR_DNSSD_READY",
                        StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    Interlocked.Exchange(ref coreDnsSdStatus, 1);
                    discoveryReady = true;
                }
                else if (line.IndexOf(
                        "AEROMIRROR_DNSSD_DEGRADED",
                        StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    Interlocked.Exchange(ref coreDnsSdStatus, -1);
                    discoveryDegraded = true;
                }

                bool bleMarkerLine = line.IndexOf(
                        "AEROMIRROR_BLE",
                        StringComparison.OrdinalIgnoreCase) >= 0 ||
                    line.IndexOf(
                        "[beacon]",
                        StringComparison.OrdinalIgnoreCase) >= 0;
                if (bleMarkerLine)
                {
                    if (line.IndexOf(
                            "Advertising started",
                            StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        Interlocked.Exchange(ref coreBleStatus, 1);
                        discoveryReady = true;
                    }
                    else if (line.IndexOf(
                                "Advertising failed",
                                StringComparison.OrdinalIgnoreCase) >= 0 ||
                             line.IndexOf(
                                "Failed to start",
                                StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        Interlocked.Exchange(ref coreBleStatus, -1);
                        discoveryDegraded = true;
                    }
                }

                if (discoveryReady)
                {
                    CancelCoreDiscoveryRecovery(true);
                    return;
                }

                if (discoveryDegraded)
                    ArmCoreDiscoveryRecovery(processId);
            }
        }

        private void ArmCoreDiscoveryRecovery(int processId)
        {
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref activeCorePid, 0, 0) != processId ||
                    Interlocked.CompareExchange(
                        ref coreDnsSdStatus, 0, 0) != -1 ||
                    Interlocked.CompareExchange(
                        ref coreBleStatus, 0, 0) != -1 ||
                    Interlocked.CompareExchange(
                        ref coreDiscoveryRecoveryPending, 2, 0) != 0)
                    return;

                Interlocked.Exchange(
                    ref coreDiscoveryRecoveryPid, processId);
                Interlocked.Exchange(
                    ref coreDiscoveryRecoveryDueTicks,
                    DateTime.UtcNow.AddSeconds(5).Ticks);
                Interlocked.Exchange(ref coreDiscoveryRecoveryPending, 1);
                Log("Both native discovery registrations reported a failure; " +
                    "waiting five seconds before bounded host recovery.");
            }
        }

        private void CancelCoreDiscoveryRecovery(bool resetAttempts)
        {
            lock (postSessionMaintenanceSync)
            {
                Interlocked.Exchange(ref coreDiscoveryRecoveryPending, 0);
                Interlocked.Exchange(ref coreDiscoveryRecoveryPid, 0);
                Interlocked.Exchange(ref coreDiscoveryRecoveryDueTicks, 0);
                if (resetAttempts)
                    Interlocked.Exchange(ref coreDiscoveryRecoveryAttempts, 0);
            }
        }

        private bool ConsumeSharedAutomaticRecoveryBudget(
            bool readinessRecovery)
        {
            lock (postSessionMaintenanceSync)
            {
                bool available = coreReadinessRecoveryAttempts < 1 &&
                    Interlocked.CompareExchange(
                        ref coreDiscoveryRecoveryAttempts, 0, 0) < 1;
                coreReadinessRecoveryAttempts = 1;
                Interlocked.Exchange(ref coreDiscoveryRecoveryAttempts, 1);
                coreReadyPending = false;
                coreReadyChecks = 0;
                coreReadyDueUtc = DateTime.MinValue;
                coreReadinessPid = 0;
                if (readinessRecovery)
                {
                    CancelCoreDiscoveryRecovery(false);
                }
                return available;
            }
        }

        private void ResetSharedAutomaticRecoveryBudget()
        {
            lock (postSessionMaintenanceSync)
            {
                coreReadinessRecoveryAttempts = 0;
                Interlocked.Exchange(ref coreDiscoveryRecoveryAttempts, 0);
            }
        }

        private void ArmLostConnectionRecovery(int processId, string marker)
        {
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref activeCorePid, 0, 0) != processId ||
                    !IsMirrorSessionActive ||
                    (Interlocked.Read(ref clientActivityGraceDueTicks) >
                        DateTime.UtcNow.Ticks) ||
                    Interlocked.CompareExchange(
                        ref lostConnectionRecoveryPending, 2, 0) != 0)
                    return;
                Interlocked.Exchange(ref lostConnectionRecoveryPid, processId);
                Interlocked.Exchange(
                    ref lostConnectionRecoveryDueTicks,
                    DateTime.UtcNow.AddSeconds(3).Ticks);
                Interlocked.Exchange(ref lostConnectionRecoveryPending, 1);
                Log("UxPlay reported a " + marker + "; waiting three seconds " +
                    "for its internal reset before host recovery.");
            }
        }

        private void ResetCoreSessionTracking(bool clearDeferredRestart)
        {
            ResetRendererMoveSizeTracking();
            lock (postSessionMaintenanceSync)
            {
                Interlocked.Exchange(ref mirrorSessionActive, 0);
                Interlocked.Exchange(ref mirrorSessionEndedPending, 0);
                Interlocked.Exchange(ref mirrorSessionEndedDueTicks, 0);
                Interlocked.Exchange(ref idleDiscoveryRenewalDueTicks, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryPending, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryPid, 0);
                Interlocked.Exchange(ref lostConnectionRecoveryDueTicks, 0);
                Interlocked.Exchange(ref coreClientActivityReadyPending, 0);
                Interlocked.Exchange(ref clientActivityGraceDueTicks, 0);
                Interlocked.Exchange(ref physicalNetworkRestartDeferred, 0);
                coreReadinessPid = 0;
                if (clearDeferredRestart)
                    Interlocked.Exchange(ref settingsRestartDeferred, 0);
            }
            Interlocked.Exchange(ref coreDnsSdStatus, 0);
            Interlocked.Exchange(ref coreBleStatus, 0);
            CancelCoreDiscoveryRecovery(false);
            lock (videoSizeSync)
            {
                pendingVideoSize = Size.Empty;
                pendingVideoSizeDueUtc = DateTime.MinValue;
                pendingVideoSizeGeneration = 0;
                currentVideoSize = Size.Empty;
                currentVideoSizeGeneration = 0;
                deviceFrameVideoSize = Size.Empty;
                lastSuppressedVideoSize = Size.Empty;
            }
            Interlocked.Exchange(ref mirrorSessionGeneration, 0);
            videoSizeWindow = IntPtr.Zero;
            initialFitPendingWindow = IntPtr.Zero;
            exactVideoSizeFitGeneration = -1;
            appliedVideoOrientation = 0;
        }

        private void ResetIdleDiscoveryRenewalLimit()
        {
            lock (postSessionMaintenanceSync)
            {
                Interlocked.Exchange(ref idleDiscoveryRenewalUsed, 0);
                Interlocked.Exchange(
                    ref idleDiscoveryRenewalDueTicks,
                    IsCoreRunning
                        ? DateTime.UtcNow.AddMinutes(10).Ticks
                        : 0);
            }
        }

        private void ArmIdleDiscoveryRenewalIfAvailable()
        {
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref idleDiscoveryRenewalUsed, 0, 0) != 0)
                {
                    Interlocked.Exchange(ref idleDiscoveryRenewalDueTicks, 0);
                    return;
                }
                Interlocked.Exchange(
                    ref idleDiscoveryRenewalDueTicks,
                    DateTime.UtcNow.AddMinutes(10).Ticks);
            }
        }

        private static bool ShouldDeferDisruptiveMaintenance(
            bool mirrorActive, long clientGraceDueTicks, long nowTicks)
        {
            return mirrorActive ||
                (clientGraceDueTicks > 0 && nowTicks < clientGraceDueTicks);
        }

        private void HandlePhysicalNetworkChangeMaintenance()
        {
            lock (postSessionMaintenanceSync)
            {
                if (!IsCoreRunning)
                    return;
                long nowTicks = DateTime.UtcNow.Ticks;
                if (ShouldDeferDisruptiveMaintenance(
                        IsMirrorSessionActive,
                        Interlocked.Read(ref clientActivityGraceDueTicks),
                        nowTicks))
                {
                    Interlocked.Exchange(
                        ref physicalNetworkRestartDeferred, 1);
                    Log("Physical network changed during AirPlay client " +
                        "activity; receiver restart was deferred until the " +
                        "session or connection grace ends.");
                    return;
                }

                Interlocked.Exchange(ref physicalNetworkRestartDeferred, 0);
                ScheduleRestart("physical network changed", false, 1200);
            }
        }

        private void HandleAutomaticDiscoveryMaintenance()
        {
            if (!IsCoreRunning || coreReadyPending || restartPending ||
                Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1)
                return;

            lock (postSessionMaintenanceSync)
            {
                if (!IsCoreRunning || coreReadyPending || restartPending ||
                    Interlocked.CompareExchange(
                        ref restartStopInProgress, 0, 0) == 1)
                    return;

                DateTime now = DateTime.UtcNow;
                if (Interlocked.CompareExchange(
                        ref physicalNetworkRestartDeferred, 0, 0) == 1)
                {
                    if (ShouldDeferDisruptiveMaintenance(
                            IsMirrorSessionActive,
                            Interlocked.Read(ref clientActivityGraceDueTicks),
                            now.Ticks))
                        return;
                    Interlocked.Exchange(
                        ref physicalNetworkRestartDeferred, 0);
                    Log("AirPlay client activity ended; applying the deferred " +
                        "physical-network receiver restart.");
                    ScheduleRestart(
                        "deferred physical network change", false, 1200);
                    return;
                }

                if (Interlocked.CompareExchange(
                        ref mirrorSessionEndedPending, 0, 0) == 1)
                {
                    long dueTicks = Interlocked.Read(
                        ref mirrorSessionEndedDueTicks);
                    if (dueTicks > 0 && now.Ticks >= dueTicks &&
                        !IsMirrorSessionActive)
                    {
                        Interlocked.Exchange(
                            ref mirrorSessionEndedPending, 0);
                        Interlocked.Exchange(
                            ref mirrorSessionEndedDueTicks, 0);
                        if (IsSettingsRestartDeferred)
                        {
                            Log("Current mirroring session ended; applying " +
                                "the saved receiver settings.");
                            lastAutomaticDiscoveryRefreshUtc = now;
                            ScheduleRestart(
                                "deferred settings change", false, 1000);
                            return;
                        }

                        Log("Post-session maintenance elapsed without deferred " +
                            "settings; keeping the healthy receiver running.");
                    }
                }

                long idleDueTicks = Interlocked.Read(
                    ref idleDiscoveryRenewalDueTicks);
                if (idleDueTicks <= 0 || now.Ticks < idleDueTicks ||
                    IsMirrorSessionActive ||
                    Interlocked.CompareExchange(
                        ref idleDiscoveryRenewalUsed, 0, 0) != 0)
                    return;

                if ((now - lastAutomaticDiscoveryRefreshUtc).TotalMinutes < 2)
                {
                    Interlocked.Exchange(
                        ref idleDiscoveryRenewalDueTicks,
                        now.AddMinutes(10).Ticks);
                    return;
                }

                Interlocked.Exchange(ref idleDiscoveryRenewalUsed, 1);
                Interlocked.Exchange(
                    ref idleDiscoveryRenewalDueTicks, 0);
                Log("Renewing idle AirPlay discovery after ten minutes without " +
                    "a mirroring session.");
                lastAutomaticDiscoveryRefreshUtc = now;
                ScheduleRestart("idle discovery renewal", false, 1200);
            }
        }

        private void HandleLostConnectionRecovery()
        {
            if (Interlocked.CompareExchange(
                    ref lostConnectionRecoveryPending, 0, 0) != 1)
                return;
            lock (postSessionMaintenanceSync)
            {
                bool restartBusy = restartPending ||
                    Interlocked.CompareExchange(
                        ref restartStopInProgress, 0, 0) == 1;
                LostConnectionRecoveryAction action =
                    ConsumeDueLostConnectionRecoveryLocked(
                        DateTime.UtcNow, IsCoreRunning, restartBusy);
                if (action == LostConnectionRecoveryAction.RestartStalledSession)
                {
                    Log("UxPlay did not finish its internal lost-client reset " +
                        "within three seconds; restarting the receiver process.");
                    ScheduleRestart(
                        "stalled mirror after lost client", false, 500);
                }
                else if (action == LostConnectionRecoveryAction.RenewDiscovery)
                {
                    Log("UxPlay completed its lost-client cleanup; performing " +
                        "one bounded AirPlay discovery renewal.");
                    lastAutomaticDiscoveryRefreshUtc = DateTime.UtcNow;
                    ScheduleRestart(
                        "lost-client discovery renewal", false, 500);
                }
            }
        }

        private LostConnectionRecoveryAction
            ConsumeDueLostConnectionRecoveryLocked(
                DateTime now, bool coreRunning, bool restartBusy)
        {
            if (Interlocked.CompareExchange(
                    ref lostConnectionRecoveryPending, 0, 0) != 1)
                return LostConnectionRecoveryAction.None;

            long dueTicks = Interlocked.Read(
                ref lostConnectionRecoveryDueTicks);
            if (dueTicks <= 0 || now.Ticks < dueTicks)
                return LostConnectionRecoveryAction.None;

            int recoveryPid = Interlocked.CompareExchange(
                ref lostConnectionRecoveryPid, 0, 0);
            bool sameRunningCore = coreRunning && recoveryPid > 0 &&
                Interlocked.CompareExchange(ref activeCorePid, 0, 0) ==
                    recoveryPid;
            bool mirrorActive = IsMirrorSessionActive;

            Interlocked.Exchange(ref lostConnectionRecoveryPending, 0);
            Interlocked.Exchange(ref lostConnectionRecoveryPid, 0);
            Interlocked.Exchange(ref lostConnectionRecoveryDueTicks, 0);

            if (!sameRunningCore || restartBusy)
                return LostConnectionRecoveryAction.None;
            return mirrorActive
                ? LostConnectionRecoveryAction.RestartStalledSession
                : LostConnectionRecoveryAction.RenewDiscovery;
        }

        private void HandleCoreDiscoveryRecovery()
        {
            if (Interlocked.CompareExchange(
                    ref coreDiscoveryRecoveryPending, 0, 0) != 1)
                return;
            lock (postSessionMaintenanceSync)
            {
                if (Interlocked.CompareExchange(
                        ref coreDiscoveryRecoveryPending, 0, 0) != 1)
                    return;
                long dueTicks = Interlocked.Read(
                    ref coreDiscoveryRecoveryDueTicks);
                if (dueTicks <= 0 || DateTime.UtcNow.Ticks < dueTicks)
                    return;

                if (coreReadyPending || IsMirrorSessionActive)
                {
                    Interlocked.Exchange(
                        ref coreDiscoveryRecoveryDueTicks,
                        DateTime.UtcNow.AddSeconds(10).Ticks);
                    return;
                }
                if (restartPending || Interlocked.CompareExchange(
                        ref restartStopInProgress, 0, 0) == 1)
                    return;
                if (Interlocked.CompareExchange(
                        ref coreDiscoveryRecoveryPending, 2, 1) != 1)
                    return;

                int recoveryPid = Interlocked.CompareExchange(
                    ref coreDiscoveryRecoveryPid, 0, 0);
                bool stillFailed =
                    Interlocked.CompareExchange(
                        ref coreDnsSdStatus, 0, 0) == -1 &&
                    Interlocked.CompareExchange(
                        ref coreBleStatus, 0, 0) == -1;
                bool sameRunningCore = IsCoreRunning && recoveryPid > 0 &&
                    Interlocked.CompareExchange(ref activeCorePid, 0, 0) ==
                        recoveryPid;
                bool socketsReady = Interlocked.CompareExchange(
                    ref coreSocketsReady, 0, 0) == 1;
                if (!sameRunningCore || !stillFailed || !socketsReady)
                {
                    CancelCoreDiscoveryRecovery(false);
                    return;
                }

                bool recoveryAvailable =
                    ConsumeSharedAutomaticRecoveryBudget(false);
                CancelCoreDiscoveryRecovery(false);
                if (recoveryAvailable)
                {
                    Log("DNS-SD and BLE discovery both remained degraded; " +
                        "performing the single shared automatic recovery.");
                    ScheduleRestart(
                        "native discovery registration recovery", false, 1200);
                    return;
                }

                Log("DNS-SD and BLE discovery remain degraded after the shared " +
                    "automatic recovery budget was consumed. The socket-ready " +
                    "receiver stays running; no automatic restart loop will " +
                    "be started.");
            }
        }

        private void ResetRapidExitWindow()
        {
            rapidExitCount = 0;
            rapidExitWindowStartedAt = DateTime.MinValue;
        }

        public void QuitApplication()
        {
            Quit();
        }

        public string BuildUxPlayArguments()
        {
            var parts = new List<string>();
            string name = string.IsNullOrWhiteSpace(settings.ReceiverName)
                ? Environment.MachineName : settings.ReceiverName.Trim();
            parts.Add("-n");
            parts.Add(QuoteArgument(name));
            parts.Add("-nh");
            string receiverDeviceId = AppSettings.GetSavedReceiverDeviceId();
            if (receiverDeviceId.Length > 0)
            {
                parts.Add("-m");
                parts.Add(receiverDeviceId);
            }
            parts.Add("-key");
            parts.Add(QuoteArgument(AppSettings.ReceiverKeyPath));

            if (settings.PairingMode == "pin")
            {
                if (settings.FixedPin.Length == 4)
                    parts.Add("-pin " + settings.FixedPin);
                else
                    parts.Add("-pin");
                parts.Add("-reg");
                parts.Add(QuoteArgument(AppSettings.TrustedClientsPath));
            }
            else if (settings.PairingMode == "password")
            {
                parts.Add("-pw");
            }

            if (settings.QualityPreset == "720p30")
            {
                parts.Add("-s 1280x720@60");
                parts.Add("-fps 30");
            }
            else if (settings.QualityPreset == "1080p30")
            {
                parts.Add("-s 1920x1080@60");
                parts.Add("-fps 30");
            }
            else if (settings.QualityPreset == "4k60")
            {
                parts.Add("-h265");
                parts.Add("-s 3840x2160@60");
                parts.Add("-fps 60");
            }
            else
            {
                parts.Add("-s 1920x1080@60");
                parts.Add("-fps 60");
            }

            if (settings.Renderer == "d3d11")
                parts.Add("-vs d3d11videosink");
            else if (settings.Renderer == "d3d12")
                parts.Add("-vs d3d12videosink");

            if (settings.LatencyProfile == "low")
            {
                parts.Add("-vsync no");
                parts.Add("-al 0.05");
            }
            else if (settings.LatencyProfile == "stable")
            {
                parts.Add("-al 0.35");
            }

            if (settings.AudioOutput == "mute")
                parts.Add("-a");

            parts.Add("-reset 6");
            if (!string.IsNullOrWhiteSpace(settings.AdvancedArguments))
                parts.Add(settings.AdvancedArguments.Trim());
            return string.Join(" ", parts.ToArray());
        }

        public string BuildSafeUxPlayArguments()
        {
            return MaskSecrets(BuildUxPlayArguments());
        }

        private string MaskSecrets(string text)
        {
            return RedactSensitiveText(text, settings.FixedPin);
        }

        private static int CountAddresses(string addresses)
        {
            if (string.IsNullOrWhiteSpace(addresses))
                return 0;
            return addresses.Split(new[] { ',' },
                StringSplitOptions.RemoveEmptyEntries).Length;
        }

        private static string FirstNumericIpv4(string addresses)
        {
            if (string.IsNullOrWhiteSpace(addresses))
                return "";
            foreach (string candidate in addresses.Split(new[] { ',' },
                StringSplitOptions.RemoveEmptyEntries))
            {
                IPAddress parsed;
                string value = candidate.Trim();
                if (IPAddress.TryParse(value, out parsed) &&
                    parsed.GetAddressBytes().Length == 4 &&
                    !IPAddress.IsLoopback(parsed))
                    return value;
            }
            return "";
        }

        private static string RedactSensitiveText(
            string text, string knownPin)
        {
            string safe = text ?? "";
            if (!string.IsNullOrWhiteSpace(knownPin))
                safe = safe.Replace(knownPin, "****");
            safe = Regex.Replace(
                safe,
                @"(?i)(-{1,2}pin(?:[ \t]+|[=:][ \t]*))[""']?\d{4,}[""']?",
                "$1****");
            safe = Regex.Replace(
                safe,
                @"(?i)(-{1,2}(?:pw|password|passcode|token|secret)(?:[ \t]+|[=:][ \t]*))(?:""[^""]*""|'[^']*'|(?!-)[^\s,;\]]+)",
                "$1****");
            safe = Regex.Replace(
                safe,
                @"(?i)\b(pin|password|passcode|token|secret)[ \t]*[:=][ \t]*(?:""[^""]*""|'[^']*'|[^\s,;\]]+)",
                "$1: ****");
            safe = Regex.Replace(
                safe,
                @"(?i)\b(password|passcode|token|secret)[ \t]+(?:""[^""]*""|'[^']*'|(?!-)[^\s,;\]]+)",
                "$1 ****");
            safe = Regex.Replace(
                safe,
                @"(?i)\b(?:[0-9a-f]{2}:){5}[0-9a-f]{2}\b",
                "**:**:**:**:**:**");
            safe = Regex.Replace(
                safe,
                @"(?is)-----BEGIN [^-]*(?:PRIVATE KEY|SECRET)[^-]*-----.*?-----END [^-]*(?:PRIVATE KEY|SECRET)[^-]*-----",
                "[redacted cryptographic material]");
            safe = Regex.Replace(
                safe,
                @"(?i)\b((?:(?:aes|ecdh|session|shared|private|stream|fairplay)[\w -]{0,24})?(?:key|secret|iv))\s*[:=]\s*(?:[0-9a-f]{2}[\s:,-]?){8,}",
                "$1: [redacted cryptographic material]");
            safe = Regex.Replace(
                safe,
                @"(?im)(Physical network profile:\s+\w+\s+\()(?!physical interface )([^,\r\n]+)(,\s*)",
                "$1[redacted network]$3");
            string localData = Environment.GetFolderPath(
                Environment.SpecialFolder.LocalApplicationData);
            string roamingData = Environment.GetFolderPath(
                Environment.SpecialFolder.ApplicationData);
            string profile = Environment.GetFolderPath(
                Environment.SpecialFolder.UserProfile);
            if (!string.IsNullOrWhiteSpace(localData))
                safe = safe.Replace(localData, "%LOCALAPPDATA%");
            if (!string.IsNullOrWhiteSpace(roamingData))
                safe = safe.Replace(roamingData, "%APPDATA%");
            if (!string.IsNullOrWhiteSpace(profile))
                safe = safe.Replace(profile, "%USERPROFILE%");
            return safe;
        }

        private static string RedactSupportText(
            string text, string knownPin)
        {
            string safe = RedactSensitiveText(text, knownPin);
            safe = Regex.Replace(
                safe,
                @"\b(?:\d{1,3}\.){3}\d{1,3}\b",
                "[redacted IP]");
            safe = Regex.Replace(
                safe,
                @"(?i)(?<![0-9a-f:])(?:(?:[0-9a-f]{1,4}:){3,}[0-9a-f:]*|[0-9a-f:]*::[0-9a-f:]*)(?![0-9a-f:])",
                "[redacted IP]");
            safe = Regex.Replace(
                safe,
                @"(?im)^(\s*(?:Имя приёмника|Receiver name)\s*:\s*).*$",
                "$1[redacted]");
            safe = Regex.Replace(
                safe,
                @"(?i)(-{1,2}n\s+)(?:""[^""]*""|'[^']*'|[^\s]+)",
                "$1\"[redacted]\"");
            safe = Regex.Replace(
                safe,
                @"(?i)(connection request from\s+).*?(\s+\([^)\r\n]+\))",
                "$1[redacted device]$2");
            safe = Regex.Replace(
                safe,
                @"(?im)^(\s*Физическая сеть:\s+\S+\s+·\s+).*$",
                "$1[redacted network]");
            return safe;
        }
        private static void SanitizeExistingLogs(string knownPin)
        {
            string[] paths =
            {
                AppSettings.LogPath,
                AppSettings.LogPath + ".1"
            };
            foreach (string path in paths)
            {
                try
                {
                    if (!File.Exists(path) ||
                        new FileInfo(path).Length > 50L * 1024L * 1024L)
                        continue;
                    string original = File.ReadAllText(path, Encoding.UTF8);
                    string sanitized =
                        RedactSensitiveText(original, knownPin);
                    if (!string.Equals(
                            original, sanitized, StringComparison.Ordinal))
                    {
                        File.WriteAllText(
                            path, sanitized, new UTF8Encoding(false));
                    }
                }
                catch { }
            }
        }

        public string GetDiagnostics()
        {
            var text = new StringBuilder();
            text.AppendLine("AeroMirror — диагностика");
            text.AppendLine("Время: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            text.AppendLine();
            text.AppendLine("Оболочка: " + AppVersion.Display);
            text.AppendLine("Windows: " + Environment.OSVersion);
            text.AppendLine("64-bit процесс: " + Environment.Is64BitProcess);
            text.AppendLine("Ядро: " + (File.Exists(CorePath) ? "найдено" : "НЕ НАЙДЕНО"));
            text.AppendLine("Путь ядра: " + MaskSecrets(CorePath));
            text.AppendLine("Процесс ядра: " + (IsCoreRunning ? "работает, PID " + coreProcess.Id : "остановлен"));
            bool coreRunningSnapshot = IsCoreRunning;
            text.AppendLine("Runtime state: coreReady=" +
                (coreRunningSnapshot && !coreReadyPending) +
                "; socketsReady=" +
                (Interlocked.CompareExchange(
                    ref coreSocketsReady, 0, 0) == 1) +
                "; mirrorActive=" + IsMirrorSessionActive +
                "; lostRecovery=" +
                (Interlocked.CompareExchange(
                    ref lostConnectionRecoveryPending, 0, 0) == 1) +
                "; restartPending=" + restartPending +
                "; stopPending=" +
                (Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1) +
                "; networkWait=" + IsWaitingForNetwork + ".");
            text.AppendLine("Discovery registration: DNS-SD=" +
                DiscoveryMarkerStatus(
                    Interlocked.CompareExchange(
                        ref coreDnsSdStatus, 0, 0),
                    "degraded") +
                "; BLE=" +
                DiscoveryMarkerStatus(
                    Interlocked.CompareExchange(
                        ref coreBleStatus, 0, 0),
                    "failed") +
                "; recoveryPending=" +
                (Interlocked.CompareExchange(
                    ref coreDiscoveryRecoveryPending, 0, 0) == 1) +
                "; recoveryAttempts=" +
                Interlocked.CompareExchange(
                    ref coreDiscoveryRecoveryAttempts, 0, 0) + ".");
            text.AppendLine("Bonjour Service: " + GetBonjourStatus());
            text.AppendLine("Автозапуск: " + (IsAutostartEnabled() ? "включён" : "выключен"));
            text.AppendLine("Запуск в трее: " + (settings.StartMinimized ? "включён" : "выключен"));
            text.AppendLine("Кнопка ×: " + (settings.CloseToTray ? "свернуть в трей" : "закрыть приложение"));
            text.AppendLine("Физическая сеть: " +
                (networkProfileKnown ? (publicNetwork ? "публичная" : "частная") : "не определена") +
                " · " + networkProfileName + " · " + networkInterfaceName);
            text.AppendLine("VPN/виртуальные сетевые профили: " +
                nonPhysicalProfileCount +
                " (публичных: " + publicNonPhysicalProfileCount + ")");
            text.AppendLine("Защита подключения: " + settings.PairingMode);
            text.AppendLine("Имя приёмника: " + settings.ReceiverName);
            text.AppendLine("Запрашиваемое качество: " + settings.QualityPreset);
            text.AppendLine("Профиль задержки: " + settings.LatencyProfile);
            text.AppendLine("Вывод звука: " + settings.AudioOutput);
            text.AppendLine("Аргументы UxPlay: " + BuildSafeUxPlayArguments());
            text.AppendLine("Файл настроек: " +
                MaskSecrets(AppSettings.FilePath));
            text.AppendLine("Журнал: " + MaskSecrets(AppSettings.LogPath));
            text.AppendLine();
            string sourceVersion = AppVersion.Display;
            text.AppendLine("Исходники AeroMirror " + sourceVersion + ":");
            text.AppendLine(
                "https://github.com/Nadejny/aeromirror/tree/v" +
                sourceVersion);
            text.AppendLine("Исходники изменённого GPL-ядра:");
            text.AppendLine(
                "https://github.com/Nadejny/aeromirror/releases/download/v" +
                sourceVersion + "/AeroMirror-native-source-" +
                sourceVersion + ".zip");
            text.AppendLine("Неизменённый runtime загружается с:");
            text.AppendLine(
                "https://github.com/leapbtw/uxplay-windows/releases/tag/2.0.0.1736");
            text.AppendLine();
            text.AppendLine("Для обнаружения iPhone и компьютер должны быть в одной локальной сети.");
            text.AppendLine("При первом запуске разрешите сетевой доступ в Windows Firewall.");
            text.AppendLine("Если устройство не видно, перезапустите Bonjour Service и приёмник.");
            return text.ToString();
        }

        private static string DiscoveryMarkerStatus(
            int status, string negativeStatus)
        {
            if (status > 0)
                return "ready";
            if (status < 0)
                return negativeStatus;
            return "unknown";
        }

        private static bool IsCoreReadinessConfirmed(
            bool socketsReady, bool bonjourRunning,
            int dnsSdStatus, int bleStatus)
        {
            bool bothDiscoveryPathsFailed =
                dnsSdStatus < 0 && bleStatus < 0;
            return socketsReady && !bothDiscoveryPathsFailed &&
                (bonjourRunning || dnsSdStatus == 1 || bleStatus == 1);
        }

        private void OnStartStop(object sender, EventArgs e)
        {
            if (IsCoreRunning) StopCore(); else StartCore();
        }

        private void OnAutostart(object sender, EventArgs e)
        {
            settings.AutoStartWindows = !IsAutostartEnabled();
            settings.Save();
            ApplyAutostart(settings.AutoStartWindows);
            autoStartItem.Checked = IsAutostartEnabled();
        }

        private void OnAlwaysOnTop(object sender, EventArgs e)
        {
            settings.AlwaysOnTop = !settings.AlwaysOnTop;
            settings.Save();
            topMostItem.Checked = settings.AlwaysOnTop;
            ApplyTopMost();
        }

        private void MonitorCore()
        {
            if (showEvent.WaitOne(0))
                ShowSettings();

            NetworkProfileInfo refreshedProfile = null;
            lock (networkProfileSync)
            {
                if (pendingNetworkProfile != null)
                {
                    refreshedProfile = pendingNetworkProfile;
                    pendingNetworkProfile = null;
                }
            }
            if (refreshedProfile != null)
            {
                bool networkChanged = ApplyNetworkProfile(
                    refreshedProfile, true);
                if (networkChanged && IsCoreRunning)
                {
                    HandlePhysicalNetworkChangeMaintenance();
                }
            }

            if (Interlocked.CompareExchange(ref networkRefreshPending, 0, 0) == 1 &&
                DateTime.UtcNow.Ticks >= Interlocked.Read(ref networkRefreshDueTicks))
            {
                Interlocked.Exchange(ref networkRefreshPending, 0);
                Log("Network event debounce elapsed; checking physical profile.");
                BeginNetworkProfileRefresh();
            }

            if (Interlocked.Exchange(ref restartStopCompleted, 0) == 1)
            {
                Interlocked.Exchange(ref restartStopInProgress, 0);
                if (restartAfterStop && !quitting)
                {
                    restartAfterStop = false;
                    restartDueUtc = DateTime.UtcNow.AddMilliseconds(
                        restartDelayAfterStop);
                    restartPending = true;
                    Log("Core stop settled; restart will run in " +
                        restartDelayAfterStop + " ms.");
                }
                else
                {
                    restartAfterStop = false;
                    SetState(false, "Приёмник остановлен");
                }
            }

            HandleExitedCore();

            if (Interlocked.Exchange(
                    ref coreClientActivityReadyPending, 0) == 1 &&
                IsCoreRunning)
            {
                SetState(true,
                    "Приёмник включён · ожидание подключения");
            }

            if (restartPending && DateTime.UtcNow >= restartDueUtc)
            {
                restartPending = false;
                Log("Starting core after scheduled restart; reason: " +
                    restartReason + ".");
                if (!quitting)
                    StartCore(false);
            }

            lock (postSessionMaintenanceSync)
            {
              if (coreReadyPending && IsCoreRunning &&
                  coreReadinessPid > 0 &&
                  Interlocked.CompareExchange(
                      ref activeCorePid, 0, 0) == coreReadinessPid &&
                  DateTime.UtcNow >= coreReadyDueUtc)
              {
                coreReadyChecks++;
                string bonjourStatus = GetBonjourStatus();
                bool socketsReady =
                    Interlocked.CompareExchange(
                        ref coreSocketsReady, 0, 0) == 1 &&
                    DateTime.UtcNow.Ticks >= Interlocked.Read(
                        ref coreSocketsReadyDueTicks);
                int dnsSdStatus = Interlocked.CompareExchange(
                    ref coreDnsSdStatus, 0, 0);
                int bleStatus = Interlocked.CompareExchange(
                    ref coreBleStatus, 0, 0);
                bool bonjourRunning = string.Equals(
                    bonjourStatus, "Running",
                    StringComparison.OrdinalIgnoreCase);
                Log("Core readiness check " + coreReadyChecks +
                    "; Bonjour Service: " + bonjourStatus +
                    "; sockets ready: " + socketsReady +
                    "; DNS-SD marker: " +
                    DiscoveryMarkerStatus(dnsSdStatus, "degraded") +
                    "; BLE marker: " +
                    DiscoveryMarkerStatus(bleStatus, "failed") + ".");
                if (IsCoreReadinessConfirmed(
                        socketsReady, bonjourRunning,
                        dnsSdStatus, bleStatus))
                {
                    coreReadyPending = false;
                    coreReadinessRecoveryAttempts = 0;
                    coreReadinessPid = 0;
                    SetState(true,
                        "Приёмник включён · ожидание подключения");
                }
                else if (coreReadyChecks < 8)
                {
                    coreReadyDueUtc = DateTime.UtcNow.AddSeconds(2);
                    SetState(true, "Приёмник запускается · ждём Bonjour…");
                }
                else
                {
                    bool recoveryAvailable =
                        ConsumeSharedAutomaticRecoveryBudget(true);
                    coreReadinessPid = 0;
                    if (recoveryAvailable)
                    {
                        SetState(false,
                            "AirPlay не опубликован · восстанавливаем…");
                        Log("Core readiness was not confirmed after eight checks; " +
                            "performing the single shared automatic recovery.");
                        ScheduleRestart(
                            "readiness recovery", false, 1500);
                    }
                    else
                    {
                        Log("Core readiness was not confirmed after automatic " +
                            "recovery, or the shared automatic recovery budget " +
                            "was already consumed by native discovery. The " +
                            "socket-running receiver stays available; no " +
                            "additional automatic restart or stop will run.");
                        SetState(false,
                            "AirPlay не опубликован · откройте диагностику");
                        if (settings.Notify)
                            tray.ShowBalloonTip(7000, AppTitle,
                                "AeroMirror не смог подтвердить публикацию AirPlay после автоматического перезапуска. Откройте диагностику или нажмите «Обновить обнаружение».",
                                ToolTipIcon.Warning);
                    }
                }
              }
            }
            HandleLostConnectionRecovery();
            HandleCoreDiscoveryRecovery();
            HandleAutomaticDiscoveryMaintenance();
            ApplyTopMost();
            if (form != null && !form.IsDisposed)
            {
                form.SyncTheme();
                form.SyncStatus();
            }
        }

        private void HandleExitedCore()
        {
            if (coreProcess == null)
                return;
            Process exitedProcess = coreProcess;
            try
            {
                if (!exitedProcess.HasExited)
                    return;
                int code = exitedProcess.ExitCode;
                CancelCoreOutputReads(exitedProcess);
                uint status = unchecked((uint)code);
                string codeHex = "0x" + status.ToString("X8");
                Log("Core exited with code " + code + " (" + codeHex + ").");
                DateTime now = DateTime.UtcNow;
                if (rapidExitWindowStartedAt == DateTime.MinValue ||
                    (now - rapidExitWindowStartedAt).TotalSeconds > 60)
                {
                    rapidExitWindowStartedAt = now;
                    rapidExitCount = 1;
                }
                else
                {
                    rapidExitCount++;
                }
                coreProcess = null;
                Interlocked.Exchange(ref activeCorePid, 0);
                ResetCoreSessionTracking(true);
                coreReadyPending = false;
                Interlocked.Exchange(ref coreSocketsReady, 0);
                Interlocked.Exchange(ref coreSocketsReadyDueTicks, 0);
                NativeMethods.CloseHandleSafe(ref coreJob);
                exitedProcess.Dispose();
                bool loaderFailure =
                    status == 0xC0000135 ||
                    status == 0xC0000139 ||
                    status == 0xC000007B;
                if (loaderFailure)
                {
                    SetState(false, "Несовместимые или отсутствующие DLL ядра");
                    Log("Automatic restart disabled for permanent Windows " +
                        "loader failure " + codeHex + ".");
                    if (settings.Notify)
                        tray.ShowBalloonTip(7000, AppTitle,
                            "Windows не смог загрузить DLL ядра UxPlay (" +
                            codeHex + "). Переустановите AeroMirror и приложите журнал к отчёту.",
                            ToolTipIcon.Error);
                }
                else if (rapidExitCount >= 3)
                {
                    SetState(false, "Ядро аварийно завершилось");
                    Log("Automatic restart disabled after three exits in " +
                        "the 60-second crash window.");
                    if (settings.Notify)
                        tray.ShowBalloonTip(5000, AppTitle,
                            "Ядро UxPlay завершилось три раза за минуту. Откройте диагностику.",
                            ToolTipIcon.Error);
                }
                else
                {
                    SetState(false, "Приёмник остановлен");
                    if (!quitting && settings.AutoStartReceiver)
                    {
                        int delay = Math.Min(
                            5000, 1000 * Math.Max(1, rapidExitCount));
                        ScheduleRestart(
                            "unexpected exit code " + code + " (" + codeHex + ")",
                            false, delay);
                    }
                }
            }
            catch (Exception ex)
            {
                Log("ERROR processing core exit: " + ex.Message);
            }
        }

        private void OnNetworkAddressChanged(object sender, EventArgs e)
        {
            long dueTicks = DateTime.UtcNow.AddMilliseconds(1500).Ticks;
            long previousDueTicks = Interlocked.Read(
                ref networkRefreshDueTicks);
            int wasPending = Interlocked.Exchange(
                ref networkRefreshPending, 1);
            if (wasPending == 0 || previousDueTicks <= 0 ||
                dueTicks < previousDueTicks)
                Interlocked.Exchange(ref networkRefreshDueTicks, dueTicks);
        }
    }
}
