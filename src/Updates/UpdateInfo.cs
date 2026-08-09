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
}
