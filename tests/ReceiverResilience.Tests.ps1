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
$lostConnectionUiSource = [IO.File]::ReadAllText(
    (Join-Path $sourceRoot "UI\LostConnectionForm.cs"))
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
Assert-True ($source.Contains("EVENT_SYSTEM_MOVESIZESTART") -and
    $source.Contains("EVENT_SYSTEM_MOVESIZEEND") -and
    $source.Contains("SetWinEventHook") -and
    $source.Contains("UnhookWinEvent")) `
    "manual renderer resize completion uses a bounded WinEvent hook lifecycle"
Assert-True ($source.Contains("processId != rendererMoveSizeHookPid") -and
    $source.Contains("windowProcessId != (uint)processId")) `
    "renderer move/size events are restricted to the active native core"
Assert-True ($source.Contains("NativeMethods.IsIconic(window)") -and
    $source.Contains("NativeMethods.IsZoomed(window)")) `
    "automatic aspect fitting does not fight minimized or maximized state"
Assert-True ($source.Contains("DateTime.UtcNow.AddMilliseconds(150)") -and
    [regex]::Matches(
        $source, 'ApplyPendingManualRendererFit\s*\(').Count -eq 2) `
    "manual renderer fitting is queued briefly and consumed by supervision"
Assert-True ($source.Contains("autoFit = MakeCheckBox(") -and
    $source.Contains("FitStreamWindow(true)")) `
    "automatic aspect fitting retains a settings control and manual tray fallback"
Assert-True ($source.Contains("internal sealed class LostConnectionForm") -and
    $lostConnectionUiSource.Contains("titleLabel.Text =") -and
    $lostConnectionUiSource.Contains("detailLabel.Text =") -and
    $lostConnectionUiSource.Contains("closeButton.Text =")) `
    "fatal connection loss has a focused user-visible placeholder"
Assert-True ($source.Contains("CopyFromScreen(") -and
    -not $source.Contains("PrintWindow(")) `
    "the placeholder uses only a non-blocking foreground screen snapshot"
Assert-True ($source.Contains("GetForegroundWindow() == rendererWindow")) `
    "desktop capture cannot include a foreground window covering the renderer"
Assert-True ($lostConnectionUiSource.Contains("source.Width / 12") -and
    $lostConnectionUiSource.Contains("source.Height / 12") -and
    $lostConnectionUiSource.Contains(
        "InterpolationMode.HighQualityBicubic")) `
    "the captured frame is softened once in memory before display"
Assert-True (-not [regex]::IsMatch(
        $lostConnectionUiSource, '\.(?:Save|SaveAdd)\s*\(')) `
    "the lost-frame placeholder never writes its snapshot to disk"
$lostArmStart = $source.IndexOf("private void ArmLostConnectionRecovery")
$lostArmEnd = $source.IndexOf(
    "private void ResetCoreSessionTracking", $lostArmStart)
Assert-True ($lostArmStart -ge 0 -and $lostArmEnd -gt $lostArmStart) `
    "fatal-loss arming has a focused implementation boundary"
$lostArmSource = $source.Substring(
    $lostArmStart, $lostArmEnd - $lostArmStart)
Assert-True ($lostArmSource.Contains("QueueLostConnectionPlaceholder()") -and
    -not $lostArmSource.Contains("CopyFromScreen(") -and
    -not $lostArmSource.Contains("new LostConnectionForm")) `
    "the native output callback only queues placeholder UI work"
$placeholderCloseCallCount = [regex]::Matches(
    $source, 'CloseLostConnectionPlaceholder\s*\(\s*\)').Count
Assert-True ($placeholderCloseCallCount -ge 5) `
    "manual stop, disabled receiver startup, app exit, and UI close consume the placeholder"
$sessionResetStart = $source.IndexOf(
    "private void ResetCoreSessionTracking")
$sessionResetEnd = $source.IndexOf(
    "private void ResetIdleDiscoveryRenewalLimit", $sessionResetStart)
Assert-True ($sessionResetStart -ge 0 -and
    $sessionResetEnd -gt $sessionResetStart) `
    "core-session reset has a focused implementation boundary"
$sessionResetSource = $source.Substring(
    $sessionResetStart, $sessionResetEnd - $sessionResetStart)
Assert-True (-not $sessionResetSource.Contains(
        "LostConnectionPlaceholder")) `
    "a native core restart does not automatically dismiss the placeholder"
$moveSizeCallbackStart = $source.IndexOf(
    "private void OnRendererMoveSizeEvent")
$moveSizeCallbackEnd = $source.IndexOf(
    "private static bool ShouldQueueManualRendererFit",
    $moveSizeCallbackStart)
Assert-True ($moveSizeCallbackStart -ge 0 -and
    $moveSizeCallbackEnd -gt $moveSizeCallbackStart) `
    "renderer move/size callback has a focused implementation boundary"
$moveSizeCallbackSource = $source.Substring(
    $moveSizeCallbackStart,
    $moveSizeCallbackEnd - $moveSizeCallbackStart)
Assert-True (-not $moveSizeCallbackSource.Contains("FitRendererWindow") -and
    -not $moveSizeCallbackSource.Contains("SetWindowPos") -and
    -not $moveSizeCallbackSource.Contains("settings.Save") -and
    -not $moveSizeCallbackSource.Contains("GetWindowRect")) `
    "the WinEvent callback only records and queues instead of resizing or writing settings"
$placementQueueIndex = $moveSizeCallbackSource.IndexOf(
    "QueueStreamWindowPlacementSave")
$fitDecisionIndex = $moveSizeCallbackSource.IndexOf(
    "ShouldQueueManualRendererFit")
Assert-True ($placementQueueIndex -ge 0 -and
    $fitDecisionIndex -gt $placementQueueIndex) `
    "move-only and automatic-fit-disabled completion still queues placement persistence"
$placementQueueCallCount = [regex]::Matches(
    $source, 'QueueStreamWindowPlacementSave\s*\(').Count
Assert-True ($placementQueueCallCount -ge 7 -and
    $source.Contains("SavePendingStreamWindowPlacement(window)")) `
    "interactive and programmatic fits persist through the supervision timer"
$placementFlushCount = [regex]::Matches(
    $source, 'FlushStreamWindowPlacementBeforeCoreStop\s*\(\s*\)').Count
Assert-True ($placementFlushCount -ge 3) `
    "manual stop and asynchronous restart flush placement before detaching the core"
Assert-True ($source.Contains("settings.StreamWindowLeft = oldLeft") -and
    $source.Contains("settings.StreamWindowDpi = oldDpi") -and
    $source.Contains("streamWindowPlacementSaveFailures < 2")) `
    "a failed atomic placement save restores memory and receives a bounded retry"
$restoredAreaFitCount = [regex]::Matches(
    $source,
    'FitRendererWindow\(\s*window, automaticVideoSize,\s*restoredStreamWindowPlacementWindow == window\)').Count
Assert-True ($restoredAreaFitCount -eq 2) `
    "initial and exact-size refinement preserve restored center and client area"

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

$decideLostPlaceholder = $contextType.GetMethod(
    "DecideLostConnectionPlaceholderAction", $staticFlags)
Assert-True ($null -ne $decideLostPlaceholder) `
    "lost-frame placeholder exposes a deterministic state transition"
Assert-True ($decideLostPlaceholder.Invoke(
        $null, [object[]]@($true, $false, $false)).ToString() -eq "Show") `
    "a first fatal-loss request opens the placeholder"
Assert-True ($decideLostPlaceholder.Invoke(
        $null, [object[]]@($true, $false, $true)).ToString() -eq "None") `
    "a repeated request cannot duplicate an existing placeholder"
Assert-True ($decideLostPlaceholder.Invoke(
        $null, [object[]]@($true, $true, $false)).ToString() -eq "Close") `
    "a reconnect or shutdown close request wins over a stale show request"
$clampLostPlaceholderBounds = $contextType.GetMethod(
    "ClampLostConnectionPlaceholderBounds", $staticFlags)
Assert-True ($null -ne $clampLostPlaceholderBounds) `
    "lost-frame placement exposes a deterministic screen-clamp path"
$placeholderWorkArea = [Drawing.Rectangle]::new(0, 0, 1920, 1080)
$rememberedRendererBounds = [Drawing.Rectangle]::new(140, 90, 520, 920)
Assert-True ([Drawing.Rectangle]$clampLostPlaceholderBounds.Invoke(
        $null, [object[]]@(
            $rememberedRendererBounds, $placeholderWorkArea)) -eq
        $rememberedRendererBounds) `
    "an on-screen placeholder reuses the last renderer bounds"
$disconnectedMonitorBounds = [Drawing.Rectangle]::new(
    2400, 1200, 520, 920)
$clampedRendererBounds = [Drawing.Rectangle]$clampLostPlaceholderBounds.Invoke(
    $null, [object[]]@(
        $disconnectedMonitorBounds, $placeholderWorkArea))
Assert-True ($clampedRendererBounds -eq
        [Drawing.Rectangle]::new(1400, 160, 520, 920)) `
    "a remembered window from a disconnected monitor returns fully on-screen"

$shouldQueueManualFit = $contextType.GetMethod(
    "ShouldQueueManualRendererFit", $staticFlags)
Assert-True ($null -ne $shouldQueueManualFit) `
    "manual renderer resize classification is independently testable"
$startClientSize = [Drawing.Size]::new(460, 1000)
Assert-True (-not [bool]$shouldQueueManualFit.Invoke(
        $null, [object[]]@($true, $startClientSize,
            [Drawing.Size]::new(460, 1000)))) `
    "moving a renderer without changing its client size does not queue a fit"
Assert-True (-not [bool]$shouldQueueManualFit.Invoke(
        $null, [object[]]@($true, $startClientSize,
            [Drawing.Size]::new(464, 996)))) `
    "four-pixel window metric noise does not queue a fit"
Assert-True ([bool]$shouldQueueManualFit.Invoke(
        $null, [object[]]@($true, $startClientSize,
            [Drawing.Size]::new(465, 1000)))) `
    "a manual client resize larger than the tolerance queues a fit"
Assert-True (-not [bool]$shouldQueueManualFit.Invoke(
        $null, [object[]]@($false, $startClientSize,
            [Drawing.Size]::new(700, 1000)))) `
    "an explicit disabled automatic-fit setting remains authoritative"

$clampSavedStreamWindowBounds = $contextType.GetMethod(
    "ClampSavedStreamWindowBounds", $staticFlags)
Assert-True ($null -ne $clampSavedStreamWindowBounds) `
    "saved renderer bounds normalization is independently testable"
function Invoke-ClampSavedRendererBounds(
    [Drawing.Rectangle]$Saved,
    [Drawing.Rectangle]$Current,
    [Drawing.Rectangle[]]$WorkAreas,
    [int]$SavedDpi,
    [int]$TargetDpi) {
    $arguments = [Array]::CreateInstance([object], 5)
    $arguments.SetValue($Saved, 0)
    $arguments.SetValue($Current, 1)
    $arguments.SetValue($WorkAreas, 2)
    $arguments.SetValue($SavedDpi, 3)
    $arguments.SetValue($TargetDpi, 4)
    return [Drawing.Rectangle]$clampSavedStreamWindowBounds.Invoke(
        $null, $arguments)
}
$dualMonitorAreas = [Drawing.Rectangle[]]@(
    [Drawing.Rectangle]::new(0, 0, 1920, 1040),
    [Drawing.Rectangle]::new(1920, 0, 1920, 1040))
$secondaryPlacement = Invoke-ClampSavedRendererBounds `
    ([Drawing.Rectangle]::new(2100, 40, 600, 900)) `
    ([Drawing.Rectangle]::new(100, 100, 460, 1000)) `
    $dualMonitorAreas 96 96
Assert-True ($secondaryPlacement -eq
    [Drawing.Rectangle]::new(2100, 40, 600, 900)) `
    "a placement on an available secondary monitor is retained"
$primaryArea = [Drawing.Rectangle[]]@(
    [Drawing.Rectangle]::new(0, 0, 1920, 1040))
$disconnectedPlacement = Invoke-ClampSavedRendererBounds `
    ([Drawing.Rectangle]::new(2500, 200, 600, 800)) `
    ([Drawing.Rectangle]::new(100, 100, 460, 1000)) `
    $primaryArea 96 96
Assert-True ($primaryArea[0].Contains($disconnectedPlacement)) `
    "a placement from a disconnected monitor is clamped into the current work area"
$dpiScaledPlacement = Invoke-ClampSavedRendererBounds `
    ([Drawing.Rectangle]::new(100, 100, 400, 600)) `
    ([Drawing.Rectangle]::new(100, 100, 460, 1000)) `
    $primaryArea 96 144
Assert-True ($dpiScaledPlacement.Width -eq 600 -and
    $dpiScaledPlacement.Height -eq 900) `
    "saved renderer size follows a target monitor DPI change"
$minimumVisiblePlacement = Invoke-ClampSavedRendererBounds `
    ([Drawing.Rectangle]::new(100, 100, 100, 100)) `
    ([Drawing.Rectangle]::new(100, 100, 460, 1000)) `
    $primaryArea 144 96
Assert-True ($minimumVisiblePlacement.Width -ge 100 -and
    $minimumVisiblePlacement.Height -ge 100 -and
    $primaryArea[0].Contains($minimumVisiblePlacement)) `
    "DPI restoration keeps a sensible visible minimum including the title bar"
$oversizedPlacement = Invoke-ClampSavedRendererBounds `
    ([Drawing.Rectangle]::new(-100, -100, 4000, 3000)) `
    ([Drawing.Rectangle]::new(100, 100, 460, 1000)) `
    $primaryArea 96 96
Assert-True ($primaryArea[0].Contains($oversizedPlacement)) `
    "an oversized saved placement is uniformly constrained to the work area"

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
Assert-True ([int]$settingsProbe.SettingsVersion -eq 10) `
    "new settings profiles use the renderer-placement schema"
Assert-True ([bool]$settingsProbe.AutoFitWindow) `
    "automatic renderer aspect fitting is enabled for a new settings profile"
$settingsProbe.AutoFitWindow = $false
$normalizeSettings.Invoke($settingsProbe, [object[]]@()) | Out-Null
Assert-True (-not [bool]$settingsProbe.AutoFitWindow) `
    "settings normalization preserves an explicit automatic-fit opt-out"
$hasValidStreamWindowPlacement = $settingsType.GetMethod(
    "HasValidStreamWindowPlacement", $instanceFlags)
Assert-True ($null -ne $hasValidStreamWindowPlacement) `
    "persisted renderer placement validation exists"
$settingsProbe.StreamWindowLeft = -1200
$settingsProbe.StreamWindowTop = 80
$settingsProbe.StreamWindowWidth = 620
$settingsProbe.StreamWindowHeight = 920
$settingsProbe.StreamWindowDpi = 144
Assert-True ([bool]$hasValidStreamWindowPlacement.Invoke(
        $settingsProbe, [object[]]@())) `
    "a valid mixed-monitor renderer placement survives normalization"
$settingsCopy = $settingsType.GetMethod("Copy", $instanceFlags).Invoke(
    $settingsProbe, [object[]]@())
Assert-True ($settingsCopy.StreamWindowLeft -eq -1200 -and
    $settingsCopy.StreamWindowWidth -eq 620 -and
    $settingsCopy.StreamWindowDpi -eq 144) `
    "ordinary settings edits preserve the saved stream-window placement"
$settingsProbe.StreamWindowDpi = 0
$normalizeSettings.Invoke($settingsProbe, [object[]]@()) | Out-Null
Assert-True ($settingsProbe.StreamWindowWidth -eq 0 -and
    $settingsProbe.StreamWindowHeight -eq 0) `
    "an incomplete persisted renderer placement is cleared as one unit"
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
    $atomicLines.SetValue("SettingsVersion=10", 0)
    $atomicLines.SetValue("PairingMode=none", 1)
    $atomicArguments = [Array]::CreateInstance([object], 2)
    $atomicArguments.SetValue([string]$atomicPath, 0)
    $atomicArguments.SetValue($atomicLines, 1)
    $atomicWriter.Invoke($null, $atomicArguments) | Out-Null
    $atomicText = [IO.File]::ReadAllText($atomicPath)
    Assert-True ($atomicText.Contains("SettingsVersion=10") -and
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
$streamWindowPlacementSync = Field "streamWindowPlacementSync"
$pendingVideoSize = Field "pendingVideoSize"
$pendingVideoSizeDueUtc = Field "pendingVideoSizeDueUtc"
$currentVideoSize = Field "currentVideoSize"
$earlyDeviceFrameVideoSize = Field "earlyDeviceFrameVideoSize"
$deviceFrameVideoSize = Field "deviceFrameVideoSize"
$lastSuppressedVideoSize = Field "lastSuppressedVideoSize"
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
$placeholderShowPending = Field "lostConnectionPlaceholderShowPending"
$placeholderClosePending = Field "lostConnectionPlaceholderClosePending"

$maintenanceSync.SetValue($context, (New-Object object))
$videoSizeSync.SetValue($context, (New-Object object))
$streamWindowPlacementSync.SetValue($context, (New-Object object))
$activePid.SetValue($context, 42)
$mirrorActive.SetValue($context, 1)
$sameDeviceAspect = $contextType.GetMethod(
    "HaveEquivalentDeviceFrameAspect", $staticFlags)
$likelyModernIPhoneFrame = $contextType.GetMethod(
    "IsLikelyModernIPhoneDeviceFrame", $staticFlags)
$resolveAutomaticVideo = $contextType.GetMethod(
    "ResolveAutomaticVideoSize", $instanceFlags)
$resolveManualFitVideo = $contextType.GetMethod(
    "ResolveManualFitVideoSize", $instanceFlags)
Assert-True ($null -ne $sameDeviceAspect -and
    $null -ne $likelyModernIPhoneFrame -and
    $null -ne $resolveAutomaticVideo -and
    $null -ne $resolveManualFitVideo) `
    "renderer orientation uses a session device-frame baseline"

$portraitFrame = [Drawing.Size]::new(998, 2160)
$landscapeFrame = [Drawing.Size]::new(3840, 1776)
$presentationCanvas = [Drawing.Size]::new(3840, 2160)
$unknownCanvas = [Drawing.Size]::new(1200, 1000)
$sixteenByNinePortrait = [Drawing.Size]::new(1080, 1920)
$sixteenByNineLandscape = [Drawing.Size]::new(1920, 1080)
Assert-True ([bool]$sameDeviceAspect.Invoke(
        $null, [object[]]@($portraitFrame, $landscapeFrame))) `
    "portrait and physical landscape frames share the device aspect"
Assert-True (-not [bool]$sameDeviceAspect.Invoke(
        $null, [object[]]@($portraitFrame, $presentationCanvas))) `
    "the Photos presentation canvas does not impersonate device rotation"
Assert-True ([bool]$likelyModernIPhoneFrame.Invoke(
        $null, [object[]]@($portraitFrame)) -and
    [bool]$likelyModernIPhoneFrame.Invoke(
        $null, [object[]]@($landscapeFrame))) `
    "phone-shaped portrait and landscape markers qualify as early device frames"
Assert-True (-not [bool]$likelyModernIPhoneFrame.Invoke(
        $null, [object[]]@($presentationCanvas)) -and
    -not [bool]$likelyModernIPhoneFrame.Invoke(
        $null, [object[]]@($sixteenByNinePortrait))) `
    "a generic 16:9 canvas is never guessed to be the early iPhone baseline"

function Resolve-AutomaticVideoSize([Drawing.Size]$VideoSize) {
    $arguments = [object[]]@($VideoSize, $false, $false)
    $resolved = [Drawing.Size]$resolveAutomaticVideo.Invoke(
        $context, $arguments)
    return [pscustomobject]@{
        Size = $resolved
        OrientationAuthoritative = [bool]$arguments[1]
        SuppressionChanged = [bool]$arguments[2]
    }
}

$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$unlearnedCanvasResult = Resolve-AutomaticVideoSize $presentationCanvas
Assert-True ($unlearnedCanvasResult.OrientationAuthoritative -and
    $unlearnedCanvasResult.Size -eq $presentationCanvas -and
    -not $unlearnedCanvasResult.SuppressionChanged) `
    "the first exact frame seeds the session even when media already uses a 16:9 canvas"
$directMediaPortrait = Resolve-AutomaticVideoSize $portraitFrame
Assert-True (-not $directMediaPortrait.OrientationAuthoritative -and
    $directMediaPortrait.Size -eq $presentationCanvas) `
    "a direct-media-first session documents the conservative wrong-baseline limitation"
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$portraitResult = Resolve-AutomaticVideoSize $portraitFrame
Assert-True ($portraitResult.OrientationAuthoritative -and
    $portraitResult.Size -eq $portraitFrame -and
    -not $portraitResult.SuppressionChanged) `
    "the first exact frame establishes session orientation"
$photoResult = Resolve-AutomaticVideoSize $presentationCanvas
Assert-True (-not $photoResult.OrientationAuthoritative -and
    $photoResult.Size -eq $portraitFrame -and
    $photoResult.SuppressionChanged) `
    "998x2160 to 3840x2160 retains portrait device orientation"
$repeatedPhotoResult = Resolve-AutomaticVideoSize $presentationCanvas
Assert-True (-not $repeatedPhotoResult.OrientationAuthoritative -and
    $repeatedPhotoResult.Size -eq $portraitFrame -and
    -not $repeatedPhotoResult.SuppressionChanged) `
    "a stable presentation canvas does not repeat its suppression notice"
$manualPhotoFit = [Drawing.Size]$resolveManualFitVideo.Invoke(
    $context, [object[]]@($presentationCanvas))
Assert-True ($manualPhotoFit -eq $portraitFrame) `
    "manual tray fitting uses the learned portrait frame instead of the raw Photos canvas"
$portraitReturnResult = Resolve-AutomaticVideoSize $portraitFrame
Assert-True ($portraitReturnResult.OrientationAuthoritative -and
    $portraitReturnResult.Size -eq $portraitFrame) `
    "returning from Photos restores authoritative portrait input"

$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
Resolve-AutomaticVideoSize $portraitFrame | Out-Null
$landscapeResult = Resolve-AutomaticVideoSize $landscapeFrame
Assert-True ($landscapeResult.OrientationAuthoritative -and
    $landscapeResult.Size -eq $landscapeFrame) `
    "998x2160 to 3840x1776 accepts a real landscape rotation"
$physicalPortraitResult = Resolve-AutomaticVideoSize $portraitFrame
Assert-True ($physicalPortraitResult.OrientationAuthoritative -and
    $physicalPortraitResult.Size -eq $portraitFrame) `
    "the physical rotation sequence can return to portrait"
$unknownResult = Resolve-AutomaticVideoSize $unknownCanvas
Assert-True (-not $unknownResult.OrientationAuthoritative -and
    $unknownResult.Size -eq $portraitFrame) `
    "an unknown non-device ratio conservatively retains current orientation"

$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$sixteenByNinePortraitResult =
    Resolve-AutomaticVideoSize $sixteenByNinePortrait
$sixteenByNineLandscapeResult =
    Resolve-AutomaticVideoSize $sixteenByNineLandscape
Assert-True ($sixteenByNinePortraitResult.OrientationAuthoritative -and
    $sixteenByNinePortraitResult.Size -eq $sixteenByNinePortrait -and
    $sixteenByNineLandscapeResult.OrientationAuthoritative -and
    $sixteenByNineLandscapeResult.Size -eq $sixteenByNineLandscape) `
    "a physical 16:9 iPhone can rotate after its first exact frame seeds the baseline"

$currentVideoSize.SetValue($context, $presentationCanvas)
Resolve-AutomaticVideoSize $presentationCanvas | Out-Null
Assert-True ([Drawing.Size]$currentVideoSize.GetValue($context) -eq
    $presentationCanvas) `
    "orientation classification preserves the raw stream size for diagnostics and manual fitting"
$currentVideoSize.SetValue($context, [Drawing.Size]::Empty)
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)

$observe = $contextType.GetMethod("ObserveCoreOutput", $instanceFlags)
Assert-True ($null -ne $observe) "core-output observer exists"
$getStableVideoSize = $contextType.GetMethod(
    "GetStableVideoSize", $instanceFlags)
Assert-True ($null -ne $getStableVideoSize) `
    "video-size debounce exposes a deterministic stable-frame boundary"

# Recorded Photos sequence: 998x2160 was followed by the app's 3840x2160
# presentation canvas about 130 ms later, before the 350 ms debounce elapsed.
$pendingVideoSize.SetValue($context, [Drawing.Size]::Empty)
$pendingVideoSizeDueUtc.SetValue($context, [DateTime]::MinValue)
$currentVideoSize.SetValue($context, [Drawing.Size]::Empty)
$earlyDeviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_SIZE source=998x2160 encoded=998x2160")) |
    Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    $portraitFrame) `
    "the first raw phone-shaped marker is retained before debounce"
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_SIZE source=3840x2160 encoded=3840x2160")) |
    Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    $portraitFrame -and
    [Drawing.Size]$pendingVideoSize.GetValue($context) -eq
        $presentationCanvas) `
    "the later Photos canvas cannot overwrite the early device-frame candidate"
$pendingVideoSizeDueUtc.SetValue(
    $context, [DateTime]::UtcNow.AddMilliseconds(-1))
$stableArguments = [object[]]@(0)
$recordedStableCanvas = [Drawing.Size]$getStableVideoSize.Invoke(
    $context, $stableArguments)
$recordedPhotosResult = Resolve-AutomaticVideoSize $recordedStableCanvas
Assert-True ($recordedStableCanvas -eq $presentationCanvas -and
    -not $recordedPhotosResult.OrientationAuthoritative -and
    $recordedPhotosResult.Size -eq $portraitFrame -and
    $recordedPhotosResult.SuppressionChanged) `
    "the recorded direct-in-Photos sequence keeps the portrait window baseline"

$pendingVideoSize.SetValue($context, [Drawing.Size]::Empty)
$pendingVideoSizeDueUtc.SetValue($context, [DateTime]::MinValue)
$currentVideoSize.SetValue($context, [Drawing.Size]::Empty)
$earlyDeviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_SIZE source=3840x2160 encoded=3840x2160")) |
    Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty) `
    "a first raw 16:9 canvas is not blindly promoted to an iPhone candidate"
$pendingVideoSize.SetValue($context, [Drawing.Size]::Empty)
$pendingVideoSizeDueUtc.SetValue($context, [DateTime]::MinValue)

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
$consumeLostRecovery = $contextType.GetMethod(
    "ConsumeDueLostConnectionRecoveryLocked", $instanceFlags)
Assert-True ($null -ne $consumeLostRecovery) `
    "lost-client recovery exposes a focused one-shot state transition"
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
$placeholderShowPending.SetValue($context, 0)
$placeholderClosePending.SetValue($context, 0)
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
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 0) `
    "a client-feedback delay warning does not show a lost-frame placeholder"

$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror->running is no longer true")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "a clean mirror shutdown does not arm abnormal-loss recovery"
Assert-True (-not [bool]$restartPending.GetValue($context)) `
    "a clean mirror shutdown does not schedule a receiver restart"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 0) `
    "a clean mirror shutdown does not show a lost-frame placeholder"

$mirrorActive.SetValue($context, 1)

$before = [DateTime]::UtcNow.Ticks
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror error in recv: 10054")) | Out-Null
$armedDue = [long]$recoveryDue.GetValue($context)
Assert-True ([int]$recoveryPending.GetValue($context) -eq 1) `
    "fatal mirror recv error arms recovery"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 1) `
    "fatal mirror recv error queues the lost-frame placeholder"
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
Assert-True ([int]$recoveryPending.GetValue($context) -eq 1) `
    "quick native cleanup preserves abnormal-loss recovery"
Assert-True ([int]$recoveryPid.GetValue($context) -eq 42) `
    "quick native cleanup preserves the abnormal-loss owner"
Assert-True ([long]$recoveryDue.GetValue($context) -eq $armedDue) `
    "quick native cleanup preserves the bounded recovery deadline"
Assert-True ([int]$mirrorActive.GetValue($context) -eq 0) `
    "abnormal mirror cleanup clears the active-session flag"
Assert-True ([int]$sessionEndedPending.GetValue($context) -eq 0) `
    "abnormal mirror cleanup does not use normal post-session maintenance"
Assert-True (-not [bool]$restartPending.GetValue($context)) `
    "abnormal mirror cleanup waits for its bounded recovery deadline"
$idleDue = [long]$idleRenewalDue.GetValue($context)
Assert-True ($idleDue -ge [DateTime]::UtcNow.AddMinutes(9).Ticks) `
    "abnormal mirror cleanup preserves the idle-discovery fallback"
Assert-True ($idleDue -le [DateTime]::UtcNow.AddMinutes(11).Ticks) `
    "idle-discovery fallback remains bounded near ten minutes"

$observe.Invoke(
    $context,
    [object[]]@(42, "connection request from reconnecting iPhone")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "a reconnect request cancels abnormal-loss discovery renewal"
Assert-True ([int]$recoveryPid.GetValue($context) -eq 0) `
    "a reconnect request clears the abnormal-loss owner"
Assert-True ([long]$recoveryDue.GetValue($context) -eq 0) `
    "a reconnect request clears the abnormal-loss deadline"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$placeholderClosePending.GetValue($context) -eq 0) `
    "a reconnect handshake keeps the placeholder until mirroring really starts"

$clientGraceDue.SetValue($context, [long]0)
$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$renewAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($renewAction -eq "RenewDiscovery") `
    "an ended abnormal session selects one discovery renewal"
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0 -and
    [int]$recoveryPid.GetValue($context) -eq 0 -and
    [long]$recoveryDue.GetValue($context) -eq 0) `
    "consuming discovery renewal clears all one-shot recovery state"
$secondRenewAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($secondRenewAction -eq "None") `
    "the same abnormal loss cannot renew discovery twice"

$mirrorActive.SetValue($context, 1)
$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$stalledAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($stalledAction -eq "RestartStalledSession") `
    "an active session at the deadline keeps stalled-session recovery"
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "stalled-session recovery is also consumed exactly once"
$mirrorActive.SetValue($context, 0)

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
$earlyDeviceFrameVideoSize.SetValue($context, $portraitFrame)
$deviceFrameVideoSize.SetValue($context, $landscapeFrame)
$lastSuppressedVideoSize.SetValue($context, $presentationCanvas)
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror starting mirroring")) | Out-Null
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 0 -and
    [int]$placeholderClosePending.GetValue($context) -eq 1) `
    "a new mirroring start dismisses the lost-frame placeholder"
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$deviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$lastSuppressedVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty) `
    "a new mirroring session forgets the previous device aspect and presentation canvas"
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

$resetCoreSession = $contextType.GetMethod(
    "ResetCoreSessionTracking", $instanceFlags)
Assert-True ($null -ne $resetCoreSession) `
    "core shutdown exposes a complete session-state reset"
$earlyDeviceFrameVideoSize.SetValue($context, $portraitFrame)
$deviceFrameVideoSize.SetValue($context, $landscapeFrame)
$lastSuppressedVideoSize.SetValue($context, $presentationCanvas)
$resetCoreSession.Invoke($context, [object[]]@($false)) | Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$deviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$lastSuppressedVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty) `
    "core reset clears learned device orientation and suppression state"

Write-Host "Receiver resilience checks passed."
