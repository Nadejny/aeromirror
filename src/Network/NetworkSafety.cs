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
    internal static class NetworkSafety
    {
        public static NetworkProfileInfo DetectPhysicalProfile()
        {
            var result = new NetworkProfileInfo();
            try
            {
                string powershell = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    @"WindowsPowerShell\v1.0\powershell.exe");
                var start = new ProcessStartInfo();
                start.FileName = powershell;
                start.Arguments =
                    "-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " +
                    "\"$OutputEncoding=[Console]::OutputEncoding=[Text.UTF8Encoding]::new(); " +
                    "$physical=@(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | " +
                    "Where-Object {$_.Status -eq 'Up'} | ForEach-Object {$_.ifIndex}); " +
                    "$connected=@(Get-NetConnectionProfile -ErrorAction SilentlyContinue | " +
                    "Where-Object {($_.IPv4Connectivity -ne 'Disconnected' -or " +
                    "$_.IPv6Connectivity -ne 'Disconnected')}); " +
                    "$physicalProfiles=@($connected | Where-Object " +
                    "{$physical -contains $_.InterfaceIndex}); " +
                    "$overlayProfiles=@($connected | Where-Object " +
                    "{$physical -notcontains $_.InterfaceIndex}); " +
                    "$publicOverlays=@($overlayProfiles | Where-Object " +
                    "{$_.NetworkCategory -eq 'Public'}); " +
                    "$p=$physicalProfiles | Sort-Object " +
                    "@{Expression={if($_.NetworkCategory -eq 'Public'){0}else{1}}}, " +
                    "@{Expression={if($_.IPv4Connectivity -eq 'Internet'){0}else{1}}} | Select-Object -First 1; " +
                    "$category='Unknown';$name='';$alias='';$index=0;$addresses=''; " +
                    "if($p){$ips=@(Get-NetIPAddress -InterfaceIndex $p.InterfaceIndex " +
                    "-AddressFamily IPv4 -ErrorAction SilentlyContinue | " +
                    "Where-Object {$_.IPAddress -notlike '169.254.*' -and " +
                    "$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource} | " +
                    "ForEach-Object {$_.IPAddress} | Sort-Object -Unique); " +
                    "$category=$p.NetworkCategory.ToString();$name=$p.Name;" +
                    "$alias=$p.InterfaceAlias;$index=[int]$p.InterfaceIndex;" +
                    "$addresses=($ips -join ',')}; " +
                    "$value=[ordered]@{category=$category;name=$name;" +
                    "interfaceName=$alias;addresses=$addresses;interfaceIndex=$index;" +
                    "overlayCount=$overlayProfiles.Count;" +
                    "publicOverlayCount=$publicOverlays.Count}; " +
                    "$value | ConvertTo-Json -Compress\"";
                start.UseShellExecute = false;
                start.CreateNoWindow = true;
                start.WindowStyle = ProcessWindowStyle.Hidden;
                start.RedirectStandardOutput = true;
                start.StandardOutputEncoding = Encoding.UTF8;
                using (Process process = Process.Start(start))
                {
                    if (!process.WaitForExit(5000))
                    {
                        process.Kill();
                        process.WaitForExit(1500);
                        return result;
                    }
                    string output = process.StandardOutput.ReadToEnd();
                    string line = output.Trim();
                    if (line.Length == 0)
                        return result;
                    Dictionary<string, object> values =
                        new JavaScriptSerializer().DeserializeObject(line)
                        as Dictionary<string, object>;
                    if (values == null)
                        return result;
                    result.NonPhysicalProfileCount = Math.Max(
                        0, ReadInt(values, "overlayCount"));
                    result.PublicNonPhysicalProfileCount = Math.Max(
                        0, ReadInt(values, "publicOverlayCount"));
                    result.Category =
                        ReadString(values, "category").Trim();
                    result.InterfaceIndex =
                        ReadInt(values, "interfaceIndex");
                    bool recognizedCategory =
                        string.Equals(
                            result.Category,
                            "Private",
                            StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(
                            result.Category,
                            "Public",
                            StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(
                            result.Category,
                            "DomainAuthenticated",
                            StringComparison.OrdinalIgnoreCase);
                    if (!recognizedCategory || result.InterfaceIndex <= 0)
                        return result;
                    result.IsKnown = true;
                    result.IsPublic = string.Equals(
                        result.Category, "Public", StringComparison.OrdinalIgnoreCase);
                    result.Name = ReadString(values, "name").Trim();
                    result.InterfaceName =
                        ReadString(values, "interfaceName").Trim();
                    result.Addresses =
                        ReadString(values, "addresses").Trim();
                    result.Signature = result.Category + "|" +
                        result.InterfaceIndex + "|" + result.Name + "|" +
                        result.InterfaceName + "|" + result.Addresses;
                    return result;
                }
            }
            catch (Exception ex)
            {
                ReceiverContext.Log("Network profile check failed: " + ex.Message);
                return result;
            }
        }

        private static string ReadString(
            Dictionary<string, object> values, string key)
        {
            object value;
            return values.TryGetValue(key, out value) && value != null
                ? Convert.ToString(value)
                : "";
        }

        private static int ReadInt(
            Dictionary<string, object> values, string key)
        {
            int parsed;
            return int.TryParse(ReadString(values, key), out parsed)
                ? parsed
                : 0;
        }
    }
}
