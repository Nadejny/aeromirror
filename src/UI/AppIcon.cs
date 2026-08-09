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
    internal static class AppIcon
    {
        private static readonly Icon icon = LoadIcon();
        private static readonly Image image = LoadImage();

        public static Icon Current { get { return icon; } }
        public static Image Image { get { return image; } }

        private static Icon LoadIcon()
        {
            try
            {
                Icon result = Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location);
                if (result != null)
                    return result;
            }
            catch { }
            return SystemIcons.Application;
        }

        private static Image LoadImage()
        {
            try
            {
                using (Stream stream = Assembly.GetExecutingAssembly()
                    .GetManifestResourceStream("AeroMirrorLogo"))
                {
                    if (stream != null)
                    {
                        using (Image source = Image.FromStream(stream))
                            return new Bitmap(source);
                    }
                }
            }
            catch { }
            return icon.ToBitmap();
        }
    }
}
