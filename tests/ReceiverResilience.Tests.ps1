param(
    [string]$AssemblyPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot "src\AirPlayReceiverMvp.cs"
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $projectRoot "artifacts\Release\AeroMirror.exe"
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "FAILED: $Message"
    }
}

Assert-True (Test-Path -LiteralPath $sourcePath) "receiver source exists"
Assert-True (Test-Path -LiteralPath $AssemblyPath) "compiled AeroMirror assembly exists"

$source = [IO.File]::ReadAllText($sourcePath)
Assert-True (-not $source.Contains("GetOrCreateReceiverDeviceId")) `
    "an upgrade must not invent a replacement AirPlay device ID"
Assert-True ($source.Contains("GetSavedReceiverDeviceId")) `
    "a previously observed UxPlay device ID is reused"
Assert-True ($source.Contains("randomly-generated) MAC address")) `
    "the exact first-run UxPlay device ID is captured"
Assert-True (-not [regex]::IsMatch($source, 'WaitForExit\s*\(\s*\)')) `
    "core shutdown contains no unbounded WaitForExit call"
Assert-True ($source.Contains(
    "WorkingDirectory = Path.GetDirectoryName(installerPath)")) `
    "the updater launches Setup outside the installed application directory"
Assert-True ($source.Contains("discoveryRefreshAfterNetworkCheck")) `
    "manual discovery refresh survives an unavailable physical network"
Assert-True ($source.Contains("physicalNetworkReady")) `
    "receiver startup requires a confirmed physical IPv4 address"
Assert-True ($source.Contains('$_.AddressState -eq ''Preferred''')) `
    "BLE binding excludes tentative or deprecated physical IPv4 addresses"
Assert-True ($source.Contains('-not $_.SkipAsSource')) `
    "BLE binding excludes physical IPv4 addresses marked SkipAsSource"
Assert-True ($source.Contains("AEROMIRROR_DNSSD_READY")) `
    "native DNS-SD readiness marker is observed"
Assert-True ($source.Contains("AEROMIRROR_DNSSD_DEGRADED")) `
    "native DNS-SD degradation marker is observed"
Assert-True ($source.Contains("AEROMIRROR_BLE")) `
    "native BLE marker is observed"
Assert-True ($source.Contains("Discovery registration: DNS-SD=")) `
    "support diagnostics expose native discovery registration"

$assembly = [Reflection.Assembly]::LoadFrom(
    [IO.Path]::GetFullPath($AssemblyPath))
$contextType = $assembly.GetType(
    "AirPlayReceiverMvp.ReceiverContext", $true)
$context = [Runtime.Serialization.FormatterServices]::GetUninitializedObject(
    $contextType)
$instanceFlags = [Reflection.BindingFlags]::Instance -bor `
    [Reflection.BindingFlags]::NonPublic -bor `
    [Reflection.BindingFlags]::Public
$staticFlags = [Reflection.BindingFlags]::Static -bor `
    [Reflection.BindingFlags]::NonPublic -bor `
    [Reflection.BindingFlags]::Public

function Field([string]$Name) {
    $field = $contextType.GetField($Name, $instanceFlags)
    Assert-True ($null -ne $field) "field '$Name' exists"
    return $field
}

$activePid = Field "activeCorePid"
$mirrorActive = Field "mirrorSessionActive"
$recoveryPending = Field "lostConnectionRecoveryPending"
$recoveryDue = Field "lostConnectionRecoveryDueTicks"
$startAfterNetwork = Field "startAfterNetworkCheck"
$refreshAfterNetwork = Field "discoveryRefreshAfterNetworkCheck"
$networkRefreshPending = Field "networkRefreshPending"
$networkRefreshDue = Field "networkRefreshDueTicks"
$socketsReady = Field "coreSocketsReady"
$dnsSdStatus = Field "coreDnsSdStatus"
$bleStatus = Field "coreBleStatus"
$discoveryRecoveryPending = Field "coreDiscoveryRecoveryPending"
$discoveryRecoveryAttempts = Field "coreDiscoveryRecoveryAttempts"
$discoveryRecoveryPid = Field "coreDiscoveryRecoveryPid"
$discoveryRecoveryDue = Field "coreDiscoveryRecoveryDueTicks"

$activePid.SetValue($context, 42)
$mirrorActive.SetValue($context, 1)
$observe = $contextType.GetMethod("ObserveCoreOutput", $instanceFlags)
Assert-True ($null -ne $observe) "core-output observer exists"
$readiness = $contextType.GetMethod(
    "IsCoreReadinessConfirmed", $staticFlags)
Assert-True ($null -ne $readiness) "core-readiness predicate exists"
Assert-True (-not [bool]$readiness.Invoke(
        $null, [object[]]@($false, $true, 1, 1))) `
    "native markers never replace the ready-socket baseline"
Assert-True ([bool]$readiness.Invoke(
        $null, [object[]]@($true, $true, 0, 0))) `
    "legacy core readiness remains valid without native markers"
Assert-True ([bool]$readiness.Invoke(
        $null, [object[]]@($true, $false, 1, 0))) `
    "direct DNS-SD confirmation can replace a service-status lookup"
Assert-True ([bool]$readiness.Invoke(
        $null, [object[]]@($true, $false, -1, 1))) `
    "healthy BLE discovery can back up degraded DNS-SD"
Assert-True (-not [bool]$readiness.Invoke(
        $null, [object[]]@($true, $false, -1, -1))) `
    "sockets alone do not confirm readiness without Bonjour or a healthy marker"
Assert-True (-not [bool]$readiness.Invoke(
        $null, [object[]]@($true, $true, -1, -1))) `
    "a running Bonjour service cannot override explicit failure of both discovery paths"

$observe.Invoke(
    $context,
    [object[]]@(99, "AEROMIRROR_DNSSD_READY")) | Out-Null
Assert-True ([int]$dnsSdStatus.GetValue($context) -eq 0) `
    "discovery markers from a stale core PID are ignored"

$socketsReady.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42, "UxPlay: AEROMIRROR_DNSSD_DEGRADED")) | Out-Null
Assert-True ([int]$dnsSdStatus.GetValue($context) -eq -1) `
    "degraded DNS-SD registration is recorded"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "one degraded discovery path does not trigger recovery"

$discoveryBefore = [DateTime]::UtcNow.Ticks
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_BLE [beacon] Failed to start: radio unavailable")) |
    Out-Null
$discoveryDue = [long]$discoveryRecoveryDue.GetValue($context)
Assert-True ([int]$bleStatus.GetValue($context) -eq -1) `
    "failed BLE advertising is recorded"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 1) `
    "recovery is armed only after both discovery paths fail"
Assert-True ([int]$discoveryRecoveryPid.GetValue($context) -eq 42) `
    "discovery recovery is tied to the active core PID"
Assert-True ($discoveryDue -ge `
        $discoveryBefore + [TimeSpan]::FromSeconds(4).Ticks) `
    "discovery recovery includes a grace period"
Assert-True ($discoveryDue -le [DateTime]::UtcNow.AddSeconds(6).Ticks) `
    "discovery recovery grace is bounded"
Assert-True ([int]$socketsReady.GetValue($context) -eq 1) `
    "discovery marker failures do not invalidate ready server sockets"

$discoveryRecoveryAttempts.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_BLE [beacon] Advertising started: 192.0.2.10:7000")) |
    Out-Null
Assert-True ([int]$bleStatus.GetValue($context) -eq 1) `
    "successful BLE advertising is recorded"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "a healthy discovery path cancels pending recovery"
Assert-True ([int]$discoveryRecoveryAttempts.GetValue($context) -eq 0) `
    "a healthy discovery path resets the bounded recovery allowance"

$bleStatus.SetValue($context, 0)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "[beacon] Advertising started: 192.0.2.10:7000")) | Out-Null
Assert-True ([int]$bleStatus.GetValue($context) -eq 1) `
    "a continuation line from a chunked BLE marker is recognized"

$dnsSdStatus.SetValue($context, -1)
$bleStatus.SetValue($context, 0)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_BLE [beacon] Advertising failed: access denied")) |
    Out-Null
Assert-True ([int]$bleStatus.GetValue($context) -eq -1) `
    "alternate BLE advertising-failed wording is recognized"
$observe.Invoke(
    $context,
    [object[]]@(42, "UxPlay: AEROMIRROR_DNSSD_READY")) | Out-Null
Assert-True ([int]$dnsSdStatus.GetValue($context) -eq 1) `
    "successful DNS-SD registration is recorded"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "DNS-SD success cancels recovery even when BLE is unavailable"

$before = [DateTime]::UtcNow.Ticks
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror error in recv: 10054")) | Out-Null
$armedDue = [long]$recoveryDue.GetValue($context)
Assert-True ([int]$recoveryPending.GetValue($context) -eq 1) `
    "fatal mirror recv error arms recovery"
Assert-True ($armedDue -ge $before + [TimeSpan]::FromSeconds(2).Ticks) `
    "recovery grace is not shorter than two seconds"
Assert-True ($armedDue -le [DateTime]::UtcNow.AddSeconds(4).Ticks) `
    "recovery grace is bounded"

$observe.Invoke(
    $context,
    [object[]]@(42, "***ERROR lost connection with client")) | Out-Null
Assert-True ([long]$recoveryDue.GetValue($context) -eq $armedDue) `
    "repeated fatal markers do not postpone recovery indefinitely"

$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror->running is no longer true")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "normal mirror shutdown cancels recovery"
Assert-True ([int]$mirrorActive.GetValue($context) -eq 0) `
    "normal mirror shutdown clears the active-session flag"

$mirrorActive.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42, "***ERROR lost connection with client")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 1) `
    "lost-client marker arms recovery"

$networkChanged = $contextType.GetMethod(
    "OnNetworkAddressChanged", $instanceFlags)
Assert-True ($null -ne $networkChanged) "network-change debounce exists"
$networkRefreshPending.SetValue($context, 0)
$networkRefreshDue.SetValue($context, [long]0)
$networkChanged.Invoke(
    $context, [object[]]@($null, [EventArgs]::Empty)) | Out-Null
$firstNetworkDue = [long]$networkRefreshDue.GetValue($context)
Assert-True ([int]$networkRefreshPending.GetValue($context) -eq 1) `
    "network change schedules a profile refresh"
Start-Sleep -Milliseconds 25
$networkChanged.Invoke(
    $context, [object[]]@($null, [EventArgs]::Empty)) | Out-Null
$secondNetworkDue = [long]$networkRefreshDue.GetValue($context)
Assert-True ($secondNetworkDue -eq $firstNetworkDue) `
    "an event storm does not keep postponing profile detection"

$waitingProperty = $contextType.GetProperty(
    "IsWaitingForNetwork", $instanceFlags)
$startAfterNetwork.SetValue($context, $false)
$refreshAfterNetwork.SetValue($context, 1)
Assert-True ([bool]$waitingProperty.GetValue($context, $null)) `
    "manual discovery refresh exposes the waiting-for-network state"
$refreshAfterNetwork.SetValue($context, 0)
$startAfterNetwork.SetValue($context, $true)
Assert-True ([bool]$waitingProperty.GetValue($context, $null)) `
    "startup exposes the waiting-for-network state even when PIN is enabled"

Write-Host "Receiver resilience checks passed."
