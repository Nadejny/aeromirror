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
            else if (control is NetworkHelpGlyph)
            {
                control.BackColor = Color.Transparent;
                control.ForeColor = textColor;
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
}
