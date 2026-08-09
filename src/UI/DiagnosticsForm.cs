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
}
