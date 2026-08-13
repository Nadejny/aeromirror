param(
    [Parameter(Mandatory = $true)]
    [string]$CorePath,

    [Parameter(Mandatory = $true)]
    [string]$RuntimeRoot,

    [long]$RequestId = 98569,
    [int]$TimeoutSeconds = 25,
    [string]$ReceiverName = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    [int]$ExpectedRegisteredNameBytes = 50
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "FAILED: $Message"
    }
}

function Find-FreePortBase {
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        $base = Get-Random -Minimum 42000 -Maximum 48000
        $tcp = New-Object Collections.Generic.List[Net.Sockets.TcpListener]
        $udp = New-Object Collections.Generic.List[Net.Sockets.UdpClient]
        try {
            foreach ($port in $base..($base + 2)) {
                $listener = [Net.Sockets.TcpListener]::new(
                    [Net.IPAddress]::Loopback, $port)
                $listener.Start()
                $tcp.Add($listener)
                $client = [Net.Sockets.UdpClient]::new($port)
                $udp.Add($client)
            }
            return $base
        }
        catch {
        }
        finally {
            foreach ($listener in $tcp) { $listener.Stop() }
            foreach ($client in $udp) { $client.Dispose() }
        }
    }
    throw "Unable to find three free TCP/UDP ports for the native harness."
}

$core = (Resolve-Path -LiteralPath $CorePath).Path
$runtime = (Resolve-Path -LiteralPath $RuntimeRoot).Path
$portBase = Find-FreePortBase
$inputNameBytes = [Text.Encoding]::UTF8.GetByteCount($ReceiverName)
$arguments =
    "--headless --uxplay -n `"$ReceiverName`" -nh -p $portBase -a -reset 15"
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = $core
$start.Arguments = $arguments
$start.WorkingDirectory = $runtime
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.StandardOutputEncoding = [Text.Encoding]::UTF8
$start.StandardErrorEncoding = [Text.Encoding]::UTF8
$process = New-Object Diagnostics.Process
$process.StartInfo = $start
$stdoutLines = New-Object Collections.Generic.List[string]
$stderrLines = New-Object Collections.Generic.List[string]

try {
    Assert-True ($process.Start()) "native harness process starts"
    $expectedPid = $process.Id
    $stdoutTask = $process.StandardOutput.ReadLineAsync()
    $stderrTask = $process.StandardError.ReadLineAsync()
    $stdoutClosed = $false
    $stderrClosed = $false
    $capability = $false
    $commandSent = $false
    $accepted = $false
    $ready = $false
    $nameMarker = $null
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        if (-not $stdoutClosed -and $stdoutTask.IsCompleted) {
            $line = $stdoutTask.Result
            if ($null -eq $line) {
                $stdoutClosed = $true
            }
            else {
                $stdoutLines.Add($line)
                if ($line -eq
                        "AEROMIRROR_DISCOVERY_REFRESH_CAPABILITY version=1") {
                    $capability = $true
                }
                if ($line.StartsWith("AEROMIRROR_SERVICE_NAME ")) {
                    $nameMarker = $line
                }
                if ($line.StartsWith(
                        "AEROMIRROR_DISCOVERY_REFRESH_ACCEPTED request=$RequestId ")) {
                    $accepted = $true
                }
                if ($line.StartsWith(
                        "AEROMIRROR_DISCOVERY_REFRESH_READY request=$RequestId ")) {
                    $ready = $true
                }
                $stdoutTask = $process.StandardOutput.ReadLineAsync()
            }
        }
        if (-not $stderrClosed -and $stderrTask.IsCompleted) {
            $line = $stderrTask.Result
            if ($null -eq $line) {
                $stderrClosed = $true
            }
            else {
                $stderrLines.Add($line)
                $stderrTask = $process.StandardError.ReadLineAsync()
            }
        }
        if ($capability -and -not $commandSent) {
            $process.StandardInput.WriteLine(
                "AEROMIRROR_COMMAND refresh-discovery request=$RequestId")
            $process.StandardInput.Flush()
            $commandSent = $true
        }
        $continueWaiting = -not ($capability -and $accepted -and $ready) -and [DateTime]::UtcNow -lt $deadline -and -not $process.HasExited
        if ($continueWaiting) { Start-Sleep -Milliseconds 20 }
    } while ($continueWaiting)

    $markers = @($stdoutLines.ToArray() | Where-Object {
        $_ -match 'AEROMIRROR_(DISCOVERY_REFRESH|DNSSD)'
    })
    $rejections = @($stderrLines.ToArray() | Where-Object {
        $_ -match 'AEROMIRROR_COMMAND_REJECTED'
    })
    Assert-True $accepted "correlated refresh is accepted over redirected stdin"
    Assert-True $ready "correlated refresh reaches paired DNS-SD readiness"
    Assert-True ($rejections.Count -eq 0) "the command is not rejected"
    Assert-True (-not [string]::IsNullOrWhiteSpace($nameMarker)) `
        "native core reports the canonical DNS-SD service-name lengths"
    Assert-True ($nameMarker -match
        'input_bytes=(\d+) registered_bytes=(\d+) raop_label_bytes=(\d+) truncated=(\d+)') `
        "service-name marker has bounded length fields"
    $reportedInputBytes = [int]$Matches[1]
    $reportedRegisteredBytes = [int]$Matches[2]
    $reportedRaopBytes = [int]$Matches[3]
    $reportedTruncated = [int]$Matches[4]
    Assert-True ($reportedInputBytes -eq $inputNameBytes) `
        "service-name input byte count matches UTF-8"
    Assert-True ($reportedRegisteredBytes -eq $ExpectedRegisteredNameBytes) `
        "service name is canonicalized at a complete expected UTF-8 prefix"
    Assert-True ($reportedRaopBytes -eq 13 + $ExpectedRegisteredNameBytes -and
        $reportedRaopBytes -le 63) `
        "RAOP MAC@name label stays within the Bonjour 63-byte limit"
    Assert-True ($reportedTruncated -eq
        [int]($inputNameBytes -gt $ExpectedRegisteredNameBytes)) `
        "service-name marker reports truncation truthfully"

    $initial = $markers | Where-Object {
        $_ -match 'DISCOVERY_REFRESH_READY request=0 '
    } | Select-Object -First 1
    $final = $markers | Where-Object {
        $_ -match "DISCOVERY_REFRESH_READY request=$RequestId "
    } | Select-Object -First 1
    Assert-True (-not [string]::IsNullOrWhiteSpace($initial)) `
        "initial DNS-SD generation becomes ready"
    Assert-True (-not [string]::IsNullOrWhiteSpace($final)) `
        "requested DNS-SD generation becomes ready"

    $fields = 'pid=(\d+) raop_port=(\d+) airplay_port=(\d+)'
    Assert-True ($initial -match $fields) "initial marker has identity fields"
    $initialPid = [int]$Matches[1]
    $initialRaopPort = [int]$Matches[2]
    $initialAirPlayPort = [int]$Matches[3]
    Assert-True ($final -match $fields) "final marker has identity fields"
    $finalPid = [int]$Matches[1]
    $finalRaopPort = [int]$Matches[2]
    $finalAirPlayPort = [int]$Matches[3]
    Assert-True ($initialPid -eq $expectedPid -and
        $finalPid -eq $expectedPid) "refresh retains the operating-system PID"
    Assert-True ($initialRaopPort -eq $finalRaopPort -and
        $initialAirPlayPort -eq $finalAirPlayPort) `
        "refresh retains both advertised listener ports"

    $markers | ForEach-Object { Write-Host $_ }
    Write-Host (
        "Native discovery pipe checks passed: PID $expectedPid, " +
        "RAOP $initialRaopPort, AirPlay $initialAirPlayPort, " +
        "request $RequestId.")
}
catch {
    Write-Host "--- native stdout ---"
    $stdoutLines.ToArray() | ForEach-Object { Write-Host $_ }
    Write-Host "--- native stderr ---"
    $stderrLines.ToArray() | ForEach-Object { Write-Host $_ }
    throw
}
finally {
    try { $process.StandardInput.Close() } catch {}
    try {
        if (-not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit(5000) | Out-Null
        }
    }
    catch {}
    $process.Dispose()
}

exit 0
