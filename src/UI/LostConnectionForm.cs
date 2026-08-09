using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace AirPlayReceiverMvp
{
    internal sealed class LostConnectionForm : Form
    {
        private Bitmap snapshot;
        private readonly Label titleLabel;
        private readonly Label detailLabel;
        private readonly Button closeButton;
        private readonly Font titleFont;
        private readonly Font detailFont;
        private readonly Font buttonFont;

        internal LostConnectionForm(Rectangle bounds, Bitmap snapshot)
        {
            this.snapshot = CreateSoftenedSnapshot(snapshot);
            Text = "iPhone · AeroMirror";
            StartPosition = FormStartPosition.Manual;
            Bounds = bounds;
            MinimumSize = new Size(280, 240);
            BackColor = Color.FromArgb(18, 21, 27);
            ForeColor = Color.White;
            DoubleBuffered = true;

            titleLabel = new Label();
            titleLabel.AutoSize = false;
            titleLabel.BackColor = Color.Transparent;
            titleLabel.ForeColor = Color.White;
            titleFont = new Font(
                "Segoe UI", 18F, FontStyle.Bold, GraphicsUnit.Point);
            titleLabel.Font = titleFont;
            titleLabel.Text = "Связь потеряна";
            titleLabel.TextAlign = ContentAlignment.MiddleCenter;

            detailLabel = new Label();
            detailLabel.AutoSize = false;
            detailLabel.BackColor = Color.Transparent;
            detailLabel.ForeColor = Color.FromArgb(218, 222, 230);
            detailFont = new Font(
                "Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point);
            detailLabel.Font = detailFont;
            detailLabel.Text = "Ожидаем повторного подключения…";
            detailLabel.TextAlign = ContentAlignment.MiddleCenter;

            closeButton = new Button();
            closeButton.AutoSize = false;
            closeButton.BackColor = Color.FromArgb(0, 120, 212);
            closeButton.FlatAppearance.BorderSize = 0;
            closeButton.FlatStyle = FlatStyle.Flat;
            closeButton.ForeColor = Color.White;
            buttonFont = new Font(
                "Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
            closeButton.Font = buttonFont;
            closeButton.Size = new Size(144, 38);
            closeButton.Text = "Закрыть окно";
            closeButton.UseVisualStyleBackColor = false;
            closeButton.Click += delegate { Close(); };

            Controls.Add(titleLabel);
            Controls.Add(detailLabel);
            Controls.Add(closeButton);
            AcceptButton = closeButton;
            Resize += delegate { LayoutMessage(); };
            LayoutMessage();
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            NativeMethods.SetImmersiveDarkMode(Handle, true);
        }

        protected override void OnPaintBackground(PaintEventArgs e)
        {
            e.Graphics.Clear(BackColor);
            if (snapshot != null)
            {
                e.Graphics.InterpolationMode =
                    InterpolationMode.HighQualityBicubic;
                e.Graphics.DrawImage(snapshot, ClientRectangle);
            }
            using (var shade = new SolidBrush(
                Color.FromArgb(snapshot == null ? 72 : 192, 12, 15, 21)))
            {
                e.Graphics.FillRectangle(shade, ClientRectangle);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && snapshot != null)
            {
                snapshot.Dispose();
                snapshot = null;
            }
            if (disposing)
            {
                titleFont.Dispose();
                detailFont.Dispose();
                buttonFont.Dispose();
            }
            base.Dispose(disposing);
        }

        private static Bitmap CreateSoftenedSnapshot(Bitmap source)
        {
            if (source == null)
                return null;

            Bitmap softened = null;
            try
            {
                int smallWidth = Math.Max(1, source.Width / 12);
                int smallHeight = Math.Max(1, source.Height / 12);
                using (var reduced = new Bitmap(smallWidth, smallHeight))
                {
                    using (Graphics graphics = Graphics.FromImage(reduced))
                    {
                        graphics.CompositingQuality =
                            CompositingQuality.HighQuality;
                        graphics.InterpolationMode =
                            InterpolationMode.HighQualityBilinear;
                        graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        graphics.DrawImage(
                            source,
                            new Rectangle(0, 0, smallWidth, smallHeight));
                    }

                    softened = new Bitmap(source.Width, source.Height);
                    using (Graphics graphics = Graphics.FromImage(softened))
                    {
                        graphics.CompositingQuality =
                            CompositingQuality.HighQuality;
                        graphics.InterpolationMode =
                            InterpolationMode.HighQualityBicubic;
                        graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        graphics.DrawImage(
                            reduced,
                            new Rectangle(0, 0, source.Width, source.Height));
                    }
                }

                source.Dispose();
                ReceiverContext.Log(
                    "Renderer snapshot was softened in memory for the " +
                    "lost-connection placeholder.");
                return softened;
            }
            catch
            {
                if (softened != null)
                    softened.Dispose();
                ReceiverContext.Log(
                    "Renderer snapshot softening was unavailable; the " +
                    "placeholder will use the darkened frame.");
                return source;
            }
        }

        private void LayoutMessage()
        {
            int contentWidth = Math.Max(1, ClientSize.Width - 32);
            int centerY = ClientSize.Height / 2;
            titleLabel.SetBounds(16, centerY - 80, contentWidth, 42);
            detailLabel.SetBounds(16, centerY - 34, contentWidth, 28);
            closeButton.Location = new Point(
                Math.Max(0, (ClientSize.Width - closeButton.Width) / 2),
                centerY + 18);
        }
    }
}
