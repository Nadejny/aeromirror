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
    internal sealed class NetworkProfileInfo
    {
        public bool IsKnown;
        public bool IsPublic;
        public string Category = "Unknown";
        public string Name = "";
        public string InterfaceName = "";
        public string Addresses = "";
        public int InterfaceIndex;
        public int NonPhysicalProfileCount;
        public int PublicNonPhysicalProfileCount;
        public string Signature = "Unknown|||";
    }
}
