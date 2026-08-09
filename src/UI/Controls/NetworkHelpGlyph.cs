using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Windows.Forms;

namespace AirPlayReceiverMvp
{
    internal sealed class NetworkHelpGlyph : Control
    {
        internal NetworkHelpGlyph()
        {
            SetStyle(
                ControlStyles.AllPaintingInWmPaint |
                ControlStyles.OptimizedDoubleBuffer |
                ControlStyles.ResizeRedraw |
                ControlStyles.SupportsTransparentBackColor |
                ControlStyles.UserPaint,
                true);
            BackColor = Color.Transparent;
            Font = new Font("Segoe UI Semibold", 9F);
            Size = new Size(24, 24);
            Text = "?";
            Cursor = Cursors.Help;
            TabStop = false;
            AccessibleRole = AccessibleRole.HelpBalloon;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);

            float dpiScale = Math.Max(1F, e.Graphics.DpiX / 96F);
            float strokeWidth = Math.Max(1F, dpiScale);
            float inset = strokeWidth / 2F + dpiScale;
            float diameter = Math.Min(ClientSize.Width, ClientSize.Height) -
                inset * 2F;
            if (diameter <= 0F)
                return;

            var circle = new RectangleF(
                (ClientSize.Width - diameter) / 2F,
                (ClientSize.Height - diameter) / 2F,
                diameter,
                diameter);

            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            e.Graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            using (var pen = new Pen(ForeColor, strokeWidth))
                e.Graphics.DrawEllipse(pen, circle);

            e.Graphics.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            using (var brush = new SolidBrush(ForeColor))
            using (var format = new StringFormat(StringFormat.GenericTypographic))
            {
                format.Alignment = StringAlignment.Center;
                format.LineAlignment = StringAlignment.Center;
                format.FormatFlags = StringFormatFlags.NoWrap;
                e.Graphics.DrawString(
                    Text,
                    Font,
                    brush,
                    new RectangleF(
                        0F,
                        0F,
                        ClientSize.Width,
                        ClientSize.Height),
                    format);
            }
        }

        protected override void OnForeColorChanged(EventArgs e)
        {
            base.OnForeColorChanged(e);
            Invalidate();
        }

        protected override void OnFontChanged(EventArgs e)
        {
            base.OnFontChanged(e);
            Invalidate();
        }

        protected override void OnTextChanged(EventArgs e)
        {
            base.OnTextChanged(e);
            Invalidate();
        }
    }
}
