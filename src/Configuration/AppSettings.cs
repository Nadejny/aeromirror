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
    internal sealed class AppSettings
    {
        internal const int CurrentSettingsVersion = 11;

        public int SettingsVersion = CurrentSettingsVersion;
        public string ReceiverName = Environment.MachineName;
        public string PairingMode = "none";
        public string FixedPin = "";
        public string QualityPreset = "1080p60";
        public string Renderer = "d3d11";
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
        public int StreamWindowLeft = 0;
        public int StreamWindowTop = 0;
        public int StreamWindowWidth = 0;
        public int StreamWindowHeight = 0;
        public int StreamWindowDpi = 0;

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
        public static string ReceiverDeviceIdPath { get { return Path.Combine(Folder, "receiver-device-id.txt"); } }
        public static string TrustedClientsPath { get { return Path.Combine(Folder, "trusted-clients.txt"); } }

        private static readonly object ReceiverDeviceIdSync = new object();
        private static string cachedReceiverDeviceId = "";

        public static string GetSavedReceiverDeviceId()
        {
            lock (ReceiverDeviceIdSync)
            {
                if (IsValidReceiverDeviceId(cachedReceiverDeviceId))
                    return cachedReceiverDeviceId;

                try
                {
                    if (File.Exists(ReceiverDeviceIdPath))
                    {
                        string saved = File.ReadAllText(
                            ReceiverDeviceIdPath, Encoding.UTF8).Trim();
                        if (IsValidReceiverDeviceId(saved))
                        {
                            cachedReceiverDeviceId = saved.ToUpperInvariant();
                            return cachedReceiverDeviceId;
                        }
                    }
                }
                catch { }
                return "";
            }
        }

        public static void RememberReceiverDeviceId(string value)
        {
            if (!IsValidReceiverDeviceId(value))
                return;
            string normalized = value.Trim().ToUpperInvariant();
            lock (ReceiverDeviceIdSync)
            {
                if (IsValidReceiverDeviceId(GetSavedReceiverDeviceId()))
                    return;
                string temporaryPath = ReceiverDeviceIdPath + "." +
                    Guid.NewGuid().ToString("N") + ".tmp";
                try
                {
                    File.WriteAllText(
                        temporaryPath,
                        normalized + Environment.NewLine,
                        new UTF8Encoding(false));
                    if (File.Exists(ReceiverDeviceIdPath))
                        File.Replace(
                            temporaryPath, ReceiverDeviceIdPath, null, true);
                    else
                        File.Move(temporaryPath, ReceiverDeviceIdPath);
                    cachedReceiverDeviceId = normalized;
                }
                catch { }
                finally
                {
                    try
                    {
                        if (File.Exists(temporaryPath))
                            File.Delete(temporaryPath);
                    }
                    catch { }
                }
            }
        }

        private static bool IsValidReceiverDeviceId(string value)
        {
            return !string.IsNullOrWhiteSpace(value) && Regex.IsMatch(
                value.Trim(),
                @"^[0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5}$",
                RegexOptions.CultureInvariant);
        }

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
                DismissPinSuggestion = DismissPinSuggestion,
                StreamWindowLeft = StreamWindowLeft,
                StreamWindowTop = StreamWindowTop,
                StreamWindowWidth = StreamWindowWidth,
                StreamWindowHeight = StreamWindowHeight,
                StreamWindowDpi = StreamWindowDpi
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
                    case "StreamWindowLeft":
                        int streamWindowLeft;
                        if (int.TryParse(value, out streamWindowLeft))
                            settings.StreamWindowLeft = streamWindowLeft;
                        break;
                    case "StreamWindowTop":
                        int streamWindowTop;
                        if (int.TryParse(value, out streamWindowTop))
                            settings.StreamWindowTop = streamWindowTop;
                        break;
                    case "StreamWindowWidth":
                        int streamWindowWidth;
                        if (int.TryParse(value, out streamWindowWidth))
                            settings.StreamWindowWidth = streamWindowWidth;
                        break;
                    case "StreamWindowHeight":
                        int streamWindowHeight;
                        if (int.TryParse(value, out streamWindowHeight))
                            settings.StreamWindowHeight = streamWindowHeight;
                        break;
                    case "StreamWindowDpi":
                        int streamWindowDpi;
                        if (int.TryParse(value, out streamWindowDpi))
                            settings.StreamWindowDpi = streamWindowDpi;
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
            if (!hasSettingsVersion || settings.SettingsVersion < 10)
            {
                settings.SettingsVersion = 10;
                settings.ClearStreamWindowPlacement();
            }
            MigrateRendererStabilityDefault(settings);
            settings.NormalizePersistedValues();
            return settings;
        }

        internal static void MigrateRendererStabilityDefault(
            AppSettings settings)
        {
            if (settings == null ||
                settings.SettingsVersion >= CurrentSettingsVersion)
                return;

            if (string.Equals(
                    (settings.Renderer ?? "").Trim(),
                    "auto",
                    StringComparison.OrdinalIgnoreCase))
            {
                settings.Renderer = "d3d11";
            }
            settings.SettingsVersion = CurrentSettingsVersion;
        }

        public void Save()
        {
            NormalizePersistedValues();
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
                "DismissPinSuggestion=" + DismissPinSuggestion,
                "StreamWindowLeft=" + StreamWindowLeft,
                "StreamWindowTop=" + StreamWindowTop,
                "StreamWindowWidth=" + StreamWindowWidth,
                "StreamWindowHeight=" + StreamWindowHeight,
                "StreamWindowDpi=" + StreamWindowDpi
            };
            WriteAllLinesAtomically(FilePath, lines);
        }

        internal void NormalizePersistedValues()
        {
            string pairing = NormalizeChoice(
                PairingMode, "none", "none", "pin");
            string pin = (FixedPin ?? "").Trim();
            if (pairing == "pin" && IsFourDigitAsciiPin(pin))
            {
                PairingMode = "pin";
                FixedPin = pin;
            }
            else
            {
                // Unknown and obsolete modes must be treated as unprotected.
                // The physical-network policy will then fail closed on a
                // Public or Unknown profile instead of launching an
                // unauthenticated receiver under a misleading mode name.
                PairingMode = "none";
                FixedPin = "";
            }

            QualityPreset = NormalizeChoice(
                QualityPreset, "1080p60",
                "720p30", "1080p30", "1080p60", "4k60");
            Renderer = NormalizeChoice(
                Renderer, "d3d11", "d3d11", "d3d12");
            LatencyProfile = NormalizeChoice(
                LatencyProfile, "balanced", "balanced", "low", "stable");
            AudioOutput = NormalizeChoice(
                AudioOutput, "default", "default", "mute");
            ThemeMode = NormalizeChoice(
                ThemeMode, "system", "system", "light", "dark");
            if (!HasValidStreamWindowPlacement())
                ClearStreamWindowPlacement();
        }

        internal bool HasValidStreamWindowPlacement()
        {
            return StreamWindowWidth >= 100 && StreamWindowWidth <= 32767 &&
                StreamWindowHeight >= 100 && StreamWindowHeight <= 32767 &&
                StreamWindowLeft >= -100000 && StreamWindowLeft <= 100000 &&
                StreamWindowTop >= -100000 && StreamWindowTop <= 100000 &&
                StreamWindowDpi >= 48 && StreamWindowDpi <= 768;
        }

        internal void ClearStreamWindowPlacement()
        {
            StreamWindowLeft = 0;
            StreamWindowTop = 0;
            StreamWindowWidth = 0;
            StreamWindowHeight = 0;
            StreamWindowDpi = 0;
        }

        private static string NormalizeChoice(
            string value, string fallback, params string[] allowed)
        {
            string normalized = (value ?? "").Trim().ToLowerInvariant();
            foreach (string candidate in allowed)
            {
                if (string.Equals(
                        normalized, candidate, StringComparison.Ordinal))
                    return candidate;
            }
            return fallback;
        }

        private static bool IsFourDigitAsciiPin(string value)
        {
            if (value == null || value.Length != 4)
                return false;
            foreach (char digit in value)
            {
                if (digit < '0' || digit > '9')
                    return false;
            }
            return true;
        }

        private static void WriteAllLinesAtomically(
            string path, string[] lines)
        {
            string fullPath = Path.GetFullPath(path);
            string directory = Path.GetDirectoryName(fullPath);
            Directory.CreateDirectory(directory);
            string temporaryPath = Path.Combine(
                directory,
                "." + Path.GetFileName(fullPath) + "." +
                Guid.NewGuid().ToString("N") + ".tmp");
            try
            {
                File.WriteAllLines(
                    temporaryPath, lines, new UTF8Encoding(false));
                if (File.Exists(fullPath))
                    File.Replace(temporaryPath, fullPath, null, true);
                else
                    File.Move(temporaryPath, fullPath);
            }
            finally
            {
                try
                {
                    if (File.Exists(temporaryPath))
                        File.Delete(temporaryPath);
                }
                catch { }
            }
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
}
