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
}
