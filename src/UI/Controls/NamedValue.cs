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
    internal sealed class NamedValue
    {
        public readonly string Name;
        public readonly string Value;
        public readonly string Subtitle;
        public NamedValue(string name, string value)
            : this(name, value, "") { }
        public NamedValue(string name, string value, string subtitle)
        {
            Name = name;
            Value = value;
            Subtitle = subtitle ?? "";
        }
        public override string ToString() { return Name; }
    }
}
