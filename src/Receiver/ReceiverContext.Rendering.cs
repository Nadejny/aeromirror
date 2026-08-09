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
    }
}
