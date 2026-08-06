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

[assembly: AssemblyTitle("AeroMirror")]
[assembly: AssemblyDescription("Minimal Windows tray shell for UxPlay")]
[assembly: AssemblyCompany("AeroMirror open-source project")]
[assembly: AssemblyProduct("AeroMirror")]
[assembly: AssemblyCopyright("Copyright (c) 2026")]
[assembly: AssemblyVersion("0.11.0.0")]
[assembly: AssemblyFileVersion("0.11.0.0")]

namespace AirPlayReceiverMvp
{
    internal static class AppVersion
    {
        public static Version Current
        {
            get { return Assembly.GetExecutingAssembly().GetName().Version; }
        }

        public static string Display
        {
            get { return Current.ToString(3); }
        }
    }

    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.SetUnhandledExceptionMode(
                UnhandledExceptionMode.CatchException);
            Application.ThreadException += delegate(
                object sender, ThreadExceptionEventArgs e)
            {
                ReceiverContext.Log("FATAL UI: " + e.Exception);
            };
            AppDomain.CurrentDomain.UnhandledException += delegate(
                object sender, UnhandledExceptionEventArgs e)
            {
                ReceiverContext.Log(
                    "FATAL APPDOMAIN: " + Convert.ToString(e.ExceptionObject));
                ReceiverContext.FlushLog(1000);
            };
            bool created;
            using (var mutex = new Mutex(true, "Local\\AirPlayReceiverMvp.Singleton", out created))
            using (var showEvent = new EventWaitHandle(
                false, EventResetMode.AutoReset, "Local\\AirPlayReceiverMvp.Show"))
            {
                if (!created)
                {
                    showEvent.Set();
                    return;
                }

                try
                {
                    Application.EnableVisualStyles();
                    Application.SetCompatibleTextRenderingDefault(false);
                    Application.Run(new ReceiverContext(args, showEvent));
                }
                catch (Exception ex)
                {
                    ReceiverContext.Log("FATAL: " + ex);
                    ReceiverContext.FlushLog(1000);
                    MessageBox.Show("Приложение не удалось запустить.\r\n\r\n" + ex.Message,
                        "AeroMirror", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
    }

    internal sealed class AppSettings
    {
        public int SettingsVersion = 9;
        public string ReceiverName = Environment.MachineName;
        public string PairingMode = "none";
        public string FixedPin = "";
        public string QualityPreset = "1080p60";
        public string Renderer = "auto";
        public string LatencyProfile = "balanced";
        public string AudioOutput = "default";
        public string ThemeMode = "system";
        public string AdvancedArguments = "";
        public bool AutoStartReceiver = true;
        public bool AutoStartWindows = true;
        public bool StartMinimized = true;
        public bool CloseToTray = true;
        public bool AutoFitWindow = true;
        public bool AlwaysOnTop = false;
        public bool ShowStreamInTaskbar = true;
        public bool Notify = true;
        public bool DismissPinSuggestion = false;

        public static string Folder
        {
            get
            {
                try
                {
                    string path = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                        "AirPlayReceiverMvp");
                    Directory.CreateDirectory(path);
                    return path;
                }
                catch
                {
                    string portable = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
                    Directory.CreateDirectory(portable);
                    return portable;
                }
            }
        }

        public static string FilePath { get { return Path.Combine(Folder, "settings.ini"); } }
        public static string LogPath { get { return Path.Combine(Folder, "receiver.log"); } }
        public static string ReceiverKeyPath { get { return Path.Combine(Folder, "receiver-key.pem"); } }
        public static string TrustedClientsPath { get { return Path.Combine(Folder, "trusted-clients.txt"); } }

        public AppSettings Copy()
        {
            return new AppSettings
            {
                SettingsVersion = SettingsVersion,
                ReceiverName = ReceiverName,
                PairingMode = PairingMode,
                FixedPin = FixedPin,
                QualityPreset = QualityPreset,
                Renderer = Renderer,
                LatencyProfile = LatencyProfile,
                AudioOutput = AudioOutput,
                ThemeMode = ThemeMode,
                AdvancedArguments = AdvancedArguments,
                AutoStartReceiver = AutoStartReceiver,
                AutoStartWindows = AutoStartWindows,
                StartMinimized = StartMinimized,
                CloseToTray = CloseToTray,
                AutoFitWindow = AutoFitWindow,
                AlwaysOnTop = AlwaysOnTop,
                ShowStreamInTaskbar = ShowStreamInTaskbar,
                Notify = Notify,
                DismissPinSuggestion = DismissPinSuggestion
            };
        }

        public static AppSettings Load()
        {
            var settings = new AppSettings();
            if (!File.Exists(FilePath))
                return settings;

            bool hasSettingsVersion = false;
            foreach (string raw in File.ReadAllLines(FilePath, Encoding.UTF8))
            {
                int equals = raw.IndexOf('=');
                if (equals <= 0)
                    continue;
                string key = raw.Substring(0, equals).Trim();
                string value = Unescape(raw.Substring(equals + 1));
                bool flag;
                switch (key)
                {
                    case "SettingsVersion":
                        int version;
                        if (int.TryParse(value, out version))
                        {
                            settings.SettingsVersion = version;
                            hasSettingsVersion = true;
                        }
                        break;
                    case "ReceiverName": settings.ReceiverName = value; break;
                    case "PairingMode": settings.PairingMode = value; break;
                    case "FixedPin": settings.FixedPin = value; break;
                    case "QualityPreset": settings.QualityPreset = value; break;
                    case "Renderer": settings.Renderer = value; break;
                    case "LatencyProfile": settings.LatencyProfile = value; break;
                    case "AudioOutput": settings.AudioOutput = value; break;
                    case "ThemeMode": settings.ThemeMode = value; break;
                    case "AdvancedArguments": settings.AdvancedArguments = value; break;
                    case "AutoStartReceiver":
                        if (bool.TryParse(value, out flag)) settings.AutoStartReceiver = flag;
                        break;
                    case "AutoStartWindows":
                        if (bool.TryParse(value, out flag)) settings.AutoStartWindows = flag;
                        break;
                    case "StartMinimized":
                        if (bool.TryParse(value, out flag)) settings.StartMinimized = flag;
                        break;
                    case "CloseToTray":
                        if (bool.TryParse(value, out flag)) settings.CloseToTray = flag;
                        break;
                    case "AutoFitWindow":
                        if (bool.TryParse(value, out flag)) settings.AutoFitWindow = flag;
                        break;
                    case "AlwaysOnTop":
                        if (bool.TryParse(value, out flag)) settings.AlwaysOnTop = flag;
                        break;
                    case "ShowStreamInTaskbar":
                        if (bool.TryParse(value, out flag)) settings.ShowStreamInTaskbar = flag;
                        break;
                    case "Notify":
                        if (bool.TryParse(value, out flag)) settings.Notify = flag;
                        break;
                    case "DismissPinSuggestion":
                        if (bool.TryParse(value, out flag)) settings.DismissPinSuggestion = flag;
                        break;
                }
            }

            // v0.2 used an invisible, random PIN as the default. Migrate that
            // exact state to the safer and understandable trusted-network mode.
            if (!hasSettingsVersion)
            {
                if (settings.PairingMode == "pin" && string.IsNullOrWhiteSpace(settings.FixedPin))
                    settings.PairingMode = "none";
                settings.AutoStartWindows = true;
                settings.StartMinimized = true;
            }
            if (!hasSettingsVersion || settings.SettingsVersion < 4)
            {
                // Let GStreamer choose the most stable decoder/sink by default.
                // Explicit D3D12 decoding caused visible stutter on some systems.
                settings.SettingsVersion = 4;
                settings.Renderer = "auto";
                settings.QualityPreset = "1080p60";
                settings.LatencyProfile = "balanced";
            }
            if (!hasSettingsVersion || settings.SettingsVersion < 5)
            {
                settings.SettingsVersion = 5;
                settings.AutoFitWindow = true;
            }
            if (!hasSettingsVersion || settings.SettingsVersion < 6)
            {
                settings.SettingsVersion = 6;
                settings.CloseToTray = true;
            }
            if (!hasSettingsVersion || settings.SettingsVersion < 7)
            {
                settings.SettingsVersion = 7;
                settings.AudioOutput = "default";
                settings.ShowStreamInTaskbar = false;
            }
            if (!hasSettingsVersion || settings.SettingsVersion < 8)
            {
                settings.SettingsVersion = 8;
                settings.ThemeMode = "system";
                settings.ShowStreamInTaskbar = true;
            }
            if (!hasSettingsVersion || settings.SettingsVersion < 9)
            {
                settings.SettingsVersion = 9;
                settings.DismissPinSuggestion = false;
            }
            return settings;
        }

        public void Save()
        {
            var lines = new[]
            {
                "SettingsVersion=" + SettingsVersion,
                "ReceiverName=" + Escape(ReceiverName),
                "PairingMode=" + Escape(PairingMode),
                "FixedPin=" + Escape(FixedPin),
                "QualityPreset=" + Escape(QualityPreset),
                "Renderer=" + Escape(Renderer),
                "LatencyProfile=" + Escape(LatencyProfile),
                "AudioOutput=" + Escape(AudioOutput),
                "ThemeMode=" + Escape(ThemeMode),
                "AdvancedArguments=" + Escape(AdvancedArguments),
                "AutoStartReceiver=" + AutoStartReceiver,
                "AutoStartWindows=" + AutoStartWindows,
                "StartMinimized=" + StartMinimized,
                "CloseToTray=" + CloseToTray,
                "AutoFitWindow=" + AutoFitWindow,
                "AlwaysOnTop=" + AlwaysOnTop,
                "ShowStreamInTaskbar=" + ShowStreamInTaskbar,
                "Notify=" + Notify,
                "DismissPinSuggestion=" + DismissPinSuggestion
            };
            File.WriteAllLines(FilePath, lines, new UTF8Encoding(false));
        }

        private static string Escape(string value)
        {
            return (value ?? "").Replace("\\", "\\\\").Replace("\r", "\\r").Replace("\n", "\\n");
        }

        private static string Unescape(string value)
        {
            var result = new StringBuilder();
            bool escaped = false;
            foreach (char c in value)
            {
                if (escaped)
                {
                    if (c == 'r') result.Append('\r');
                    else if (c == 'n') result.Append('\n');
                    else result.Append(c);
                    escaped = false;
                }
                else if (c == '\\')
                {
                    escaped = true;
                }
                else result.Append(c);
            }
            if (escaped) result.Append('\\');
            return result.ToString();
        }
    }

    internal sealed class ReceiverContext : ApplicationContext
    {
        private const string AppTitle = "AeroMirror";
        private readonly NotifyIcon tray;
        private readonly ToolStripMenuItem statusItem;
        private readonly ToolStripMenuItem startStopItem;
        private readonly ToolStripMenuItem autoStartItem;
        private readonly ToolStripMenuItem topMostItem;
        private readonly ToolStripMenuItem networkWarningItem;
        private readonly System.Windows.Forms.Timer monitorTimer;
        private readonly EventWaitHandle showEvent;
        private AppSettings settings;
        private Process coreProcess;
        private IntPtr coreJob = IntPtr.Zero;
        private int rapidExitCount;
        private DateTime rapidExitWindowStartedAt = DateTime.MinValue;
        private SettingsForm form;
        private bool quitting;
        private bool publicNetwork;
        private bool networkWarningShown;
        private bool networkProfileKnown;
        private string networkProfileName = "";
        private string networkInterfaceName = "";
        private string networkSignature = "";
        private int nonPhysicalProfileCount;
        private int publicNonPhysicalProfileCount;
        private IntPtr fittedStreamWindow = IntPtr.Zero;
        private int networkRefreshPending;
        private long networkRefreshDueTicks;
        private int networkRefreshRunning;
        private int networkUnknownRetries;
        private int knownNetworkUnknownRetries;
        private readonly object networkProfileSync = new object();
        private NetworkProfileInfo pendingNetworkProfile;
        private bool restartPending;
        private DateTime restartDueUtc;
        private string restartReason = "";
        private int restartStopInProgress;
        private int restartStopCompleted;
        private int restartDelayAfterStop;
        private bool restartAfterStop;
        private readonly ManualResetEvent restartStopDone =
            new ManualResetEvent(true);
        private bool coreReadyPending;
        private DateTime coreReadyDueUtc;
        private int coreReadyChecks;
        private int coreReadinessRecoveryAttempts;
        private int coreSocketsReady;
        private long coreSocketsReadyDueTicks;
        private int activeCorePid;
        private int mirrorSessionActive;
        private int mirrorSessionEndedPending;
        private long mirrorSessionEndedDueTicks;
        private int settingsRestartDeferred;
        private long idleDiscoveryRenewalDueTicks;
        private int idleDiscoveryRenewalUsed;
        private DateTime lastAutomaticDiscoveryRefreshUtc = DateTime.MinValue;
        private readonly object videoSizeSync = new object();
        private Size pendingVideoSize = Size.Empty;
        private DateTime pendingVideoSizeDueUtc = DateTime.MinValue;
        private int pendingVideoSizeGeneration;
        private Size currentVideoSize = Size.Empty;
        private int currentVideoSizeGeneration;
        private int mirrorSessionGeneration;
        private IntPtr videoSizeWindow = IntPtr.Zero;
        private IntPtr initialFitPendingWindow = IntPtr.Zero;
        private int exactVideoSizeFitGeneration = -1;
        private int appliedVideoOrientation;
        private bool startAfterNetworkCheck;
        private bool resumeAfterSafeNetwork;
        private string receiverStateText = "Приёмник остановлен";

        public ReceiverContext(string[] args, EventWaitHandle showEvent)
        {
            this.showEvent = showEvent;
            bool show = false;
            bool startup = false;
            foreach (string arg in args)
            {
                if (string.Equals(arg, "--show", StringComparison.OrdinalIgnoreCase))
                    show = true;
                if (string.Equals(arg, "--startup", StringComparison.OrdinalIgnoreCase))
                    startup = true;
            }

            settings = AppSettings.Load();
            settings.Save();
            ApplyAutostart(settings.AutoStartWindows);
            SanitizeExistingLogs(settings.FixedPin);

            statusItem = new ToolStripMenuItem("● Приёмник остановлен");
            statusItem.Enabled = false;
            startStopItem = new ToolStripMenuItem("Запустить приёмник", null, OnStartStop);
            autoStartItem = new ToolStripMenuItem("Запускать вместе с Windows", null, OnAutostart);
            autoStartItem.Checked = IsAutostartEnabled();
            topMostItem = new ToolStripMenuItem("Окно трансляции поверх остальных", null, OnAlwaysOnTop);
            topMostItem.Checked = settings.AlwaysOnTop;
            networkWarningItem = new ToolStripMenuItem(
                "⚠ Публичная сеть без PIN — открыть настройки", null,
                delegate { ShowSettings(); });
            networkWarningItem.ForeColor = Color.FromArgb(154, 92, 0);
            networkWarningItem.Visible = false;

            var menu = new ContextMenuStrip();
            menu.Items.Add(statusItem);
            menu.Items.Add(networkWarningItem);
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Открыть настройки", null, delegate { ShowSettings(); });
            menu.Items.Add(startStopItem);
            menu.Items.Add("Перезапустить приёмник", null, delegate { RestartCore(); });
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add(autoStartItem);
            menu.Items.Add(topMostItem);
            menu.Items.Add("Подогнать окно под экран iPhone", null, delegate { FitStreamWindow(true); });
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Диагностика", null, delegate { ShowDiagnostics(); });
            menu.Items.Add("Открыть журнал", null, delegate { OpenLog(); });
            menu.Items.Add("Сообщить о проблеме", null, delegate
            {
                OpenProblemReport(null);
            });
            menu.Items.Add("Выход", null, delegate { RequestQuit(); });

            tray = new NotifyIcon();
            tray.Icon = AppIcon.Current;
            tray.Text = AppTitle;
            tray.ContextMenuStrip = menu;
            tray.MouseClick += delegate(object sender, MouseEventArgs e)
            {
                if (e.Button == MouseButtons.Left)
                    ShowSettings();
            };
            tray.BalloonTipClicked += delegate { ShowSettings(); };
            tray.Visible = true;

            monitorTimer = new System.Windows.Forms.Timer();
            monitorTimer.Interval = 250;
            monitorTimer.Tick += delegate { MonitorCore(); };
            monitorTimer.Start();
            NetworkChange.NetworkAddressChanged += OnNetworkAddressChanged;

            Log("=== AeroMirror session started ===");
            Log("Shell version " +
                AppVersion.Display +
                "; Windows " + Environment.OSVersion +
                "; 64-bit process: " + Environment.Is64BitProcess +
                "; startup: " + startup + ".");
            Log("Executable: " +
                Path.GetFileName(Assembly.GetExecutingAssembly().Location));
            BeginNetworkProfileRefresh();
            if (settings.AutoStartReceiver &&
                settings.PairingMode != "none")
                StartCore(!startup);
            else if (settings.AutoStartReceiver)
            {
                startAfterNetworkCheck = true;
                SetState(false, "Проверяем безопасность сети…");
            }

            if (!startup || !settings.StartMinimized)
                show = true;
            if (show)
                ShowSettings();
        }

        public bool IsCoreRunning
        {
            get
            {
                try { return coreProcess != null && !coreProcess.HasExited; }
                catch { return false; }
            }
        }

        public AppSettings CurrentSettings { get { return settings; } }
        public bool IsPublicNetwork { get { return publicNetwork; } }
        public bool IsNetworkProfileKnown { get { return networkProfileKnown; } }
        public string NetworkProfileName { get { return networkProfileName; } }
        public string NetworkInterfaceName { get { return networkInterfaceName; } }
        public bool HasNetworkOverlay
        {
            get { return nonPhysicalProfileCount > 0; }
        }
        public int NetworkOverlayCount
        {
            get { return nonPhysicalProfileCount; }
        }
        public string ReceiverStateText { get { return receiverStateText; } }
        public bool IsMirrorSessionActive
        {
            get
            {
                return Interlocked.CompareExchange(
                    ref mirrorSessionActive, 0, 0) == 1;
            }
        }
        public bool IsSettingsRestartDeferred
        {
            get
            {
                return Interlocked.CompareExchange(
                    ref settingsRestartDeferred, 0, 0) == 1;
            }
        }

        public string CorePath
        {
            get
            {
                return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "core", "uxplay-windows.exe");
            }
        }

        public void ShowSettings()
        {
            Log("Opening settings window.");
            if (form == null || form.IsDisposed)
            {
                form = new SettingsForm(this);
                form.FormClosed += delegate { form = null; };
            }
            form.SyncStatus();
            form.Show();
            form.WindowState = FormWindowState.Normal;
            form.Activate();
            Log("Settings window visible: " + form.Visible + ".");
        }

        public bool SaveSettings(AppSettings updated, bool restartIfCoreArgumentsChanged)
        {
            ResetRapidExitWindow();
            string previousArguments = BuildUxPlayArguments();
            bool wasRunning = IsCoreRunning;
            settings = updated;
            settings.SettingsVersion = 9;
            settings.Save();
            ApplyAutostart(settings.AutoStartWindows);
            autoStartItem.Checked = IsAutostartEnabled();
            topMostItem.Checked = settings.AlwaysOnTop;
            Log("Settings saved.");
            string currentArguments = BuildUxPlayArguments();
            bool argumentsChanged = !string.Equals(
                previousArguments, currentArguments, StringComparison.Ordinal);
            bool restarted = false;

            if (!settings.AutoStartReceiver)
            {
                restartPending = false;
                restartAfterStop = false;
                startAfterNetworkCheck = false;
                resumeAfterSafeNetwork = false;
                if (IsCoreRunning)
                    StopCore();
            }
            else if (!publicNetwork || settings.PairingMode != "none")
            {
                if (wasRunning && IsCoreRunning &&
                    restartIfCoreArgumentsChanged && argumentsChanged)
                {
                    if (IsMirrorSessionActive)
                    {
                        Interlocked.Exchange(ref settingsRestartDeferred, 1);
                        Log("Core argument changes were saved; restart deferred " +
                            "until the current mirroring session ends.");
                    }
                    else
                    {
                        ScheduleRestart("settings changed", false, 1000);
                    }
                    restarted = true;
                }
                else if (!IsCoreRunning)
                {
                    StartCore(false);
                    restarted = IsCoreRunning;
                }
                else
                {
                    ApplyTopMost();
                }
            }
            return restarted;
        }

        public void RefreshNetworkSafety(bool notify)
        {
            NetworkProfileInfo profile = NetworkSafety.DetectPhysicalProfile();
            ApplyNetworkProfile(profile, notify);
        }

        private bool ApplyNetworkProfile(NetworkProfileInfo profile, bool notify)
        {
            if (!profile.IsKnown && networkProfileKnown)
            {
                if (knownNetworkUnknownRetries < 3)
                {
                    knownNetworkUnknownRetries++;
                    Interlocked.Exchange(
                        ref networkRefreshDueTicks,
                        DateTime.UtcNow.AddSeconds(5).Ticks);
                    Interlocked.Exchange(ref networkRefreshPending, 1);
                    Log("Physical network profile temporarily returned Unknown; " +
                        "keeping the last known profile during safety grace period " +
                        "(" + knownNetworkUnknownRetries + "/3).");
                    return false;
                }
                Log("Physical network profile remained Unknown after the safety " +
                    "grace period; discarding the last known profile.");
            }
            if (profile.IsKnown)
                knownNetworkUnknownRetries = 0;
            string previousSignature = networkSignature;
            networkProfileKnown = profile.IsKnown;
            publicNetwork = profile.IsPublic;
            networkProfileName = profile.Name;
            networkInterfaceName = profile.InterfaceName;
            nonPhysicalProfileCount = profile.NonPhysicalProfileCount;
            publicNonPhysicalProfileCount =
                profile.PublicNonPhysicalProfileCount;
            networkSignature = profile.Signature;
            bool physicalNetworkUnsafe =
                !profile.IsKnown || profile.IsPublic;
            bool unsafeAccess =
                settings.PairingMode == "none" && physicalNetworkUnsafe;
            bool receiverStartedByProfile = false;
            networkWarningItem.Visible = unsafeAccess;
            networkWarningItem.Text = profile.IsKnown
                ? (profile.NonPhysicalProfileCount > 0
                    ? "⚠ Wi-Fi/Ethernet публичная · VPN/виртуальная сеть обнаружена"
                    : "⚠ Публичная сеть без PIN — открыть настройки")
                : "⚠ Профиль сети не определён — включить PIN";
            bool changed = previousSignature.Length > 0 &&
                !string.Equals(previousSignature, networkSignature,
                    StringComparison.Ordinal);
            if (changed)
                ResetIdleDiscoveryRenewalLimit();
            if (previousSignature.Length == 0 || changed)
            {
                Log("Physical network profile: " +
                    (profile.IsKnown ? profile.Category : "Unknown") +
                    " (physical interface " + profile.InterfaceName +
                    ", IPv4 count " + CountAddresses(profile.Addresses) + ")" +
                    "; non-physical overlays " +
                    profile.NonPhysicalProfileCount +
                    " (public " +
                    profile.PublicNonPhysicalProfileCount + ")" +
                    "; access: " + settings.PairingMode +
                    "; changed: " + changed + ".");
            }

            if (unsafeAccess && IsCoreRunning)
            {
                bool shouldResume = settings.AutoStartReceiver;
                StopCore();
                resumeAfterSafeNetwork = shouldResume;
                SetState(false, profile.IsKnown
                    ? "Публичная сеть · включите PIN"
                    : "Сеть не определена · включите PIN");
                Log(profile.IsKnown
                    ? "Receiver paused: a public network requires PIN protection."
                    : "Receiver paused: the physical network profile is unknown.");
            }
            else if (unsafeAccess)
            {
                SetState(false, profile.IsKnown
                    ? "Публичная сеть · включите PIN"
                    : "Сеть не определена · включите PIN");
            }

            if (unsafeAccess && notify && settings.Notify && !networkWarningShown)
            {
                networkWarningShown = true;
                tray.ShowBalloonTip(7000, AppTitle,
                    profile.IsKnown
                        ? (profile.NonPhysicalProfileCount > 0
                            ? "Приёмник приостановлен: Windows считает физическую сеть публичной. VPN или виртуальная сеть обнаружены, но не используются для определения доверия. Включите PIN или проверьте профиль Wi-Fi/Ethernet."
                            : "Приёмник приостановлен: публичная сеть требует PIN. Нажмите уведомление, чтобы включить защиту.")
                        : "Приёмник приостановлен: Windows не удалось определить профиль сети. Включите PIN или повторите проверку.",
                    ToolTipIcon.Warning);
            }
            if (!unsafeAccess)
                networkWarningShown = false;

            if (profile.IsKnown && !unsafeAccess &&
                resumeAfterSafeNetwork && settings.AutoStartReceiver &&
                !IsCoreRunning)
            {
                resumeAfterSafeNetwork = false;
                Log("Safe physical network profile restored; resuming receiver.");
                StartCore(false);
                receiverStartedByProfile = IsCoreRunning;
            }

            if (form != null && !form.IsDisposed)
                form.SyncStatus();
            if (startAfterNetworkCheck)
            {
                if (profile.IsKnown)
                {
                    startAfterNetworkCheck = false;
                    networkUnknownRetries = 0;
                    if (!unsafeAccess)
                    {
                        StartCore(false);
                        receiverStartedByProfile = IsCoreRunning;
                    }
                }
                else if (networkUnknownRetries < 3)
                {
                    networkUnknownRetries++;
                    Interlocked.Exchange(
                        ref networkRefreshDueTicks,
                        DateTime.UtcNow.AddSeconds(5).Ticks);
                    Interlocked.Exchange(ref networkRefreshPending, 1);
                    SetState(false,
                        "Проверяем сеть ещё раз…");
                    Log("Initial physical network check returned Unknown; " +
                        "retry " + networkUnknownRetries + " scheduled.");
                }
                else
                {
                    SetState(false,
                        "Не удалось определить сеть · включите PIN");
                    Log("Initial physical network check remained Unknown " +
                        "after three retries; receiver stays paused.");
                }
            }
            return changed && !receiverStartedByProfile;
        }

        private void BeginNetworkProfileRefresh()
        {
            if (Interlocked.CompareExchange(ref networkRefreshRunning, 1, 0) != 0)
            {
                Interlocked.Exchange(
                    ref networkRefreshDueTicks,
                    DateTime.UtcNow.AddSeconds(1).Ticks);
                Interlocked.Exchange(ref networkRefreshPending, 1);
                return;
            }
            ThreadPool.QueueUserWorkItem(delegate
            {
                NetworkProfileInfo profile = NetworkSafety.DetectPhysicalProfile();
                lock (networkProfileSync)
                    pendingNetworkProfile = profile;
                Interlocked.Exchange(ref networkRefreshRunning, 0);
            });
        }

        public void StartCore()
        {
            ResetRapidExitWindow();
            coreReadinessRecoveryAttempts = 0;
            if (!networkProfileKnown && settings.PairingMode == "none")
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
                    coreProcess.WaitForExit();
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
                start.Arguments = "--headless --uxplay " + BuildUxPlayArguments();
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
                coreProcess = process;
                coreJob = NativeMethods.CreateKillOnCloseJob(process);
                if (coreJob == IntPtr.Zero)
                    throw new InvalidOperationException(
                        "UxPlay could not be isolated in a Windows Job Object.");
                int processId = process.Id;
                Interlocked.Exchange(ref activeCorePid, processId);
                ResetCoreSessionTracking(true);
                ArmIdleDiscoveryRenewalIfAvailable();
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
                fittedStreamWindow = IntPtr.Zero;
                coreReadyPending = true;
                coreReadyChecks = 0;
                coreReadyDueUtc = DateTime.UtcNow.AddSeconds(2);
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
                        if (coreProcess.HasExited)
                            coreProcess.WaitForExit();
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
                SetState(false, "Ошибка запуска");
                if (settings.Notify)
                    tray.ShowBalloonTip(
                        5000, AppTitle, ex.Message, ToolTipIcon.Error);
            }
        }

        public void StopCore()
        {
            startAfterNetworkCheck = false;
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
            coreReadinessRecoveryAttempts = 0;
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
                        NativeMethods.CloseHandleSafe(ref jobHandle);
                    else
                        process.Kill();
                    exited = process.WaitForExit(2500);
                }
                if (exited)
                    process.WaitForExit();
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

        public void RefreshDiscovery()
        {
            ResetRapidExitWindow();
            coreReadinessRecoveryAttempts = 0;
            ResetIdleDiscoveryRenewalLimit();
            Log("Manual AirPlay discovery refresh requested.");
            ScheduleRestart("manual discovery refresh", false, 1200);
        }

        private void ObserveCoreOutput(int processId, string line)
        {
            if (Interlocked.CompareExchange(
                    ref activeCorePid, 0, 0) != processId)
                return;

            if (line.IndexOf(
                    "raop_rtp_mirror starting mirroring",
                    StringComparison.OrdinalIgnoreCase) >= 0)
            {
                Interlocked.Exchange(ref mirrorSessionActive, 1);
                Interlocked.Exchange(ref mirrorSessionEndedPending, 0);
                Interlocked.Increment(ref mirrorSessionGeneration);
                lock (videoSizeSync)
                {
                    pendingVideoSize = Size.Empty;
                    pendingVideoSizeDueUtc = DateTime.MinValue;
                    pendingVideoSizeGeneration = 0;
                    currentVideoSize = Size.Empty;
                    currentVideoSizeGeneration = 0;
                }
                ResetIdleDiscoveryRenewalLimit();
            }

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

            if (line.IndexOf(
                    "raop_rtp_mirror->running is no longer true",
                    StringComparison.OrdinalIgnoreCase) >= 0)
            {
                if (Interlocked.Exchange(ref mirrorSessionActive, 0) == 1)
                {
                    Interlocked.Exchange(
                        ref mirrorSessionEndedDueTicks,
                        DateTime.UtcNow.AddSeconds(5).Ticks);
                    Interlocked.Exchange(ref mirrorSessionEndedPending, 1);
                    Interlocked.Exchange(
                        ref idleDiscoveryRenewalDueTicks,
                        DateTime.UtcNow.AddMinutes(10).Ticks);
                    Log("Mirroring session ended; a bounded discovery renewal " +
                        "will run if the iPhone does not reconnect.");
                }
            }
        }

        private void ResetCoreSessionTracking(bool clearDeferredRestart)
        {
            Interlocked.Exchange(ref mirrorSessionActive, 0);
            Interlocked.Exchange(ref mirrorSessionEndedPending, 0);
            Interlocked.Exchange(ref mirrorSessionEndedDueTicks, 0);
            Interlocked.Exchange(ref idleDiscoveryRenewalDueTicks, 0);
            if (clearDeferredRestart)
                Interlocked.Exchange(ref settingsRestartDeferred, 0);
            lock (videoSizeSync)
            {
                pendingVideoSize = Size.Empty;
                pendingVideoSizeDueUtc = DateTime.MinValue;
                pendingVideoSizeGeneration = 0;
                currentVideoSize = Size.Empty;
                currentVideoSizeGeneration = 0;
            }
            Interlocked.Exchange(ref mirrorSessionGeneration, 0);
            videoSizeWindow = IntPtr.Zero;
            initialFitPendingWindow = IntPtr.Zero;
            exactVideoSizeFitGeneration = -1;
            appliedVideoOrientation = 0;
        }

        private void ResetIdleDiscoveryRenewalLimit()
        {
            Interlocked.Exchange(ref idleDiscoveryRenewalUsed, 0);
            Interlocked.Exchange(
                ref idleDiscoveryRenewalDueTicks,
                IsCoreRunning
                    ? DateTime.UtcNow.AddMinutes(10).Ticks
                    : 0);
        }

        private void ArmIdleDiscoveryRenewalIfAvailable()
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

        private void HandleAutomaticDiscoveryMaintenance()
        {
            if (!IsCoreRunning || coreReadyPending || restartPending ||
                Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1)
                return;

            DateTime now = DateTime.UtcNow;
            if (Interlocked.CompareExchange(
                    ref mirrorSessionEndedPending, 0, 0) == 1)
            {
                long dueTicks = Interlocked.Read(
                    ref mirrorSessionEndedDueTicks);
                if (dueTicks > 0 && now.Ticks >= dueTicks)
                {
                    Interlocked.Exchange(ref mirrorSessionEndedPending, 0);
                    if (!IsMirrorSessionActive)
                    {
                        if (IsSettingsRestartDeferred)
                        {
                            Log("Current mirroring session ended; applying " +
                                "the saved receiver settings.");
                            lastAutomaticDiscoveryRefreshUtc = now;
                            ScheduleRestart(
                                "deferred settings change", false, 1000);
                            return;
                        }

                        if ((now - lastAutomaticDiscoveryRefreshUtc).
                                TotalSeconds >= 60)
                        {
                            Log("Renewing AirPlay discovery after the completed " +
                                "mirroring session.");
                            lastAutomaticDiscoveryRefreshUtc = now;
                            ScheduleRestart(
                                "post-session discovery renewal", false, 1200);
                            return;
                        }
                    }
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

            if (Interlocked.CompareExchange(
                    ref idleDiscoveryRenewalUsed, 1, 0) != 0)
                return;
            Interlocked.Exchange(ref idleDiscoveryRenewalDueTicks, 0);
            if (IsMirrorSessionActive)
            {
                ResetIdleDiscoveryRenewalLimit();
                return;
            }

            Log("Renewing idle AirPlay discovery after ten minutes without " +
                "a mirroring session.");
            lastAutomaticDiscoveryRefreshUtc = now;
            ScheduleRestart("idle discovery renewal", false, 1200);
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
            text.AppendLine("Исходники AeroMirror 0.11.0:");
            text.AppendLine(
                "https://github.com/Nadejny/aeromirror/tree/v0.11.0");
            text.AppendLine("Исходники изменённого GPL-ядра:");
            text.AppendLine(
                "https://github.com/Nadejny/aeromirror/releases/download/v0.11.0/AeroMirror-native-source-0.11.0.zip");
            text.AppendLine("Неизменённый runtime загружается с:");
            text.AppendLine(
                "https://github.com/leapbtw/uxplay-windows/releases/tag/2.0.0.1736");
            text.AppendLine();
            text.AppendLine("Для обнаружения iPhone и компьютер должны быть в одной локальной сети.");
            text.AppendLine("При первом запуске разрешите сетевой доступ в Windows Firewall.");
            text.AppendLine("Если устройство не видно, перезапустите Bonjour Service и приёмник.");
            return text.ToString();
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
                if (networkChanged && IsCoreRunning &&
                    !HasVisibleRendererWindow())
                {
                    ScheduleRestart(
                        "physical network changed", false, 1200);
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

            if (restartPending && DateTime.UtcNow >= restartDueUtc)
            {
                restartPending = false;
                Log("Starting core after scheduled restart; reason: " +
                    restartReason + ".");
                if (!quitting)
                    StartCore(false);
            }

            if (coreReadyPending && IsCoreRunning &&
                DateTime.UtcNow >= coreReadyDueUtc)
            {
                coreReadyChecks++;
                string bonjourStatus = GetBonjourStatus();
                bool socketsReady =
                    Interlocked.CompareExchange(
                        ref coreSocketsReady, 0, 0) == 1 &&
                    DateTime.UtcNow.Ticks >= Interlocked.Read(
                        ref coreSocketsReadyDueTicks);
                Log("Core readiness check " + coreReadyChecks +
                    "; Bonjour Service: " + bonjourStatus +
                    "; sockets ready: " + socketsReady + ".");
                if (string.Equals(
                        bonjourStatus, "Running",
                        StringComparison.OrdinalIgnoreCase) &&
                    socketsReady)
                {
                    coreReadyPending = false;
                    coreReadinessRecoveryAttempts = 0;
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
                    coreReadyPending = false;
                    if (coreReadinessRecoveryAttempts < 1)
                    {
                        coreReadinessRecoveryAttempts++;
                        SetState(false,
                            "AirPlay не опубликован · восстанавливаем…");
                        Log("Core readiness was not confirmed after eight checks; " +
                            "performing one full stop/start recovery.");
                        ScheduleRestart(
                            "readiness recovery", false, 1500);
                    }
                    else
                    {
                        Log("Core readiness was not confirmed after automatic " +
                            "recovery; stopping the unconfirmed receiver.");
                        StopCoreInternal(
                            "readiness confirmation failed", true, false);
                        SetState(false,
                            "AirPlay не опубликован · откройте диагностику");
                        if (settings.Notify)
                            tray.ShowBalloonTip(7000, AppTitle,
                                "AeroMirror не смог подтвердить публикацию AirPlay после автоматического перезапуска. Откройте диагностику или нажмите «Обновить обнаружение».",
                                ToolTipIcon.Warning);
                    }
                }
            }
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
                exitedProcess.WaitForExit();
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
            Interlocked.Exchange(
                ref networkRefreshDueTicks,
                DateTime.UtcNow.AddSeconds(5).Ticks);
            Interlocked.Exchange(ref networkRefreshPending, 1);
        }

        private bool HasVisibleRendererWindow()
        {
            IntPtr window;
            return TryGetRendererWindow(out window);
        }

        private bool TryGetRendererWindow(out IntPtr rendererWindow)
        {
            rendererWindow = IntPtr.Zero;
            if (!IsCoreRunning)
                return false;

            if (fittedStreamWindow != IntPtr.Zero &&
                NativeMethods.IsWindow(fittedStreamWindow) &&
                NativeMethods.IsWindowVisible(fittedStreamWindow))
            {
                uint cachedPid;
                NativeMethods.GetWindowThreadProcessId(
                    fittedStreamWindow, out cachedPid);
                if (cachedPid == (uint)coreProcess.Id)
                {
                    rendererWindow = fittedStreamWindow;
                    return true;
                }
                fittedStreamWindow = IntPtr.Zero;
            }

            int pid = coreProcess.Id;
            IntPtr foundWindow = IntPtr.Zero;
            NativeMethods.EnumWindows(delegate(IntPtr window, IntPtr parameter)
            {
                uint windowPid;
                NativeMethods.GetWindowThreadProcessId(window, out windowPid);
                if (windowPid == (uint)pid && NativeMethods.IsWindowVisible(window))
                {
                    var title = new StringBuilder(512);
                    NativeMethods.GetWindowText(window, title, title.Capacity);
                    if (IsRendererWindowTitle(title.ToString()))
                    {
                        foundWindow = window;
                        return false;
                    }
                }
                return true;
            }, IntPtr.Zero);
            if (foundWindow != IntPtr.Zero)
            {
                rendererWindow = foundWindow;
                fittedStreamWindow = rendererWindow;
                return true;
            }
            return false;
        }

        private void ApplyTopMost()
        {
            if (!IsCoreRunning)
                return;
            IntPtr previousWindow = fittedStreamWindow;
            IntPtr window;
            if (!TryGetRendererWindow(out window))
                return;

            NativeMethods.SetWindowText(window, "iPhone · AeroMirror");
            NativeMethods.SetToolWindowStyle(
                window, !settings.ShowStreamInTaskbar);
            bool newWindow = previousWindow != window;
            if (newWindow)
            {
                NativeMethods.SetImmersiveDarkMode(window, true);
                videoSizeWindow = window;
                initialFitPendingWindow = window;
                exactVideoSizeFitGeneration = -1;
                appliedVideoOrientation = 0;
            }

            int videoSizeGeneration;
            Size videoSize = GetStableVideoSize(out videoSizeGeneration);
            int orientation = VideoOrientation(videoSize);
            if (settings.AutoFitWindow &&
                !NativeMethods.IsLeftMouseButtonDown())
            {
                if (initialFitPendingWindow == window)
                {
                    if (FitRendererWindow(window, videoSize, false))
                    {
                        initialFitPendingWindow = IntPtr.Zero;
                        exactVideoSizeFitGeneration = videoSize.IsEmpty
                            ? -1 : videoSizeGeneration;
                        appliedVideoOrientation = orientation != 0
                            ? orientation : GetWindowOrientation(window);
                        Log("Applied initial renderer window fit" +
                            VideoSizeLogSuffix(videoSize) + ".");
                    }
                }
                else if (videoSizeWindow == window &&
                    !videoSize.IsEmpty &&
                    exactVideoSizeFitGeneration != videoSizeGeneration)
                {
                    if (FitRendererWindow(window, videoSize, false))
                    {
                        exactVideoSizeFitGeneration = videoSizeGeneration;
                        appliedVideoOrientation = orientation;
                        Log("Refined renderer window fit for the first exact " +
                            "video size " + videoSize.Width + "x" +
                            videoSize.Height + ".");
                    }
                }
                else if (videoSizeWindow == window &&
                    orientation != 0 &&
                    appliedVideoOrientation != 0 &&
                    orientation != appliedVideoOrientation)
                {
                    if (FitRendererWindow(window, videoSize, true))
                    {
                        appliedVideoOrientation = orientation;
                        Log("Adapted renderer window to " +
                            (orientation == 1 ? "portrait" : "landscape") +
                            " video " + videoSize.Width + "x" +
                            videoSize.Height + ".");
                    }
                }
                else if (appliedVideoOrientation == 0 && orientation != 0)
                {
                    appliedVideoOrientation = orientation;
                }
            }
            NativeMethods.SetWindowPos(window,
                settings.AlwaysOnTop
                    ? NativeMethods.HWND_TOPMOST
                    : NativeMethods.HWND_NOTOPMOST,
                0, 0, 0, 0,
                NativeMethods.SWP_NOMOVE | NativeMethods.SWP_NOSIZE |
                NativeMethods.SWP_NOACTIVATE);
        }

        private void FitStreamWindow(bool notifyIfMissing)
        {
            if (!IsCoreRunning)
            {
                if (notifyIfMissing && settings.Notify)
                    tray.ShowBalloonTip(3000, AppTitle,
                        "Сначала подключите iPhone: окно трансляции пока не открыто.",
                        ToolTipIcon.Info);
                return;
            }

            IntPtr window = IntPtr.Zero;
            for (int attempt = 0; attempt < 5; attempt++)
            {
                if (TryGetRendererWindow(out window))
                    break;
                if (attempt < 4)
                    Thread.Sleep(150);
            }

            if (window != IntPtr.Zero)
            {
                int videoSizeGeneration;
                Size videoSize = GetStableVideoSize(
                    out videoSizeGeneration);
                if (FitRendererWindow(window, videoSize, false))
                {
                    fittedStreamWindow = window;
                    videoSizeWindow = window;
                    initialFitPendingWindow = IntPtr.Zero;
                    exactVideoSizeFitGeneration = videoSize.IsEmpty
                        ? -1 : videoSizeGeneration;
                    int orientation = VideoOrientation(videoSize);
                    appliedVideoOrientation = orientation != 0
                        ? orientation : GetWindowOrientation(window);
                    Log("Renderer window fitted manually" +
                        VideoSizeLogSuffix(videoSize) + ".");
                    return;
                }
                Log("Manual renderer window fit failed for the visible " +
                    "renderer window.");
                return;
            }

            Log("Manual renderer window fit skipped: no visible renderer " +
                "window was found after five attempts.");
            if (notifyIfMissing && settings.Notify)
                tray.ShowBalloonTip(3000, AppTitle,
                    "Окно трансляции пока не найдено. Подключите iPhone и повторите.",
                    ToolTipIcon.Info);
        }

        private static bool IsRendererWindowTitle(string value)
        {
            return value.IndexOf("renderer", StringComparison.OrdinalIgnoreCase) >= 0 ||
                value.IndexOf("video", StringComparison.OrdinalIgnoreCase) >= 0 ||
                value.IndexOf("AirPlay", StringComparison.OrdinalIgnoreCase) >= 0 ||
                value.IndexOf("AeroMirror", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private Size GetStableVideoSize(out int generation)
        {
            lock (videoSizeSync)
            {
                if (!pendingVideoSize.IsEmpty &&
                    DateTime.UtcNow >= pendingVideoSizeDueUtc)
                {
                    currentVideoSize = pendingVideoSize;
                    currentVideoSizeGeneration =
                        pendingVideoSizeGeneration;
                    pendingVideoSize = Size.Empty;
                    pendingVideoSizeDueUtc = DateTime.MinValue;
                    pendingVideoSizeGeneration = 0;
                }
                generation = currentVideoSizeGeneration;
                return currentVideoSize;
            }
        }

        private static int VideoOrientation(Size videoSize)
        {
            if (videoSize.Width <= 0 || videoSize.Height <= 0 ||
                videoSize.Width == videoSize.Height)
                return 0;
            return videoSize.Height > videoSize.Width ? 1 : 2;
        }

        private static int GetWindowOrientation(IntPtr window)
        {
            NativeMethods.RECT client;
            if (!NativeMethods.GetClientRect(window, out client))
                return 0;
            int width = client.Right - client.Left;
            int height = client.Bottom - client.Top;
            if (width <= 0 || height <= 0 || width == height)
                return 0;
            return height > width ? 1 : 2;
        }

        private static string VideoSizeLogSuffix(Size videoSize)
        {
            return videoSize.Width > 0 && videoSize.Height > 0
                ? " for " + videoSize.Width + "x" + videoSize.Height
                : " using the iPhone fallback aspect";
        }

        private static bool FitRendererWindow(
            IntPtr window, Size videoSize, bool preserveClientArea)
        {
            NativeMethods.RECT outer;
            NativeMethods.RECT client;
            if (!NativeMethods.GetWindowRect(window, out outer) ||
                !NativeMethods.GetClientRect(window, out client))
                return false;

            int outerWidth = outer.Right - outer.Left;
            int outerHeight = outer.Bottom - outer.Top;
            int clientWidth = client.Right - client.Left;
            int clientHeight = client.Bottom - client.Top;
            if (outerWidth <= 0 || outerHeight <= 0 ||
                clientWidth <= 0 || clientHeight <= 0)
                return false;

            const double phoneAspect = 9.0 / 19.5;
            double aspect = videoSize.Width > 0 && videoSize.Height > 0
                ? (double)videoSize.Width / videoSize.Height
                : (clientHeight >= clientWidth
                    ? phoneAspect : 1.0 / phoneAspect);
            int targetClientWidth;
            int targetClientHeight;
            if (preserveClientArea)
            {
                double area = Math.Max(
                    1.0, (double)clientWidth * clientHeight);
                targetClientWidth = Math.Max(
                    1, (int)Math.Round(Math.Sqrt(area * aspect)));
                targetClientHeight = Math.Max(
                    1, (int)Math.Round(targetClientWidth / aspect));
            }
            else if (aspect <= 1.0)
            {
                targetClientHeight = clientHeight;
                targetClientWidth =
                    (int)Math.Round(targetClientHeight * aspect);
                if (targetClientWidth < 280)
                {
                    targetClientWidth = 280;
                    targetClientHeight =
                        (int)Math.Round(targetClientWidth / aspect);
                }
            }
            else
            {
                targetClientWidth = clientWidth;
                targetClientHeight =
                    (int)Math.Round(targetClientWidth / aspect);
                if (targetClientHeight < 280)
                {
                    targetClientHeight = 280;
                    targetClientWidth =
                        (int)Math.Round(targetClientHeight * aspect);
                }
            }

            int borderWidth = outerWidth - clientWidth;
            int borderHeight = outerHeight - clientHeight;
            Rectangle workArea = Screen.FromHandle(window).WorkingArea;
            int maxClientWidth = Math.Max(
                280, (int)Math.Floor(workArea.Width * 0.88) - borderWidth);
            int maxClientHeight = Math.Max(
                280, (int)Math.Floor(workArea.Height * 0.88) - borderHeight);
            double scale = Math.Min(
                1.0,
                Math.Min(
                    (double)maxClientWidth / targetClientWidth,
                    (double)maxClientHeight / targetClientHeight));
            if (scale < 1.0)
            {
                targetClientWidth =
                    Math.Max(1, (int)Math.Round(targetClientWidth * scale));
                targetClientHeight =
                    Math.Max(1, (int)Math.Round(targetClientHeight * scale));
            }
            if (Math.Abs(targetClientWidth - clientWidth) <= 4 &&
                Math.Abs(targetClientHeight - clientHeight) <= 4)
                return true;

            int targetOuterWidth = targetClientWidth + borderWidth;
            int targetOuterHeight = targetClientHeight + borderHeight;
            int x = outer.Left;
            int y = outer.Top;
            uint flags = NativeMethods.SWP_NOZORDER |
                NativeMethods.SWP_NOACTIVATE;
            if (preserveClientArea)
            {
                int centerX = outer.Left + outerWidth / 2;
                int centerY = outer.Top + outerHeight / 2;
                x = centerX - targetOuterWidth / 2;
                y = centerY - targetOuterHeight / 2;
                x = Math.Max(
                    workArea.Left,
                    Math.Min(x, workArea.Right - targetOuterWidth));
                y = Math.Max(
                    workArea.Top,
                    Math.Min(y, workArea.Bottom - targetOuterHeight));
            }
            else
            {
                flags |= NativeMethods.SWP_NOMOVE;
            }
            return NativeMethods.SetWindowPos(
                window, IntPtr.Zero, x, y,
                targetOuterWidth, targetOuterHeight, flags);
        }

        private void ApplyAutostart(bool enabled)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.CreateSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Run"))
                {
                    if (enabled)
                    {
                        key.SetValue("AeroMirror",
                            "\"" + Assembly.GetExecutingAssembly().Location + "\" --startup",
                            RegistryValueKind.String);
                        key.DeleteValue("AirPlayReceiverMvp", false);
                    }
                    else
                    {
                        key.DeleteValue("AeroMirror", false);
                        key.DeleteValue("AirPlayReceiverMvp", false);
                    }
                }
            }
            catch (Exception ex)
            {
                Log("ERROR updating autostart: " + ex.Message);
            }
        }

        private bool IsAutostartEnabled()
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Run"))
                {
                    return key != null &&
                        (key.GetValue("AeroMirror") != null ||
                         key.GetValue("AirPlayReceiverMvp") != null);
                }
            }
            catch { return false; }
        }

        private string GetBonjourStatus()
        {
            string[] names = { "Bonjour Service", "mDNSResponder" };
            foreach (string name in names)
            {
                try
                {
                    using (var service = new ServiceController(name))
                    {
                        ServiceControllerStatus status = service.Status;
                        return status.ToString();
                    }
                }
                catch { }
            }
            return "не установлен или недоступен";
        }

        private void ShowDiagnostics()
        {
            using (var dialog = new DiagnosticsForm(GetDiagnostics()))
                dialog.ShowDialog();
        }

        private void OpenLog()
        {
            if (!File.Exists(AppSettings.LogPath))
                File.WriteAllText(AppSettings.LogPath, "", Encoding.UTF8);
            Process.Start(new ProcessStartInfo(AppSettings.LogPath) { UseShellExecute = true });
        }

        public void OpenProblemReport(IWin32Window owner)
        {
            try
            {
                FlushLog(1000);
                string folder = Path.Combine(
                    Path.GetTempPath(), "AeroMirror", "Support");
                Directory.CreateDirectory(folder);
                string path = Path.Combine(
                    folder,
                    "AeroMirror-report-" +
                    DateTime.Now.ToString("yyyyMMdd-HHmmss") + ".log");

                var report = new StringBuilder();
                report.AppendLine(
                    "AeroMirror support report — review before attaching");
                report.AppendLine(
                    "Created: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                report.AppendLine();
                report.AppendLine(GetDiagnostics());
                report.AppendLine();
                report.AppendLine("Recent application log:");
                report.AppendLine(ReadLogTail(AppSettings.LogPath, 1024 * 1024));
                File.WriteAllText(
                    path,
                    RedactSupportText(report.ToString(), settings.FixedPin),
                    new UTF8Encoding(false));

                string issueBody =
                    "Опишите, что произошло и как повторить проблему.\r\n\r\n" +
                    "Версия AeroMirror: " + AppVersion.Display + "\r\n" +
                    "Windows: " + Environment.OSVersion.Version + "\r\n\r\n" +
                    "AeroMirror подготовил обезличенный файл `" +
                    Path.GetFileName(path) + "`. GitHub не разрешает приложению " +
                    "прикрепить локальный файл автоматически: перетащите выбранный " +
                    "файл в это сообщение после входа в GitHub.";
                string issueUrl =
                    "https://github.com/Nadejny/aeromirror/issues/new" +
                    "?title=" + Uri.EscapeDataString("[Bug] ") +
                    "&body=" + Uri.EscapeDataString(issueBody);
                Process.Start(new ProcessStartInfo(issueUrl)
                {
                    UseShellExecute = true
                });
                Process.Start(new ProcessStartInfo("explorer.exe")
                {
                    Arguments = "/select,\"" + path + "\"",
                    UseShellExecute = true
                });
                MessageBox.Show(
                    owner,
                    "Открыта форма GitHub Issue и выделен обезличенный файл журнала.\r\n\r\n" +
                    "Проверьте его и перетащите в форму — AeroMirror ничего не " +
                    "отправляет автоматически.",
                    AppTitle,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                Log("Support report could not be prepared: " + ex.Message);
                MessageBox.Show(
                    owner,
                    "Не удалось подготовить сообщение о проблеме.\r\n\r\n" +
                    ex.Message,
                    AppTitle,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        private static string ReadLogTail(string path, int maximumBytes)
        {
            if (!File.Exists(path))
                return "(log file is empty)";
            using (var stream = new FileStream(
                path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.ReadWrite | FileShare.Delete))
            {
                bool truncated = stream.Length > maximumBytes;
                if (truncated)
                    stream.Seek(-maximumBytes, SeekOrigin.End);
                using (var reader = new StreamReader(
                    stream, Encoding.UTF8, true, 4096, false))
                {
                    if (truncated)
                        reader.ReadLine();
                    string text = reader.ReadToEnd();
                    return truncated
                        ? "(older log entries omitted)\r\n" + text
                        : text;
                }
            }
        }

        private void SetState(bool running, string text)
        {
            receiverStateText = text;
            statusItem.Text = running ? "● " + text : "○ " + text;
            startStopItem.Text = running ? "Остановить приёмник" : "Запустить приёмник";
            tray.Text = text.Length > 63 ? text.Substring(0, 63) : text;
        }

        private void Quit()
        {
            quitting = true;
            monitorTimer.Stop();
            NetworkChange.NetworkAddressChanged -= OnNetworkAddressChanged;
            restartPending = false;
            restartAfterStop = false;
            if (Interlocked.CompareExchange(
                    ref restartStopInProgress, 0, 0) == 1)
            {
                restartStopDone.WaitOne(4000);
                Interlocked.Exchange(ref restartStopInProgress, 0);
                Interlocked.Exchange(ref restartStopCompleted, 0);
            }
            StopCoreInternal("application exit", true, true);
            Log("=== AeroMirror session ended ===");
            FlushLog(1000);
            tray.Visible = false;
            tray.Dispose();
            ExitThread();
        }

        private void RequestQuit()
        {
            if (form != null && !form.IsDisposed &&
                !form.ConfirmCloseForQuit())
            {
                ShowSettings();
                return;
            }
            Quit();
        }

        private static string QuoteArgument(string value)
        {
            return "\"" + value.Replace("\"", "\\\"") + "\"";
        }

        internal static void Log(string message)
        {
            string line = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") +
                "  " + RedactSensitiveText(message, "") +
                Environment.NewLine;
            bool scheduleWriter = false;
            lock (LogSync)
            {
                if (LogQueue.Count >= 10000)
                {
                    LogQueue.Dequeue();
                    if (!logOverflowReported)
                    {
                        LogQueue.Enqueue(
                            DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") +
                            "  WARN: log queue overflow; oldest lines were dropped." +
                            Environment.NewLine);
                        logOverflowReported = true;
                    }
                }
                LogQueue.Enqueue(line);
                if (!logWriterScheduled)
                {
                    logWriterScheduled = true;
                    LogQueueDrained.Reset();
                    scheduleWriter = true;
                }
            }
            if (scheduleWriter)
                ThreadPool.QueueUserWorkItem(delegate { FlushLogQueue(); });
        }

        private static readonly object LogSync = new object();
        private static readonly Queue<string> LogQueue =
            new Queue<string>();
        private static bool logWriterScheduled;
        private static bool logOverflowReported;
        private static readonly ManualResetEvent LogQueueDrained =
            new ManualResetEvent(true);

        private static void FlushLogQueue()
        {
            const long maxLogBytes = 5L * 1024L * 1024L;
            while (true)
            {
                var batch = new StringBuilder();
                lock (LogSync)
                {
                    int count = 0;
                    while (LogQueue.Count > 0 && count < 250)
                    {
                        batch.Append(LogQueue.Dequeue());
                        count++;
                    }
                    if (batch.Length == 0)
                    {
                        logWriterScheduled = false;
                        logOverflowReported = false;
                        LogQueueDrained.Set();
                        return;
                    }
                }

                try
                {
                    if (File.Exists(AppSettings.LogPath) &&
                        new FileInfo(AppSettings.LogPath).Length >=
                            maxLogBytes)
                    {
                        string previous = AppSettings.LogPath + ".1";
                        try
                        {
                            if (File.Exists(previous))
                                File.Delete(previous);
                            File.Move(AppSettings.LogPath, previous);
                        }
                        catch
                        {
                            // Rotation must not prevent current diagnostics
                            // from being appended to the active file.
                        }
                    }
                    File.AppendAllText(
                        AppSettings.LogPath, batch.ToString(),
                        new UTF8Encoding(false));
                }
                catch { }
            }
        }

        internal static void FlushLog(int timeoutMilliseconds)
        {
            try { LogQueueDrained.WaitOne(timeoutMilliseconds); }
            catch { }
        }
    }

    internal sealed class SettingsForm : Form
    {
        private readonly ReceiverContext context;
        private readonly Panel homePage;
        private readonly Panel settingsPage;
        private readonly Panel advancedPage;
        private readonly Panel updatesPage;
        private readonly Label status;
        private readonly Label statusDot;
        private readonly Panel networkCard;
        private readonly Label networkTitle;
        private readonly Label networkHelp;
        private readonly Panel trustCard;
        private readonly Button refreshDiscovery;
        private readonly Button settingsButton;
        private readonly Button updatesButton;
        private readonly LinkLabel reportProblem;
        private readonly Label homeQuality;
        private readonly ToolTip toolTips;
        private readonly TextBox receiverName;
        private readonly ComboBox quality;
        private readonly ComboBox pairing;
        private readonly Label accessNote;
        private readonly Panel pinPanel;
        private readonly TextBox fixedPin;
        private readonly ComboBox latency;
        private readonly ComboBox audioOutput;
        private readonly ComboBox theme;
        private readonly CheckBox topMost;
        private readonly CheckBox autoFit;
        private readonly CheckBox showStreamInTaskbar;
        private readonly CheckBox autoReceiver;
        private readonly CheckBox autoWindows;
        private readonly CheckBox startMinimized;
        private readonly CheckBox closeToTray;
        private readonly CheckBox notifications;
        private readonly Button startStop;
        private readonly Button saveButton;
        private readonly Label savedLabel;
        private readonly ComboBox renderer;
        private readonly TextBox arguments;
        private readonly TextBox argumentPreview;
        private readonly Button advancedSave;
        private readonly Label updateState;
        private readonly Label updateTitle;
        private readonly TextBox updateNotes;
        private readonly Button checkUpdate;
        private readonly Button installUpdate;
        private readonly Button openRelease;
        private UpdateInfo availableUpdate;
        private string pendingInstallerPath = "";
        private bool suppressDirty;
        private bool? appliedDarkTheme;
        private DateTime nextThemeCheck;
        private bool homePageSelected;

        public SettingsForm(ReceiverContext context)
        {
            this.context = context;
            Text = "AeroMirror";
            Icon = AppIcon.Current;
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            ClientSize = new Size(620, 430);
            MinimumSize = new Size(636, 369);
            BackColor = Color.FromArgb(247, 247, 247);
            Font = new Font("Segoe UI", 9.5F);

            homePage = new Panel();
            homePage.Dock = DockStyle.Fill;
            homePage.BackColor = BackColor;
            Controls.Add(homePage);

            toolTips = new ToolTip();
            toolTips.AutoPopDelay = 12000;
            toolTips.InitialDelay = 350;
            toolTips.ReshowDelay = 100;
            toolTips.ShowAlways = true;

            var homeHeader = new Panel();
            homeHeader.Dock = DockStyle.Top;
            homeHeader.Height = 96;
            homeHeader.BackColor = Color.White;
            homePage.Controls.Add(homeHeader);

            var logo = new PictureBox();
            logo.Image = AppIcon.Image;
            logo.SizeMode = PictureBoxSizeMode.Zoom;
            logo.Location = new Point(24, 20);
            logo.Size = new Size(52, 52);
            homeHeader.Controls.Add(logo);

            var title = MakeLabel("AeroMirror", 91, 15);
            title.Font = new Font("Segoe UI Semibold", 19F);
            homeHeader.Controls.Add(title);

            statusDot = MakeLabel("●", 92, 51);
            statusDot.AutoSize = false;
            statusDot.Size = new Size(16, 24);
            statusDot.Font = new Font("Segoe UI", 11F);
            statusDot.AccessibleName = "Состояние приёмника";
            homeHeader.Controls.Add(statusDot);

            status = MakeLabel("", 112, 53);
            status.AutoSize = false;
            status.Size = new Size(420, 24);
            status.AutoEllipsis = true;
            status.Font = new Font("Segoe UI Semibold", 10.5F);
            homeHeader.Controls.Add(status);

            settingsButton = MakeButton(
                "\uE713", 552, 28, 44, 36, false);
            settingsButton.Font = new Font("Segoe MDL2 Assets", 14F);
            settingsButton.AccessibleName = "Настройки";
            settingsButton.Click += delegate { ShowSettingsPage(false); };
            toolTips.SetToolTip(settingsButton, "Настройки");
            homeHeader.Controls.Add(settingsButton);

            networkCard = new Panel();
            networkCard.Location = new Point(24, 112);
            networkCard.Size = new Size(572, 50);
            homePage.Controls.Add(networkCard);

            networkTitle = MakeLabel("", 15, 10);
            networkTitle.AutoSize = false;
            networkTitle.Size = new Size(505, 27);
            networkTitle.AutoEllipsis = true;
            networkTitle.Font = new Font("Segoe UI Semibold", 9.5F);
            networkCard.Controls.Add(networkTitle);

            networkHelp = MakeLabel("?", 533, 10);
            networkHelp.AutoSize = false;
            networkHelp.Size = new Size(24, 24);
            networkHelp.TextAlign = ContentAlignment.MiddleCenter;
            networkHelp.Font = new Font("Segoe UI Semibold", 10F);
            networkHelp.Cursor = Cursors.Help;
            networkHelp.AccessibleName = "Подробнее о проверке сети";
            networkCard.Controls.Add(networkHelp);

            trustCard = new Panel();
            trustCard.Location = new Point(24, 178);
            trustCard.Size = new Size(572, 94);
            trustCard.BackColor = Color.FromArgb(242, 247, 253);
            homePage.Controls.Add(trustCard);

            var trustTitle = MakeLabel(
                "Подключайтесь безопасно в любой знакомой и новой сети", 15, 10);
            trustTitle.Font = new Font("Segoe UI Semibold", 9.5F);
            trustCard.Controls.Add(trustTitle);

            var trustText = new Label();
            trustText.Text =
                "Настройте PIN один раз: iPhone и ноутбук сохранят ключи друг друга.\r\n" +
                "После этого смена домашнего Wi-Fi сама по себе не потребует нового PIN.";
            trustText.AutoSize = false;
            trustText.Size = new Size(405, 48);
            trustText.Location = new Point(15, 37);
            trustText.ForeColor = Color.FromArgb(55, 55, 55);
            trustCard.Controls.Add(trustText);

            var dismissPinSuggestion = MakeButton("×", 531, 7, 26, 26, false);
            dismissPinSuggestion.FlatAppearance.BorderSize = 0;
            dismissPinSuggestion.Click += delegate
            {
                AppSettings updated = context.CurrentSettings.Copy();
                updated.DismissPinSuggestion = true;
                context.SaveSettings(updated, false);
                SyncStatus();
            };
            trustCard.Controls.Add(dismissPinSuggestion);

            var pinSetup = MakeButton("Настроить PIN", 425, 48, 130, 34, false);
            pinSetup.Click += delegate { ShowSettingsPage(true); };
            trustCard.Controls.Add(pinSetup);

            refreshDiscovery = MakeButton(
                "Перезапустить обнаружение", 24, 314, 224, 38, false);
            refreshDiscovery.Click += delegate
            {
                context.RefreshDiscovery();
                SyncStatus();
            };
            homePage.Controls.Add(refreshDiscovery);

            startStop = MakeButton("", 260, 314, 145, 38, true);
            startStop.Click += delegate
            {
                if (context.IsCoreRunning) context.StopCore(); else context.StartCore();
                SyncStatus();
            };
            homePage.Controls.Add(startStop);

            updatesButton = MakeButton(
                "Обновления", 417, 314, 179, 38, false);
            updatesButton.Click += delegate { ShowUpdatesPage(); };
            homePage.Controls.Add(updatesButton);

            homeQuality = MakeLabel("", 26, 365);
            homeQuality.AutoSize = false;
            homeQuality.Size = new Size(570, 22);
            homeQuality.ForeColor = Color.DimGray;
            homePage.Controls.Add(homeQuality);

            reportProblem = new LinkLabel();
            reportProblem.Text = "Сообщить о проблеме";
            reportProblem.AutoSize = true;
            reportProblem.Location = new Point(452, 398);
            reportProblem.LinkClicked += delegate
            {
                context.OpenProblemReport(this);
            };
            homePage.Controls.Add(reportProblem);

            settingsPage = new Panel();
            settingsPage.Dock = DockStyle.Fill;
            settingsPage.AutoScroll = true;
            settingsPage.BackColor = BackColor;
            settingsPage.Visible = false;
            Controls.Add(settingsPage);

            var settingsContent = new Panel();
            settingsContent.Location = new Point(0, 0);
            settingsContent.Size = new Size(600, 1090);
            settingsContent.BackColor = BackColor;
            settingsPage.Controls.Add(settingsContent);

            var back = MakeButton("‹  Назад", 20, 16, 90, 34, false);
            back.Click += delegate { TryLeaveSettingsToHome(); };
            settingsContent.Controls.Add(back);

            var settingsTitle = MakeLabel("Настройки", 126, 17);
            settingsTitle.Font = new Font("Segoe UI Semibold", 18F);
            settingsContent.Controls.Add(settingsTitle);

            AddSection(settingsContent, "Видео и звук", 24, 72);

            settingsContent.Controls.Add(MakeLabel(
                "Имя в меню «Повтор экрана»", 24, 108));
            receiverName = new TextBox();
            receiverName.Location = new Point(24, 130);
            receiverName.Size = new Size(552, 27);
            settingsContent.Controls.Add(receiverName);

            settingsContent.Controls.Add(MakeLabel("Качество трансляции", 24, 174));
            quality = new WheelSafeComboBox();
            quality.Location = new Point(24, 196);
            quality.Size = new Size(552, 42);
            quality.DropDownStyle = ComboBoxStyle.DropDownList;
            quality.FlatStyle = FlatStyle.Flat;
            quality.DrawMode = DrawMode.OwnerDrawFixed;
            quality.ItemHeight = 38;
            quality.DropDownHeight = 160;
            quality.IntegralHeight = false;
            quality.DrawItem += DrawQualityItem;
            quality.Items.Add(new NamedValue(
                "4K · 60 FPS", "4k60",
                "HEVC · максимальный запрос; фактическое разрешение выбирает iPhone"));
            quality.Items.Add(new NamedValue(
                "Full HD · 60 FPS", "1080p60",
                "Рекомендуется · плавное движение"));
            quality.Items.Add(new NamedValue(
                "Full HD · 30 FPS", "1080p30",
                "Меньше нагрузка на сеть и компьютер"));
            quality.Items.Add(new NamedValue(
                "HD · 30 FPS", "720p30",
                "Для слабой сети или маломощного компьютера"));
            settingsContent.Controls.Add(quality);

            var qualityNote = MakeFixedLabel(
                "Качество применяется после сохранения и нового подключения iPhone.",
                27, 241, 548, 30);
            qualityNote.ForeColor = Color.DimGray;
            settingsContent.Controls.Add(qualityNote);

            settingsContent.Controls.Add(MakeLabel("Профиль задержки", 24, 276));
            latency = MakeCombo(24, 298, 552);
            latency.Items.Add(new NamedValue(
                "Сбалансированный — рекомендуется", "balanced"));
            latency.Items.Add(new NamedValue(
                "Минимальный — меньше буфер, возможны рывки", "low"));
            latency.Items.Add(new NamedValue(
                "Стабильный — больше буфер и заметнее задержка", "stable"));
            settingsContent.Controls.Add(latency);

            settingsContent.Controls.Add(MakeLabel("Вывод звука", 24, 340));
            audioOutput = MakeCombo(24, 362, 552);
            audioOutput.Items.Add(new NamedValue(
                "Системное устройство Windows по умолчанию", "default"));
            audioOutput.Items.Add(new NamedValue(
                "Без звука на компьютере", "mute"));
            settingsContent.Controls.Add(audioOutput);

            topMost = MakeCheckBox(
                "Показывать окно трансляции поверх остальных окон", 24, 406);
            settingsContent.Controls.Add(topMost);

            autoFit = MakeCheckBox(
                "Автоматически подгонять окно при открытии и повороте iPhone", 24, 438);
            settingsContent.Controls.Add(autoFit);

            showStreamInTaskbar = MakeCheckBox(
                "Показывать окно трансляции на панели задач", 24, 470);
            settingsContent.Controls.Add(showStreamInTaskbar);

            AddSection(settingsContent, "Защита подключения", 24, 516);

            pairing = MakeCombo(24, 550, 552);
            pairing.Items.Add(new NamedValue(
                "Без PIN — удобно для частной домашней сети", "none"));
            pairing.Items.Add(new NamedValue(
                "С PIN — один раз для доверия этому iPhone", "pin"));
            pairing.SelectedIndexChanged += delegate { UpdatePinPanel(); };
            settingsContent.Controls.Add(pairing);

            accessNote = MakeFixedLabel("", 27, 585, 548, 60);
            accessNote.ForeColor = Color.DimGray;
            settingsContent.Controls.Add(accessNote);

            pinPanel = new Panel();
            pinPanel.Location = new Point(24, 584);
            pinPanel.Size = new Size(552, 76);
            pinPanel.BackColor = Color.FromArgb(237, 246, 255);
            settingsContent.Controls.Add(pinPanel);

            pinPanel.Controls.Add(MakeLabel(
                "PIN, который нужно ввести на iPhone", 13, 7));
            fixedPin = new TextBox();
            fixedPin.Location = new Point(15, 28);
            fixedPin.Size = new Size(130, 25);
            fixedPin.MaxLength = 4;
            fixedPin.Font = new Font("Segoe UI Semibold", 10F);
            pinPanel.Controls.Add(fixedPin);

            var generate = MakeButton("Новый PIN", 154, 27, 105, 28, false);
            generate.Click += delegate { fixedPin.Text = GeneratePin(); };
            pinPanel.Controls.Add(generate);

            var pinNote = MakeFixedLabel(
                "Ключ хранится для пары iPhone + ноутбук,\r\nа не для конкретной Wi-Fi-сети.",
                276, 25, 260, 43);
            pinNote.ForeColor = Color.DimGray;
            pinPanel.Controls.Add(pinNote);

            AddSection(settingsContent, "Запуск и поведение приложения", 24, 682);

            settingsContent.Controls.Add(MakeLabel("Цветовая тема", 24, 718));
            theme = MakeCombo(24, 740, 552);
            theme.Items.Add(new NamedValue(
                "Как в Windows", "system"));
            theme.Items.Add(new NamedValue(
                "Светлая", "light"));
            theme.Items.Add(new NamedValue(
                "Тёмная", "dark"));
            theme.SelectedIndexChanged += delegate
            {
                if (!suppressDirty)
                    MarkDirty();
            };
            settingsContent.Controls.Add(theme);

            autoReceiver = MakeCheckBox(
                "Держать приёмник включённым, пока приложение работает", 24, 790);
            settingsContent.Controls.Add(autoReceiver);

            autoWindows = MakeCheckBox(
                "Запускать AeroMirror вместе с Windows", 24, 822);
            autoWindows.CheckedChanged += delegate { UpdateStartupChild(); };
            settingsContent.Controls.Add(autoWindows);

            startMinimized = MakeCheckBox(
                "При запуске с Windows сразу скрывать в трей", 48, 854);
            startMinimized.ForeColor = Color.FromArgb(70, 70, 70);
            settingsContent.Controls.Add(startMinimized);

            closeToTray = MakeCheckBox(
                "По кнопке × сворачивать в трей, а не закрывать приложение", 24, 886);
            settingsContent.Controls.Add(closeToTray);

            notifications = MakeCheckBox(
                "Показывать служебные уведомления приёмника", 24, 918);
            settingsContent.Controls.Add(notifications);

            var notificationsNote = MakeLabel(
                "Это предупреждения об ошибках и безопасности сети — не SMS с iPhone.",
                48, 942);
            notificationsNote.ForeColor = Color.DimGray;
            settingsContent.Controls.Add(notificationsNote);

            var advancedButton = MakeButton(
                "Дополнительные настройки", 24, 908, 220, 36, false);
            advancedButton.Location = new Point(24, 980);
            advancedButton.Click += delegate { ShowAdvancedPage(); };
            settingsContent.Controls.Add(advancedButton);

            savedLabel = MakeLabel("", 24, 976);
            savedLabel.AutoSize = false;
            savedLabel.Size = new Size(552, 22);
            savedLabel.TextAlign = ContentAlignment.MiddleRight;
            savedLabel.ForeColor = Color.FromArgb(42, 122, 74);
            settingsContent.Controls.Add(savedLabel);

            saveButton = MakeButton("Сохранить", 426, 1008, 150, 40, true);
            saveButton.Click += OnSave;
            settingsContent.Controls.Add(saveButton);

            advancedButton.Location = new Point(24, 1010);

            advancedPage = new Panel();
            advancedPage.Dock = DockStyle.Fill;
            advancedPage.BackColor = BackColor;
            advancedPage.Visible = false;
            Controls.Add(advancedPage);

            var advancedBack = MakeButton("‹  Назад", 20, 16, 90, 34, false);
            advancedBack.Click += delegate { TryLeaveAdvancedToSettings(); };
            advancedPage.Controls.Add(advancedBack);

            var advancedTitle = MakeLabel("Дополнительные настройки", 126, 17);
            advancedTitle.Font = new Font("Segoe UI Semibold", 18F);
            advancedPage.Controls.Add(advancedTitle);

            var advancedWarning = MakeFixedLabel(
                "Эти параметры нужны для совместимости и диагностики. " +
                "Если всё работает, их лучше не менять.",
                24, 67, 552, 42);
            advancedWarning.ForeColor = Color.DimGray;
            advancedPage.Controls.Add(advancedWarning);

            advancedPage.Controls.Add(MakeLabel("Видеорендер", 24, 122));
            renderer = MakeCombo(24, 145, 552);
            renderer.Items.Add(new NamedValue(
                "Автоматический выбор GStreamer — рекомендуется", "auto"));
            renderer.Items.Add(new NamedValue(
                "Direct3D 11 — режим совместимости", "d3d11"));
            renderer.Items.Add(new NamedValue(
                "Direct3D 12 — экспериментально", "d3d12"));
            advancedPage.Controls.Add(renderer);

            advancedPage.Controls.Add(MakeLabel(
                "Дополнительные аргументы UxPlay", 24, 195));
            arguments = new TextBox();
            arguments.Location = new Point(24, 218);
            arguments.Size = new Size(552, 88);
            arguments.Multiline = true;
            arguments.ScrollBars = ScrollBars.Vertical;
            arguments.Font = new Font("Consolas", 9F);
            advancedPage.Controls.Add(arguments);

            var argsNote = MakeFixedLabel(
                "Аргументы добавляются в конец команды и могут переопределить " +
                "обычные настройки приложения.",
                24, 312, 552, 42);
            argsNote.ForeColor = Color.DimGray;
            advancedPage.Controls.Add(argsNote);

            advancedPage.Controls.Add(MakeLabel(
                "Текущие аргументы запуска", 24, 365));
            argumentPreview = new TextBox();
            argumentPreview.Location = new Point(24, 388);
            argumentPreview.Size = new Size(552, 76);
            argumentPreview.Multiline = true;
            argumentPreview.ReadOnly = true;
            argumentPreview.BackColor = Color.White;
            argumentPreview.Font = new Font("Consolas", 8.5F);
            advancedPage.Controls.Add(argumentPreview);

            var hotspot = MakeButton(
                "Временная личная сеть…", 24, 492, 205, 36, false);
            hotspot.Click += delegate { OpenMobileHotspot(this); };
            advancedPage.Controls.Add(hotspot);

            var diagnostics = MakeButton(
                "Диагностика", 244, 492, 145, 36, false);
            diagnostics.Click += delegate
            {
                using (var dialog = new DiagnosticsForm(context.GetDiagnostics()))
                    dialog.ShowDialog(this);
            };
            advancedPage.Controls.Add(diagnostics);

            advancedSave = MakeButton("Сохранить", 426, 488, 150, 40, true);
            advancedSave.Click += OnAdvancedSave;
            advancedPage.Controls.Add(advancedSave);

            updatesPage = new Panel();
            updatesPage.Dock = DockStyle.Fill;
            updatesPage.BackColor = BackColor;
            updatesPage.Visible = false;
            Controls.Add(updatesPage);

            var updatesBack = MakeButton("‹  Назад", 20, 16, 90, 34, false);
            updatesBack.Click += delegate { ShowHomePage(); };
            updatesPage.Controls.Add(updatesBack);

            var updatesTitle = MakeLabel("Обновления", 126, 17);
            updatesTitle.Font = new Font("Segoe UI Semibold", 18F);
            updatesPage.Controls.Add(updatesTitle);

            var currentVersion = MakeLabel(
                "Установлена версия " +
                AppVersion.Display,
                24, 76);
            currentVersion.ForeColor = Color.DimGray;
            updatesPage.Controls.Add(currentVersion);

            checkUpdate = MakeButton(
                "Проверить обновления", 396, 66, 180, 38, true);
            checkUpdate.Click += delegate { CheckForUpdates(); };
            updatesPage.Controls.Add(checkUpdate);

            updateState = MakeFixedLabel(
                "Проверка выполняется только по нажатию. " +
                "Приложение обращается к публичному GitHub Release.",
                24, 116, 552, 42);
            updateState.ForeColor = Color.DimGray;
            updatesPage.Controls.Add(updateState);

            updateTitle = MakeLabel("", 24, 172);
            updateTitle.Font = new Font("Segoe UI Semibold", 14F);
            updatesPage.Controls.Add(updateTitle);

            updateNotes = new TextBox();
            updateNotes.Location = new Point(24, 210);
            updateNotes.Size = new Size(552, 240);
            updateNotes.Multiline = true;
            updateNotes.ReadOnly = true;
            updateNotes.ScrollBars = ScrollBars.Vertical;
            updateNotes.BackColor = Color.White;
            updateNotes.Text =
                "Здесь появится короткое описание новой версии: " +
                "что добавлено, что исправлено и стоит ли обновляться.";
            updatesPage.Controls.Add(updateNotes);

            openRelease = MakeButton(
                "Открыть страницу релиза", 24, 478, 200, 38, false);
            openRelease.Enabled = false;
            openRelease.Click += delegate
            {
                if (availableUpdate != null &&
                    !string.IsNullOrWhiteSpace(availableUpdate.ReleasePage))
                    Process.Start(new ProcessStartInfo(
                        availableUpdate.ReleasePage)
                    {
                        UseShellExecute = true
                    });
            };
            updatesPage.Controls.Add(openRelease);

            installUpdate = MakeButton(
                "Скачать и установить", 376, 474, 200, 42, true);
            installUpdate.Enabled = false;
            installUpdate.Click += delegate { DownloadUpdate(); };
            updatesPage.Controls.Add(installUpdate);

            LoadSettings();
            WireDirtyTracking();
            settingsPage.Scroll += delegate { CloseOpenDropDowns(); };
            settingsPage.MouseWheel += delegate { CloseOpenDropDowns(); };
            SetDirty(false);
            UpdateAdvancedDirty();
            ShowHomePage();

            FormClosing += delegate(object sender, FormClosingEventArgs e)
            {
                if (e.CloseReason == CloseReason.UserClosing)
                {
                    if (!ConfirmAllUnsavedChanges())
                    {
                        e.Cancel = true;
                        return;
                    }
                    if (context.CurrentSettings.CloseToTray)
                    {
                        e.Cancel = true;
                        Hide();
                    }
                    else
                    {
                        context.QuitApplication();
                    }
                }
            };
            FormClosed += delegate { DeletePendingInstaller(); };
        }

        public void SyncStatus()
        {
            if (IsDisposed)
                return;

            bool unsafeAccess = context.IsPublicNetwork &&
                context.CurrentSettings.PairingMode == "none";
            bool dark = appliedDarkTheme ??
                ThemeHelper.IsDark(context.CurrentSettings.ThemeMode);
            bool receiverReady = context.IsCoreRunning &&
                context.ReceiverStateText.IndexOf(
                    "включён", StringComparison.OrdinalIgnoreCase) >= 0;
            if (receiverReady)
            {
                status.Text = "Приёмник включён";
                status.ForeColor = dark
                    ? Color.FromArgb(94, 204, 126)
                    : Color.FromArgb(31, 122, 67);
                statusDot.ForeColor = status.ForeColor;
                startStop.Text = "Остановить";
            }
            else if (context.IsCoreRunning)
            {
                status.Text = "Приёмник запускается";
                status.ForeColor = dark
                    ? Color.FromArgb(255, 197, 92)
                    : Color.FromArgb(154, 92, 0);
                statusDot.ForeColor = status.ForeColor;
                startStop.Text = "Остановить";
            }
            else if (!context.IsNetworkProfileKnown &&
                context.CurrentSettings.PairingMode == "none")
            {
                status.Text = "Проверяем сеть";
                status.ForeColor = dark
                    ? Color.FromArgb(255, 197, 92)
                    : Color.FromArgb(154, 92, 0);
                statusDot.ForeColor = status.ForeColor;
                startStop.Text = "Проверить";
            }
            else if (unsafeAccess)
            {
                status.Text = "Приёмник приостановлен — включите PIN";
                status.ForeColor = dark
                    ? Color.FromArgb(255, 197, 92)
                    : Color.FromArgb(154, 92, 0);
                statusDot.ForeColor = status.ForeColor;
                startStop.Text = "Включить";
            }
            else
            {
                status.Text = "Приёмник выключен";
                status.ForeColor = dark
                    ? Color.FromArgb(225, 126, 126)
                    : Color.FromArgb(128, 70, 70);
                statusDot.ForeColor = dark
                    ? Color.FromArgb(238, 92, 92)
                    : Color.FromArgb(196, 43, 43);
                startStop.Text = "Включить";
            }
            toolTips.SetToolTip(status, context.ReceiverStateText);
            toolTips.SetToolTip(statusDot, context.ReceiverStateText);

            string networkDetails;
            if (unsafeAccess)
            {
                networkCard.BackColor = dark
                    ? Color.FromArgb(73, 57, 24)
                    : Color.FromArgb(255, 244, 215);
                networkTitle.Text = "Сеть «" + DisplayNetworkName() +
                    "» · публичная · требуется PIN" +
                    (context.HasNetworkOverlay
                        ? " · VPN/виртуальная сеть" : "");
                networkDetails = context.HasNetworkOverlay
                    ? "Проверен именно физический Wi-Fi или Ethernet. VPN и виртуальный профиль не меняют режим защиты. Windows считает физическую сеть публичной, поэтому для подключения нужен PIN."
                    : "Windows считает это физическое подключение публичной сетью. Без PIN приёмник приостановлен.";
                networkTitle.ForeColor = dark
                    ? Color.FromArgb(255, 197, 92)
                    : Color.FromArgb(133, 78, 0);
            }
            else
            {
                networkCard.BackColor = dark
                    ? Color.FromArgb(31, 50, 67)
                    : Color.FromArgb(237, 246, 255);
                if (!context.IsNetworkProfileKnown)
                {
                    networkTitle.Text = "Проверяем физическую сеть…";
                    networkDetails =
                        "Компьютер и iPhone должны находиться в одной локальной сети. VPN и виртуальные адаптеры не используются для определения режима защиты.";
                }
                else if (context.IsPublicNetwork)
                {
                    networkTitle.Text = "Сеть «" + DisplayNetworkName() +
                        "» · публичная · PIN включён" +
                        (context.HasNetworkOverlay
                            ? " · VPN/виртуальная сеть" : "");
                    networkDetails = context.HasNetworkOverlay
                        ? "Проверен именно физический Wi-Fi или Ethernet. VPN и виртуальный профиль не меняют режим защиты. Знакомый iPhone проверяется по сохранённому ключу."
                        : "PIN защищает первое подключение. Знакомый iPhone затем проверяется по сохранённому ключу.";
                }
                else
                {
                    networkTitle.Text = "Сеть «" + DisplayNetworkName() +
                        "» · частная" +
                        (context.HasNetworkOverlay
                            ? " · VPN/виртуальная сеть" : "");
                    networkDetails = context.HasNetworkOverlay
                        ? "Проверен именно физический Wi-Fi или Ethernet. VPN и виртуальный профиль не меняют режим защиты. В частной сети PIN необязателен, но его можно включить."
                        : "Windows пометила физическое подключение как частную сеть. PIN необязателен, но его можно включить.";
                }
                networkTitle.ForeColor = dark
                    ? Color.FromArgb(111, 190, 255)
                    : Color.FromArgb(0, 80, 145);
            }
            networkHelp.ForeColor = networkTitle.ForeColor;
            toolTips.SetToolTip(networkHelp, networkDetails);
            toolTips.SetToolTip(networkTitle, networkDetails);

            homeQuality.Text = "Качество: " +
                QualityDisplayName(context.CurrentSettings.QualityPreset) +
                "   ·   Имя приёмника: " + context.CurrentSettings.ReceiverName;
            bool showTrustCard =
                context.CurrentSettings.PairingMode != "pin" &&
                !context.CurrentSettings.DismissPinSuggestion;
            trustCard.Visible = showTrustCard;
            LayoutHome(showTrustCard);
            UpdateAccessNote();
        }

        public bool ConfirmCloseForQuit()
        {
            return ConfirmAllUnsavedChanges();
        }

        public void SyncTheme()
        {
            string mode = context.CurrentSettings.ThemeMode;
            if (string.Equals(mode, "system", StringComparison.OrdinalIgnoreCase) &&
                DateTime.UtcNow < nextThemeCheck)
                return;
            nextThemeCheck = DateTime.UtcNow.AddSeconds(2);
            bool dark = ThemeHelper.IsDark(mode);
            if (!appliedDarkTheme.HasValue || appliedDarkTheme.Value != dark)
                ApplyTheme();
        }

        private void ApplyTheme()
        {
            string mode = context.CurrentSettings.ThemeMode;
            bool dark = ThemeHelper.IsDark(mode);
            Point settingsScroll = settingsPage == null
                ? Point.Empty : settingsPage.AutoScrollPosition;
            NativeMethods.SetImmersiveDarkMode(Handle, dark);
            ThemeHelper.Apply(this, dark);
            if (settingsPage != null)
            {
                settingsPage.AutoScrollPosition = new Point(
                    Math.Max(0, -settingsScroll.X),
                    Math.Max(0, -settingsScroll.Y));
            }
            appliedDarkTheme = dark;
            nextThemeCheck = DateTime.UtcNow.AddSeconds(2);
            SyncStatus();
        }

        private void ShowHomePage()
        {
            CloseOpenDropDowns();
            homePageSelected = true;
            settingsPage.Visible = false;
            advancedPage.Visible = false;
            updatesPage.Visible = false;
            homePage.Visible = true;
            homePage.BringToFront();
            SyncStatus();
        }

        private void LayoutHome(bool showTrustCard)
        {
            int actionTop;
            if (showTrustCard)
            {
                trustCard.Location = new Point(24, 178);
                actionTop = 286;
            }
            else
            {
                actionTop = 178;
            }
            refreshDiscovery.Location = new Point(24, actionTop);
            startStop.Location = new Point(260, actionTop);
            updatesButton.Location = new Point(417, actionTop);
            homeQuality.Location = new Point(26, actionTop + 51);
            reportProblem.Location = new Point(452, actionTop + 82);
            if (homePageSelected)
                ClientSize = new Size(620, actionTop + 112);
        }

        private void CloseOpenDropDowns()
        {
            ComboBox[] controls =
            {
                quality, latency, audioOutput, pairing, theme, renderer
            };
            foreach (ComboBox combo in controls)
            {
                if (combo != null && combo.DroppedDown)
                    combo.DroppedDown = false;
            }
        }

        private void TryLeaveSettingsToHome()
        {
            if (!ConfirmGeneralUnsavedChanges())
                return;
            ShowHomePage();
        }

        private void TryLeaveAdvancedToSettings()
        {
            if (!ConfirmAdvancedUnsavedChanges())
                return;
            ShowSettingsPage(false);
        }

        private void ShowSettingsPage(bool focusPin)
        {
            CloseOpenDropDowns();
            homePageSelected = false;
            ClientSize = new Size(620, 700);
            homePage.Visible = false;
            advancedPage.Visible = false;
            updatesPage.Visible = false;
            settingsPage.Visible = true;
            settingsPage.BringToFront();
            if (focusPin)
            {
                SelectValue(pairing, "pin");
                fixedPin.Focus();
            }
        }

        private void ShowAdvancedPage()
        {
            CloseOpenDropDowns();
            homePageSelected = false;
            ClientSize = new Size(620, 570);
            homePage.Visible = false;
            settingsPage.Visible = false;
            updatesPage.Visible = false;
            advancedPage.Visible = true;
            advancedPage.BringToFront();
            argumentPreview.Text = context.BuildSafeUxPlayArguments();
            UpdateAdvancedDirty();
        }

        private void ShowUpdatesPage()
        {
            CloseOpenDropDowns();
            homePageSelected = false;
            ClientSize = new Size(620, 570);
            homePage.Visible = false;
            settingsPage.Visible = false;
            advancedPage.Visible = false;
            updatesPage.Visible = true;
            updatesPage.BringToFront();
        }

        private void CheckForUpdates()
        {
            checkUpdate.Enabled = false;
            installUpdate.Enabled = false;
            openRelease.Enabled = false;
            updateTitle.Text = "";
            updateState.Text = "Проверяем последний опубликованный GitHub Release…";
            updateNotes.Text = "";
            ThreadPool.QueueUserWorkItem(delegate
            {
                try
                {
                    UpdateInfo info = UpdateService.Check();
                    if (IsDisposed)
                        return;
                    BeginInvoke((MethodInvoker)delegate
                    {
                        availableUpdate = info;
                        checkUpdate.Enabled = true;
                        openRelease.Enabled =
                            !string.IsNullOrWhiteSpace(info.ReleasePage);
                        updateNotes.Text = string.IsNullOrWhiteSpace(info.Notes)
                            ? "Автор релиза не добавил описание изменений."
                            : info.Notes;
                        if (info.IsNewer)
                        {
                            updateTitle.Text =
                                "Доступна версия " + info.Version.ToString(3);
                            if (string.IsNullOrWhiteSpace(info.InstallerUrl))
                            {
                                updateState.Text =
                                    "Версия найдена, но установщик не прикреплён к релизу.";
                                SetPrimaryButtonState(installUpdate, false);
                            }
                            else if (string.IsNullOrWhiteSpace(
                                info.InstallerSha256))
                            {
                                updateState.Text =
                                    "Версия найдена, но GitHub ещё не рассчитал SHA-256.";
                                SetPrimaryButtonState(installUpdate, false);
                            }
                            else
                            {
                                updateState.Text =
                                    "Прочитайте изменения и решите, нужно ли обновление.";
                                SetPrimaryButtonState(installUpdate, true);
                            }
                        }
                        else
                        {
                            updateTitle.Text =
                                "Установлена актуальная версия";
                            updateState.Text =
                                "Новых опубликованных версий сейчас нет.";
                            SetPrimaryButtonState(installUpdate, false);
                        }
                    });
                }
                catch (Exception ex)
                {
                    if (IsDisposed)
                        return;
                    BeginInvoke((MethodInvoker)delegate
                    {
                        checkUpdate.Enabled = true;
                        updateTitle.Text = "Не удалось проверить обновления";
                        updateState.Text = ex.Message;
                        updateNotes.Text =
                            "Проверьте интернет-соединение и повторите попытку позже.";
                        SetPrimaryButtonState(installUpdate, false);
                    });
                }
            });
        }

        private void DownloadUpdate()
        {
            if (availableUpdate == null || !availableUpdate.IsNewer)
                return;
            SetPrimaryButtonState(installUpdate, false);
            checkUpdate.Enabled = false;
            updateState.Text =
                "Скачиваем установщик и проверяем его SHA-256…";
            ThreadPool.QueueUserWorkItem(delegate
            {
                string installerPath = "";
                try
                {
                    installerPath =
                        UpdateService.DownloadAndVerify(availableUpdate);
                    pendingInstallerPath = installerPath;
                    if (IsDisposed)
                    {
                        DeleteFileQuietly(installerPath);
                        pendingInstallerPath = "";
                        return;
                    }
                    BeginInvoke((MethodInvoker)delegate
                    {
                        updateState.Text =
                            "Установщик загружен и проверен.";
                        DialogResult answer = MessageBox.Show(
                            this,
                            "Запустить обновление до версии " +
                            availableUpdate.Version.ToString(3) +
                            "?\r\n\r\nПриложение закроется, настройки сохранятся.",
                            "AeroMirror",
                            MessageBoxButtons.YesNo,
                            MessageBoxIcon.Question);
                        if (answer == DialogResult.Yes)
                        {
                            Process.Start(new ProcessStartInfo(installerPath)
                            {
                                Arguments = "/update /delete-source",
                                UseShellExecute = true
                            });
                            pendingInstallerPath = "";
                            context.QuitApplication();
                        }
                        else
                        {
                            DeleteFileQuietly(installerPath);
                            pendingInstallerPath = "";
                            checkUpdate.Enabled = true;
                            SetPrimaryButtonState(installUpdate, true);
                        }
                    });
                }
                catch (Exception ex)
                {
                    DeleteFileQuietly(installerPath);
                    pendingInstallerPath = "";
                    if (IsDisposed)
                        return;
                    BeginInvoke((MethodInvoker)delegate
                    {
                        checkUpdate.Enabled = true;
                        updateState.Text =
                            "Обновление не скачано: " + ex.Message;
                        SetPrimaryButtonState(installUpdate, true);
                    });
                }
            });
        }

        private void DeletePendingInstaller()
        {
            string path = pendingInstallerPath;
            pendingInstallerPath = "";
            DeleteFileQuietly(path);
        }

        private static void DeleteFileQuietly(string path)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
                    File.Delete(path);
            }
            catch { }
        }

        private string DisplayNetworkName()
        {
            return string.IsNullOrWhiteSpace(context.NetworkProfileName)
                ? "текущая" : context.NetworkProfileName;
        }

        private void LoadSettings()
        {
            suppressDirty = true;
            AppSettings s = context.CurrentSettings;
            receiverName.Text = s.ReceiverName;
            SelectValue(quality, s.QualityPreset);
            SelectValue(pairing,
                s.PairingMode == "password" ? "none" : s.PairingMode);
            fixedPin.Text = s.FixedPin;
            SelectValue(latency, s.LatencyProfile);
            SelectValue(audioOutput, s.AudioOutput);
            SelectValue(theme, s.ThemeMode);
            topMost.Checked = s.AlwaysOnTop;
            autoFit.Checked = s.AutoFitWindow;
            showStreamInTaskbar.Checked = s.ShowStreamInTaskbar;
            autoReceiver.Checked = s.AutoStartReceiver;
            autoWindows.Checked = s.AutoStartWindows;
            startMinimized.Checked = s.StartMinimized;
            closeToTray.Checked = s.CloseToTray;
            notifications.Checked = s.Notify;
            SelectValue(renderer, s.Renderer);
            arguments.Text = s.AdvancedArguments;
            argumentPreview.Text = context.BuildSafeUxPlayArguments();
            UpdatePinPanel();
            UpdateStartupChild();
            suppressDirty = false;
            SetDirty(false);
            UpdateAdvancedDirty();
            ApplyTheme();
            SyncStatus();
        }

        private void WireDirtyTracking()
        {
            receiverName.TextChanged += delegate { MarkDirty(); };
            quality.SelectedIndexChanged += delegate { MarkDirty(); };
            pairing.SelectedIndexChanged += delegate { MarkDirty(); };
            fixedPin.TextChanged += delegate { MarkDirty(); };
            latency.SelectedIndexChanged += delegate { MarkDirty(); };
            audioOutput.SelectedIndexChanged += delegate { MarkDirty(); };
            topMost.CheckedChanged += delegate { MarkDirty(); };
            autoFit.CheckedChanged += delegate { MarkDirty(); };
            showStreamInTaskbar.CheckedChanged += delegate { MarkDirty(); };
            autoReceiver.CheckedChanged += delegate { MarkDirty(); };
            autoWindows.CheckedChanged += delegate { MarkDirty(); };
            startMinimized.CheckedChanged += delegate { MarkDirty(); };
            closeToTray.CheckedChanged += delegate { MarkDirty(); };
            notifications.CheckedChanged += delegate { MarkDirty(); };
            renderer.SelectedIndexChanged += delegate { UpdateAdvancedDirty(); };
            arguments.TextChanged += delegate { UpdateAdvancedDirty(); };
        }

        private void MarkDirty()
        {
            if (!suppressDirty)
                SetDirty(HasUnsavedChanges());
        }

        private bool HasUnsavedChanges()
        {
            AppSettings s = context.CurrentSettings;
            string mode = SelectedValue(pairing);
            string currentMode =
                s.PairingMode == "password" ? "none" : s.PairingMode;
            string pin = mode == "pin" ? fixedPin.Text.Trim() : "";
            string currentPin =
                currentMode == "pin" ? s.FixedPin.Trim() : "";
            return receiverName.Text.Trim() != s.ReceiverName.Trim() ||
                SelectedValue(quality) != s.QualityPreset ||
                mode != currentMode ||
                pin != currentPin ||
                SelectedValue(latency) != s.LatencyProfile ||
                SelectedValue(audioOutput) != s.AudioOutput ||
                SelectedValue(theme) != s.ThemeMode ||
                topMost.Checked != s.AlwaysOnTop ||
                autoFit.Checked != s.AutoFitWindow ||
                showStreamInTaskbar.Checked != s.ShowStreamInTaskbar ||
                autoReceiver.Checked != s.AutoStartReceiver ||
                autoWindows.Checked != s.AutoStartWindows ||
                (autoWindows.Checked && startMinimized.Checked) !=
                    (s.AutoStartWindows && s.StartMinimized) ||
                closeToTray.Checked != s.CloseToTray ||
                notifications.Checked != s.Notify;
        }

        private void SetDirty(bool dirty)
        {
            SetPrimaryButtonState(saveButton, dirty);
            if (dirty)
                savedLabel.Text = "";
        }

        private void UpdateAdvancedDirty()
        {
            if (advancedSave == null || renderer == null || arguments == null)
                return;
            SetPrimaryButtonState(advancedSave, HasAdvancedUnsavedChanges());
        }

        private bool HasAdvancedUnsavedChanges()
        {
            return SelectedValue(renderer) != context.CurrentSettings.Renderer ||
                arguments.Text.Trim() !=
                    context.CurrentSettings.AdvancedArguments.Trim();
        }

        private bool ConfirmAllUnsavedChanges()
        {
            bool generalDirty = HasUnsavedChanges();
            bool advancedDirty = HasAdvancedUnsavedChanges();
            if (generalDirty && advancedDirty)
            {
                DialogResult combinedAnswer = MessageBox.Show(
                    this,
                    "Сохранить все изменения в обычных и дополнительных настройках?",
                    "AeroMirror",
                    MessageBoxButtons.YesNoCancel,
                    MessageBoxIcon.Question);
                if (combinedAnswer == DialogResult.Cancel)
                    return false;
                if (combinedAnswer == DialogResult.Yes)
                    return TrySaveGeneralSettings(true);
                LoadSettings();
                return true;
            }
            if (!ConfirmAdvancedUnsavedChanges())
                return false;
            return ConfirmGeneralUnsavedChanges();
        }

        private bool ConfirmGeneralUnsavedChanges()
        {
            if (!HasUnsavedChanges())
                return true;
            DialogResult answer = MessageBox.Show(
                this,
                "Сохранить изменения в настройках перед выходом?",
                "AeroMirror",
                MessageBoxButtons.YesNoCancel,
                MessageBoxIcon.Question);
            if (answer == DialogResult.Cancel)
                return false;
            if (answer == DialogResult.Yes)
                return TrySaveGeneralSettings();
            LoadSettings();
            return true;
        }

        private bool ConfirmAdvancedUnsavedChanges()
        {
            if (!HasAdvancedUnsavedChanges())
                return true;
            DialogResult answer = MessageBox.Show(
                this,
                "Сохранить изменения в дополнительных настройках?",
                "AeroMirror",
                MessageBoxButtons.YesNoCancel,
                MessageBoxIcon.Question);
            if (answer == DialogResult.Cancel)
                return false;
            if (answer == DialogResult.Yes)
                return TrySaveAdvancedSettings();
            suppressDirty = true;
            SelectValue(renderer, context.CurrentSettings.Renderer);
            arguments.Text = context.CurrentSettings.AdvancedArguments;
            argumentPreview.Text = context.BuildSafeUxPlayArguments();
            suppressDirty = false;
            UpdateAdvancedDirty();
            return true;
        }

        private void UpdatePinPanel()
        {
            bool enabled = SelectedValue(pairing) == "pin";
            pinPanel.Visible = enabled;
            accessNote.Visible = !enabled;
            if (enabled && string.IsNullOrWhiteSpace(fixedPin.Text))
                fixedPin.Text = GeneratePin();
            UpdateAccessNote();
        }

        private void UpdateAccessNote()
        {
            if (accessNote == null || pairing == null)
                return;
            if (SelectedValue(pairing) == "pin")
            {
                accessNote.Text =
                    "PIN вводится при первом знакомстве устройств. Доверие сохраняется " +
                    "между этим iPhone и ноутбуком независимо от названия Wi-Fi-сети.";
            }
            else if (context.IsPublicNetwork)
            {
                accessNote.Text = context.HasNetworkOverlay
                    ? "VPN или виртуальная сеть обнаружены, но Windows считает физический Wi-Fi/Ethernet " +
                      "публичным. Включите PIN либо отключите VPN и повторите проверку."
                    : "В публичной сети приёмник без PIN будет приостановлен. " +
                      "Включите PIN или измените профиль сети в Windows.";
            }
            else
            {
                accessNote.Text =
                    "В частной домашней сети PIN необязателен. Его можно включить " +
                    "заранее, чтобы знакомый iPhone подключался и в других сетях.";
            }
        }

        private void UpdateStartupChild()
        {
            startMinimized.Visible = autoWindows.Checked;
            startMinimized.Enabled = autoWindows.Checked;
        }

        private void OnSave(object sender, EventArgs e)
        {
            TrySaveGeneralSettings();
        }

        private bool TrySaveGeneralSettings()
        {
            return TrySaveGeneralSettings(false);
        }

        private bool TrySaveGeneralSettings(bool includeAdvanced)
        {
            Point scrollPosition = settingsPage.AutoScrollPosition;
            string name = receiverName.Text.Trim();
            if (name.Length == 0)
            {
                MessageBox.Show(this, "Введите имя приёмника.", Text,
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }

            string mode = SelectedValue(pairing);
            string pin = fixedPin.Text.Trim();
            if (mode == "pin" && (pin.Length != 4 || !IsDigits(pin)))
            {
                MessageBox.Show(this,
                    "Для защищённого подключения нужен PIN из четырёх цифр.",
                    Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }

            AppSettings updated = context.CurrentSettings.Copy();
            updated.ReceiverName = name;
            updated.QualityPreset = SelectedValue(quality);
            updated.PairingMode = mode;
            updated.FixedPin = mode == "pin" ? pin : "";
            updated.LatencyProfile = SelectedValue(latency);
            updated.AudioOutput = SelectedValue(audioOutput);
            updated.ThemeMode = SelectedValue(theme);
            updated.AlwaysOnTop = topMost.Checked;
            updated.AutoFitWindow = autoFit.Checked;
            updated.ShowStreamInTaskbar = showStreamInTaskbar.Checked;
            updated.AutoStartReceiver = autoReceiver.Checked;
            updated.AutoStartWindows = autoWindows.Checked;
            updated.StartMinimized =
                autoWindows.Checked && startMinimized.Checked;
            updated.CloseToTray = closeToTray.Checked;
            updated.Notify = notifications.Checked;
            if (includeAdvanced)
            {
                updated.Renderer = SelectedValue(renderer);
                updated.AdvancedArguments = arguments.Text.Trim();
            }
            if (mode == "pin")
                updated.DismissPinSuggestion = true;
            bool qualityChanged =
                updated.QualityPreset != context.CurrentSettings.QualityPreset;
            bool restarted = context.SaveSettings(updated, true);
            bool deferred = context.IsSettingsRestartDeferred;
            SetDirty(false);
            UpdateAdvancedDirty();
            ApplyTheme();
            savedLabel.ForeColor = ThemeHelper.IsDark(
                    context.CurrentSettings.ThemeMode)
                ? Color.FromArgb(94, 204, 126)
                : Color.FromArgb(42, 122, 74);
            savedLabel.Text = deferred
                ? "Сохранено · применится после отключения iPhone"
                : restarted && qualityChanged
                ? "Сохранено · применяется для нового подключения"
                : restarted
                ? "Сохранено · приёмник перезапускается"
                : "Сохранено";
            SyncStatus();
            settingsPage.AutoScrollPosition = new Point(
                Math.Max(0, -scrollPosition.X),
                Math.Max(0, -scrollPosition.Y));
            return true;
        }

        private void OnAdvancedSave(object sender, EventArgs e)
        {
            TrySaveAdvancedSettings();
        }

        private bool TrySaveAdvancedSettings()
        {
            AppSettings updated = context.CurrentSettings.Copy();
            updated.Renderer = SelectedValue(renderer);
            updated.AdvancedArguments = arguments.Text.Trim();
            context.SaveSettings(updated, true);
            argumentPreview.Text = context.BuildSafeUxPlayArguments();
            UpdateAdvancedDirty();
            return true;
        }

        private void DrawQualityItem(object sender, DrawItemEventArgs e)
        {
            bool isClosedSelection =
                (e.State & DrawItemState.ComboBoxEdit) != 0;
            bool highlight =
                !isClosedSelection && (e.State & DrawItemState.Selected) != 0;
            if (isClosedSelection)
            {
                using (var background = new SolidBrush(quality.BackColor))
                    e.Graphics.FillRectangle(background, e.Bounds);
            }
            else
                e.DrawBackground();
            if (e.Index < 0 || e.Index >= quality.Items.Count)
                return;
            NamedValue item = quality.Items[e.Index] as NamedValue;
            if (item == null)
                return;

            Color mainColor = highlight
                ? SystemColors.HighlightText : quality.ForeColor;
            Color noteColor = highlight
                ? SystemColors.HighlightText
                : (appliedDarkTheme == true
                    ? Color.FromArgb(185, 185, 185)
                    : Color.DimGray);
            using (var mainFont = new Font(Font, FontStyle.Regular))
            using (var noteFont = new Font(Font.FontFamily, 8.25F))
            {
                TextRenderer.DrawText(e.Graphics, item.Name, mainFont,
                    new Point(e.Bounds.Left + 8, e.Bounds.Top + 3),
                    mainColor, TextFormatFlags.NoPadding);
                TextRenderer.DrawText(e.Graphics, item.Subtitle, noteFont,
                    new Rectangle(e.Bounds.Left + 8, e.Bounds.Top + 20,
                        e.Bounds.Width - 24, 16),
                    noteColor, TextFormatFlags.NoPadding |
                    TextFormatFlags.EndEllipsis);
            }
            if (highlight)
                e.DrawFocusRectangle();
        }

        private static string QualityDisplayName(string value)
        {
            if (value == "4k60") return "4K · 60 FPS";
            if (value == "1080p30") return "Full HD · 30 FPS";
            if (value == "720p30") return "HD · 30 FPS";
            return "Full HD · 60 FPS";
        }

        private static void AddSection(
            Control parent, string text, int x, int y)
        {
            var label = MakeLabel(text, x, y);
            label.Font = new Font("Segoe UI Semibold", 12F);
            parent.Controls.Add(label);
        }

        private static Label MakeLabel(string text, int x, int y)
        {
            var label = new Label();
            label.Text = text;
            label.AutoSize = true;
            label.Location = new Point(x, y);
            return label;
        }

        private static Label MakeFixedLabel(
            string text, int x, int y, int width, int height)
        {
            var label = new Label();
            label.Text = text;
            label.AutoSize = false;
            label.Location = new Point(x, y);
            label.Size = new Size(width, height);
            return label;
        }

        private static Button MakeButton(
            string text, int x, int y, int width, int height, bool primary)
        {
            var button = new Button();
            button.Text = text;
            button.Location = new Point(x, y);
            button.Size = new Size(width, height);
            button.FlatStyle = FlatStyle.Flat;
            if (primary)
            {
                button.FlatAppearance.BorderSize = 0;
                button.BackColor = Color.FromArgb(0, 95, 184);
                button.ForeColor = Color.White;
            }
            return button;
        }

        private static ComboBox MakeCombo(int x, int y, int width)
        {
            var combo = new WheelSafeComboBox();
            combo.Location = new Point(x, y);
            combo.Size = new Size(width, 27);
            combo.DropDownStyle = ComboBoxStyle.DropDownList;
            combo.FlatStyle = FlatStyle.Flat;
            combo.DrawMode = DrawMode.OwnerDrawFixed;
            combo.DrawItem += DrawSimpleComboItem;
            return combo;
        }

        private static void DrawSimpleComboItem(
            object sender, DrawItemEventArgs e)
        {
            ComboBox combo = sender as ComboBox;
            if (combo == null)
                return;
            bool isClosed =
                (e.State & DrawItemState.ComboBoxEdit) != 0;
            bool selected =
                !isClosed && (e.State & DrawItemState.Selected) != 0;
            using (var background = new SolidBrush(
                selected ? SystemColors.Highlight : combo.BackColor))
                e.Graphics.FillRectangle(background, e.Bounds);
            if (e.Index < 0 || e.Index >= combo.Items.Count)
                return;
            Color textColor = selected
                ? SystemColors.HighlightText : combo.ForeColor;
            TextRenderer.DrawText(
                e.Graphics,
                combo.Items[e.Index].ToString(),
                combo.Font,
                new Rectangle(
                    e.Bounds.Left + 4,
                    e.Bounds.Top + 1,
                    e.Bounds.Width - 8,
                    e.Bounds.Height - 2),
                textColor,
                TextFormatFlags.VerticalCenter |
                TextFormatFlags.EndEllipsis |
                TextFormatFlags.NoPrefix);
            if (selected)
                e.DrawFocusRectangle();
        }

        private static CheckBox MakeCheckBox(string text, int x, int y)
        {
            var check = new CheckBox();
            check.Text = text;
            check.AutoSize = true;
            check.Location = new Point(x, y);
            return check;
        }

        private void SetPrimaryButtonState(Button button, bool enabled)
        {
            bool dark = appliedDarkTheme ??
                ThemeHelper.IsDark(context.CurrentSettings.ThemeMode);
            button.Enabled = enabled;
            button.BackColor = enabled
                ? Color.FromArgb(0, 95, 184)
                : dark
                ? Color.FromArgb(57, 58, 63)
                : Color.FromArgb(225, 225, 225);
            button.ForeColor = enabled
                ? Color.White
                : dark
                ? Color.FromArgb(190, 190, 190)
                : Color.DimGray;
        }

        private static void SelectValue(ComboBox combo, string value)
        {
            for (int i = 0; i < combo.Items.Count; i++)
            {
                var item = combo.Items[i] as NamedValue;
                if (item != null && item.Value == value)
                {
                    combo.SelectedIndex = i;
                    return;
                }
            }
            if (combo.Items.Count > 0)
                combo.SelectedIndex = 0;
        }

        private static string SelectedValue(ComboBox combo)
        {
            var item = combo.SelectedItem as NamedValue;
            return item == null ? "" : item.Value;
        }

        private static bool IsDigits(string text)
        {
            foreach (char c in text)
                if (c < '0' || c > '9') return false;
            return true;
        }

        private static string GeneratePin()
        {
            return new Random(
                Guid.NewGuid().GetHashCode()).Next(1000, 10000).ToString();
        }

        internal static void OpenMobileHotspot(IWin32Window owner)
        {
            try
            {
                Process.Start(new ProcessStartInfo(
                    "ms-settings:network-mobilehotspot")
                {
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show(owner,
                    "Не удалось открыть параметры Windows.\r\n\r\n" + ex.Message,
                    "AeroMirror",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }
    }

    internal sealed class LegacyPrimarySettingsForm : Form
    {
        private readonly ReceiverContext context;
        private readonly Label status;
        private readonly Panel networkCard;
        private readonly Label networkTitle;
        private readonly Label networkText;
        private readonly TextBox receiverName;
        private readonly ComboBox quality;
        private readonly ComboBox pairing;
        private readonly Label accessNote;
        private readonly Panel pinPanel;
        private readonly TextBox fixedPin;
        private readonly CheckBox autoReceiver;
        private readonly CheckBox autoWindows;
        private readonly CheckBox startMinimized;
        private readonly CheckBox closeToTray;
        private readonly CheckBox notifications;
        private readonly Button startStop;
        private readonly Button saveButton;
        private readonly Label savedLabel;
        private bool suppressDirty;

        public LegacyPrimarySettingsForm(ReceiverContext context)
        {
            this.context = context;
            Text = "AeroMirror";
            Icon = AppIcon.Current;
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            ClientSize = new Size(600, 820);
            BackColor = Color.FromArgb(250, 250, 250);
            Font = new Font("Segoe UI", 9F);

            var header = new Panel();
            header.Location = new Point(0, 0);
            header.Size = new Size(600, 105);
            header.BackColor = Color.White;
            Controls.Add(header);

            var logo = new PictureBox();
            logo.Image = AppIcon.Image;
            logo.SizeMode = PictureBoxSizeMode.Zoom;
            logo.Location = new Point(28, 23);
            logo.Size = new Size(56, 56);
            header.Controls.Add(logo);

            var title = new Label();
            title.Text = "AeroMirror";
            title.Font = new Font("Segoe UI Semibold", 19F);
            title.AutoSize = true;
            title.Location = new Point(99, 22);
            header.Controls.Add(title);

            status = new Label();
            status.AutoSize = true;
            status.Location = new Point(102, 61);
            header.Controls.Add(status);

            networkCard = new Panel();
            networkCard.Location = new Point(28, 123);
            networkCard.Size = new Size(544, 82);
            Controls.Add(networkCard);

            networkTitle = new Label();
            networkTitle.Font = new Font("Segoe UI Semibold", 9.5F);
            networkTitle.AutoSize = true;
            networkTitle.Location = new Point(14, 10);
            networkCard.Controls.Add(networkTitle);

            networkText = new Label();
            networkText.AutoSize = false;
            networkText.Location = new Point(14, 34);
            networkText.Size = new Size(512, 39);
            networkCard.Controls.Add(networkText);

            var deviceCaption = MakeLabel("Имя в меню «Повтор экрана»", 28, 224);
            Controls.Add(deviceCaption);
            receiverName = new TextBox();
            receiverName.Location = new Point(28, 247);
            receiverName.Size = new Size(544, 27);
            Controls.Add(receiverName);

            var qualityCaption = MakeLabel("Качество трансляции", 28, 291);
            Controls.Add(qualityCaption);
            quality = new ComboBox();
            quality.Location = new Point(28, 314);
            quality.Size = new Size(544, 42);
            quality.DropDownStyle = ComboBoxStyle.DropDownList;
            quality.DrawMode = DrawMode.OwnerDrawFixed;
            quality.ItemHeight = 38;
            quality.DropDownHeight = 160;
            quality.IntegralHeight = false;
            quality.DrawItem += DrawQualityItem;
            quality.Items.Add(new NamedValue(
                "4K · 60 FPS",
                "4k60",
                "HEVC · максимальное качество; фактическое разрешение выбирает iPhone"));
            quality.Items.Add(new NamedValue(
                "Full HD · 60 FPS",
                "1080p60",
                "Рекомендуется · плавное движение"));
            quality.Items.Add(new NamedValue(
                "Full HD · 30 FPS",
                "1080p30",
                "Меньше нагрузка на сеть и компьютер"));
            quality.Items.Add(new NamedValue(
                "HD · 30 FPS",
                "720p30",
                "Для слабой сети или маломощного компьютера"));
            Controls.Add(quality);
            var qualityNote = new Label();
            qualityNote.Text = "Это максимальное запрашиваемое качество. Применяется после «Сохранить» и нового подключения iPhone.";
            qualityNote.AutoSize = false;
            qualityNote.Size = new Size(544, 35);
            qualityNote.ForeColor = Color.DimGray;
            qualityNote.Location = new Point(31, 363);
            Controls.Add(qualityNote);

            var accessCaption = MakeLabel("Защита подключения", 28, 410);
            Controls.Add(accessCaption);
            pairing = new ComboBox();
            pairing.Location = new Point(28, 433);
            pairing.Size = new Size(544, 27);
            pairing.DropDownStyle = ComboBoxStyle.DropDownList;
            pairing.Items.Add(new NamedValue("Без PIN — удобно для частной домашней сети", "none"));
            pairing.Items.Add(new NamedValue("С PIN — дополнительная защита в любой сети", "pin"));
            pairing.SelectedIndexChanged += delegate { UpdatePinPanel(); };
            Controls.Add(pairing);

            accessNote = new Label();
            accessNote.Text = "В частной сети PIN необязателен. В публичной сети без PIN приёмник будет приостановлен.";
            accessNote.AutoSize = false;
            accessNote.Size = new Size(544, 38);
            accessNote.Location = new Point(31, 470);
            accessNote.ForeColor = Color.DimGray;
            Controls.Add(accessNote);

            pinPanel = new Panel();
            pinPanel.Location = new Point(28, 467);
            pinPanel.Size = new Size(544, 57);
            pinPanel.BackColor = Color.FromArgb(242, 247, 253);
            Controls.Add(pinPanel);

            var pinCaption = new Label();
            pinCaption.Text = "PIN, который нужно ввести на iPhone";
            pinCaption.AutoSize = true;
            pinCaption.Location = new Point(12, 8);
            pinPanel.Controls.Add(pinCaption);
            fixedPin = new TextBox();
            fixedPin.Location = new Point(15, 28);
            fixedPin.Size = new Size(145, 25);
            fixedPin.MaxLength = 4;
            fixedPin.Font = new Font("Segoe UI Semibold", 10F);
            pinPanel.Controls.Add(fixedPin);
            var generate = new Button();
            generate.Text = "Новый PIN";
            generate.Size = new Size(112, 27);
            generate.Location = new Point(169, 27);
            generate.FlatStyle = FlatStyle.Flat;
            generate.Click += delegate { fixedPin.Text = GeneratePin(); };
            pinPanel.Controls.Add(generate);
            var pinNote = new Label();
            pinNote.Text = "Затем iPhone узнаётся по ключу.";
            pinNote.AutoSize = true;
            pinNote.ForeColor = Color.DimGray;
            pinNote.Location = new Point(298, 33);
            pinPanel.Controls.Add(pinNote);

            autoReceiver = MakeCheckBox(
                "Приёмник включён, пока приложение работает", 28, 540);
            Controls.Add(autoReceiver);

            autoWindows = MakeCheckBox(
                "Запускать AeroMirror вместе с Windows", 28, 574);
            autoWindows.CheckedChanged += delegate { UpdateStartupChild(); };
            Controls.Add(autoWindows);

            startMinimized = MakeCheckBox(
                "При запуске с Windows сразу скрывать в трей", 51, 607);
            startMinimized.ForeColor = Color.FromArgb(70, 70, 70);
            Controls.Add(startMinimized);

            closeToTray = MakeCheckBox(
                "По кнопке × сворачивать в трей, а не закрывать приложение", 28, 640);
            Controls.Add(closeToTray);

            notifications = MakeCheckBox(
                "Показывать уведомления о запуске, ошибках и небезопасной сети", 28, 675);
            Controls.Add(notifications);
            var notificationsNote = new Label();
            notificationsNote.Text = "Это не SMS и не уведомления с iPhone.";
            notificationsNote.AutoSize = true;
            notificationsNote.ForeColor = Color.DimGray;
            notificationsNote.Location = new Point(51, 700);
            Controls.Add(notificationsNote);

            var advancedButton = new Button();
            advancedButton.Text = "Дополнительные настройки";
            advancedButton.Size = new Size(205, 34);
            advancedButton.Location = new Point(28, 738);
            advancedButton.FlatStyle = FlatStyle.Flat;
            advancedButton.Click += delegate
            {
                using (var dialog = new AdvancedSettingsForm(context))
                    dialog.ShowDialog(this);
                LoadSettings();
            };
            Controls.Add(advancedButton);

            startStop = new Button();
            startStop.Size = new Size(150, 38);
            startStop.Location = new Point(262, 766);
            startStop.FlatStyle = FlatStyle.Flat;
            startStop.Click += delegate
            {
                if (context.IsCoreRunning) context.StopCore(); else context.StartCore();
                SyncStatus();
            };
            Controls.Add(startStop);

            saveButton = new Button();
            saveButton.Text = "Сохранить";
            saveButton.Size = new Size(150, 38);
            saveButton.Location = new Point(422, 766);
            saveButton.FlatStyle = FlatStyle.Flat;
            saveButton.FlatAppearance.BorderSize = 0;
            saveButton.Click += OnSave;
            Controls.Add(saveButton);

            savedLabel = new Label();
            savedLabel.Text = "";
            savedLabel.AutoSize = true;
            savedLabel.ForeColor = Color.FromArgb(42, 122, 74);
            savedLabel.Location = new Point(240, 744);
            Controls.Add(savedLabel);

            LoadSettings();
            WireDirtyTracking();
            SetDirty(false);
            FormClosing += delegate(object sender, FormClosingEventArgs e)
            {
                if (e.CloseReason == CloseReason.UserClosing)
                {
                    if (context.CurrentSettings.CloseToTray)
                    {
                        e.Cancel = true;
                        Hide();
                    }
                    else
                    {
                        context.QuitApplication();
                    }
                }
            };
        }

        public void SyncStatus()
        {
            if (IsDisposed)
                return;

            bool unsafeAccess = context.IsPublicNetwork &&
                SelectedValue(pairing) == "none";
            if (context.IsCoreRunning)
            {
                status.Text = "● Приёмник включён · можно подключаться";
                status.ForeColor = Color.FromArgb(42, 122, 74);
                startStop.Text = "Остановить";
            }
            else if (unsafeAccess)
            {
                status.Text = "⚠ Приёмник приостановлен · включите PIN";
                status.ForeColor = Color.FromArgb(154, 92, 0);
                startStop.Text = "Включить";
            }
            else
            {
                status.Text = "○ Приёмник выключен";
                status.ForeColor = Color.FromArgb(128, 70, 70);
                startStop.Text = "Включить";
            }

            if (unsafeAccess)
            {
                networkCard.BackColor = Color.FromArgb(255, 244, 215);
                networkTitle.Text = "Windows считает сеть «" +
                    DisplayNetworkName() + "» публичной";
                networkText.Text = "Без PIN приёмник приостановлен. Включите PIN или измените профиль этой сети на «Частный» в Windows.";
                networkTitle.ForeColor = Color.FromArgb(133, 78, 0);
            }
            else
            {
                networkCard.BackColor = Color.FromArgb(237, 246, 255);
                if (!context.IsNetworkProfileKnown)
                {
                    networkTitle.Text = "Проверяем профиль Wi-Fi или Ethernet…";
                    networkText.Text = "VPN и виртуальные адаптеры не используются для этой проверки.";
                }
                else if (context.IsPublicNetwork)
                {
                    networkTitle.Text = "Сеть «" + DisplayNetworkName() + "» публичная · PIN включён";
                    networkText.Text = "PIN нужен только при первом подключении. Затем iPhone проверяется по сохранённому ключу.";
                }
                else
                {
                    networkTitle.Text = "Сеть «" + DisplayNetworkName() + "» частная";
                    networkText.Text = "Здесь можно работать без PIN. Защиту при желании можно оставить включённой.";
                }
                networkTitle.ForeColor = Color.FromArgb(0, 80, 145);
            }
        }

        private string DisplayNetworkName()
        {
            return string.IsNullOrWhiteSpace(context.NetworkProfileName)
                ? "текущая" : context.NetworkProfileName;
        }

        private void LoadSettings()
        {
            suppressDirty = true;
            AppSettings s = context.CurrentSettings;
            receiverName.Text = s.ReceiverName;
            SelectValue(quality, s.QualityPreset);
            SelectValue(pairing, s.PairingMode == "password" ? "none" : s.PairingMode);
            fixedPin.Text = s.FixedPin;
            autoReceiver.Checked = s.AutoStartReceiver;
            autoWindows.Checked = s.AutoStartWindows;
            startMinimized.Checked = s.StartMinimized;
            closeToTray.Checked = s.CloseToTray;
            notifications.Checked = s.Notify;
            UpdatePinPanel();
            UpdateStartupChild();
            SyncStatus();
            suppressDirty = false;
            SetDirty(false);
        }

        private void WireDirtyTracking()
        {
            receiverName.TextChanged += delegate { MarkDirty(); };
            quality.SelectedIndexChanged += delegate { MarkDirty(); };
            pairing.SelectedIndexChanged += delegate { MarkDirty(); };
            fixedPin.TextChanged += delegate { MarkDirty(); };
            autoReceiver.CheckedChanged += delegate { MarkDirty(); };
            autoWindows.CheckedChanged += delegate { MarkDirty(); };
            startMinimized.CheckedChanged += delegate { MarkDirty(); };
            closeToTray.CheckedChanged += delegate { MarkDirty(); };
            notifications.CheckedChanged += delegate { MarkDirty(); };
        }

        private void MarkDirty()
        {
            if (!suppressDirty)
                SetDirty(HasUnsavedChanges());
        }

        private bool HasUnsavedChanges()
        {
            AppSettings s = context.CurrentSettings;
            string mode = SelectedValue(pairing);
            string currentMode = s.PairingMode == "password" ? "none" : s.PairingMode;
            string pin = mode == "pin" ? fixedPin.Text.Trim() : "";
            string currentPin = currentMode == "pin" ? s.FixedPin.Trim() : "";
            return receiverName.Text.Trim() != s.ReceiverName.Trim() ||
                SelectedValue(quality) != s.QualityPreset ||
                mode != currentMode ||
                pin != currentPin ||
                autoReceiver.Checked != s.AutoStartReceiver ||
                autoWindows.Checked != s.AutoStartWindows ||
                (autoWindows.Checked && startMinimized.Checked) !=
                    (s.AutoStartWindows && s.StartMinimized) ||
                closeToTray.Checked != s.CloseToTray ||
                notifications.Checked != s.Notify;
        }

        private void SetDirty(bool dirty)
        {
            saveButton.Enabled = dirty;
            saveButton.BackColor = dirty
                ? Color.FromArgb(0, 95, 184)
                : Color.FromArgb(225, 225, 225);
            saveButton.ForeColor = dirty ? Color.White : Color.DimGray;
            if (dirty)
                savedLabel.Text = "";
        }

        private void UpdatePinPanel()
        {
            bool enabled = SelectedValue(pairing) == "pin";
            pinPanel.Visible = enabled;
            accessNote.Visible = !enabled;
            if (enabled && string.IsNullOrWhiteSpace(fixedPin.Text))
                fixedPin.Text = GeneratePin();
            SyncStatus();
        }

        private void UpdateStartupChild()
        {
            startMinimized.Visible = autoWindows.Checked;
            startMinimized.Enabled = autoWindows.Checked;
        }

        private void OnSave(object sender, EventArgs e)
        {
            string name = receiverName.Text.Trim();
            if (name.Length == 0)
            {
                MessageBox.Show(this, "Введите имя приёмника.", Text,
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string mode = SelectedValue(pairing);
            string pin = fixedPin.Text.Trim();
            if (mode == "pin" && (pin.Length != 4 || !IsDigits(pin)))
            {
                MessageBox.Show(this, "Для защищённого подключения нужен PIN из четырёх цифр.",
                    Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            AppSettings updated = context.CurrentSettings.Copy();
            updated.ReceiverName = name;
            updated.QualityPreset = SelectedValue(quality);
            updated.PairingMode = mode;
            updated.FixedPin = mode == "pin" ? pin : "";
            updated.AutoStartReceiver = autoReceiver.Checked;
            updated.AutoStartWindows = autoWindows.Checked;
            updated.StartMinimized = autoWindows.Checked && startMinimized.Checked;
            updated.CloseToTray = closeToTray.Checked;
            updated.Notify = notifications.Checked;
            bool qualityChanged = updated.QualityPreset != context.CurrentSettings.QualityPreset;
            bool restarted = context.SaveSettings(updated, true);
            savedLabel.Text = restarted && qualityChanged
                ? "Сохранено · переподключите iPhone"
                : restarted
                ? "Сохранено · приёмник перезапущен"
                : "Сохранено";
            SetDirty(false);
            SyncStatus();
        }

        private static Label MakeLabel(string text, int x, int y)
        {
            var label = new Label();
            label.Text = text;
            label.AutoSize = true;
            label.Location = new Point(x, y);
            return label;
        }

        private void DrawQualityItem(object sender, DrawItemEventArgs e)
        {
            bool isClosedSelection =
                (e.State & DrawItemState.ComboBoxEdit) != 0;
            bool highlight =
                !isClosedSelection && (e.State & DrawItemState.Selected) != 0;
            if (isClosedSelection)
                e.Graphics.FillRectangle(SystemBrushes.Window, e.Bounds);
            else
                e.DrawBackground();
            if (e.Index < 0 || e.Index >= quality.Items.Count)
                return;
            NamedValue item = quality.Items[e.Index] as NamedValue;
            if (item == null)
                return;

            Color mainColor = highlight
                ? SystemColors.HighlightText : Color.FromArgb(28, 28, 28);
            Color noteColor = highlight
                ? SystemColors.HighlightText : Color.DimGray;
            using (var mainFont = new Font(Font, FontStyle.Regular))
            using (var noteFont = new Font(Font.FontFamily, 8.25F))
            {
                TextRenderer.DrawText(e.Graphics, item.Name, mainFont,
                    new Point(e.Bounds.Left + 8, e.Bounds.Top + 3),
                    mainColor, TextFormatFlags.NoPadding);
                TextRenderer.DrawText(e.Graphics, item.Subtitle, noteFont,
                    new Rectangle(e.Bounds.Left + 8, e.Bounds.Top + 20,
                        e.Bounds.Width - 24, 16),
                    noteColor, TextFormatFlags.NoPadding | TextFormatFlags.EndEllipsis);
            }
            if (highlight)
                e.DrawFocusRectangle();
        }

        private static CheckBox MakeCheckBox(string text, int x, int y)
        {
            var check = new CheckBox();
            check.Text = text;
            check.AutoSize = true;
            check.Location = new Point(x, y);
            return check;
        }

        private static void SelectValue(ComboBox combo, string value)
        {
            for (int i = 0; i < combo.Items.Count; i++)
            {
                var item = combo.Items[i] as NamedValue;
                if (item != null && item.Value == value)
                {
                    combo.SelectedIndex = i;
                    return;
                }
            }
            if (combo.Items.Count > 0)
                combo.SelectedIndex = 0;
        }

        private static string SelectedValue(ComboBox combo)
        {
            var item = combo.SelectedItem as NamedValue;
            return item == null ? "" : item.Value;
        }

        private static bool IsDigits(string text)
        {
            foreach (char c in text)
                if (c < '0' || c > '9') return false;
            return true;
        }

        private static string GeneratePin()
        {
            return new Random(Guid.NewGuid().GetHashCode()).Next(1000, 10000).ToString();
        }

        internal static void OpenMobileHotspot(IWin32Window owner)
        {
            try
            {
                Process.Start(new ProcessStartInfo("ms-settings:network-mobilehotspot")
                {
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show(owner, "Не удалось открыть параметры Windows.\r\n\r\n" + ex.Message,
                    "AeroMirror", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }

    internal sealed class AdvancedSettingsForm : Form
    {
        private readonly ReceiverContext context;
        private readonly ComboBox renderer;
        private readonly ComboBox latency;
        private readonly TextBox arguments;
        private readonly CheckBox topMost;
        private readonly CheckBox autoFit;

        public AdvancedSettingsForm(ReceiverContext context)
        {
            this.context = context;
            Text = "Дополнительные настройки";
            Icon = AppIcon.Current;
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            ClientSize = new Size(570, 590);
            BackColor = Color.FromArgb(250, 250, 250);
            Font = new Font("Segoe UI", 9F);

            var title = new Label();
            title.Text = "Видео и совместимость";
            title.Font = new Font("Segoe UI Semibold", 15F);
            title.AutoSize = true;
            title.Location = new Point(24, 20);
            Controls.Add(title);

            AddLabel("Профиль задержки", 24, 67);
            latency = new ComboBox();
            latency.Location = new Point(24, 90);
            latency.Size = new Size(522, 27);
            latency.DropDownStyle = ComboBoxStyle.DropDownList;
            latency.Items.Add(new NamedValue("Автоматическая синхронизация UxPlay — рекомендуется", "balanced"));
            latency.Items.Add(new NamedValue("Минимальный — меньше буфер, чаще рывки и рассинхрон", "low"));
            latency.Items.Add(new NamedValue("Стабильный — больше буфер и заметнее задержка", "stable"));
            Controls.Add(latency);

            var latencyNote = AddLabel(
                "Режим качества и FPS выбирается на главной странице. Здесь меняется только глубина буфера и синхронизация.", 24, 124);
            latencyNote.Size = new Size(522, 38);
            latencyNote.AutoSize = false;
            latencyNote.ForeColor = Color.DimGray;

            AddLabel("Вывод видео", 24, 170);
            renderer = new ComboBox();
            renderer.Location = new Point(24, 193);
            renderer.Size = new Size(522, 27);
            renderer.DropDownStyle = ComboBoxStyle.DropDownList;
            renderer.Items.Add(new NamedValue("Автоматический выбор GStreamer — рекомендуется", "auto"));
            renderer.Items.Add(new NamedValue("Direct3D 11 — режим совместимости", "d3d11"));
            renderer.Items.Add(new NamedValue("Direct3D 12 — экспериментально", "d3d12"));
            Controls.Add(renderer);

            topMost = new CheckBox();
            topMost.Text = "Показывать окно трансляции поверх остальных окон";
            topMost.AutoSize = true;
            topMost.Location = new Point(24, 237);
            Controls.Add(topMost);

            autoFit = new CheckBox();
            autoFit.Text = "Сохранять пропорции окна трансляции как у экрана iPhone";
            autoFit.AutoSize = true;
            autoFit.Location = new Point(24, 267);
            Controls.Add(autoFit);

            var fitNote = AddLabel(
                "После ручного изменения размера лишняя ширина или высота окна будет убрана.", 45, 289);
            fitNote.ForeColor = Color.DimGray;

            AddLabel("Дополнительные аргументы UxPlay", 24, 311);
            arguments = new TextBox();
            arguments.Location = new Point(24, 334);
            arguments.Size = new Size(522, 66);
            arguments.Multiline = true;
            arguments.ScrollBars = ScrollBars.Vertical;
            arguments.Font = new Font("Consolas", 9F);
            Controls.Add(arguments);

            var argsNote = AddLabel(
                "Для диагностики и редких параметров ядра. Они добавляются в конец команды и могут переопределить обычные настройки.", 24, 406);
            argsNote.AutoSize = false;
            argsNote.Size = new Size(522, 38);
            argsNote.ForeColor = Color.DimGray;

            AddLabel("Текущие аргументы запуска", 24, 451);
            var preview = new TextBox();
            preview.Location = new Point(24, 474);
            preview.Size = new Size(522, 45);
            preview.Multiline = true;
            preview.ReadOnly = true;
            preview.BackColor = Color.White;
            preview.Font = new Font("Consolas", 8.5F);
            preview.Text = context.BuildSafeUxPlayArguments();
            Controls.Add(preview);

            var hotspot = new Button();
            hotspot.Text = "Создать временную личную сеть…";
            hotspot.Size = new Size(215, 35);
            hotspot.Location = new Point(24, 540);
            hotspot.FlatStyle = FlatStyle.Flat;
            hotspot.Visible = context.IsPublicNetwork;
            hotspot.Click += delegate { SettingsForm.OpenMobileHotspot(this); };
            Controls.Add(hotspot);
            var hotspotTip = new ToolTip();
            hotspotTip.SetToolTip(hotspot,
                "Открывает системную настройку Windows. Сеть появляется только после того, как вы сами включите хот-спот.");

            var save = new Button();
            save.Text = "Сохранить";
            save.Size = new Size(130, 35);
            save.Location = new Point(416, 540);
            save.BackColor = Color.FromArgb(0, 95, 184);
            save.ForeColor = Color.White;
            save.FlatStyle = FlatStyle.Flat;
            save.FlatAppearance.BorderSize = 0;
            save.Click += OnSave;
            Controls.Add(save);

            AppSettings s = context.CurrentSettings;
            SelectValue(latency, s.LatencyProfile);
            SelectValue(renderer, s.Renderer);
            arguments.Text = s.AdvancedArguments;
            topMost.Checked = s.AlwaysOnTop;
            autoFit.Checked = s.AutoFitWindow;
        }

        private Label AddLabel(string text, int x, int y)
        {
            var label = new Label();
            label.Text = text;
            label.AutoSize = true;
            label.Location = new Point(x, y);
            Controls.Add(label);
            return label;
        }

        private void OnSave(object sender, EventArgs e)
        {
            AppSettings updated = context.CurrentSettings.Copy();
            updated.LatencyProfile = SelectedValue(latency);
            updated.Renderer = SelectedValue(renderer);
            updated.AdvancedArguments = arguments.Text.Trim();
            updated.AlwaysOnTop = topMost.Checked;
            updated.AutoFitWindow = autoFit.Checked;
            context.SaveSettings(updated, true);
            DialogResult = DialogResult.OK;
            Close();
        }

        private static void SelectValue(ComboBox combo, string value)
        {
            for (int i = 0; i < combo.Items.Count; i++)
            {
                var item = combo.Items[i] as NamedValue;
                if (item != null && item.Value == value)
                {
                    combo.SelectedIndex = i;
                    return;
                }
            }
            if (combo.Items.Count > 0)
                combo.SelectedIndex = 0;
        }

        private static string SelectedValue(ComboBox combo)
        {
            var item = combo.SelectedItem as NamedValue;
            return item == null ? "" : item.Value;
        }
    }

    internal sealed class LegacySettingsForm : Form
    {
        private readonly ReceiverContext context;
        private readonly Label status;
        private readonly TextBox receiverName;
        private readonly ComboBox pairing;
        private readonly TextBox fixedPin;
        private readonly ComboBox renderer;
        private readonly ComboBox latency;
        private readonly TextBox advanced;
        private readonly CheckBox autoReceiver;
        private readonly CheckBox autoWindows;
        private readonly CheckBox topMost;
        private readonly CheckBox notifications;
        private readonly Button startStop;

        public LegacySettingsForm(ReceiverContext context)
        {
            this.context = context;
            Text = "AeroMirror";
            Icon = SystemIcons.Application;
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            ClientSize = new Size(520, 690);
            BackColor = Color.FromArgb(248, 249, 251);
            Font = new Font("Segoe UI", 9F);

            var title = new Label();
            title.Text = "AeroMirror";
            title.Font = new Font("Segoe UI Semibold", 20F);
            title.AutoSize = true;
            title.Location = new Point(28, 22);
            Controls.Add(title);

            status = new Label();
            status.AutoSize = true;
            status.Location = new Point(31, 66);
            status.ForeColor = Color.FromArgb(55, 104, 72);
            Controls.Add(status);

            var networkNote = new Label();
            networkNote.Text = "iPhone и компьютер должны быть в одной локальной сети.";
            networkNote.AutoSize = true;
            networkNote.Location = new Point(31, 91);
            networkNote.ForeColor = Color.DimGray;
            Controls.Add(networkNote);

            int y = 128;
            receiverName = AddTextBox("Имя в меню «Повтор экрана»", ref y, false);

            pairing = AddCombo("Доступ", ref y);
            pairing.Items.Add(new NamedValue("Без PIN (только доверенная сеть)", "none"));
            pairing.Items.Add(new NamedValue("PIN при первом подключении", "pin"));
            pairing.Items.Add(new NamedValue("Код при каждом подключении", "password"));

            fixedPin = AddTextBox("Фиксированный PIN (4 цифры, необязательно)", ref y, false);
            fixedPin.MaxLength = 4;

            renderer = AddCombo("Видеорендерер", ref y);
            renderer.Items.Add(new NamedValue("Автоматически", "auto"));
            renderer.Items.Add(new NamedValue("Direct3D 11", "d3d11"));
            renderer.Items.Add(new NamedValue("Direct3D 12 (рекомендуется)", "d3d12"));

            latency = AddCombo("Задержка", ref y);
            latency.Items.Add(new NamedValue("Минимальная — быстрее, возможен рассинхрон", "low"));
            latency.Items.Add(new NamedValue("Сбалансированная — рекомендуется", "balanced"));
            latency.Items.Add(new NamedValue("Стабильная — больше буфер, меньше сбоев", "stable"));

            advanced = AddTextBox("Дополнительные аргументы UxPlay", ref y, false);

            autoReceiver = AddCheckBox("Запускать приёмник вместе с приложением", ref y);
            autoWindows = AddCheckBox("Запускать приложение вместе с Windows", ref y);
            topMost = AddCheckBox("Окно трансляции поверх остальных окон", ref y);
            notifications = AddCheckBox("Показывать системные уведомления", ref y);

            var save = new Button();
            save.Text = "Сохранить и перезапустить";
            save.Size = new Size(190, 38);
            save.Location = new Point(298, 633);
            save.BackColor = Color.FromArgb(0, 95, 184);
            save.ForeColor = Color.White;
            save.FlatStyle = FlatStyle.Flat;
            save.FlatAppearance.BorderSize = 0;
            save.Click += OnSave;
            Controls.Add(save);

            startStop = new Button();
            startStop.Size = new Size(180, 38);
            startStop.Location = new Point(32, 633);
            startStop.Click += delegate
            {
                if (context.IsCoreRunning) context.StopCore(); else context.StartCore();
                SyncStatus();
            };
            Controls.Add(startStop);

            LoadSettings();
            FormClosing += delegate(object sender, FormClosingEventArgs e)
            {
                if (e.CloseReason == CloseReason.UserClosing)
                {
                    e.Cancel = true;
                    Hide();
                }
            };
        }

        public void SyncStatus()
        {
            if (IsDisposed)
                return;
            if (context.IsCoreRunning)
            {
                status.Text = "● Приёмник включён · ожидание подключения";
                status.ForeColor = Color.FromArgb(42, 122, 74);
                startStop.Text = "Остановить приёмник";
            }
            else
            {
                status.Text = "○ Приёмник остановлен";
                status.ForeColor = Color.FromArgb(128, 70, 70);
                startStop.Text = "Запустить приёмник";
            }
        }

        private void LoadSettings()
        {
            AppSettings s = context.CurrentSettings;
            receiverName.Text = s.ReceiverName;
            SelectValue(pairing, s.PairingMode);
            fixedPin.Text = s.FixedPin;
            SelectValue(renderer, s.Renderer);
            SelectValue(latency, s.LatencyProfile);
            advanced.Text = s.AdvancedArguments;
            autoReceiver.Checked = s.AutoStartReceiver;
            autoWindows.Checked = s.AutoStartWindows;
            topMost.Checked = s.AlwaysOnTop;
            notifications.Checked = s.Notify;
            SyncStatus();
        }

        private void OnSave(object sender, EventArgs e)
        {
            string name = receiverName.Text.Trim();
            if (name.Length == 0)
            {
                MessageBox.Show(this, "Введите имя приёмника.", Text,
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            string pin = fixedPin.Text.Trim();
            if (pin.Length > 0 && (pin.Length != 4 || !IsDigits(pin)))
            {
                MessageBox.Show(this, "PIN должен состоять ровно из четырёх цифр.", Text,
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            var updated = new AppSettings();
            updated.ReceiverName = name;
            updated.PairingMode = SelectedValue(pairing);
            updated.FixedPin = pin;
            updated.Renderer = SelectedValue(renderer);
            updated.LatencyProfile = SelectedValue(latency);
            updated.AdvancedArguments = advanced.Text.Trim();
            updated.AutoStartReceiver = autoReceiver.Checked;
            updated.AutoStartWindows = autoWindows.Checked;
            updated.AlwaysOnTop = topMost.Checked;
            updated.Notify = notifications.Checked;
            context.SaveSettings(updated, true);
            MessageBox.Show(this, "Настройки сохранены. Приёмник перезапущен.", Text,
                MessageBoxButtons.OK, MessageBoxIcon.Information);
            SyncStatus();
        }

        private TextBox AddTextBox(string label, ref int y, bool multiline)
        {
            var caption = new Label();
            caption.Text = label;
            caption.AutoSize = true;
            caption.Location = new Point(31, y);
            Controls.Add(caption);
            y += 23;
            var box = new TextBox();
            box.Location = new Point(32, y);
            box.Size = new Size(456, multiline ? 55 : 26);
            box.Multiline = multiline;
            Controls.Add(box);
            y += multiline ? 66 : 39;
            return box;
        }

        private ComboBox AddCombo(string label, ref int y)
        {
            var caption = new Label();
            caption.Text = label;
            caption.AutoSize = true;
            caption.Location = new Point(31, y);
            Controls.Add(caption);
            y += 23;
            var combo = new ComboBox();
            combo.Location = new Point(32, y);
            combo.Size = new Size(456, 26);
            combo.DropDownStyle = ComboBoxStyle.DropDownList;
            Controls.Add(combo);
            y += 39;
            return combo;
        }

        private CheckBox AddCheckBox(string text, ref int y)
        {
            var check = new CheckBox();
            check.Text = text;
            check.AutoSize = true;
            check.Location = new Point(32, y);
            Controls.Add(check);
            y += 27;
            return check;
        }

        private static void SelectValue(ComboBox combo, string value)
        {
            for (int i = 0; i < combo.Items.Count; i++)
            {
                var item = combo.Items[i] as NamedValue;
                if (item != null && item.Value == value)
                {
                    combo.SelectedIndex = i;
                    return;
                }
            }
            if (combo.Items.Count > 0)
                combo.SelectedIndex = 0;
        }

        private static string SelectedValue(ComboBox combo)
        {
            var item = combo.SelectedItem as NamedValue;
            return item == null ? "" : item.Value;
        }

        private static bool IsDigits(string text)
        {
            foreach (char c in text)
                if (c < '0' || c > '9') return false;
            return true;
        }
    }

    internal sealed class NamedValue
    {
        public readonly string Name;
        public readonly string Value;
        public readonly string Subtitle;
        public NamedValue(string name, string value)
            : this(name, value, "") { }
        public NamedValue(string name, string value, string subtitle)
        {
            Name = name;
            Value = value;
            Subtitle = subtitle ?? "";
        }
        public override string ToString() { return Name; }
    }

    internal sealed class WheelSafeComboBox : ComboBox
    {
        private const int WmMouseWheel = 0x020A;
        private int wheelPixelRemainder;
        private DropDownGlyph dropDownGlyph;

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WmMouseWheel)
            {
                if (DroppedDown)
                {
                    base.WndProc(ref m);
                    return;
                }
                int delta = unchecked((short)(
                    (m.WParam.ToInt64() >> 16) & 0xFFFF));
                ScrollParent(delta);
                m.Result = IntPtr.Zero;
                return;
            }
            base.WndProc(ref m);
        }

        protected override void OnMouseWheel(MouseEventArgs e)
        {
            if (DroppedDown)
            {
                base.OnMouseWheel(e);
                return;
            }
            ScrollParent(e.Delta);
        }

        protected override void OnCreateControl()
        {
            base.OnCreateControl();
            if (dropDownGlyph == null)
            {
                dropDownGlyph = new DropDownGlyph(this);
                Controls.Add(dropDownGlyph);
            }
            LayoutDropDownGlyph();
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);
            LayoutDropDownGlyph();
        }

        protected override void OnBackColorChanged(EventArgs e)
        {
            base.OnBackColorChanged(e);
            if (dropDownGlyph != null)
                dropDownGlyph.BackColor = BackColor;
            Invalidate();
        }

        protected override void OnForeColorChanged(EventArgs e)
        {
            base.OnForeColorChanged(e);
            if (dropDownGlyph != null)
                dropDownGlyph.ForeColor = ForeColor;
            Invalidate();
        }

        private void LayoutDropDownGlyph()
        {
            if (dropDownGlyph == null ||
                DropDownStyle != ComboBoxStyle.DropDownList)
                return;
            int width = Math.Max(24, Font.Height + 9);
            dropDownGlyph.Bounds = new Rectangle(
                Math.Max(0, ClientSize.Width - width - 1),
                1,
                Math.Min(width, ClientSize.Width),
                Math.Max(1, ClientSize.Height - 2));
            dropDownGlyph.BackColor = BackColor;
            dropDownGlyph.ForeColor = ForeColor;
            dropDownGlyph.Visible = true;
            dropDownGlyph.BringToFront();
        }

        private sealed class DropDownGlyph : Control
        {
            private readonly WheelSafeComboBox owner;
            private bool hovered;

            internal DropDownGlyph(WheelSafeComboBox owner)
            {
                this.owner = owner;
                SetStyle(
                    ControlStyles.AllPaintingInWmPaint |
                    ControlStyles.OptimizedDoubleBuffer |
                    ControlStyles.UserPaint, true);
                TabStop = false;
                AccessibleName = "Открыть список";
                MouseEnter += delegate
                {
                    hovered = true;
                    Invalidate();
                };
                MouseLeave += delegate
                {
                    hovered = false;
                    Invalidate();
                };
                MouseDown += delegate
                {
                    if (!owner.Enabled)
                        return;
                    owner.Focus();
                    owner.DroppedDown = !owner.DroppedDown;
                };
            }

            protected override void OnPaint(PaintEventArgs e)
            {
                Color fill = hovered && owner.Enabled
                    ? Blend(BackColor, ForeColor, 0.08F)
                    : BackColor;
                using (var background = new SolidBrush(fill))
                using (var divider = new Pen(
                    Color.FromArgb(90, ForeColor), 1F))
                using (var chevron = new Pen(owner.Enabled
                    ? ForeColor : SystemColors.GrayText, 1.6F))
                {
                    e.Graphics.FillRectangle(background, ClientRectangle);
                    e.Graphics.DrawLine(
                        divider, 0, 3, 0, Math.Max(3, Height - 4));
                    float centerX = Width / 2F;
                    float centerY = Height / 2F + 1F;
                    float half =
                        Math.Max(3F, Math.Min(5F, Width / 6F));
                    e.Graphics.SmoothingMode =
                        System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                    e.Graphics.DrawLines(chevron, new[]
                    {
                        new PointF(centerX - half, centerY - half / 2F),
                        new PointF(centerX, centerY + half / 2F),
                        new PointF(centerX + half, centerY - half / 2F)
                    });
                }
            }

            private static Color Blend(
                Color background, Color foreground, float amount)
            {
                return Color.FromArgb(
                    (int)(background.R * (1F - amount) +
                        foreground.R * amount),
                    (int)(background.G * (1F - amount) +
                        foreground.G * amount),
                    (int)(background.B * (1F - amount) +
                        foreground.B * amount));
            }
        }

        private void ScrollParent(int delta)
        {
            Control current = Parent;
            while (current != null)
            {
                ScrollableControl scroll = current as ScrollableControl;
                if (scroll != null && scroll.AutoScroll)
                {
                    Point position = scroll.AutoScrollPosition;
                    int configuredLines = SystemInformation.MouseWheelScrollLines;
                    if (configuredLines == 0)
                        return;
                    int pixelsPerDetent = configuredLines < 0
                        ? Math.Max(1, scroll.ClientSize.Height)
                        : configuredLines * 16;
                    int numerator =
                        delta * pixelsPerDetent + wheelPixelRemainder;
                    int step = numerator / 120;
                    wheelPixelRemainder = numerator % 120;
                    if (step == 0)
                        return;
                    int targetY = Math.Max(0, -position.Y - step);
                    scroll.AutoScrollPosition =
                        new Point(Math.Max(0, -position.X), targetY);
                    return;
                }
                current = current.Parent;
            }
        }
    }

    internal sealed class DiagnosticsForm : Form
    {
        public DiagnosticsForm(string diagnostics)
        {
            Text = "Диагностика";
            StartPosition = FormStartPosition.CenterParent;
            ClientSize = new Size(700, 480);
            Font = new Font("Segoe UI", 9F);

            var text = new TextBox();
            text.Multiline = true;
            text.ReadOnly = true;
            text.ScrollBars = ScrollBars.Both;
            text.WordWrap = false;
            text.Dock = DockStyle.Fill;
            text.Text = diagnostics;
            Controls.Add(text);

            var copy = new Button();
            copy.Text = "Копировать";
            copy.Dock = DockStyle.Bottom;
            copy.Height = 38;
            copy.Click += delegate { Clipboard.SetText(diagnostics); };
            Controls.Add(copy);
        }
    }

    internal sealed class UpdateInfo
    {
        internal Version Version;
        internal string VersionText = "";
        internal string Title = "";
        internal string Notes = "";
        internal string ReleasePage = "";
        internal string InstallerUrl = "";
        internal string InstallerSha256 = "";
        internal bool IsNewer;
    }

    internal static class UpdateService
    {
        internal static string RepositoryFilePath
        {
            get
            {
                return Path.Combine(
                    AppDomain.CurrentDomain.BaseDirectory,
                    "update-repository.txt");
            }
        }

        internal static UpdateInfo Check()
        {
            string repository = ReadRepository();
            if (repository.Length == 0)
                throw new InvalidOperationException(
                    "Канал обновлений ещё не настроен. " +
                    "Он станет доступен после публикации проекта на GitHub.");

            ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
            string api = "https://api.github.com/repos/" +
                repository + "/releases/latest";
            string json;
            using (var client = CreateClient())
                json = client.DownloadString(api);

            var serializer = new JavaScriptSerializer();
            var root = serializer.DeserializeObject(json)
                as Dictionary<string, object>;
            if (root == null)
                throw new InvalidDataException(
                    "GitHub вернул неизвестный формат ответа.");

            string tag = GetString(root, "tag_name");
            Version latest;
            if (!TryParseVersion(tag, out latest))
                throw new InvalidDataException(
                    "В последнем GitHub Release не найдена корректная версия.");

            var info = new UpdateInfo();
            info.Version = latest;
            info.VersionText = tag;
            info.Title = GetString(root, "name");
            info.Notes = CleanReleaseNotes(GetString(root, "body"));
            info.ReleasePage = GetString(root, "html_url");
            info.IsNewer = latest.CompareTo(
                AppVersion.Current) > 0;

            object assetsValue;
            object[] assets = root.TryGetValue("assets", out assetsValue)
                ? assetsValue as object[] : null;
            if (assets != null)
            {
                string expectedInstaller =
                    "AeroMirror-Setup-" + latest.ToString(3) + ".exe";
                foreach (object assetValue in assets)
                {
                    var asset = assetValue as Dictionary<string, object>;
                    if (asset == null)
                        continue;
                    string name = GetString(asset, "name");
                    if (string.Equals(
                            name,
                            expectedInstaller,
                            StringComparison.OrdinalIgnoreCase) &&
                        IsCompatibleInstallerName(name))
                    {
                        info.InstallerUrl =
                            GetString(asset, "browser_download_url");
                        string digest = GetString(asset, "digest");
                        if (digest.StartsWith(
                            "sha256:", StringComparison.OrdinalIgnoreCase))
                            info.InstallerSha256 = digest.Substring(7);
                        break;
                    }
                }
            }
            return info;
        }

        private static bool IsCompatibleInstallerName(string name)
        {
            string lower = (name ?? "").ToLowerInvariant();
            return lower.IndexOf("arm64") < 0 &&
                lower.IndexOf("aarch64") < 0 &&
                lower.IndexOf("x86") < 0 &&
                lower.IndexOf("win32") < 0;
        }

        internal static string DownloadAndVerify(UpdateInfo info)
        {
            if (info == null || string.IsNullOrWhiteSpace(info.InstallerUrl))
                throw new InvalidOperationException(
                    "В GitHub Release нет установщика обновления.");
            if (string.IsNullOrWhiteSpace(info.InstallerSha256))
                throw new InvalidOperationException(
                    "GitHub Release не содержит SHA-256 установщика. " +
                    "Автоматическое обновление остановлено для безопасности.");

            var uri = new Uri(info.InstallerUrl);
            if (!string.Equals(
                uri.Scheme, Uri.UriSchemeHttps,
                StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException(
                    "Установщик обновления должен загружаться по HTTPS.");

            string name = Path.GetFileName(uri.AbsolutePath);
            if (string.IsNullOrWhiteSpace(name) ||
                !name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                name = "AeroMirror-Update.exe";
            string path = Path.Combine(
                Path.GetTempPath(),
                "AeroMirror-" + Guid.NewGuid().ToString("N") + "-" + name);
            bool complete = false;
            try
            {
                using (var client = CreateClient())
                    client.DownloadFile(uri, path);

                string actual;
                using (var stream = File.OpenRead(path))
                using (var sha = SHA256.Create())
                    actual = BitConverter.ToString(
                        sha.ComputeHash(stream)).Replace("-", "");
                if (!string.Equals(
                    actual, info.InstallerSha256,
                    StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException(
                        "SHA-256 загруженного установщика не совпал с GitHub Release.");
                complete = true;
                return path;
            }
            finally
            {
                if (!complete)
                {
                    try { File.Delete(path); }
                    catch { }
                }
            }
        }

        private static WebClient CreateClient()
        {
            var client = new WebClient();
            client.Encoding = Encoding.UTF8;
            client.Headers[HttpRequestHeader.UserAgent] =
                "AeroMirror-Windows/" +
                AppVersion.Display;
            client.Headers[HttpRequestHeader.Accept] =
                "application/vnd.github+json";
            client.Headers["X-GitHub-Api-Version"] = "2026-03-10";
            return client;
        }

        private static string ReadRepository()
        {
            if (!File.Exists(RepositoryFilePath))
                return "";
            foreach (string raw in File.ReadAllLines(
                RepositoryFilePath, Encoding.UTF8))
            {
                string value = raw.Trim();
                if (value.Length == 0 || value.StartsWith("#"))
                    continue;
                string[] parts = value.Split('/');
                if (parts.Length == 2 &&
                    IsSafeRepositoryPart(parts[0]) &&
                    IsSafeRepositoryPart(parts[1]))
                    return parts[0] + "/" + parts[1];
            }
            return "";
        }

        private static bool IsSafeRepositoryPart(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length > 100)
                return false;
            foreach (char c in value)
            {
                if (!char.IsLetterOrDigit(c) &&
                    c != '-' && c != '_' && c != '.')
                    return false;
            }
            return true;
        }

        private static string GetString(
            Dictionary<string, object> values, string key)
        {
            object value;
            return values.TryGetValue(key, out value) && value != null
                ? Convert.ToString(value) : "";
        }

        private static bool TryParseVersion(string text, out Version version)
        {
            string value = (text ?? "").Trim();
            if (value.StartsWith("v", StringComparison.OrdinalIgnoreCase))
                value = value.Substring(1);
            int suffix = value.IndexOf('-');
            if (suffix >= 0)
                value = value.Substring(0, suffix);
            return Version.TryParse(value, out version);
        }

        private static string CleanReleaseNotes(string markdown)
        {
            string text = (markdown ?? "").Replace("\r\n", "\n");
            text = text.Replace("### ", "").Replace("## ", "")
                .Replace("# ", "").Replace("**", "").Replace("`", "");
            return text.Replace("\n", Environment.NewLine).Trim();
        }
    }

    internal static class ThemeHelper
    {
        private static readonly Color LightBase = Color.FromArgb(247, 247, 247);
        private static readonly Color LightSurface = Color.White;
        private static readonly Color LightAccent = Color.FromArgb(242, 247, 253);
        private static readonly Color LightField = Color.White;
        private static readonly Color LightText = Color.FromArgb(28, 28, 28);
        private static readonly Color LightSecondary = Color.FromArgb(95, 95, 95);
        private static readonly Color DarkBase = Color.FromArgb(30, 31, 34);
        private static readonly Color DarkSurface = Color.FromArgb(44, 45, 49);
        private static readonly Color DarkAccent = Color.FromArgb(35, 55, 72);
        private static readonly Color DarkField = Color.FromArgb(52, 53, 58);
        private static readonly Color DarkText = Color.FromArgb(250, 250, 250);
        private static readonly Color DarkSecondary = Color.FromArgb(207, 207, 207);
        private static readonly Color Primary = Color.FromArgb(0, 95, 184);

        internal static bool IsDark(string mode)
        {
            if (string.Equals(mode, "dark", StringComparison.OrdinalIgnoreCase))
                return true;
            if (string.Equals(mode, "light", StringComparison.OrdinalIgnoreCase))
                return false;
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"))
                {
                    object value = key == null
                        ? null : key.GetValue("AppsUseLightTheme");
                    if (value is int)
                        return (int)value == 0;
                }
            }
            catch { }
            return false;
        }

        internal static void Apply(Control root, bool dark)
        {
            ApplyControl(root, dark);
        }

        private static void ApplyControl(Control control, bool dark)
        {
            Color currentBack = control.BackColor;
            Color currentFore = control.ForeColor;
            Color baseColor = dark ? DarkBase : LightBase;
            Color surfaceColor = dark ? DarkSurface : LightSurface;
            Color accentColor = dark ? DarkAccent : LightAccent;
            Color fieldColor = dark ? DarkField : LightField;
            Color textColor = dark ? DarkText : LightText;
            Color secondaryColor = dark ? DarkSecondary : LightSecondary;

            if (control is Form)
            {
                control.BackColor = baseColor;
                control.ForeColor = textColor;
            }
            else if (control is TextBox || control is RichTextBox ||
                control is ComboBox)
            {
                control.BackColor = fieldColor;
                control.ForeColor = textColor;
            }
            else if (control is Button)
            {
                Button button = (Button)control;
                bool primary = IsPrimary(currentBack);
                button.BackColor = primary ? Primary : surfaceColor;
                button.ForeColor = primary ? Color.White : textColor;
                if (!button.Enabled)
                {
                    button.BackColor = dark
                        ? Color.FromArgb(57, 57, 57)
                        : Color.FromArgb(225, 225, 225);
                    button.ForeColor = secondaryColor;
                }
            }
            else if (control is Panel)
            {
                if (IsAccent(currentBack))
                    control.BackColor = accentColor;
                else if (IsSurface(currentBack))
                    control.BackColor = surfaceColor;
                else
                    control.BackColor = baseColor;
                control.ForeColor = textColor;
            }
            else if (control is PictureBox)
            {
                control.BackColor = Color.Transparent;
                control.ForeColor = textColor;
            }
            else if (control is LinkLabel)
            {
                var link = (LinkLabel)control;
                link.LinkColor = dark
                    ? Color.FromArgb(111, 190, 255)
                    : Color.FromArgb(0, 95, 184);
                link.ActiveLinkColor = dark
                    ? Color.FromArgb(157, 211, 255)
                    : Color.FromArgb(0, 72, 140);
                link.VisitedLinkColor = link.LinkColor;
            }
            else if (control is Label || control is CheckBox)
            {
                control.ForeColor = IsSecondary(currentFore)
                    ? secondaryColor : textColor;
            }
            else if (control.Parent is WheelSafeComboBox)
            {
                control.BackColor = control.Parent.BackColor;
                control.ForeColor = control.Parent.ForeColor;
            }
            else
            {
                control.BackColor = baseColor;
                control.ForeColor = textColor;
            }

            foreach (Control child in control.Controls)
                ApplyControl(child, dark);
        }

        private static bool IsPrimary(Color color)
        {
            return color.ToArgb() == Primary.ToArgb() ||
                (color.B > 120 && color.B > color.R * 1.4 &&
                 color.B > color.G * 1.1);
        }

        private static bool IsSurface(Color color)
        {
            return color.ToArgb() == LightSurface.ToArgb() ||
                color.ToArgb() == DarkSurface.ToArgb();
        }

        private static bool IsAccent(Color color)
        {
            return color.ToArgb() == LightAccent.ToArgb() ||
                color.ToArgb() == DarkAccent.ToArgb() ||
                color.ToArgb() == Color.FromArgb(237, 246, 255).ToArgb() ||
                color.ToArgb() == Color.FromArgb(255, 244, 215).ToArgb() ||
                color.ToArgb() == Color.FromArgb(73, 57, 24).ToArgb();
        }

        private static bool IsSecondary(Color color)
        {
            return color.ToArgb() == Color.DimGray.ToArgb() ||
                color.ToArgb() == LightSecondary.ToArgb() ||
                color.ToArgb() == DarkSecondary.ToArgb() ||
                color.ToArgb() == Color.FromArgb(70, 70, 70).ToArgb();
        }
    }

    internal static class AppIcon
    {
        private static readonly Icon icon = LoadIcon();
        private static readonly Image image = LoadImage();

        public static Icon Current { get { return icon; } }
        public static Image Image { get { return image; } }

        private static Icon LoadIcon()
        {
            try
            {
                Icon result = Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location);
                if (result != null)
                    return result;
            }
            catch { }
            return SystemIcons.Application;
        }

        private static Image LoadImage()
        {
            try
            {
                using (Stream stream = Assembly.GetExecutingAssembly()
                    .GetManifestResourceStream("AeroMirrorLogo"))
                {
                    if (stream != null)
                    {
                        using (Image source = Image.FromStream(stream))
                            return new Bitmap(source);
                    }
                }
            }
            catch { }
            return icon.ToBitmap();
        }
    }

    internal sealed class NetworkProfileInfo
    {
        public bool IsKnown;
        public bool IsPublic;
        public string Category = "Unknown";
        public string Name = "";
        public string InterfaceName = "";
        public string Addresses = "";
        public int InterfaceIndex;
        public int NonPhysicalProfileCount;
        public int PublicNonPhysicalProfileCount;
        public string Signature = "Unknown|||";
    }

    internal static class NetworkSafety
    {
        public static NetworkProfileInfo DetectPhysicalProfile()
        {
            var result = new NetworkProfileInfo();
            try
            {
                string powershell = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    @"WindowsPowerShell\v1.0\powershell.exe");
                var start = new ProcessStartInfo();
                start.FileName = powershell;
                start.Arguments =
                    "-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " +
                    "\"$OutputEncoding=[Console]::OutputEncoding=[Text.UTF8Encoding]::new(); " +
                    "$physical=@(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | " +
                    "Where-Object {$_.Status -eq 'Up'} | ForEach-Object {$_.ifIndex}); " +
                    "$connected=@(Get-NetConnectionProfile -ErrorAction SilentlyContinue | " +
                    "Where-Object {($_.IPv4Connectivity -ne 'Disconnected' -or " +
                    "$_.IPv6Connectivity -ne 'Disconnected')}); " +
                    "$physicalProfiles=@($connected | Where-Object " +
                    "{$physical -contains $_.InterfaceIndex}); " +
                    "$overlayProfiles=@($connected | Where-Object " +
                    "{$physical -notcontains $_.InterfaceIndex}); " +
                    "$publicOverlays=@($overlayProfiles | Where-Object " +
                    "{$_.NetworkCategory -eq 'Public'}); " +
                    "$p=$physicalProfiles | Sort-Object " +
                    "@{Expression={if($_.NetworkCategory -eq 'Public'){0}else{1}}}, " +
                    "@{Expression={if($_.IPv4Connectivity -eq 'Internet'){0}else{1}}} | Select-Object -First 1; " +
                    "$category='Unknown';$name='';$alias='';$index=0;$addresses=''; " +
                    "if($p){$ips=@(Get-NetIPAddress -InterfaceIndex $p.InterfaceIndex " +
                    "-AddressFamily IPv4 -ErrorAction SilentlyContinue | " +
                    "Where-Object {$_.IPAddress -notlike '169.254.*'} | " +
                    "ForEach-Object {$_.IPAddress} | Sort-Object -Unique); " +
                    "$category=$p.NetworkCategory.ToString();$name=$p.Name;" +
                    "$alias=$p.InterfaceAlias;$index=[int]$p.InterfaceIndex;" +
                    "$addresses=($ips -join ',')}; " +
                    "$value=[ordered]@{category=$category;name=$name;" +
                    "interfaceName=$alias;addresses=$addresses;interfaceIndex=$index;" +
                    "overlayCount=$overlayProfiles.Count;" +
                    "publicOverlayCount=$publicOverlays.Count}; " +
                    "$value | ConvertTo-Json -Compress\"";
                start.UseShellExecute = false;
                start.CreateNoWindow = true;
                start.WindowStyle = ProcessWindowStyle.Hidden;
                start.RedirectStandardOutput = true;
                start.StandardOutputEncoding = Encoding.UTF8;
                using (Process process = Process.Start(start))
                {
                    if (!process.WaitForExit(5000))
                    {
                        process.Kill();
                        process.WaitForExit(1500);
                        return result;
                    }
                    string output = process.StandardOutput.ReadToEnd();
                    string line = output.Trim();
                    if (line.Length == 0)
                        return result;
                    Dictionary<string, object> values =
                        new JavaScriptSerializer().DeserializeObject(line)
                        as Dictionary<string, object>;
                    if (values == null)
                        return result;
                    result.NonPhysicalProfileCount = Math.Max(
                        0, ReadInt(values, "overlayCount"));
                    result.PublicNonPhysicalProfileCount = Math.Max(
                        0, ReadInt(values, "publicOverlayCount"));
                    result.Category =
                        ReadString(values, "category").Trim();
                    result.InterfaceIndex =
                        ReadInt(values, "interfaceIndex");
                    bool recognizedCategory =
                        string.Equals(
                            result.Category,
                            "Private",
                            StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(
                            result.Category,
                            "Public",
                            StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(
                            result.Category,
                            "DomainAuthenticated",
                            StringComparison.OrdinalIgnoreCase);
                    if (!recognizedCategory || result.InterfaceIndex <= 0)
                        return result;
                    result.IsKnown = true;
                    result.IsPublic = string.Equals(
                        result.Category, "Public", StringComparison.OrdinalIgnoreCase);
                    result.Name = ReadString(values, "name").Trim();
                    result.InterfaceName =
                        ReadString(values, "interfaceName").Trim();
                    result.Addresses =
                        ReadString(values, "addresses").Trim();
                    result.Signature = result.Category + "|" +
                        result.InterfaceIndex + "|" + result.Name + "|" +
                        result.InterfaceName + "|" + result.Addresses;
                    return result;
                }
            }
            catch (Exception ex)
            {
                ReceiverContext.Log("Network profile check failed: " + ex.Message);
                return result;
            }
        }

        private static string ReadString(
            Dictionary<string, object> values, string key)
        {
            object value;
            return values.TryGetValue(key, out value) && value != null
                ? Convert.ToString(value)
                : "";
        }

        private static int ReadInt(
            Dictionary<string, object> values, string key)
        {
            int parsed;
            return int.TryParse(ReadString(values, key), out parsed)
                ? parsed
                : 0;
        }
    }

    internal static class NativeMethods
    {
        internal delegate bool EnumWindowsProc(IntPtr window, IntPtr parameter);
        internal static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        internal static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
        internal const uint SWP_NOSIZE = 0x0001;
        internal const uint SWP_NOMOVE = 0x0002;
        internal const uint SWP_NOZORDER = 0x0004;
        internal const uint SWP_NOACTIVATE = 0x0010;
        internal const uint SWP_FRAMECHANGED = 0x0020;
        private const int GWL_EXSTYLE = -20;
        private const long WS_EX_TOOLWINDOW = 0x00000080L;
        private const long WS_EX_APPWINDOW = 0x00040000L;
        private const int VK_LBUTTON = 0x01;
        private const uint JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
        private const int JobObjectExtendedLimitInformation = 9;

        [StructLayout(LayoutKind.Sequential)]
        internal struct RECT
        {
            internal int Left;
            internal int Top;
            internal int Right;
            internal int Bottom;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_BASIC_LIMIT_INFORMATION
        {
            internal long PerProcessUserTimeLimit;
            internal long PerJobUserTimeLimit;
            internal uint LimitFlags;
            internal UIntPtr MinimumWorkingSetSize;
            internal UIntPtr MaximumWorkingSetSize;
            internal uint ActiveProcessLimit;
            internal IntPtr Affinity;
            internal uint PriorityClass;
            internal uint SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IO_COUNTERS
        {
            internal ulong ReadOperationCount;
            internal ulong WriteOperationCount;
            internal ulong OtherOperationCount;
            internal ulong ReadTransferCount;
            internal ulong WriteTransferCount;
            internal ulong OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            internal JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            internal IO_COUNTERS IoInfo;
            internal UIntPtr ProcessMemoryLimit;
            internal UIntPtr JobMemoryLimit;
            internal UIntPtr PeakProcessMemoryUsed;
            internal UIntPtr PeakJobMemoryUsed;
        }

        [DllImport("user32.dll")]
        internal static extern bool EnumWindows(EnumWindowsProc callback, IntPtr parameter);

        [DllImport("user32.dll")]
        internal static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

        [DllImport("user32.dll")]
        internal static extern bool IsWindowVisible(IntPtr window);

        [DllImport("user32.dll")]
        internal static extern bool IsWindow(IntPtr window);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr CreateJobObject(
            IntPtr securityAttributes, string name);

        [DllImport("kernel32.dll")]
        private static extern bool SetInformationJobObject(
            IntPtr job, int informationClass, IntPtr information,
            uint informationLength);

        [DllImport("kernel32.dll")]
        private static extern bool AssignProcessToJobObject(
            IntPtr job, IntPtr process);

        [DllImport("kernel32.dll")]
        private static extern bool CloseHandle(IntPtr handle);

        internal static IntPtr CreateKillOnCloseJob(Process process)
        {
            IntPtr job = IntPtr.Zero;
            IntPtr information = IntPtr.Zero;
            try
            {
                job = CreateJobObject(IntPtr.Zero, null);
                if (job == IntPtr.Zero)
                    return IntPtr.Zero;
                var limits = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
                limits.BasicLimitInformation.LimitFlags =
                    JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
                int size = Marshal.SizeOf(
                    typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
                information = Marshal.AllocHGlobal(size);
                Marshal.StructureToPtr(limits, information, false);
                if (!SetInformationJobObject(
                        job, JobObjectExtendedLimitInformation,
                        information, (uint)size) ||
                    !AssignProcessToJobObject(job, process.Handle))
                {
                    CloseHandle(job);
                    return IntPtr.Zero;
                }
                return job;
            }
            catch
            {
                if (job != IntPtr.Zero)
                    CloseHandle(job);
                return IntPtr.Zero;
            }
            finally
            {
                if (information != IntPtr.Zero)
                    Marshal.FreeHGlobal(information);
            }
        }

        internal static void CloseHandleSafe(ref IntPtr handle)
        {
            if (handle == IntPtr.Zero)
                return;
            try { CloseHandle(handle); }
            catch { }
            handle = IntPtr.Zero;
        }

        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(
            IntPtr window, int attribute, ref int value, int valueSize);

        internal static void SetImmersiveDarkMode(
            IntPtr window, bool enabled)
        {
            if (window == IntPtr.Zero)
                return;
            int value = enabled ? 1 : 0;
            try
            {
                int result = DwmSetWindowAttribute(
                    window, 20, ref value, sizeof(int));
                if (result != 0)
                    DwmSetWindowAttribute(
                        window, 19, ref value, sizeof(int));
            }
            catch { }
        }

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        internal static extern int GetWindowText(IntPtr window, StringBuilder text, int count);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetClassName(IntPtr window, StringBuilder text, int count);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        internal static extern bool SetWindowText(IntPtr window, string text);

        [DllImport("user32.dll")]
        internal static extern bool SetWindowPos(IntPtr window, IntPtr insertAfter,
            int x, int y, int width, int height, uint flags);

        [DllImport("user32.dll", EntryPoint = "GetWindowLong")]
        private static extern int GetWindowLong32(IntPtr window, int index);

        [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
        private static extern IntPtr GetWindowLongPtr64(IntPtr window, int index);

        [DllImport("user32.dll", EntryPoint = "SetWindowLong")]
        private static extern int SetWindowLong32(IntPtr window, int index, int value);

        [DllImport("user32.dll", EntryPoint = "SetWindowLongPtr")]
        private static extern IntPtr SetWindowLongPtr64(
            IntPtr window, int index, IntPtr value);

        internal static void SetToolWindowStyle(IntPtr window, bool hideFromTaskbar)
        {
            long current = IntPtr.Size == 8
                ? GetWindowLongPtr64(window, GWL_EXSTYLE).ToInt64()
                : GetWindowLong32(window, GWL_EXSTYLE);
            long updated = hideFromTaskbar
                ? (current | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW
                : (current | WS_EX_APPWINDOW) & ~WS_EX_TOOLWINDOW;
            if (updated == current)
                return;
            if (IntPtr.Size == 8)
                SetWindowLongPtr64(window, GWL_EXSTYLE, new IntPtr(updated));
            else
                SetWindowLong32(window, GWL_EXSTYLE, (int)updated);
            SetWindowPos(window, IntPtr.Zero, 0, 0, 0, 0,
                SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                SWP_NOACTIVATE | SWP_FRAMECHANGED);
        }

        [DllImport("user32.dll")]
        internal static extern bool GetWindowRect(IntPtr window, out RECT rectangle);

        [DllImport("user32.dll")]
        internal static extern bool GetClientRect(IntPtr window, out RECT rectangle);

        [DllImport("user32.dll")]
        private static extern short GetAsyncKeyState(int virtualKey);

        internal static bool IsLeftMouseButtonDown()
        {
            return (GetAsyncKeyState(VK_LBUTTON) & 0x8000) != 0;
        }

        [DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr window, int command);

        [DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr window);

        internal static void ShowExistingWindow()
        {
            int currentPid = Process.GetCurrentProcess().Id;
            string currentProcessName = Process.GetCurrentProcess().ProcessName;
            EnumWindows(delegate(IntPtr window, IntPtr parameter)
            {
                uint windowPid;
                GetWindowThreadProcessId(window, out windowPid);
                if (windowPid == (uint)currentPid)
                    return true;

                var title = new StringBuilder(256);
                GetWindowText(window, title, title.Capacity);
                string value = title.ToString();
                var className = new StringBuilder(256);
                GetClassName(window, className, className.Capacity);
                bool matchingHiddenForm = false;
                try
                {
                    using (Process process = Process.GetProcessById((int)windowPid))
                    {
                        matchingHiddenForm =
                            string.Equals(process.ProcessName, currentProcessName,
                                StringComparison.OrdinalIgnoreCase) &&
                            className.ToString().StartsWith(
                                "WindowsForms10.Window.", StringComparison.Ordinal);
                    }
                }
                catch { }

                if (value == "AeroMirror" ||
                    value == "AirPlay Receiver" ||
                    value == "AirPlay Receiver MVP" ||
                    matchingHiddenForm)
                {
                    ShowWindow(window, 9);
                    SetForegroundWindow(window);
                    return false;
                }
                return true;
            }, IntPtr.Zero);
        }
    }
}
