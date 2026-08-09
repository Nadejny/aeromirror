param(
    [string]$AssemblyPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $projectRoot "src"
$sourcePaths = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter "*.cs" -File |
        Sort-Object -Property FullName |
        ForEach-Object { $_.FullName }
)
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $projectRoot "artifacts\Release\AeroMirror.exe"
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "FAILED: $Message"
    }
}

Assert-True ($sourcePaths.Count -gt 0) "receiver sources exist"
Assert-True (Test-Path -LiteralPath $AssemblyPath) "compiled AeroMirror assembly exists"

$source = [string]::Join(
    [Environment]::NewLine,
    @($sourcePaths | ForEach-Object {
        [IO.File]::ReadAllText($_)
    }))
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
Assert-True (-not $source.Contains("post-session discovery renewal")) `
    "a completed session does not force an unconditional core restart"
Assert-True ($source.Contains('parts.Add("-reset 6")')) `
    "UxPlay receives the six-second lost-client reset bound"
$systemResetIndex = $source.IndexOf('parts.Add("-reset 6")')
$advancedArgumentsIndex = $source.IndexOf(
    'parts.Add(settings.AdvancedArguments.Trim())')
Assert-True ($systemResetIndex -lt $advancedArgumentsIndex) `
    "advanced UxPlay arguments can override the system reset bound"
Assert-True (-not $source.Contains('parts.Add("-nohold")')) `
    "the receiver does not allow a new client to preempt an active session"
$sharedBudgetCallCount = [regex]::Matches(
    $source, 'ConsumeSharedAutomaticRecoveryBudget\s*\(').Count
Assert-True ($sharedBudgetCallCount -ge 3) `
    "readiness and native discovery both consume one shared recovery budget"
Assert-True (-not $source.Contains(
        'StopCoreInternal("readiness confirmation failed"')) `
    "unconfirmed readiness never synchronously stops a socket-ready core"
Assert-True ($source.Contains(
        "networkTitle.TextAlign = ContentAlignment.MiddleLeft")) `
    "network text is vertically centered beside its help glyph"
Assert-True ($source.Contains(
        "toolTips.SetToolTip(statusDot, receiverDetails)") -and
    $source.Contains("toolTips.SetToolTip(status, receiverDetails)")) `
    "receiver details are available from both the status dot and status text"
Assert-True ($source.Contains("status.Size = new Size(1, 24)") -and
    $source.Contains(
        "TextRenderer.MeasureText(status.Text, status.Font).Width")) `
    "receiver status tooltip target follows the rendered text instead of blank space"
Assert-True (-not $source.Contains("toolTips.SetToolTip(networkCard") -and
    -not $source.Contains("toolTips.SetToolTip(networkTitle")) `
    "network details are not attached to the whole network card"
$networkHelpTooltipCount = [regex]::Matches(
    $source, 'toolTips\.SetToolTip\(networkHelp, networkDetails\)').Count
Assert-True ($networkHelpTooltipCount -eq 1) `
    "network details are attached only to the question-mark control"
$privatePinGuidanceBreakCount = [regex]::Matches(
    $source, '\\r\\n" \+\s*"[^"]*PIN [^"]*"').Count
Assert-True ($privatePinGuidanceBreakCount -ge 2) `
    "private-network PIN guidance starts on a separate tooltip line"
Assert-True ($source.Contains("e.Graphics.DpiX / 96F") -and
    $source.Contains("SmoothingMode.AntiAlias") -and
    $source.Contains("format.Alignment = StringAlignment.Center") -and
    $source.Contains("format.LineAlignment = StringAlignment.Center")) `
    "the help circle and question glyph use DPI-aware anti-aliased centering"

$assembly = [Reflection.Assembly]::LoadFrom(
    [IO.Path]::GetFullPath($AssemblyPath))
$settingsType = $assembly.GetType(
    "AirPlayReceiverMvp.AppSettings", $true)
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

$networkHelpType = $assembly.GetType(
    "AirPlayReceiverMvp.NetworkHelpGlyph", $true)
Assert-True ($networkHelpType.BaseType.FullName -eq
    "System.Windows.Forms.Control") `
    "the network help glyph is a dedicated custom control"
$networkHelpPaint = $networkHelpType.GetMethod("OnPaint", $instanceFlags)
Assert-True ($null -ne $networkHelpPaint -and
    $networkHelpPaint.DeclaringType -eq $networkHelpType) `
    "the network help glyph owns its DPI-aware drawing path"
$networkHelpProbe = [Activator]::CreateInstance($networkHelpType, $true)
try {
    Assert-True ($networkHelpProbe.Width -eq 24 -and
        $networkHelpProbe.Height -eq 24) `
        "the help glyph has a compact square layout box"
    Assert-True ($networkHelpProbe.Text -eq "?") `
        "the help glyph exposes a question-mark text alternative"
    Assert-True ($networkHelpProbe.AccessibleRole.ToString() -eq
        "HelpBalloon") `
        "assistive technology receives an explicit help role"
}
finally {
    $networkHelpProbe.Dispose()
}

$normalizeSettings = $settingsType.GetMethod(
    "NormalizePersistedValues", $instanceFlags)
Assert-True ($null -ne $normalizeSettings) `
    "persisted settings normalization exists"
$settingsProbe = [Activator]::CreateInstance($settingsType, $true)
$settingsProbe.PairingMode = "garbage"
$settingsProbe.FixedPin = "1234"
$settingsProbe.QualityPreset = "unknown-quality"
$settingsProbe.Renderer = "vulkan"
$settingsProbe.LatencyProfile = "turbo"
$settingsProbe.AudioOutput = "custom"
$settingsProbe.ThemeMode = "sepia"
$normalizeSettings.Invoke($settingsProbe, [object[]]@()) | Out-Null
Assert-True ($settingsProbe.PairingMode -eq "none") `
    "an unknown pairing mode becomes unprotected so network policy fails closed"
Assert-True ($settingsProbe.FixedPin -eq "") `
    "an invalid pairing mode does not retain a misleading PIN"
Assert-True ($settingsProbe.QualityPreset -eq "1080p60") `
    "an unknown quality preset receives the stable default"
Assert-True ($settingsProbe.Renderer -eq "auto") `
    "an unknown renderer receives the automatic default"
Assert-True ($settingsProbe.LatencyProfile -eq "balanced") `
    "an unknown latency profile receives the balanced default"
Assert-True ($settingsProbe.AudioOutput -eq "default") `
    "an unknown audio output receives the system default"
Assert-True ($settingsProbe.ThemeMode -eq "system") `
    "an unknown theme follows Windows"

$settingsProbe.PairingMode = "password"
$settingsProbe.FixedPin = "1234"
$normalizeSettings.Invoke($settingsProbe, [object[]]@()) | Out-Null
Assert-True ($settingsProbe.PairingMode -eq "none") `
    "the obsolete password mode migrates to the fail-closed unprotected state"
$settingsProbe.PairingMode = "pin"
$settingsProbe.FixedPin = -join @(
    [char]0xFF11, [char]0xFF12, [char]0xFF13, [char]0xFF14)
$normalizeSettings.Invoke($settingsProbe, [object[]]@()) | Out-Null
Assert-True ($settingsProbe.PairingMode -eq "none") `
    "PIN protection requires four ASCII digits"
$settingsProbe.PairingMode = " PIN "
$settingsProbe.FixedPin = " 0427 "
$normalizeSettings.Invoke($settingsProbe, [object[]]@()) | Out-Null
Assert-True ($settingsProbe.PairingMode -eq "pin" -and
    $settingsProbe.FixedPin -eq "0427") `
    "a valid persisted PIN is canonicalized and preserved"

$atomicWriter = $settingsType.GetMethod(
    "WriteAllLinesAtomically", $staticFlags)
Assert-True ($null -ne $atomicWriter) "atomic settings writer exists"
$atomicRoot = Join-Path ([IO.Path]::GetTempPath()) (
    "AeroMirror-settings-atomic-test-" + [Guid]::NewGuid().ToString("N"))
$atomicPath = Join-Path $atomicRoot "settings.ini"
try {
    [IO.Directory]::CreateDirectory($atomicRoot) | Out-Null
    [IO.File]::WriteAllText($atomicPath, "old=value")
    $atomicLines = [Array]::CreateInstance([string], 2)
    $atomicLines.SetValue("SettingsVersion=9", 0)
    $atomicLines.SetValue("PairingMode=none", 1)
    $atomicArguments = [Array]::CreateInstance([object], 2)
    $atomicArguments.SetValue([string]$atomicPath, 0)
    $atomicArguments.SetValue($atomicLines, 1)
    $atomicWriter.Invoke($null, $atomicArguments) | Out-Null
    $atomicText = [IO.File]::ReadAllText($atomicPath)
    Assert-True ($atomicText.Contains("SettingsVersion=9") -and
        $atomicText.Contains("PairingMode=none")) `
        "atomic settings replacement publishes the complete new file"
    Assert-True (([IO.Directory]::GetFiles(
        $atomicRoot, "*.tmp")).Count -eq 0) `
        "atomic settings replacement leaves no temporary file"
}
finally {
    if ([IO.Directory]::Exists($atomicRoot)) {
        [IO.Directory]::Delete($atomicRoot, $true)
    }
}

$updateType = $assembly.GetType(
    "AirPlayReceiverMvp.UpdateService", $true)
$tryParseVersion = $updateType.GetMethod("TryParseVersion", $staticFlags)
Assert-True ($null -ne $tryParseVersion) `
    "release version parser exists"
function Invoke-VersionParse([string]$Value) {
    $arguments = [Array]::CreateInstance([object], 2)
    $arguments.SetValue([string]$Value, 0)
    $arguments.SetValue($null, 1)
    $parsed = [bool]$tryParseVersion.Invoke($null, $arguments)
    return [pscustomobject]@{
        Success = $parsed
        Version = $arguments[1]
    }
}
$threePartVersion = Invoke-VersionParse "v0.11.4"
Assert-True ($threePartVersion.Success -and
    $threePartVersion.Version.ToString() -eq "0.11.4") `
    "an exact three-part release version is accepted"
Assert-True (-not (Invoke-VersionParse "v0.11").Success) `
    "a two-part release version is rejected"
Assert-True (-not (Invoke-VersionParse "v0.11.4.1").Success) `
    "a four-part release version is rejected"
Assert-True (-not (Invoke-VersionParse "v0.11.4-beta").Success) `
    "a suffixed release version is rejected"

function Field([string]$Name) {
    $field = $contextType.GetField($Name, $instanceFlags)
    Assert-True ($null -ne $field) "field '$Name' exists"
    return $field
}

$activePid = Field "activeCorePid"
$mirrorActive = Field "mirrorSessionActive"
$recoveryPending = Field "lostConnectionRecoveryPending"
$recoveryPid = Field "lostConnectionRecoveryPid"
$recoveryDue = Field "lostConnectionRecoveryDueTicks"
$sessionEndedPending = Field "mirrorSessionEndedPending"
$sessionEndedDue = Field "mirrorSessionEndedDueTicks"
$settingsRestartDeferred = Field "settingsRestartDeferred"
$idleRenewalDue = Field "idleDiscoveryRenewalDueTicks"
$idleRenewalUsed = Field "idleDiscoveryRenewalUsed"
$restartPending = Field "restartPending"
$coreReadyPending = Field "coreReadyPending"
$coreReadyChecks = Field "coreReadyChecks"
$coreReadinessAttempts = Field "coreReadinessRecoveryAttempts"
$coreReadinessPid = Field "coreReadinessPid"
$clientReadyPending = Field "coreClientActivityReadyPending"
$clientGraceDue = Field "clientActivityGraceDueTicks"
$physicalNetworkRestartDeferred = Field "physicalNetworkRestartDeferred"
$maintenanceSync = Field "postSessionMaintenanceSync"
$videoSizeSync = Field "videoSizeSync"
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

$maintenanceSync.SetValue($context, (New-Object object))
$videoSizeSync.SetValue($context, (New-Object object))
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

$connectionMarker = $contextType.GetMethod(
    "IsIncomingAirPlayConnectionRequestMarker", $staticFlags)
$pinMarker = $contextType.GetMethod(
    "IsAirPlayPinEntryMarker", $staticFlags)
$deferDisruptive = $contextType.GetMethod(
    "ShouldDeferDisruptiveMaintenance", $staticFlags)
Assert-True ([bool]$connectionMarker.Invoke(
        $null, [object[]]@("connection request from iPhone (iPhone14,8)"))) `
    "the anchored post-auth AirPlay request marker is recognized"
Assert-True (-not [bool]$connectionMarker.Invoke(
        $null, [object[]]@("rejecting new connection request from iPhone"))) `
    "a rejected request is not treated as successful client activity"
Assert-True ([bool]$pinMarker.Invoke(
        $null, [object[]]@('*** CLIENT MUST NOW ENTER PIN = "1234" AS AIRPLAY PASSWORD'))) `
    "the exact pre-auth PIN progress prefix is recognized"
Assert-True (-not [bool]$pinMarker.Invoke(
        $null, [object[]]@("CLIENT MUST NOW ENTER PIN"))) `
    "a PIN-marker near miss is ignored"
$graceProbeNow = [DateTime]::UtcNow.Ticks
Assert-True ([bool]$deferDisruptive.Invoke(
        $null, [object[]]@($true, [long]0, $graceProbeNow))) `
    "an active stream defers disruptive maintenance without a renderer HWND"
Assert-True ([bool]$deferDisruptive.Invoke(
        $null, [object[]]@(
            $false, [DateTime]::UtcNow.AddSeconds(30).Ticks, $graceProbeNow))) `
    "client-activity grace defers disruptive maintenance before rendering"
Assert-True (-not [bool]$deferDisruptive.Invoke(
        $null, [object[]]@($false, [long]0, $graceProbeNow))) `
    "idle maintenance is allowed when no session or client grace exists"

$consumeSharedBudget = $contextType.GetMethod(
    "ConsumeSharedAutomaticRecoveryBudget", $instanceFlags)
Assert-True ($null -ne $consumeSharedBudget) `
    "shared automatic recovery budget exists"

$coreReadyPending.SetValue($context, $true)
$coreReadyChecks.SetValue($context, 8)
$coreReadinessAttempts.SetValue($context, 0)
$coreReadinessPid.SetValue($context, 42)
$discoveryRecoveryPending.SetValue($context, 1)
$discoveryRecoveryAttempts.SetValue($context, 0)
$discoveryRecoveryPid.SetValue($context, 42)
$discoveryRecoveryDue.SetValue(
    $context, [DateTime]::UtcNow.AddSeconds(5).Ticks)
$readinessWon = [bool]$consumeSharedBudget.Invoke(
    $context, [object[]]@($true))
Assert-True $readinessWon `
    "readiness can consume an unused shared automatic recovery budget"
Assert-True ([int]$coreReadinessAttempts.GetValue($context) -eq 1) `
    "readiness recovery marks its own shared allowance consumed"
Assert-True ([int]$discoveryRecoveryAttempts.GetValue($context) -eq 1) `
    "readiness recovery also consumes the native-discovery allowance"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "readiness recovery cancels sibling native-discovery maintenance"
Assert-True (-not [bool]$coreReadyPending.GetValue($context)) `
    "readiness recovery resolves its completed readiness check"
$discoveryAfterReadiness = [bool]$consumeSharedBudget.Invoke(
    $context, [object[]]@($false))
Assert-True (-not $discoveryAfterReadiness) `
    "native discovery cannot trigger a second restart after readiness recovery"

$coreReadyPending.SetValue($context, $true)
$coreReadyChecks.SetValue($context, 8)
$coreReadinessAttempts.SetValue($context, 0)
$coreReadinessPid.SetValue($context, 42)
$discoveryRecoveryPending.SetValue($context, 1)
$discoveryRecoveryAttempts.SetValue($context, 0)
$discoveryRecoveryPid.SetValue($context, 42)
$discoveryRecoveryDue.SetValue(
    $context, [DateTime]::UtcNow.AddSeconds(5).Ticks)
$discoveryWon = [bool]$consumeSharedBudget.Invoke(
    $context, [object[]]@($false))
Assert-True $discoveryWon `
    "native discovery can consume an unused shared automatic recovery budget"
Assert-True ([int]$coreReadinessAttempts.GetValue($context) -eq 1) `
    "native-discovery recovery also consumes the readiness allowance"
Assert-True (-not [bool]$coreReadyPending.GetValue($context)) `
    "native-discovery recovery cancels sibling readiness maintenance"
Assert-True ([int]$coreReadinessPid.GetValue($context) -eq 0) `
    "native-discovery recovery clears the sibling readiness owner"
$readinessAfterDiscovery = [bool]$consumeSharedBudget.Invoke(
    $context, [object[]]@($true))
Assert-True (-not $readinessAfterDiscovery) `
    "readiness cannot trigger a second restart after native discovery recovery"

$coreReadyPending.SetValue($context, $false)
$coreReadyChecks.SetValue($context, 0)
$coreReadinessAttempts.SetValue($context, 0)
$coreReadinessPid.SetValue($context, 0)
$discoveryRecoveryPending.SetValue($context, 0)
$discoveryRecoveryAttempts.SetValue($context, 0)
$discoveryRecoveryPid.SetValue($context, 0)
$discoveryRecoveryDue.SetValue($context, [long]0)

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

$recoveryPending.SetValue($context, 0)
$restartPending.SetValue($context, $false)
$mirrorActive.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "*** ERROR:   3 seconds since last client feedback request (expected every two seconds); client may be offline")) |
    Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "a client-feedback delay warning does not arm the lost-client watchdog"
Assert-True (-not [bool]$restartPending.GetValue($context)) `
    "a client-feedback delay warning does not schedule a core restart"

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
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 0) `
    "normal mirror shutdown does not schedule post-session maintenance"
Assert-True (-not [bool]$restartPending.GetValue($context)) `
    "normal mirror shutdown does not schedule a core restart"
$idleDue = [long]$idleRenewalDue.GetValue($context)
Assert-True ($idleDue -ge [DateTime]::UtcNow.AddMinutes(9).Ticks) `
    "normal mirror shutdown preserves the bounded idle-discovery fallback"
Assert-True ($idleDue -le [DateTime]::UtcNow.AddMinutes(11).Ticks) `
    "idle-discovery fallback remains bounded near ten minutes"

$settingsRestartDeferred.SetValue($context, 1)
$sessionEndedPending.SetValue($context, 1)
$rawAcceptDue = [DateTime]::UtcNow.AddMilliseconds(100).Ticks
$rawAcceptIdleDue = [DateTime]::UtcNow.AddMilliseconds(100).Ticks
$sessionEndedDue.SetValue($context, $rawAcceptDue)
$idleRenewalDue.SetValue($context, $rawAcceptIdleDue)
$idleRenewalUsed.SetValue($context, 1)
$discoveryRecoveryPending.SetValue($context, 1)
$discoveryRecoveryAttempts.SetValue($context, 1)
$discoveryRecoveryPid.SetValue($context, 42)
$discoveryRecoveryDue.SetValue($context, $rawAcceptDue)
$coreReadyPending.SetValue($context, $true)
$coreReadyChecks.SetValue($context, 8)
$coreReadinessAttempts.SetValue($context, 1)
$coreReadinessPid.SetValue($context, 42)
$clientReadyPending.SetValue($context, 0)
$clientGraceDue.SetValue($context, [long]0)
$observe.Invoke(
    $context,
    [object[]]@(42, "Accepted IPv4 client on socket 12, port 7000")) |
    Out-Null
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 1) `
    "a low-level accepted socket is not treated as an AirPlay request"
Assert-True ([long]$sessionEndedDue.GetValue($context) -eq $rawAcceptDue) `
    "a low-level accepted socket does not alter deferred maintenance"
Assert-True ([long]$idleRenewalDue.GetValue($context) -eq $rawAcceptIdleDue) `
    "a low-level accepted socket does not postpone idle maintenance"
Assert-True ([int]$idleRenewalUsed.GetValue($context) -eq 1) `
    "a low-level accepted socket does not renew the idle fallback allowance"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 1) `
    "a low-level accepted socket does not cancel discovery recovery"
Assert-True ([bool]$coreReadyPending.GetValue($context)) `
    "a low-level accepted socket does not bypass readiness confirmation"
Assert-True ([long]$clientGraceDue.GetValue($context) -eq 0) `
    "a low-level accepted socket does not start client-activity grace"
Assert-True ([int]$settingsRestartDeferred.GetValue($context) -eq 1) `
    "a low-level accepted socket does not discard deferred settings"

$observe.Invoke(
    $context,
    [object[]]@(42,
        "rejecting new connection request from unsupported client")) |
    Out-Null
Assert-True ([long]$sessionEndedDue.GetValue($context) -eq $rawAcceptDue) `
    "a rejected request does not postpone deferred maintenance"
Assert-True ([bool]$coreReadyPending.GetValue($context)) `
    "a rejected request does not bypass readiness confirmation"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 1) `
    "a rejected request does not cancel discovery recovery"

$mirrorActive.SetValue($context, 1)
$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$pinBefore = [DateTime]::UtcNow
$observe.Invoke(
    $context,
    [object[]]@(42,
        '*** CLIENT MUST NOW ENTER PIN = "1234" AS AIRPLAY PASSWORD')) |
    Out-Null
Assert-True ([bool]$coreReadyPending.GetValue($context) -eq $false) `
    "PIN-entry progress resolves readiness without waiting for DNS-SD checks"
Assert-True ([int]$coreReadinessAttempts.GetValue($context) -eq 0) `
    "PIN-entry progress cancels readiness recovery"
Assert-True ([int]$coreReadinessPid.GetValue($context) -eq 0) `
    "PIN-entry progress clears the readiness recovery owner"
Assert-True ([int]$clientReadyPending.GetValue($context) -eq 1) `
    "PIN-entry progress queues the ready UI state for the monitor thread"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "PIN-entry progress cancels obsolete discovery recovery"
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "PIN-entry progress cancels the previous session's lost-client watchdog"
$pinGraceDue = [long]$clientGraceDue.GetValue($context)
Assert-True ($pinGraceDue -ge $pinBefore.AddSeconds(59).Ticks) `
    "PIN entry receives a usable authentication grace period"
Assert-True ($pinGraceDue -le [DateTime]::UtcNow.AddSeconds(61).Ticks) `
    "PIN authentication grace remains bounded"
Assert-True ([int]$mirrorActive.GetValue($context) -eq 1) `
    "PIN-entry progress does not manufacture a new mirroring start"
$observe.Invoke(
    $context,
    [object[]]@(42, "***ERROR lost connection with client")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "a late old-session fatal marker cannot re-arm during PIN grace"
Assert-True (-not [bool]$restartPending.GetValue($context)) `
    "a late old-session fatal marker cannot schedule a handshake restart"

$mirrorActive.SetValue($context, 0)
$sessionEndedPending.SetValue($context, 1)
$sessionEndedDue.SetValue($context, [DateTime]::UtcNow.AddMilliseconds(100).Ticks)
$idleRenewalUsed.SetValue($context, 1)
$discoveryRecoveryPending.SetValue($context, 1)
$discoveryRecoveryAttempts.SetValue($context, 1)
$discoveryRecoveryPid.SetValue($context, 42)
$discoveryRecoveryDue.SetValue(
    $context, [DateTime]::UtcNow.AddMilliseconds(100).Ticks)
$coreReadyPending.SetValue($context, $true)
$coreReadyChecks.SetValue($context, 8)
$coreReadinessAttempts.SetValue($context, 1)
$coreReadinessPid.SetValue($context, 42)
$clientReadyPending.SetValue($context, 0)
$requestBefore = [DateTime]::UtcNow
$observe.Invoke(
    $context,
    [object[]]@(42, "connection request from iPhone (iPhone14,8)")) |
    Out-Null
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 1) `
    "an AirPlay request keeps deferred settings maintenance pending"
$postponedDue = [long]$sessionEndedDue.GetValue($context)
Assert-True ($postponedDue -ge $requestBefore.AddSeconds(29).Ticks) `
    "an AirPlay request grants deferred settings a new grace period"
Assert-True ($postponedDue -le [DateTime]::UtcNow.AddSeconds(31).Ticks) `
    "the deferred settings grace period remains bounded"
$requestIdleDue = [long]$idleRenewalDue.GetValue($context)
Assert-True ($requestIdleDue -ge $requestBefore.AddMinutes(9).Ticks) `
    "an AirPlay request moves idle maintenance away from the handshake"
Assert-True ($requestIdleDue -le [DateTime]::UtcNow.AddMinutes(11).Ticks) `
    "the re-armed idle fallback remains bounded near ten minutes"
Assert-True ([int]$idleRenewalUsed.GetValue($context) -eq 0) `
    "an AirPlay request re-arms one idle fallback allowance"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "an AirPlay request cancels obsolete discovery recovery"
Assert-True ([int]$discoveryRecoveryPid.GetValue($context) -eq 0) `
    "an AirPlay request clears the discovery recovery owner"
Assert-True ([long]$discoveryRecoveryDue.GetValue($context) -eq 0) `
    "an AirPlay request clears the discovery recovery deadline"
Assert-True ([int]$discoveryRecoveryAttempts.GetValue($context) -eq 0) `
    "an AirPlay request restores the bounded discovery recovery allowance"
Assert-True (-not [bool]$coreReadyPending.GetValue($context)) `
    "an AirPlay request cancels pending readiness recovery"
Assert-True ([int]$coreReadyChecks.GetValue($context) -eq 0) `
    "an AirPlay request clears stale readiness checks"
Assert-True ([int]$coreReadinessAttempts.GetValue($context) -eq 0) `
    "an AirPlay request restores the readiness recovery allowance"
Assert-True ([int]$coreReadinessPid.GetValue($context) -eq 0) `
    "an AirPlay request clears the readiness recovery owner"
Assert-True ([int]$clientReadyPending.GetValue($context) -eq 1) `
    "an AirPlay request queues ready UI state on the monitor thread"
$requestGraceDue = [long]$clientGraceDue.GetValue($context)
Assert-True ($requestGraceDue -ge $requestBefore.AddSeconds(29).Ticks) `
    "post-auth client activity receives a connection grace period"
Assert-True ($requestGraceDue -le [DateTime]::UtcNow.AddSeconds(31).Ticks) `
    "post-auth client grace remains bounded"

$applySettingsRestart = $contextType.GetMethod(
    "ApplyOrDeferSettingsRestart", $instanceFlags)
$settingsRestartDeferred.SetValue($context, 0)
$sessionEndedPending.SetValue($context, 0)
$sessionEndedDue.SetValue($context, [long]0)
$applySettingsRestart.Invoke($context, [object[]]@()) | Out-Null
Assert-True ([int]$settingsRestartDeferred.GetValue($context) -eq 1) `
    "settings restart is deferred during client-activity grace"
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 1) `
    "deferred settings remain scheduled after handshake grace"
Assert-True ([long]$sessionEndedDue.GetValue($context) -ge $requestGraceDue) `
    "settings maintenance cannot interrupt the current handshake"

$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$discoveryRecoveryPending.SetValue($context, 1)
$discoveryRecoveryAttempts.SetValue($context, 1)
$discoveryRecoveryPid.SetValue($context, 42)
$discoveryRecoveryDue.SetValue(
    $context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$coreReadyPending.SetValue($context, $true)
$coreReadyChecks.SetValue($context, 8)
$coreReadinessAttempts.SetValue($context, 1)
$coreReadinessPid.SetValue($context, 42)
$clientReadyPending.SetValue($context, 0)
$physicalNetworkRestartDeferred.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror starting mirroring")) | Out-Null
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 0) `
    "actual mirroring start clears pending post-session maintenance"
Assert-True ([long]$sessionEndedDue.GetValue($context) -eq 0) `
    "actual mirroring start clears the post-session deadline"
Assert-True ([int]$settingsRestartDeferred.GetValue($context) -eq 1) `
    "actual mirroring start preserves the deferred settings change"
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "actual mirroring start atomically cancels the old lost-client watchdog"
Assert-True ([int]$recoveryPid.GetValue($context) -eq 0) `
    "actual mirroring start clears the old lost-client recovery owner"
Assert-True ([long]$recoveryDue.GetValue($context) -eq 0) `
    "actual mirroring start clears the old lost-client recovery deadline"
Assert-True ([int]$discoveryRecoveryPending.GetValue($context) -eq 0) `
    "actual mirroring start atomically cancels discovery recovery"
Assert-True ([int]$discoveryRecoveryPid.GetValue($context) -eq 0) `
    "actual mirroring start clears the discovery recovery owner"
Assert-True ([long]$discoveryRecoveryDue.GetValue($context) -eq 0) `
    "actual mirroring start clears the discovery recovery deadline"
Assert-True ([int]$discoveryRecoveryAttempts.GetValue($context) -eq 0) `
    "actual mirroring start restores the discovery recovery allowance"
Assert-True (-not [bool]$coreReadyPending.GetValue($context)) `
    "actual mirroring start cancels readiness recovery"
Assert-True ([int]$coreReadinessPid.GetValue($context) -eq 0) `
    "actual mirroring start clears the readiness owner"
Assert-True ([int]$clientReadyPending.GetValue($context) -eq 1) `
    "actual mirroring start queues the ready UI state"
Assert-True ([long]$clientGraceDue.GetValue($context) -eq 0) `
    "actual mirroring start replaces handshake grace with active-session state"
Assert-True ([int]$physicalNetworkRestartDeferred.GetValue($context) -eq 1) `
    "a deferred physical-network restart remains queued during mirroring"

$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror->running is no longer true")) |
    Out-Null
Assert-True ([int]$mirrorActive.GetValue($context) -eq 0) `
    "session end releases the active-stream maintenance guard"
Assert-True ([int]$physicalNetworkRestartDeferred.GetValue($context) -eq 1) `
    "session end leaves one physical-network restart for the monitor"
Assert-True (-not [bool]$deferDisruptive.Invoke(
        $null, [object[]]@($false, [long]0, [DateTime]::UtcNow.Ticks))) `
    "deferred network maintenance becomes eligible after session end"
$physicalNetworkRestartDeferred.SetValue($context, 0)
$sessionEndedPending.SetValue($context, 0)
$sessionEndedDue.SetValue($context, [long]0)
$settingsRestartDeferred.SetValue($context, 0)

$mirrorActive.SetValue($context, 1)
$settingsRestartDeferred.SetValue($context, 1)
$physicalNetworkRestartDeferred.SetValue($context, 1)
$clientGraceDue.SetValue($context, [long]0)
$staleEndRequestBefore = [DateTime]::UtcNow
$observe.Invoke(
    $context,
    [object[]]@(42, "connection request from reconnecting iPhone")) |
    Out-Null
$staleEndRequestGrace = [long]$clientGraceDue.GetValue($context)
Assert-True ($staleEndRequestGrace -ge
    $staleEndRequestBefore.AddSeconds(29).Ticks) `
    "a reconnect request establishes grace before old-session cleanup"
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror->running is no longer true")) |
    Out-Null
Assert-True ([int]$mirrorActive.GetValue($context) -eq 0) `
    "the stale end marker can close the old active-session state"
Assert-True ([long]$clientGraceDue.GetValue($context) -ge
    $staleEndRequestGrace) `
    "a stale end marker preserves the newer reconnect grace"
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 1) `
    "deferred settings remain pending after stale old-session cleanup"
Assert-True ([long]$sessionEndedDue.GetValue($context) -ge
    $staleEndRequestGrace) `
    "deferred settings cannot interrupt the newer reconnect handshake"
Assert-True ([int]$physicalNetworkRestartDeferred.GetValue($context) -eq 1) `
    "deferred network maintenance remains guarded by reconnect grace"
Assert-True ([bool]$deferDisruptive.Invoke(
        $null,
        [object[]]@(
            $false,
            [long]$clientGraceDue.GetValue($context),
            [DateTime]::UtcNow.Ticks))) `
    "automatic maintenance remains blocked between stale end and new start"
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror starting mirroring")) | Out-Null
Assert-True ([int]$mirrorActive.GetValue($context) -eq 1) `
    "the reconnecting stream starts after stale old-session cleanup"
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 0) `
    "new mirroring cancels stale post-session maintenance"
Assert-True ([long]$clientGraceDue.GetValue($context) -eq 0) `
    "new mirroring replaces reconnect grace with active-session state"
Assert-True ([int]$settingsRestartDeferred.GetValue($context) -eq 1) `
    "new mirroring preserves the user's deferred settings change"
Assert-True ([int]$physicalNetworkRestartDeferred.GetValue($context) -eq 1) `
    "new mirroring keeps deferred network maintenance queued"
$physicalNetworkRestartDeferred.SetValue($context, 0)
$sessionEndedPending.SetValue($context, 0)
$sessionEndedDue.SetValue($context, [long]0)
$settingsRestartDeferred.SetValue($context, 0)

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
