using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("AeroMirror Setup")]
[assembly: AssemblyProduct("AeroMirror")]
[assembly: AssemblyCompany("AeroMirror open-source project")]
[assembly: AssemblyVersion("0.10.0.0")]
[assembly: AssemblyFileVersion("0.10.0.0")]

namespace AirPlayReceiverSetup
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            if (!Environment.Is64BitOperatingSystem)
            {
                MessageBox.Show(
                    "AeroMirror поддерживает только 64-разрядные версии Windows 10 и 11.",
                    "AeroMirror",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }
            if (args.Length > 0 &&
                string.Equals(
                    args[0], "/verify-runtime",
                    StringComparison.OrdinalIgnoreCase))
            {
                SetupLog.Write("Runtime verification started.");
                try
                {
                    InstallerOperations.VerifyRuntimePayload();
                    SetupLog.Write("Runtime verification completed successfully.");
                }
                catch (Exception ex)
                {
                    SetupLog.Write("Runtime verification failed: " + ex);
                    Environment.ExitCode = 2;
                }
                return;
            }
            if (args.Length > 0 &&
                string.Equals(
                    args[0], "/install-silent",
                    StringComparison.OrdinalIgnoreCase))
            {
                try
                {
                    bool keepStartMenu =
                        File.Exists(InstallPaths.StartMenuShortcut);
                    bool keepDesktop =
                        File.Exists(InstallPaths.DesktopShortcut);
                    SetupLog.Write("Silent installation started.");
                    InstallerOperations.Install(keepStartMenu, keepDesktop);
                    SetupLog.Write("Silent installation completed successfully.");
                }
                catch (Exception ex)
                {
                    SetupLog.Write("Silent installation failed: " + ex);
                    Environment.ExitCode = 2;
                }
                return;
            }
            foreach (string arg in args)
            {
                if (string.Equals(
                    arg, "/delete-source",
                    StringComparison.OrdinalIgnoreCase))
                {
                    MoveFileEx(
                        Assembly.GetExecutingAssembly().Location,
                        null,
                        MoveFileFlags.DelayUntilReboot);
                    break;
                }
            }

            if (args.Length > 0 &&
                string.Equals(args[0], "/uninstall-worker", StringComparison.OrdinalIgnoreCase))
            {
                UninstallWorker(args);
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            if (args.Length > 0 &&
                string.Equals(args[0], "/uninstall", StringComparison.OrdinalIgnoreCase))
            {
                BeginUninstall();
                return;
            }

            Application.Run(new SetupForm());
        }

        private static void BeginUninstall()
        {
            DialogResult answer = MessageBox.Show(
                "Удалить AeroMirror с этого компьютера?\r\n\r\n" +
                "Настройки и журнал пользователя будут сохранены.",
                "Удаление AeroMirror",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (answer != DialogResult.Yes)
                return;

            string temporary = Path.Combine(
                Path.GetTempPath(),
                "AeroMirror-uninstall-" + Guid.NewGuid().ToString("N") + ".exe");
            try
            {
                File.Copy(Assembly.GetExecutingAssembly().Location, temporary, true);
                var start = new ProcessStartInfo();
                start.FileName = temporary;
                start.Arguments = "/uninstall-worker " +
                    Quote(InstallPaths.InstallDirectory) + " " +
                    Process.GetCurrentProcess().Id;
                start.UseShellExecute = false;
                Process.Start(start);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Не удалось запустить удаление.\r\n\r\n" + ex.Message,
                    "AeroMirror",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        private static void UninstallWorker(string[] args)
        {
            if (args.Length < 3)
                return;

            string installDirectory = Path.GetFullPath(args[1]);
            string expected = Path.GetFullPath(InstallPaths.InstallDirectory);
            if (!string.Equals(
                installDirectory.TrimEnd('\\'),
                expected.TrimEnd('\\'),
                StringComparison.OrdinalIgnoreCase))
                return;

            int parentPid;
            if (int.TryParse(args[2], out parentPid))
            {
                try
                {
                    using (Process parent = Process.GetProcessById(parentPid))
                        parent.WaitForExit(10000);
                }
                catch { }
            }

            try
            {
                InstallerOperations.StopInstalledProcesses(installDirectory);
                InstallerOperations.RemoveShortcuts();
                InstallerOperations.RemoveRegistryEntries(installDirectory);
                InstallerOperations.RemoveRuntimeCache();
                if (Directory.Exists(installDirectory))
                    Directory.Delete(installDirectory, true);
                MessageBox.Show(
                    "AeroMirror удалён. Пользовательские настройки сохранены.",
                    "AeroMirror",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Не удалось полностью удалить приложение.\r\n\r\n" + ex.Message,
                    "AeroMirror",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
            finally
            {
                MoveFileEx(
                    Assembly.GetExecutingAssembly().Location,
                    null,
                    MoveFileFlags.DelayUntilReboot);
            }
        }

        private static string Quote(string value)
        {
            return "\"" + value.Replace("\"", "\\\"") + "\"";
        }

        [Flags]
        private enum MoveFileFlags
        {
            DelayUntilReboot = 0x4
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool MoveFileEx(
            string existingFile,
            string newFile,
            MoveFileFlags flags);
    }

    internal static class SetupLog
    {
        private static readonly object Sync = new object();

        internal static readonly string Path = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AirPlayReceiverMvp",
            "setup.log");

        internal static void Write(string message)
        {
            try
            {
                lock (Sync)
                {
                    Directory.CreateDirectory(System.IO.Path.GetDirectoryName(Path));
                    if (File.Exists(Path) &&
                        new FileInfo(Path).Length > 1024 * 1024)
                    {
                        string previous = Path + ".1";
                        if (File.Exists(previous))
                            File.Delete(previous);
                        File.Move(Path, previous);
                    }
                    File.AppendAllText(
                        Path,
                        DateTime.UtcNow.ToString("o") + "  " + message +
                        Environment.NewLine,
                        new UTF8Encoding(false));
                }
            }
            catch
            {
            }
        }
    }

    internal sealed class SetupForm : Form
    {
        private static readonly Version SetupVersion = new Version(0, 10, 0);
        private readonly CheckBox startMenu;
        private readonly CheckBox desktop;
        private readonly CheckBox launch;
        private readonly Button install;
        private readonly ProgressBar progress;
        private readonly Label state;
        private readonly Version installedVersion;

        public SetupForm()
        {
            installedVersion = InstallerOperations.GetInstalledVersion();
            Text = "Установка AeroMirror";
            Icon = Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            ClientSize = new Size(560, 420);
            BackColor = Color.FromArgb(250, 250, 250);
            Font = new Font("Segoe UI", 9F);

            var header = new Panel();
            header.Dock = DockStyle.Top;
            header.Height = 102;
            header.BackColor = Color.White;
            Controls.Add(header);

            var title = new Label();
            title.Text = "AeroMirror";
            title.Font = new Font("Segoe UI Semibold", 20F);
            title.AutoSize = true;
            title.Location = new Point(28, 20);
            header.Controls.Add(title);

            var subtitle = new Label();
            subtitle.Text = installedVersion == null
                ? "Установка для текущего пользователя · без прав администратора"
                : installedVersion.CompareTo(SetupVersion) < 0
                ? "Обновление " + installedVersion.ToString(3) +
                    " → " + SetupVersion.ToString(3) +
                    " · настройки сохранятся"
                : installedVersion.CompareTo(SetupVersion) == 0
                ? "Переустановка версии " + SetupVersion.ToString(3) +
                    " · настройки сохранятся"
                : "Установлена более новая версия " +
                    installedVersion.ToString(3);
            subtitle.AutoSize = true;
            subtitle.ForeColor = Color.DimGray;
            subtitle.Location = new Point(31, 62);
            header.Controls.Add(subtitle);

            var pathTitle = MakeLabel("Приложение будет установлено в:", 28, 126);
            Controls.Add(pathTitle);

            var path = new TextBox();
            path.Text = InstallPaths.InstallDirectory;
            path.ReadOnly = true;
            path.BackColor = Color.White;
            path.Location = new Point(28, 150);
            path.Size = new Size(504, 27);
            Controls.Add(path);

            var runtimeNotice = MakeLabel(
                "Review-установщик скачает неизменённый runtime uxplay-windows " +
                "(около 110 МБ) с GitHub и проверит его SHA-256.",
                28, 184);
            runtimeNotice.AutoSize = false;
            runtimeNotice.Size = new Size(504, 34);
            runtimeNotice.ForeColor = Color.DimGray;
            Controls.Add(runtimeNotice);

            startMenu = MakeCheckBox("Добавить ярлык в меню «Пуск»", 28, 224, true);
            desktop = MakeCheckBox("Добавить ярлык на рабочий стол", 28, 255, false);
            launch = MakeCheckBox("Запустить AeroMirror после установки", 28, 286, true);
            Controls.Add(startMenu);
            Controls.Add(desktop);
            Controls.Add(launch);

            state = MakeLabel("", 28, 326);
            state.ForeColor = Color.FromArgb(42, 122, 74);
            Controls.Add(state);

            progress = new ProgressBar();
            progress.Location = new Point(28, 362);
            progress.Size = new Size(340, 25);
            progress.Style = ProgressBarStyle.Marquee;
            progress.MarqueeAnimationSpeed = 25;
            progress.Visible = false;
            Controls.Add(progress);

            install = new Button();
            install.Text = installedVersion == null
                ? "Установить"
                : installedVersion.CompareTo(SetupVersion) < 0
                ? "Обновить"
                : "Переустановить";
            install.Size = new Size(150, 40);
            install.Location = new Point(382, 354);
            install.BackColor = Color.FromArgb(0, 95, 184);
            install.ForeColor = Color.White;
            install.FlatStyle = FlatStyle.Flat;
            install.FlatAppearance.BorderSize = 0;
            install.Click += OnInstall;
            Controls.Add(install);
        }

        private void OnInstall(object sender, EventArgs e)
        {
            if (installedVersion != null &&
                installedVersion.CompareTo(SetupVersion) > 0)
            {
                DialogResult answer = MessageBox.Show(
                    this,
                    "На компьютере установлена более новая версия " +
                    installedVersion.ToString(3) +
                    ".\r\n\r\nУстановить более старую версию " +
                    SetupVersion.ToString(3) + "?",
                    "AeroMirror",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Warning);
                if (answer != DialogResult.Yes)
                    return;
            }

            install.Enabled = false;
            startMenu.Enabled = false;
            desktop.Enabled = false;
            launch.Enabled = false;
            progress.Visible = true;
            state.Text = "Скачиваем и устанавливаем проверенный runtime…";

            bool createStartMenu = startMenu.Checked;
            bool createDesktop = desktop.Checked;
            bool launchAfter = launch.Checked;
            ThreadPool.QueueUserWorkItem(delegate
            {
                SetupLog.Write("Interactive installation started.");
                try
                {
                    string executable = InstallerOperations.Install(
                        createStartMenu, createDesktop);
                    SetupLog.Write(
                        "Interactive installation completed successfully.");
                    BeginInvoke((MethodInvoker)delegate
                    {
                        progress.Visible = false;
                        if (launchAfter)
                        {
                            // Remove the setup window before the application
                            // appears, so the two windows never cover each other.
                            Hide();
                            try
                            {
                                Process.Start(new ProcessStartInfo(executable)
                                {
                                    UseShellExecute = true
                                });
                                Close();
                            }
                            catch (Exception launchError)
                            {
                                SetupLog.Write(
                                    "Launching AeroMirror after installation failed: " +
                                    launchError);
                                Show();
                                state.Text = "Приложение установлено, но не запущено.";
                                state.ForeColor = Color.FromArgb(160, 45, 45);
                                MessageBox.Show(
                                    this,
                                    launchError.Message,
                                    "AeroMirror",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Warning);
                            }
                            return;
                        }

                        state.Text = "Готово. Приложение установлено.";
                        install.Text = "Закрыть";
                        install.Enabled = true;
                        install.Click -= OnInstall;
                        install.Click += delegate { Close(); };
                    });
                }
                catch (Exception ex)
                {
                    SetupLog.Write("Interactive installation failed: " + ex);
                    BeginInvoke((MethodInvoker)delegate
                    {
                        progress.Visible = false;
                        state.Text = "Установка не завершена.";
                        state.ForeColor = Color.FromArgb(160, 45, 45);
                        install.Enabled = true;
                        startMenu.Enabled = true;
                        desktop.Enabled = true;
                        launch.Enabled = true;
                        MessageBox.Show(
                            this,
                            ex.Message,
                            "AeroMirror",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error);
                    });
                }
            });
        }

        private static Label MakeLabel(string text, int x, int y)
        {
            var label = new Label();
            label.Text = text;
            label.AutoSize = true;
            label.Location = new Point(x, y);
            return label;
        }

        private static CheckBox MakeCheckBox(
            string text, int x, int y, bool value)
        {
            var check = new CheckBox();
            check.Text = text;
            check.AutoSize = true;
            check.Location = new Point(x, y);
            check.Checked = value;
            return check;
        }
    }

    internal static class InstallPaths
    {
        internal static readonly string InstallDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Programs",
            "AirPlayReceiverMvp");

        internal static readonly string StartMenuShortcut = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "Microsoft",
            "Windows",
            "Start Menu",
            "Programs",
            "AeroMirror.lnk");

        internal static readonly string DesktopShortcut = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
            "AeroMirror.lnk");

        internal static readonly string LegacyStartMenuShortcut = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "Microsoft",
            "Windows",
            "Start Menu",
            "Programs",
            "AirPlay Receiver.lnk");

        internal static readonly string LegacyDesktopShortcut = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
            "AirPlay Receiver.lnk");
    }

    internal static class InstallerOperations
    {
        private const string PayloadResource = "AirPlayReceiverPayload";
        private const string UninstallerResource = "AirPlayReceiverUninstaller";
        private const string RuntimeUrl =
            "https://github.com/leapbtw/uxplay-windows/releases/download/" +
            "2.0.0.1736/uxplay-windows.zip";
        private const string RuntimeSha256 =
            "9D3A51C15FC9DB857351195E7EB7BBB21700D9AE25D936A54BCF8536B62CCA18";
        private const string RequiredQtBuildVersion = "6.10.1";
        private const string RequiredRuntimeRelease = "2.0.0.1736";
        private const string RequiredCoreRuntimeCompatibility =
            "uxplay-windows-2.0.0.1736";
        private static readonly string RuntimeCacheDirectory = Path.Combine(
            Environment.GetFolderPath(
                Environment.SpecialFolder.LocalApplicationData),
            "AirPlayReceiverMvp",
            "cache",
            "runtime");
        private static readonly string RuntimeCachePath = Path.Combine(
            RuntimeCacheDirectory,
            "sha256-" + RuntimeSha256.ToLowerInvariant() +
            "-uxplay-windows.zip");
        private const string UninstallKey =
            @"Software\Microsoft\Windows\CurrentVersion\Uninstall\AirPlayReceiverMvp";

        internal static Version GetInstalledVersion()
        {
            try
            {
                using (RegistryKey key =
                    Registry.CurrentUser.OpenSubKey(UninstallKey))
                {
                    string value = key == null
                        ? null : key.GetValue("DisplayVersion") as string;
                    Version version;
                    if (Version.TryParse(value, out version))
                        return version;
                }
            }
            catch { }

            try
            {
                string[] executableNames =
                {
                    "AeroMirror.exe",
                    "AirPlayReceiverMvp.exe"
                };
                foreach (string executableName in executableNames)
                {
                    string executable = Path.Combine(
                        InstallPaths.InstallDirectory, executableName);
                    if (File.Exists(executable))
                    {
                        string value = FileVersionInfo.GetVersionInfo(
                            executable).FileVersion;
                        Version version;
                        if (Version.TryParse(value, out version))
                            return version;
                    }
                }
            }
            catch { }
            return null;
        }

        internal static void VerifyRuntimePayload()
        {
            string staging = Path.Combine(
                Path.GetTempPath(),
                "AeroMirror-runtime-check-" + Guid.NewGuid().ToString("N"));
            string zipPath = Path.Combine(staging, "payload.zip");
            Directory.CreateDirectory(staging);
            try
            {
                using (Stream resource = Assembly.GetExecutingAssembly()
                    .GetManifestResourceStream(PayloadResource))
                {
                    if (resource == null)
                        throw new InvalidOperationException(
                            "В установщике не найден пакет приложения.");
                    using (var output = File.Create(zipPath))
                        resource.CopyTo(output);
                }
                string extracted = Path.Combine(staging, "extracted");
                ZipFile.ExtractToDirectory(zipPath, extracted);
                string source = Path.Combine(extracted, "AeroMirror");
                PreparePinnedRuntime(source, staging);
                string core = Path.Combine(source, "core");
                if (!File.Exists(Path.Combine(core, "Qt6Core.dll")) ||
                    !File.Exists(Path.Combine(core, "LICENSE.rtf")) ||
                    !File.Exists(Path.Combine(core, "uxplay-windows.exe")))
                {
                    throw new InvalidOperationException(
                        "Runtime payload verification failed.");
                }
            }
            finally
            {
                try
                {
                    if (Directory.Exists(staging))
                        Directory.Delete(staging, true);
                }
                catch { }
            }
        }

        internal static string Install(bool startMenu, bool desktop)
        {
            string staging = Path.Combine(
                Path.GetTempPath(),
                "AeroMirror-install-" + Guid.NewGuid().ToString("N"));
            string zipPath = Path.Combine(staging, "payload.zip");
            Directory.CreateDirectory(staging);

            try
            {
                using (Stream resource = Assembly.GetExecutingAssembly()
                    .GetManifestResourceStream(PayloadResource))
                {
                    if (resource == null)
                        throw new InvalidOperationException(
                            "В установщике не найден пакет приложения.");
                    using (var output = File.Create(zipPath))
                        resource.CopyTo(output);
                }

                string extracted = Path.Combine(staging, "extracted");
                ZipFile.ExtractToDirectory(zipPath, extracted);
                string source = Path.Combine(extracted, "AeroMirror");
                if (!File.Exists(Path.Combine(source, "AeroMirror.exe")))
                    throw new InvalidOperationException(
                        "Пакет приложения повреждён.");
                PreparePinnedRuntime(source, staging);

                string sourceUninstaller = Path.Combine(
                    source, "Uninstall.exe");
                using (Stream resource = Assembly.GetExecutingAssembly()
                    .GetManifestResourceStream(UninstallerResource))
                {
                    if (resource == null)
                        throw new InvalidOperationException(
                            "В установщике не найден модуль удаления.");
                    using (var output = File.Create(sourceUninstaller))
                        resource.CopyTo(output);
                }

                StopInstalledProcesses(InstallPaths.InstallDirectory);
                string backup = InstallPaths.InstallDirectory +
                    ".backup-" + Guid.NewGuid().ToString("N");
                Directory.CreateDirectory(
                    Path.GetDirectoryName(InstallPaths.InstallDirectory));
                if (Directory.Exists(InstallPaths.InstallDirectory))
                    Directory.Move(InstallPaths.InstallDirectory, backup);
                try
                {
                    MoveOrCopyDirectory(source, InstallPaths.InstallDirectory);

                    string uninstaller = Path.Combine(
                        InstallPaths.InstallDirectory, "Uninstall.exe");
                    RemoveShortcuts();
                    string executable = Path.Combine(
                        InstallPaths.InstallDirectory, "AeroMirror.exe");
                    if (startMenu)
                        CreateShortcut(InstallPaths.StartMenuShortcut, executable);
                    if (desktop)
                        CreateShortcut(InstallPaths.DesktopShortcut, executable);
                    WriteUninstallRegistry(executable, uninstaller);
                    MigrateAutostart(executable);
                    TryDeleteDirectory(backup);
                    return executable;
                }
                catch
                {
                    try
                    {
                        if (Directory.Exists(InstallPaths.InstallDirectory))
                            Directory.Delete(
                                InstallPaths.InstallDirectory, true);
                        if (Directory.Exists(backup))
                            Directory.Move(
                                backup, InstallPaths.InstallDirectory);
                    }
                    catch { }
                    throw;
                }
            }
            finally
            {
                try
                {
                    if (Directory.Exists(staging))
                        Directory.Delete(staging, true);
                }
                catch { }
            }
        }

        private static void PreparePinnedRuntime(string source, string staging)
        {
            string core = Path.Combine(source, "core");
            string delivery = Path.Combine(
                core, "resources", "runtime-delivery.json");
            if (!File.Exists(delivery))
                throw new InvalidOperationException(
                    "В review-пакете отсутствует описание загрузки runtime.");
            string manifest = Path.Combine(
                core, "resources", "build-manifest.json");
            ValidateReviewedManifest(manifest);

            string patchedCore = Path.Combine(staging, "headless-core.exe");
            string reviewedManifest = Path.Combine(
                staging, "aeromirror-headless-build.json");
            string deliveryCopy = Path.Combine(
                staging, "runtime-delivery.json");
            File.Copy(
                Path.Combine(core, "uxplay-windows.exe"),
                patchedCore,
                true);
            File.Copy(
                Path.Combine(core, "resources", "build-manifest.json"),
                reviewedManifest,
                true);
            File.Copy(delivery, deliveryCopy, true);

            ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
            string archive = Path.Combine(staging, "uxplay-windows.zip");
            AcquirePinnedRuntimeArchive(archive);
            string actualHash = ComputeSha256(archive);
            if (!string.Equals(
                    actualHash, RuntimeSha256,
                    StringComparison.OrdinalIgnoreCase))
            {
                File.Delete(archive);
                throw new InvalidOperationException(
                    "Проверка runtime не пройдена: SHA-256 не совпал. " +
                    "Установка остановлена без замены текущей версии.");
            }

            string extractedRuntime = Path.Combine(staging, "upstream-runtime");
            ZipFile.ExtractToDirectory(archive, extractedRuntime);
            string runtimeRoot = FindRuntimeRoot(extractedRuntime);
            if (runtimeRoot == null ||
                !File.Exists(Path.Combine(runtimeRoot, "LICENSE.rtf")))
            {
                throw new InvalidOperationException(
                    "Проверенный архив runtime имеет неизвестную структуру.");
            }

            string upstreamManifest = Path.Combine(
                runtimeRoot, "resources", "build-manifest.json");
            string upstreamManifestCopy = Path.Combine(
                staging, "upstream-build-manifest.json");
            if (File.Exists(upstreamManifest))
                File.Copy(upstreamManifest, upstreamManifestCopy, true);

            CopyDirectory(runtimeRoot, core);
            File.Copy(patchedCore, Path.Combine(core, "uxplay-windows.exe"), true);
            string resources = Path.Combine(core, "resources");
            Directory.CreateDirectory(resources);
            File.Copy(
                reviewedManifest,
                Path.Combine(resources, "build-manifest.json"),
                true);
            File.Copy(
                deliveryCopy,
                Path.Combine(resources, "runtime-delivery.json"),
                true);
            if (File.Exists(upstreamManifestCopy))
            {
                File.Copy(
                    upstreamManifestCopy,
                    Path.Combine(resources, "upstream-build-manifest.json"),
                    true);
            }

            if (!File.Exists(Path.Combine(core, "Qt6Core.dll")) ||
                !File.Exists(Path.Combine(core, "LICENSE.rtf")))
            {
                throw new InvalidOperationException(
                    "Runtime не прошёл проверку полноты после распаковки.");
            }
            VerifyCoreLoaderCompatibility(core);
        }

        private static void AcquirePinnedRuntimeArchive(string archive)
        {
            bool cacheHit = false;
            try
            {
                PruneRuntimeCache();
                if (File.Exists(RuntimeCachePath) &&
                    string.Equals(
                        ComputeSha256(RuntimeCachePath),
                        RuntimeSha256,
                        StringComparison.OrdinalIgnoreCase))
                {
                    File.Copy(RuntimeCachePath, archive, true);
                    cacheHit = string.Equals(
                        ComputeSha256(archive),
                        RuntimeSha256,
                        StringComparison.OrdinalIgnoreCase);
                    if (cacheHit)
                        SetupLog.Write(
                            "Verified pinned runtime cache reused.");
                }
                else if (File.Exists(RuntimeCachePath))
                {
                    SetupLog.Write(
                        "Pinned runtime cache was invalid and will be replaced.");
                    TryDeleteFile(RuntimeCachePath);
                }
            }
            catch (Exception ex)
            {
                SetupLog.Write(
                    "Pinned runtime cache could not be reused: " + ex.Message);
                TryDeleteFile(archive);
            }

            if (cacheHit)
                return;

            SetupLog.Write("Downloading pinned runtime.");
            using (var client = new PinnedDownloadClient())
            {
                client.Headers[HttpRequestHeader.UserAgent] =
                    "AeroMirror-Setup/0.10.0";
                client.DownloadFile(RuntimeUrl, archive);
            }
            if (!string.Equals(
                    ComputeSha256(archive),
                    RuntimeSha256,
                    StringComparison.OrdinalIgnoreCase))
            {
                TryDeleteFile(archive);
                throw new InvalidOperationException(
                    "Проверка runtime не пройдена: SHA-256 не совпал. " +
                    "Установка остановлена без замены текущей версии.");
            }
            TryStorePinnedRuntimeCache(archive);
        }

        private static void PruneRuntimeCache()
        {
            if (!Directory.Exists(RuntimeCacheDirectory))
                return;
            foreach (string candidate in Directory.GetFiles(
                RuntimeCacheDirectory))
            {
                if (!string.Equals(
                        candidate,
                        RuntimeCachePath,
                        StringComparison.OrdinalIgnoreCase))
                    TryDeleteFile(candidate);
            }
        }

        private static void TryStorePinnedRuntimeCache(string archive)
        {
            string temporary = "";
            try
            {
                Directory.CreateDirectory(RuntimeCacheDirectory);
                temporary = Path.Combine(
                    RuntimeCacheDirectory,
                    "." + Guid.NewGuid().ToString("N") + ".partial");
                File.Copy(archive, temporary, true);
                if (!string.Equals(
                        ComputeSha256(temporary),
                        RuntimeSha256,
                        StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException(
                        "Runtime cache copy failed SHA-256 verification.");

                if (File.Exists(RuntimeCachePath))
                {
                    if (string.Equals(
                            ComputeSha256(RuntimeCachePath),
                            RuntimeSha256,
                            StringComparison.OrdinalIgnoreCase))
                    {
                        TryDeleteFile(temporary);
                        return;
                    }
                    TryDeleteFile(RuntimeCachePath);
                }
                File.Move(temporary, RuntimeCachePath);
                temporary = "";
                SetupLog.Write("Verified pinned runtime stored in cache.");
            }
            catch (Exception ex)
            {
                SetupLog.Write(
                    "Pinned runtime cache could not be stored: " + ex.Message);
            }
            finally
            {
                if (!string.IsNullOrWhiteSpace(temporary))
                    TryDeleteFile(temporary);
            }
        }

        private static void ValidateReviewedManifest(string path)
        {
            if (!File.Exists(path))
                throw new InvalidOperationException(
                    "В review-пакете отсутствует manifest headless core.");

            Dictionary<string, object> manifest;
            try
            {
                var serializer = new JavaScriptSerializer();
                manifest = serializer.DeserializeObject(File.ReadAllText(path))
                    as Dictionary<string, object>;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "Manifest headless core повреждён.", ex);
            }

            if (manifest == null ||
                !ManifestValueEquals(
                    manifest, "qtBuildVersion", RequiredQtBuildVersion) ||
                !ManifestValueEquals(
                    manifest, "pinnedRuntimeRelease", RequiredRuntimeRelease) ||
                !ManifestValueEquals(
                    manifest,
                    "coreRuntimeCompatibility",
                    RequiredCoreRuntimeCompatibility))
            {
                throw new InvalidOperationException(
                    "Headless core не совместим с закреплённым runtime " +
                    RequiredRuntimeRelease + ".");
            }
        }

        private static bool ManifestValueEquals(
            Dictionary<string, object> manifest,
            string name,
            string expected)
        {
            object value;
            return manifest.TryGetValue(name, out value) &&
                string.Equals(
                    value as string,
                    expected,
                    StringComparison.Ordinal);
        }

        private static void VerifyCoreLoaderCompatibility(string core)
        {
            string executable = Path.Combine(core, "uxplay-windows.exe");
            var start = new ProcessStartInfo();
            start.FileName = executable;
            start.Arguments = "--loader-test";
            start.WorkingDirectory = core;
            start.UseShellExecute = false;
            start.CreateNoWindow = true;
            start.WindowStyle = ProcessWindowStyle.Hidden;

            try
            {
                using (Process process = Process.Start(start))
                {
                    if (process == null)
                        throw new InvalidOperationException(
                            "Не удалось запустить проверку совместимости core.");
                    if (!process.WaitForExit(15000))
                    {
                        try
                        {
                            process.Kill();
                            process.WaitForExit(5000);
                        }
                        catch { }
                        throw new TimeoutException(
                            "Проверка совместимости core не завершилась за 15 секунд.");
                    }

                    int exitCode = process.ExitCode;
                    if (exitCode != 0)
                    {
                        string code = "0x" +
                            unchecked((uint)exitCode).ToString("X8");
                        if (exitCode == unchecked((int)0xC0000139))
                        {
                            throw new InvalidOperationException(
                                "Core несовместим с runtime: отсутствует " +
                                "требуемая точка входа (" + code + ").");
                        }
                        throw new InvalidOperationException(
                            "Проверка совместимости core завершилась с кодом " +
                            code + ".");
                    }
                }
            }
            catch (TimeoutException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "Не удалось проверить совместимость core с runtime.", ex);
            }
        }

        private static string FindRuntimeRoot(string extracted)
        {
            string direct = Path.Combine(extracted, "uxplay-windows.exe");
            if (File.Exists(direct))
                return extracted;
            foreach (string candidate in Directory.GetFiles(
                extracted, "uxplay-windows.exe", SearchOption.AllDirectories))
            {
                return Path.GetDirectoryName(candidate);
            }
            return null;
        }

        private static string ComputeSha256(string path)
        {
            using (var algorithm = SHA256.Create())
            using (var stream = File.OpenRead(path))
            {
                byte[] hash = algorithm.ComputeHash(stream);
                var text = new StringBuilder(hash.Length * 2);
                foreach (byte value in hash)
                    text.Append(value.ToString("x2"));
                return text.ToString();
            }
        }

        internal static void StopInstalledProcesses(string installDirectory)
        {
            string[] names =
            {
                "AeroMirror",
                "AirPlayReceiverMvp",
                "uxplay-windows",
                "uxplay-bluetooth-beacon"
            };
            string prefix = Path.GetFullPath(installDirectory).TrimEnd('\\') + "\\";
            DateTime deadline = DateTime.UtcNow.AddSeconds(8);
            while (true)
            {
                bool foundInstalledProcess = false;
                foreach (string name in names)
                {
                    foreach (Process process in Process.GetProcessesByName(name))
                    {
                        using (process)
                        {
                            try
                            {
                                string path = process.MainModule.FileName;
                                if (!path.StartsWith(
                                    prefix, StringComparison.OrdinalIgnoreCase))
                                    continue;
                                foundInstalledProcess = true;
                                bool exited = process.HasExited;
                                if (!exited && process.CloseMainWindow())
                                    exited = process.WaitForExit(1500);
                                if (!exited)
                                {
                                    process.Kill();
                                    exited = process.WaitForExit(5000);
                                }
                                if (!exited)
                                    throw new IOException(
                                        "Не удалось остановить процесс " +
                                        process.ProcessName + ".");
                                process.WaitForExit();
                            }
                            catch (InvalidOperationException)
                            {
                                // The process exited between enumeration and
                                // inspection.
                            }
                        }
                    }
                }
                if (!foundInstalledProcess)
                    return;
                if (DateTime.UtcNow >= deadline)
                    throw new IOException(
                        "Не удалось дождаться завершения процессов AeroMirror.");
                Thread.Sleep(150);
            }
        }

        internal static void RemoveShortcuts()
        {
            TryDeleteFile(InstallPaths.StartMenuShortcut);
            TryDeleteFile(InstallPaths.DesktopShortcut);
            TryDeleteFile(InstallPaths.LegacyStartMenuShortcut);
            TryDeleteFile(InstallPaths.LegacyDesktopShortcut);
        }

        internal static void RemoveRegistryEntries(string installDirectory)
        {
            try
            {
                Registry.CurrentUser.DeleteSubKeyTree(UninstallKey, false);
            }
            catch { }

            try
            {
                using (RegistryKey run = Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Run", true))
                {
                    if (run != null)
                    {
                        string[] valueNames =
                        {
                            "AeroMirror",
                            "AirPlayReceiverMvp"
                        };
                        foreach (string valueName in valueNames)
                        {
                            string value = run.GetValue(valueName) as string;
                            if (!string.IsNullOrWhiteSpace(value) &&
                                value.IndexOf(
                                    installDirectory,
                                    StringComparison.OrdinalIgnoreCase) >= 0)
                                run.DeleteValue(valueName, false);
                        }
                    }
                }
            }
            catch { }
        }

        internal static void RemoveRuntimeCache()
        {
            TryDeleteDirectory(RuntimeCacheDirectory);
            if (Directory.Exists(RuntimeCacheDirectory))
                SetupLog.Write(
                    "Runtime cache could not be fully removed during uninstall.");
        }

        private static void WriteUninstallRegistry(
            string executable, string uninstaller)
        {
            using (RegistryKey key = Registry.CurrentUser.CreateSubKey(UninstallKey))
            {
                key.SetValue("DisplayName", "AeroMirror");
                key.SetValue("DisplayVersion", "0.10.0");
                key.SetValue("Publisher", "AeroMirror open-source project");
                key.SetValue("InstallLocation", InstallPaths.InstallDirectory);
                key.SetValue("DisplayIcon", executable);
                key.SetValue("UninstallString",
                    "\"" + uninstaller + "\" /uninstall");
                key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
                long bytes = DirectorySize(InstallPaths.InstallDirectory);
                key.SetValue("EstimatedSize",
                    (int)Math.Min(int.MaxValue, Math.Max(1, bytes / 1024)),
                    RegistryValueKind.DWord);
            }
        }

        private static void MigrateAutostart(string executable)
        {
            try
            {
                using (RegistryKey run = Registry.CurrentUser.CreateSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Run"))
                {
                    bool enabled =
                        run.GetValue("AeroMirror") != null ||
                        run.GetValue("AirPlayReceiverMvp") != null;
                    if (enabled)
                    {
                        run.SetValue(
                            "AeroMirror",
                            "\"" + executable + "\" --startup",
                            RegistryValueKind.String);
                    }
                    run.DeleteValue("AirPlayReceiverMvp", false);
                }
            }
            catch { }
        }

        private static void CreateShortcut(string shortcutPath, string target)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(shortcutPath));
            Type shellType = Type.GetTypeFromProgID("WScript.Shell");
            if (shellType == null)
                throw new InvalidOperationException(
                    "Windows Script Host недоступен для создания ярлыка.");
            object shell = Activator.CreateInstance(shellType);
            object shortcut = null;
            try
            {
                shortcut = shellType.InvokeMember(
                    "CreateShortcut",
                    BindingFlags.InvokeMethod,
                    null,
                    shell,
                    new object[] { shortcutPath });
                Type shortcutType = shortcut.GetType();
                shortcutType.InvokeMember(
                    "TargetPath",
                    BindingFlags.SetProperty,
                    null,
                    shortcut,
                    new object[] { target });
                shortcutType.InvokeMember(
                    "WorkingDirectory",
                    BindingFlags.SetProperty,
                    null,
                    shortcut,
                    new object[] { Path.GetDirectoryName(target) });
                shortcutType.InvokeMember(
                    "IconLocation",
                    BindingFlags.SetProperty,
                    null,
                    shortcut,
                    new object[] { target + ",0" });
                shortcutType.InvokeMember(
                    "Save",
                    BindingFlags.InvokeMethod,
                    null,
                    shortcut,
                    null);
            }
            finally
            {
                if (shortcut != null && Marshal.IsComObject(shortcut))
                    Marshal.FinalReleaseComObject(shortcut);
                if (shell != null && Marshal.IsComObject(shell))
                    Marshal.FinalReleaseComObject(shell);
            }
        }

        private static void MoveOrCopyDirectory(string source, string destination)
        {
            try
            {
                Directory.Move(source, destination);
            }
            catch (IOException)
            {
                CopyDirectory(source, destination);
            }
        }

        private static void CopyDirectory(string source, string destination)
        {
            Directory.CreateDirectory(destination);
            foreach (string file in Directory.GetFiles(source))
                File.Copy(file, Path.Combine(destination, Path.GetFileName(file)), true);
            foreach (string directory in Directory.GetDirectories(source))
                CopyDirectory(
                    directory,
                    Path.Combine(destination, Path.GetFileName(directory)));
        }

        private static long DirectorySize(string path)
        {
            long total = 0;
            foreach (string file in Directory.GetFiles(
                path, "*", SearchOption.AllDirectories))
            {
                try { total += new FileInfo(file).Length; }
                catch { }
            }
            return total;
        }

        private static void TryDeleteFile(string path)
        {
            try
            {
                if (File.Exists(path))
                    File.Delete(path);
            }
            catch { }
        }

        private static void TryDeleteDirectory(string path)
        {
            try
            {
                if (Directory.Exists(path))
                    Directory.Delete(path, true);
            }
            catch { }
        }
    }

    internal sealed class PinnedDownloadClient : WebClient
    {
        protected override WebRequest GetWebRequest(Uri address)
        {
            WebRequest request = base.GetWebRequest(address);
            request.Timeout = 300000;
            HttpWebRequest http = request as HttpWebRequest;
            if (http != null)
            {
                http.ReadWriteTimeout = 300000;
                http.AllowAutoRedirect = true;
            }
            return request;
        }
    }
}
