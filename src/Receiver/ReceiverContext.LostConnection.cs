using System;
using System.Drawing;
using System.Threading;
using System.Windows.Forms;

namespace AirPlayReceiverMvp
{
    internal sealed partial class ReceiverContext
    {
        private enum LostConnectionPlaceholderAction
        {
            None,
            Show,
            Close
        }

        private int lostConnectionPlaceholderShowPending;
        private int lostConnectionPlaceholderClosePending;
        private Rectangle lastRendererBounds = Rectangle.Empty;
        private LostConnectionForm lostConnectionForm;

        private void QueueLostConnectionPlaceholder()
        {
            Interlocked.Exchange(ref lostConnectionPlaceholderClosePending, 0);
            Interlocked.Exchange(ref lostConnectionPlaceholderShowPending, 1);
        }

        private void QueueLostConnectionPlaceholderClose()
        {
            Interlocked.Exchange(ref lostConnectionPlaceholderShowPending, 0);
            Interlocked.Exchange(ref lostConnectionPlaceholderClosePending, 1);
        }

        private void RememberRendererBounds(IntPtr window)
        {
            NativeMethods.RECT nativeBounds;
            if (window == IntPtr.Zero ||
                !NativeMethods.GetWindowRect(window, out nativeBounds))
                return;

            int width = nativeBounds.Right - nativeBounds.Left;
            int height = nativeBounds.Bottom - nativeBounds.Top;
            if (width <= 0 || height <= 0)
                return;
            lastRendererBounds = new Rectangle(
                nativeBounds.Left, nativeBounds.Top, width, height);
        }

        private void HandleLostConnectionPlaceholder()
        {
            bool closeRequested = Interlocked.Exchange(
                ref lostConnectionPlaceholderClosePending, 0) == 1;
            bool showRequested = Interlocked.Exchange(
                ref lostConnectionPlaceholderShowPending, 0) == 1;
            if (Interlocked.Exchange(
                    ref lostConnectionPlaceholderClosePending, 0) == 1)
                closeRequested = true;

            bool visible = lostConnectionForm != null &&
                !lostConnectionForm.IsDisposed;
            LostConnectionPlaceholderAction action =
                DecideLostConnectionPlaceholderAction(
                    showRequested, closeRequested, visible);
            if (action == LostConnectionPlaceholderAction.Close)
            {
                CloseLostConnectionPlaceholder();
                return;
            }
            if (action != LostConnectionPlaceholderAction.Show || quitting)
                return;

            IntPtr rendererWindow;
            if (TryGetRendererWindow(out rendererWindow))
                RememberRendererBounds(rendererWindow);
            else
                rendererWindow = IntPtr.Zero;

            Rectangle rendererBounds = lastRendererBounds;
            Rectangle bounds = ResolveLostConnectionPlaceholderBounds(
                rendererBounds);
            Bitmap snapshot = TryCaptureRendererSnapshot(
                rendererWindow, rendererBounds);
            try
            {
                if (quitting || Interlocked.Exchange(
                        ref lostConnectionPlaceholderClosePending, 0) == 1)
                    return;
                var placeholder = new LostConnectionForm(bounds, snapshot);
                snapshot = null;
                placeholder.ShowInTaskbar = settings.ShowStreamInTaskbar;
                placeholder.TopMost = settings.AlwaysOnTop;
                placeholder.FormClosed += delegate
                {
                    if (ReferenceEquals(lostConnectionForm, placeholder))
                    {
                        lostConnectionForm = null;
                        Log("Lost-connection placeholder was closed.");
                    }
                };
                lostConnectionForm = placeholder;
                placeholder.Show();
                Log("Lost-connection placeholder opened at the last renderer " +
                    "bounds; waiting for a new mirroring start.");
            }
            finally
            {
                if (snapshot != null)
                    snapshot.Dispose();
            }
        }

        private static LostConnectionPlaceholderAction
            DecideLostConnectionPlaceholderAction(
                bool showRequested, bool closeRequested, bool visible)
        {
            if (closeRequested)
                return LostConnectionPlaceholderAction.Close;
            if (showRequested && !visible)
                return LostConnectionPlaceholderAction.Show;
            return LostConnectionPlaceholderAction.None;
        }

        private static Rectangle ResolveLostConnectionPlaceholderBounds(
            Rectangle rememberedBounds)
        {
            if (rememberedBounds.Width > 0 && rememberedBounds.Height > 0)
            {
                Rectangle rememberedWorkArea = Screen.FromRectangle(
                    rememberedBounds).WorkingArea;
                return ClampLostConnectionPlaceholderBounds(
                    rememberedBounds, rememberedWorkArea);
            }

            Rectangle workArea = Screen.PrimaryScreen == null
                ? SystemInformation.WorkingArea
                : Screen.PrimaryScreen.WorkingArea;
            int height = Math.Min(760, Math.Max(360,
                (int)Math.Round(workArea.Height * 0.78)));
            int width = Math.Min(520, Math.Max(320,
                (int)Math.Round(height * ProvisionalIPhoneAspect) + 32));
            Rectangle fallback = new Rectangle(
                workArea.Left + (workArea.Width - width) / 2,
                workArea.Top + (workArea.Height - height) / 2,
                width,
                height);
            return ClampLostConnectionPlaceholderBounds(
                fallback, workArea);
        }

        private static Rectangle ClampLostConnectionPlaceholderBounds(
            Rectangle desiredBounds, Rectangle workArea)
        {
            if (workArea.Width <= 0 || workArea.Height <= 0)
                return desiredBounds;

            int width = Math.Min(
                Math.Max(1, desiredBounds.Width), workArea.Width);
            int height = Math.Min(
                Math.Max(1, desiredBounds.Height), workArea.Height);
            int x = Math.Max(
                workArea.Left,
                Math.Min(desiredBounds.Left, workArea.Right - width));
            int y = Math.Max(
                workArea.Top,
                Math.Min(desiredBounds.Top, workArea.Bottom - height));
            return new Rectangle(x, y, width, height);
        }

        private static Bitmap TryCaptureRendererSnapshot(
            IntPtr rendererWindow, Rectangle bounds)
        {
            if (rendererWindow == IntPtr.Zero ||
                !NativeMethods.IsWindow(rendererWindow) ||
                bounds.Width <= 0 || bounds.Height <= 0 ||
                bounds.Width > 8192 || bounds.Height > 8192)
                return null;

            Bitmap snapshot = null;
            try
            {
                Rectangle virtualScreen = SystemInformation.VirtualScreen;
                bool fullyOnScreen = Rectangle.Intersect(
                    virtualScreen, bounds) == bounds;
                if (NativeMethods.IsWindowVisible(rendererWindow) &&
                    NativeMethods.GetForegroundWindow() == rendererWindow &&
                    fullyOnScreen)
                {
                    snapshot = new Bitmap(bounds.Width, bounds.Height);
                    using (Graphics graphics = Graphics.FromImage(snapshot))
                    {
                        graphics.CopyFromScreen(
                            bounds.Left, bounds.Top, 0, 0, bounds.Size,
                            CopyPixelOperation.SourceCopy);
                    }
                    Log("Renderer snapshot is available from the desktop " +
                        "compositor for the lost-connection placeholder.");
                    return snapshot;
                }

                Log("Renderer snapshot is unavailable or the renderer is " +
                    "not in the foreground; the lost-connection placeholder " +
                    "will use a dark fallback.");
                return null;
            }
            catch
            {
                if (snapshot != null)
                    snapshot.Dispose();
                Log("Renderer snapshot is unavailable; the lost-connection " +
                    "placeholder will use a dark fallback.");
                return null;
            }
        }

        private void CloseLostConnectionPlaceholder()
        {
            Interlocked.Exchange(ref lostConnectionPlaceholderShowPending, 0);
            Interlocked.Exchange(ref lostConnectionPlaceholderClosePending, 0);
            LostConnectionForm placeholder = lostConnectionForm;
            lostConnectionForm = null;
            if (placeholder == null)
                return;
            try
            {
                if (!placeholder.IsDisposed)
                    placeholder.Close();
            }
            catch { }
            finally
            {
                placeholder.Dispose();
            }
        }

        private void ApplyLostConnectionPlaceholderPolicy()
        {
            LostConnectionForm placeholder = lostConnectionForm;
            if (placeholder == null || placeholder.IsDisposed)
                return;
            placeholder.TopMost = settings.AlwaysOnTop;
            placeholder.ShowInTaskbar = settings.ShowStreamInTaskbar;
        }
    }
}
