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
$nativePatchPath = Join-Path $projectRoot `
    "native-core\libuxplay-aeromirror.patch"
Assert-True (Test-Path -LiteralPath $nativePatchPath) `
    "pinned libuxplay patch exists"
$nativePatchSource = [IO.File]::ReadAllText($nativePatchPath)
$upstreamLockPath = Join-Path $projectRoot "UPSTREAM.lock"
$nativeProvenancePath = Join-Path $projectRoot `
    "native-core\source-provenance.json"
$wrapperPatchPath = Join-Path $projectRoot `
    "native-core\uxplay-windows-headless.patch"
Assert-True (Test-Path -LiteralPath $upstreamLockPath) `
    "the pinned runtime version contract exists"
Assert-True (Test-Path -LiteralPath $nativeProvenancePath) `
    "the native source provenance contract exists"
Assert-True (Test-Path -LiteralPath $wrapperPatchPath) `
    "the pinned wrapper patch exists"
$upstreamLock = [IO.File]::ReadAllText($upstreamLockPath)
$nativeProvenance = Get-Content -LiteralPath $nativeProvenancePath `
    -Raw -Encoding UTF8 | ConvertFrom-Json
$wrapperPatchSource = [IO.File]::ReadAllText($wrapperPatchPath)
$runtimeGStreamerVersionMatch = [regex]::Match(
    $upstreamLock, '(?m)^runtime\.gstreamer=([0-9]+\.[0-9]+\.[0-9]+)$')
$buildGStreamerVersionMatch = [regex]::Match(
    $upstreamLock, '(?m)^build\.gstreamer=([0-9]+\.[0-9]+\.[0-9]+)$')
Assert-True ($runtimeGStreamerVersionMatch.Success -and
    $buildGStreamerVersionMatch.Success -and
    $runtimeGStreamerVersionMatch.Groups[1].Value -eq
        [string]$nativeProvenance.runtimeGStreamerVersion -and
    $buildGStreamerVersionMatch.Groups[1].Value -eq
        [string]$nativeProvenance.buildGStreamerVersion -and
    [version]$nativeProvenance.runtimeGStreamerVersion -ge
        [version]"1.28.0" -and
    $nativeProvenance.runtimeGStreamerCoreSha256 -match '^[0-9a-f]{64}$' -and
    $nativeProvenance.runtimeWasapi2PluginSha256 -match '^[0-9a-f]{64}$' -and
    $nativeProvenance.runtimeWasapi2RequiredProperty -eq
        "continue-on-error") `
    "redistributed and build-time GStreamer contracts are distinct and pinned"
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
Assert-True ($source.Contains('parts.Add("-reset 15")')) `
    "UxPlay receives its upstream fifteen-second lost-client reset bound"
$systemResetIndex = $source.IndexOf('parts.Add("-reset 15")')
$advancedArgumentsIndex = $source.IndexOf(
    'parts.Add(settings.AdvancedArguments.Trim())')
Assert-True ($systemResetIndex -lt $advancedArgumentsIndex) `
    "advanced UxPlay arguments can override the system reset bound"
$managedAudioSinkIndex = $source.IndexOf(
    '"wasapi2sink continue-on-error=true"')
Assert-True ($managedAudioSinkIndex -ge 0 -and
    $managedAudioSinkIndex -lt $advancedArgumentsIndex) `
    "the resilient Windows audio sink is applied before advanced overrides"
Assert-True (-not $source.Contains('parts.Add("-nohold")')) `
    "the receiver does not allow a new client to preempt an active session"
Assert-True (-not $source.Contains('parts.Add("-p ') -and
    $source.Contains("AEROMIRROR_HTTP_READY") -and
    $source.Contains("AEROMIRROR_HTTP_FAILED")) `
    "the managed receiver verifies native HTTP lifecycle markers without pinning a speculative fixed port"
Assert-True ($nativePatchSource.Contains(
        'AEROMIRROR_HTTP_READY stage=initial port=%u') -and
    $nativePatchSource.Contains(
        'AEROMIRROR_HTTP_READY stage=reset port=%u') -and
    $nativePatchSource.Contains(
        'AEROMIRROR_HTTP_FAILED stage=reset expected_port=%u')) `
    "the pinned native patch checks initial/reset HTTP binding"
$teardownHunk = [regex]::Match(
    $nativePatchSource,
    '(?ms)^@@ -1265.*?(?=^diff --git |\z)')
Assert-True ($teardownHunk.Success -and
    $teardownHunk.Value.Contains(
        'AEROMIRROR_TEARDOWN audio=%d video=%d disconnect=client-managed') -and
    -not $teardownHunk.Value.Contains(
        'http_response_set_disconnect(response, 1);')) `
    "type-specific TEARDOWN does not force an immediate server-side disconnect"
Assert-True ($wrapperPatchSource.Contains(
        'if (m_headless || !m_argumentOverride.isEmpty())') -and
    $wrapperPatchSource.Contains(
        'AEROMIRROR_ARGUMENTS_PASSTHROUGH mode=external')) `
    "the headless wrapper preserves externally supplied renderer arguments"
Assert-True ($nativePatchSource.Contains(
        'AEROMIRROR_MIRROR_ONLY_FEATURES_READY') -and
    $nativePatchSource.Contains(
        'dnssd_set_airplay_features(dnssd,  1, 0)') -and
    $nativePatchSource.Contains(
        'dnssd_set_airplay_features(dnssd,  5, 0)') -and
    $nativePatchSource.Contains(
        'dnssd_set_airplay_features(dnssd, 13, 0)') -and
    $nativePatchSource.Contains(
        'plist_new_uint(0x25D)')) `
    "the native receiver clears only unsupported photo, slideshow, and photo-preload declarations"
Assert-True ($source.Contains('parts.Add("-vsync no")') -and
    -not $source.Contains('parts.Add("-al 0.05")')) `
    "the interactive profile disables timestamp scheduling without the old aggressive audio buffer"
Assert-True ($source.Contains('parts.Add("-vd d3d11h264dec")') -and
    $source.Contains('parts.Add("-vs d3d11videosink")') -and
    $source.Contains('parts.Add("-vd d3d12h264dec")') -and
    $source.Contains('parts.Add("-vs d3d12videosink")')) `
    "an explicit Direct3D choice pins both decoder and sink for a valid compatibility test"
$d3d11DecoderIndex = $source.IndexOf(
    'parts.Add("-vd d3d11h264dec")')
$d3d11SinkIndex = $source.IndexOf(
    'parts.Add("-vs d3d11videosink")')
$d3d12DecoderIndex = $source.IndexOf(
    'parts.Add("-vd d3d12h264dec")')
$d3d12SinkIndex = $source.IndexOf(
    'parts.Add("-vs d3d12videosink")')
Assert-True ($d3d11DecoderIndex -lt $advancedArgumentsIndex -and
    $d3d11SinkIndex -lt $advancedArgumentsIndex -and
    $d3d12DecoderIndex -lt $advancedArgumentsIndex -and
    $d3d12SinkIndex -lt $advancedArgumentsIndex) `
    "advanced UxPlay arguments can override the managed renderer compatibility choice"
$automaticRendererOptionCount = [regex]::Matches(
    $source, 'NamedValue\(\s*"[^"]*"\s*,\s*"auto"\s*\)').Count
$recommendedD3D11OptionCount = [regex]::Matches(
    $source,
    'NamedValue\(\s*"Direct3D 11[^"]*"\s*,\s*"d3d11"\s*\)').Count
Assert-True ($automaticRendererOptionCount -eq 0 -and
    $recommendedD3D11OptionCount -eq 1) `
    "the settings UI recommends the pinned Direct3D 11 pipeline instead of automatic D3D12 selection"
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
    $source.Contains("EVENT_OBJECT_SHOW") -and
    $source.Contains("SetWinEventHook") -and
    $source.Contains("UnhookWinEvent")) `
    "renderer placement and resize completion use bounded WinEvent hook lifecycles"
Assert-True ($source.Contains("processId != rendererMoveSizeHookPid") -and
    $source.Contains("windowProcessId != (uint)processId")) `
    "renderer move/size events are restricted to the active native core"
Assert-True ($source.Contains("NativeMethods.IsIconic(window)") -and
    $source.Contains("NativeMethods.IsZoomed(window)")) `
    "automatic aspect fitting does not fight minimized or maximized state"
Assert-True ($source.Contains("pendingManualFitDueTicks") -and
    $source.Contains("DateTime.UtcNow.Ticks") -and
    [regex]::Matches(
        $source, 'ApplyPendingManualRendererFit\s*\(').Count -eq 2) `
    "manual renderer fitting is queued for the next supervision pass"
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
    "the placeholder uses only a non-blocking desktop screen snapshot"
Assert-True ($source.Contains("IsRendererWindowUnoccluded(") -and
    $source.Contains("NativeMethods.GW_HWNDPREV") -and
    $source.Contains("Rectangle.Intersect(")) `
    "desktop capture is rejected when any visible higher z-order window overlaps the renderer"
Assert-True ($source.Contains("TryGetRendererClientScreenBounds(") -and
    $source.Contains("NativeMethods.ClientToScreen(")) `
    "the continuity frame captures renderer client pixels rather than duplicating native chrome"
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
$mirroringStartStart = $source.IndexOf(
    "private bool HandleMirroringStartedMaintenance")
$mirroringStartEnd = $source.IndexOf(
    "private void ResolveCoreReadinessFromClientActivityLocked",
    $mirroringStartStart)
Assert-True ($mirroringStartStart -ge 0 -and
    $mirroringStartEnd -gt $mirroringStartStart) `
    "mirroring-start maintenance has a focused implementation boundary"
$mirroringStartSource = $source.Substring(
    $mirroringStartStart, $mirroringStartEnd - $mirroringStartStart)
Assert-True (-not $mirroringStartSource.Contains(
        "QueueLostConnectionPlaceholderClose")) `
    "a protocol start marker does not dismiss continuity before a renderer exists"
Assert-True ($source.Contains(
        "CompleteLostConnectionRendererHandoff();") -and
    $source.Contains("lostConnectionRendererHandoffPending") -and
    $source.Contains(
        "Mirroring renderer is visible and positioned; beginning") -and
    $source.Contains("Renderer handoff fade completed; closing")) `
    "continuity is dismissed only after supervision has positioned a visible renderer"
Assert-True ($source.Contains("ShowConnectionRecovered()") -and
    $source.Contains("ShowReconnectHint(settings.ReceiverName)") -and
    $source.Contains("ShowConnectionLost()") -and
    [regex]::Matches(
        $lostConnectionUiSource, 'titleLabel\.Text\s*=').Count -ge 2 -and
    [regex]::Matches(
        $lostConnectionUiSource, 'detailLabel\.Text\s*=').Count -ge 2) `
    "loss, manual reconnect guidance, and recovered waiting states remain distinct"
Assert-True ($lostConnectionUiSource.Contains(
        "IntPtr rendererWindow, Action completed") -and
    $lostConnectionUiSource.Contains("rendererHandoffTimer.Interval = 20") -and
    $lostConnectionUiSource.Contains("elapsedMilliseconds / 180.0") -and
    $lostConnectionUiSource.Contains("CancelRendererHandoff();") -and
    $source.Contains("lostConnectionPlaceholderShowPending, 0, 0") -and
    $lostConnectionUiSource.Contains("NativeMethods.SWP_NOACTIVATE") -and
    -not $lostConnectionUiSource.Contains("Thread.Sleep")) `
    "successful renderer handoff uses a short non-blocking opacity fade"
Assert-True ($lostConnectionUiSource.Contains(
        "protected override bool ShowWithoutActivation")) `
    "the continuity placeholder does not steal focus when it first appears"
Assert-True ($lostConnectionUiSource.Contains(
        "BringAboveRendererWithoutActivation(") -and
    $lostConnectionUiSource.Contains("NativeMethods.HWND_TOP") -and
    $lostConnectionUiSource.Contains(
        "NativeMethods.GetWindow(") -and
    $source.Contains(
        "placeholder.BringAboveRendererWithoutActivation(") -and
    -not $lostConnectionUiSource.Contains("Activate()") -and
    -not $lostConnectionUiSource.Contains("SetForegroundWindow")) `
    "continuity is raised above the foreign renderer without activation or a permanent topmost policy"
$bringContinuityStart = $lostConnectionUiSource.IndexOf(
    "internal bool BringAboveRendererWithoutActivation")
$bringContinuityEnd = $lostConnectionUiSource.IndexOf(
    "internal bool BeginRendererHandoff", $bringContinuityStart)
Assert-True ($bringContinuityStart -ge 0 -and
    $bringContinuityEnd -gt $bringContinuityStart) `
    "continuity z-order has a focused implementation boundary"
$bringContinuitySource = $lostConnectionUiSource.Substring(
    $bringContinuityStart,
    $bringContinuityEnd - $bringContinuityStart)
Assert-True ($bringContinuitySource.Contains(
        "IntPtr insertAfter = TopMost") -and
    $bringContinuitySource.Contains("NativeMethods.HWND_TOPMOST") -and
    $bringContinuitySource.Contains("NativeMethods.HWND_TOP") -and
    $bringContinuitySource.Contains("NativeMethods.SWP_NOACTIVATE") -and
    $bringContinuitySource.Contains("aboveRenderer == Handle")) `
    "always-on-top is preserved only when requested and ordinary continuity is inserted immediately above the renderer"
$handoffUiStart = $bringContinuityEnd
$handoffUiEnd = $lostConnectionUiSource.IndexOf(
    "internal void ShowConnectionRecovered", $handoffUiStart)
Assert-True ($handoffUiEnd -gt $handoffUiStart) `
    "continuity handoff has a focused UI implementation boundary"
$handoffUiSource = $lostConnectionUiSource.Substring(
    $handoffUiStart, $handoffUiEnd - $handoffUiStart)
Assert-True ($handoffUiSource.Contains(
        "BringAboveRendererWithoutActivation(rendererWindow)") -and
    -not $handoffUiSource.Contains("NativeMethods.HWND_TOPMOST") -and
    -not $handoffUiSource.Contains("SetWindowPos(")) `
    "renderer handoff reuses the same non-activating z-order policy"
$renewedLossStateStart = $lostConnectionUiSource.IndexOf(
    "internal void ShowConnectionLost")
$renewedLossStateEnd = $lostConnectionUiSource.IndexOf(
    "private void CancelRendererHandoff", $renewedLossStateStart)
Assert-True ($renewedLossStateStart -ge 0 -and
    $renewedLossStateEnd -gt $renewedLossStateStart) `
    "renewed-loss presentation has a focused implementation boundary"
$renewedLossStateSource = $lostConnectionUiSource.Substring(
    $renewedLossStateStart,
    $renewedLossStateEnd - $renewedLossStateStart)
Assert-True ([regex]::Matches(
        $renewedLossStateSource,
        'CancelRendererHandoff\(\);').Count -eq 2) `
    "a renewed or fatal loss cancels an in-progress renderer handoff fade"
$mirroringEndStart = $source.IndexOf(
    "private void HandleMirroringEndedMaintenance")
$mirroringEndEnd = $source.IndexOf(
    "private void ObserveClientFeedbackHealth", $mirroringEndStart)
Assert-True ($mirroringEndStart -ge 0 -and
    $mirroringEndEnd -gt $mirroringEndStart) `
    "mirroring-end maintenance has a focused implementation boundary"
$mirroringEndSource = $source.Substring(
    $mirroringEndStart, $mirroringEndEnd - $mirroringEndStart)
Assert-True ($mirroringEndSource.Contains(
        "if (showReconnectHint)") -and
    $mirroringEndSource.Contains(
        "QueueLostConnectionReconnectHint();") -and
    $mirroringEndSource.Contains(
        "if (closeTransientFeedbackPlaceholder)")) `
    "only abnormal cleanup queues reconnect guidance while a clean stop still closes transient continuity"
$showCallbackStart = $source.IndexOf(
    "private void OnRendererWindowShowEvent")
$showCallbackEnd = $source.IndexOf(
    "private void OnRendererMoveSizeEvent", $showCallbackStart)
Assert-True ($showCallbackStart -ge 0 -and
    $showCallbackEnd -gt $showCallbackStart) `
    "renderer-show callback has a focused implementation boundary"
$showCallbackSource = $source.Substring(
    $showCallbackStart, $showCallbackEnd - $showCallbackStart)
Assert-True ($showCallbackSource.Contains(
        "TryApplySavedStreamWindowPlacement") -and
    -not $showCallbackSource.Contains("settings.Save") -and
    -not $showCallbackSource.Contains("FitRendererWindow") -and
    -not $showCallbackSource.Contains("Log(")) `
    "renderer show pre-positions from loaded settings without IO, activation, or aspect fitting"
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
Assert-True ($source.Contains(
        "MarkStreamWindowPlacementPersistable(window)") -and
    $source.Contains(
        "CanPersistStreamWindowPlacement(window)") -and
    $source.Contains(
        "if (!automaticVideoSize.IsEmpty)")) `
    "only a device-oriented automatic fit or explicit user move can replace saved renderer placement"
$restorePlacementStart = $source.IndexOf(
    "private bool TryRestoreStreamWindowPlacement")
$restorePlacementEnd = $source.IndexOf(
    "private bool TryApplySavedStreamWindowPlacement",
    $restorePlacementStart)
Assert-True ($restorePlacementStart -ge 0 -and
    $restorePlacementEnd -gt $restorePlacementStart) `
    "saved renderer restoration has a focused implementation boundary"
$restorePlacementSource = $source.Substring(
    $restorePlacementStart,
    $restorePlacementEnd - $restorePlacementStart)
Assert-True (-not $restorePlacementSource.Contains(
        "QueueStreamWindowPlacementSave")) `
    "a provisional restored window is not persisted before device orientation is known"
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
$decideLostPresentation = $contextType.GetMethod(
    "DecideLostConnectionPresentationState", $staticFlags)
Assert-True ($null -ne $decideLostPresentation) `
    "lost-frame copy exposes deterministic presentation states"
Assert-True ($decideLostPresentation.Invoke(
        $null, [object[]]@($true, $false, $false)).ToString() -eq "Lost") `
    "a transient feedback gap starts with ordinary waiting guidance"
Assert-True ($decideLostPresentation.Invoke(
        $null, [object[]]@($true, $true, $false)).ToString() -eq
        "ReconnectHint") `
    "abnormal native cleanup replaces generic waiting with explicit iPhone reconnect guidance"
Assert-True ($decideLostPresentation.Invoke(
        $null, [object[]]@($false, $false, $true)).ToString() -eq
        "Recovered") `
    "only explicit recovery evidence selects the recovered waiting-for-image state"
Assert-True ($decideLostPresentation.Invoke(
        $null, [object[]]@($false, $false, $false)).ToString() -eq "None") `
    "an unrelated supervision tick does not rewrite continuity text"
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

$shouldApplyRendererPolicy = $contextType.GetMethod(
    "ShouldApplyRendererWindowPolicy", $staticFlags)
Assert-True ($null -ne $shouldApplyRendererPolicy) `
    "foreign renderer policy caching is independently testable"
$rendererOne = [IntPtr]::new(101)
$rendererTwo = [IntPtr]::new(202)
Assert-True ([bool]$shouldApplyRendererPolicy.Invoke(
        $null, [object[]]@(
            $rendererOne, [IntPtr]::Zero, $false,
            $false, $false, $true, $true))) `
    "a newly observed renderer receives window policy once"
Assert-True (-not [bool]$shouldApplyRendererPolicy.Invoke(
        $null, [object[]]@(
            $rendererOne, $rendererOne, $true,
            $false, $false, $true, $true))) `
    "an unchanged supervision tick does not mutate the foreign renderer"
Assert-True ([bool]$shouldApplyRendererPolicy.Invoke(
        $null, [object[]]@(
            $rendererOne, $rendererOne, $true,
            $true, $false, $true, $true))) `
    "an always-on-top settings change reapplies renderer policy"
Assert-True ([bool]$shouldApplyRendererPolicy.Invoke(
        $null, [object[]]@(
            $rendererOne, $rendererOne, $true,
            $false, $false, $false, $true))) `
    "a taskbar settings change reapplies renderer policy"
Assert-True ([bool]$shouldApplyRendererPolicy.Invoke(
        $null, [object[]]@(
            $rendererTwo, $rendererOne, $true,
            $false, $false, $true, $true))) `
    "a replacement renderer receives policy even when settings are unchanged"

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
$migrateRendererDefault = $settingsType.GetMethod(
    "MigrateRendererStabilityDefault", $staticFlags)
Assert-True ($null -ne $migrateRendererDefault) `
    "the renderer stability migration is independently testable"
$contextSettingsField = $contextType.GetField("settings", $instanceFlags)
$buildUxPlayArguments = $contextType.GetMethod(
    "BuildUxPlayArguments", $instanceFlags)
Assert-True ($null -ne $contextSettingsField -and
    $null -ne $buildUxPlayArguments) `
    "receiver arguments can be verified from normalized settings"
function Invoke-UxPlayArguments($Settings) {
    $contextSettingsField.SetValue($context, $Settings)
    return [string]$buildUxPlayArguments.Invoke($context, [object[]]@())
}
$resilientAudioArgument = '-as "wasapi2sink continue-on-error=true"'
$legacyAutomaticSettings = [Activator]::CreateInstance($settingsType, $true)
$legacyAutomaticSettings.SettingsVersion = 10
$legacyAutomaticSettings.Renderer = "auto"
$migrateRendererDefault.Invoke(
    $null, [object[]]@($legacyAutomaticSettings)) | Out-Null
Assert-True ($legacyAutomaticSettings.SettingsVersion -eq 11 -and
    $legacyAutomaticSettings.Renderer -eq "d3d11") `
    "a legacy automatic renderer profile migrates to pinned Direct3D 11"
$legacyDefaultAudioArguments = Invoke-UxPlayArguments `
    $legacyAutomaticSettings
Assert-True ($legacyDefaultAudioArguments.Contains(
        $resilientAudioArgument)) `
    "an existing default-audio profile receives resilient WASAPI2 output without a settings migration"
$explicitD3D12Settings = [Activator]::CreateInstance($settingsType, $true)
$explicitD3D12Settings.SettingsVersion = 10
$explicitD3D12Settings.Renderer = "d3d12"
$migrateRendererDefault.Invoke(
    $null, [object[]]@($explicitD3D12Settings)) | Out-Null
Assert-True ($explicitD3D12Settings.SettingsVersion -eq 11 -and
    $explicitD3D12Settings.Renderer -eq "d3d12") `
    "the stability migration preserves an explicit Direct3D 12 choice"
$settingsProbe = [Activator]::CreateInstance($settingsType, $true)
Assert-True ([int]$settingsProbe.SettingsVersion -eq 11 -and
    $settingsProbe.Renderer -eq "d3d11") `
    "new settings profiles use the pinned Direct3D 11 stability default"
$defaultAudioArguments = Invoke-UxPlayArguments $settingsProbe
Assert-True ([regex]::Matches(
        $defaultAudioArguments,
        [regex]::Escape($resilientAudioArgument)).Count -eq 1) `
    "default audio emits exactly one resilient WASAPI2 sink argument"
$mutedSettings = [Activator]::CreateInstance($settingsType, $true)
$mutedSettings.AudioOutput = "mute"
$mutedArguments = Invoke-UxPlayArguments $mutedSettings
Assert-True (-not $mutedArguments.Contains($resilientAudioArgument) -and
    [regex]::IsMatch($mutedArguments, '(?:^|\s)-a(?:\s|$)')) `
    "mute disables audio without adding the managed WASAPI2 sink"
$advancedAudioSettings = [Activator]::CreateInstance($settingsType, $true)
$advancedAudioSettings.AdvancedArguments = '-as "fakesink sync=false"'
$advancedAudioArguments = Invoke-UxPlayArguments $advancedAudioSettings
Assert-True ($advancedAudioArguments.IndexOf(
        $resilientAudioArgument, [StringComparison]::Ordinal) -ge 0 -and
    $advancedAudioArguments.LastIndexOf(
        $advancedAudioSettings.AdvancedArguments,
        [StringComparison]::Ordinal) -gt
    $advancedAudioArguments.IndexOf(
        $resilientAudioArgument, [StringComparison]::Ordinal)) `
    "advanced arguments remain later and can override the managed audio sink"
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
Assert-True ($settingsProbe.Renderer -eq "d3d11") `
    "an unknown renderer receives the pinned Direct3D 11 default"
Assert-True ($settingsProbe.LatencyProfile -eq "balanced") `
    "an unknown latency profile receives the balanced default"
Assert-True ($settingsProbe.AudioOutput -eq "default") `
    "an unknown audio output receives the system default"
Assert-True ((Invoke-UxPlayArguments $settingsProbe).Contains(
        $resilientAudioArgument)) `
    "normalized unknown audio output receives resilient WASAPI2 output"
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
    $atomicLines.SetValue("SettingsVersion=11", 0)
    $atomicLines.SetValue("PairingMode=none", 1)
    $atomicArguments = [Array]::CreateInstance([object], 2)
    $atomicArguments.SetValue([string]$atomicPath, 0)
    $atomicArguments.SetValue($atomicLines, 1)
    $atomicWriter.Invoke($null, $atomicArguments) | Out-Null
    $atomicText = [IO.File]::ReadAllText($atomicPath)
    Assert-True ($atomicText.Contains("SettingsVersion=11") -and
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
$pendingVideoSizeIsAmbiguous =
    Field "pendingVideoSizeIsAmbiguousMediaCanvas"
$currentVideoSize = Field "currentVideoSize"
$currentVideoSizeIsAmbiguous =
    Field "currentVideoSizeIsAmbiguousMediaCanvas"
$rawGeometryVideoSize = Field "rawGeometryVideoSize"
$rawGeometryVideoSizeGeneration = Field "rawGeometryVideoSizeGeneration"
$rawGeometryIsAmbiguous = Field "rawGeometryIsAmbiguousMediaCanvas"
$earlyDeviceFrameVideoSize = Field "earlyDeviceFrameVideoSize"
$deviceFrameVideoSize = Field "deviceFrameVideoSize"
$lastSuppressedVideoSize = Field "lastSuppressedVideoSize"
$persistablePlacementWindow =
    Field "persistableStreamWindowPlacementWindow"
$startAfterNetwork = Field "startAfterNetworkCheck"
$refreshAfterNetwork = Field "discoveryRefreshAfterNetworkCheck"
$networkRefreshPending = Field "networkRefreshPending"
$networkRefreshDue = Field "networkRefreshDueTicks"
$socketsReady = Field "coreSocketsReady"
$httpMarkersReady = Field "coreHttpMarkersReady"
$httpPort = Field "coreHttpPort"
$httpResetStatus = Field "lostConnectionHttpResetStatus"
$httpResetPort = Field "lostConnectionHttpResetPort"
$dnsSdStatus = Field "coreDnsSdStatus"
$bleStatus = Field "coreBleStatus"
$discoveryRecoveryPending = Field "coreDiscoveryRecoveryPending"
$discoveryRecoveryAttempts = Field "coreDiscoveryRecoveryAttempts"
$discoveryRecoveryPid = Field "coreDiscoveryRecoveryPid"
$discoveryRecoveryDue = Field "coreDiscoveryRecoveryDueTicks"
$placeholderShowPending = Field "lostConnectionPlaceholderShowPending"
$placeholderClosePending = Field "lostConnectionPlaceholderClosePending"
$rendererHandoffPending = Field "lostConnectionRendererHandoffPending"
$lostStatePending = Field "lostConnectionLostStatePending"
$recoveredStatePending = Field "lostConnectionRecoveredStatePending"
$feedbackEpisodeActive = Field "feedbackGapEpisodeActive"
$feedbackEpisodeCount = Field "feedbackGapEpisodeCount"
$feedbackLongest = Field "feedbackGapLongestSeconds"
$feedbackPlaceholderActive = Field "feedbackGapPlaceholderActive"
$feedbackPlaceholderDue = Field "feedbackGapPlaceholderDueTicks"
$feedbackMarkersReady = Field "feedbackHealthMarkersReady"

$maintenanceSync.SetValue($context, (New-Object object))
$videoSizeSync.SetValue($context, (New-Object object))
$streamWindowPlacementSync.SetValue($context, (New-Object object))
$activePid.SetValue($context, 42)
$mirrorActive.SetValue($context, 1)
$markPlacementPersistable = $contextType.GetMethod(
    "MarkStreamWindowPlacementPersistable", $instanceFlags)
$canPersistPlacement = $contextType.GetMethod(
    "CanPersistStreamWindowPlacement", $instanceFlags)
$clearPlacementPersistence = $contextType.GetMethod(
    "ClearStreamWindowPlacementPersistence", $instanceFlags)
Assert-True ($null -ne $markPlacementPersistable -and
    $null -ne $canPersistPlacement -and
    $null -ne $clearPlacementPersistence) `
    "renderer placement persistence exposes a deterministic trust gate"
$placementWindow = [IntPtr]::new(501)
$otherPlacementWindow = [IntPtr]::new(502)
Assert-True (-not [bool]$canPersistPlacement.Invoke(
        $context, [object[]]@($placementWindow))) `
    "an unresolved provisional renderer cannot overwrite saved placement"
$markPlacementPersistable.Invoke(
    $context, [object[]]@($placementWindow)) | Out-Null
Assert-True ([bool]$canPersistPlacement.Invoke(
        $context, [object[]]@($placementWindow)) -and
    -not [bool]$canPersistPlacement.Invoke(
        $context, [object[]]@($otherPlacementWindow))) `
    "placement persistence is scoped to the explicitly trusted renderer"
$clearPlacementPersistence.Invoke(
    $context, [object[]]@($placementWindow)) | Out-Null
Assert-True (-not [bool]$canPersistPlacement.Invoke(
        $context, [object[]]@($placementWindow)) -and
    [IntPtr]$persistablePlacementWindow.GetValue($context) -eq
        [IntPtr]::Zero) `
    "renderer placement persistence is cleared after the session"
$sameDeviceAspect = $contextType.GetMethod(
    "HaveEquivalentDeviceFrameAspect", $staticFlags)
$likelyModernIPhoneFrame = $contextType.GetMethod(
    "IsLikelyModernIPhoneDeviceFrame", $staticFlags)
$knownAmbiguousMediaCanvas = $contextType.GetMethod(
    "IsKnownAmbiguousMediaCanvasGeometry", $staticFlags)
$resolveAutomaticVideo = $contextType.GetMethod(
    "ResolveAutomaticVideoSize", $instanceFlags)
$resolveManualFitVideo = $contextType.GetMethod(
    "ResolveManualFitVideoSize", $instanceFlags)
Assert-True ($null -ne $sameDeviceAspect -and
    $null -ne $likelyModernIPhoneFrame -and
    $null -ne $knownAmbiguousMediaCanvas -and
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
Assert-True ([bool]$knownAmbiguousMediaCanvas.Invoke(
        $null, [object[]]@(
            3840, 2160, 3840, 2160, 0, 0, 3840, 2160))) `
    "the recorded direct-in-Photos 4K canvas signature is treated as ambiguous"
Assert-True (-not [bool]$knownAmbiguousMediaCanvas.Invoke(
        $null, [object[]]@(
            3840, 1776, 3840, 1776, 0, 192, 3840, 1776)) -and
    -not [bool]$knownAmbiguousMediaCanvas.Invoke(
        $null, [object[]]@(
            1920, 1080, 1920, 1080, 0, 0, 1920, 1080))) `
    "real landscape and non-matching 16:9 streams are not rejected by the Photos signature"

function Resolve-AutomaticVideoSize(
    [Drawing.Size]$VideoSize,
    [bool]$AmbiguousMediaCanvas = $false
) {
    $arguments = [object[]]@(
        $VideoSize, $AmbiguousMediaCanvas, $false, $false)
    $resolved = [Drawing.Size]$resolveAutomaticVideo.Invoke(
        $context, $arguments)
    return [pscustomobject]@{
        Size = $resolved
        OrientationAuthoritative = [bool]$arguments[2]
        SuppressionChanged = [bool]$arguments[3]
    }
}

$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$unlearnedCanvasResult = Resolve-AutomaticVideoSize `
    $presentationCanvas $true
Assert-True (-not $unlearnedCanvasResult.OrientationAuthoritative -and
    $unlearnedCanvasResult.Size.IsEmpty -and
    $unlearnedCanvasResult.SuppressionChanged) `
    "a first recorded Photos canvas cannot seed the device-frame baseline"
$directMediaPortrait = Resolve-AutomaticVideoSize $portraitFrame
Assert-True ($directMediaPortrait.OrientationAuthoritative -and
    $directMediaPortrait.Size -eq $portraitFrame) `
    "a later phone-shaped frame recovers a direct-in-Photos session to portrait"
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$unlearnedCanvasResult = Resolve-AutomaticVideoSize `
    $presentationCanvas $false
Assert-True ($unlearnedCanvasResult.OrientationAuthoritative -and
    $unlearnedCanvasResult.Size -eq $presentationCanvas -and
    -not $unlearnedCanvasResult.SuppressionChanged) `
    "a 4K landscape frame without the complete Photos signature remains valid"
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$portraitResult = Resolve-AutomaticVideoSize $portraitFrame
Assert-True ($portraitResult.OrientationAuthoritative -and
    $portraitResult.Size -eq $portraitFrame -and
    -not $portraitResult.SuppressionChanged) `
    "the first exact frame establishes session orientation"
$photoResult = Resolve-AutomaticVideoSize $presentationCanvas $true
Assert-True (-not $photoResult.OrientationAuthoritative -and
    $photoResult.Size -eq $portraitFrame -and
    $photoResult.SuppressionChanged) `
    "998x2160 to 3840x2160 retains portrait device orientation"
$repeatedPhotoResult = Resolve-AutomaticVideoSize $presentationCanvas $true
Assert-True (-not $repeatedPhotoResult.OrientationAuthoritative -and
    $repeatedPhotoResult.Size -eq $portraitFrame -and
    -not $repeatedPhotoResult.SuppressionChanged) `
    "a stable presentation canvas does not repeat its suppression notice"
$manualPhotoFit = [Drawing.Size]$resolveManualFitVideo.Invoke(
    $context, [object[]]@($presentationCanvas, $true))
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
Resolve-AutomaticVideoSize $presentationCanvas $true | Out-Null
Assert-True ([Drawing.Size]$currentVideoSize.GetValue($context) -eq
    $presentationCanvas) `
    "orientation classification preserves the raw stream size for diagnostics and manual fitting"
$currentVideoSize.SetValue($context, [Drawing.Size]::Empty)
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)

$observe = $contextType.GetMethod("ObserveCoreOutput", $instanceFlags)
Assert-True ($null -ne $observe) "core-output observer exists"
$observeSocketReady = $contextType.GetMethod(
    "ObserveCoreSocketReady", $instanceFlags)
Assert-True ($null -ne $observeSocketReady) `
    "generic native socket readiness has a process-scoped observer"

$httpMarkersReady.SetValue($context, 0)
$httpPort.SetValue($context, 0)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 0)
$recoveryPending.SetValue($context, 0)
$recoveryPid.SetValue($context, 0)
$observe.Invoke(
    $context,
    [object[]]@(41,
        "AEROMIRROR_HTTP_READY stage=initial port=53999")) | Out-Null
Assert-True ([int]$httpMarkersReady.GetValue($context) -eq 0 -and
    [int]$httpPort.GetValue($context) -eq 0) `
    "an HTTP-ready marker from a stale native PID is ignored"
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_READY stage=initial port=53999")) | Out-Null
Assert-True ([int]$httpMarkersReady.GetValue($context) -eq 1 -and
    [int]$httpPort.GetValue($context) -eq 53999 -and
    [int]$socketsReady.GetValue($context) -eq 1) `
    "the initial marker establishes native capability and advertised AirPlay port"

$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 0)
$observe.Invoke(
    $context,
    [object[]]@(41,
        "AEROMIRROR_HTTP_READY stage=reset port=53999")) | Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq 0 -and
    [int]$socketsReady.GetValue($context) -eq 0) `
    "a reset marker from a stale native PID cannot satisfy recovery"
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_READY stage=reset port=54000")) | Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq -1 -and
    [int]$httpResetPort.GetValue($context) -eq 54000 -and
    [int]$socketsReady.GetValue($context) -eq 0) `
    "a reset marker for a different port is rejected"
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_READY stage=reset port=53999")) | Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq 1 -and
    [int]$httpResetPort.GetValue($context) -eq 53999 -and
    [int]$socketsReady.GetValue($context) -eq 1) `
    "a matching reset marker explicitly confirms same-process recovery"
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_FAILED stage=reset expected_port=53999 port=0 code=-1")) |
    Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq -1 -and
    [int]$socketsReady.GetValue($context) -eq 0) `
    "a native reset-bind failure clears readiness while full-process recovery begins"

$recoveryPending.SetValue($context, 0)
$recoveryPid.SetValue($context, 0)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_FAILED stage=reset expected_port=53999 port=0 code=-1")) |
    Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq 0 -and
    [int]$socketsReady.GetValue($context) -eq 1) `
    "an out-of-sequence reset failure marker cannot overwrite healthy listener state"

$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$httpMarkersReady.SetValue($context, 0)
$httpPort.SetValue($context, 0)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 0)
$observeSocketReady.Invoke($context, [object[]]@(42)) | Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq 2 -and
    [int]$socketsReady.GetValue($context) -eq 1) `
    "a legacy core can use only the bounded post-fatal generic listener fallback"
$recoveryPending.SetValue($context, 0)
$recoveryPid.SetValue($context, 0)
$recoveryDue.SetValue($context, [long]0)
$httpMarkersReady.SetValue($context, 0)
$httpPort.SetValue($context, 0)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 0)
$getStableVideoSize = $contextType.GetMethod(
    "GetStableVideoSize", $instanceFlags)
Assert-True ($null -ne $getStableVideoSize) `
    "video-size debounce exposes a deterministic stable-frame boundary"

# Recorded Photos sequence: 998x2160 was followed by the app's 3840x2160
# presentation canvas about 130 ms later, before the 350 ms debounce elapsed.
$pendingVideoSize.SetValue($context, [Drawing.Size]::Empty)
$pendingVideoSizeDueUtc.SetValue($context, [DateTime]::MinValue)
$pendingVideoSizeIsAmbiguous.SetValue($context, $false)
$currentVideoSize.SetValue($context, [Drawing.Size]::Empty)
$currentVideoSizeIsAmbiguous.SetValue($context, $false)
$rawGeometryVideoSize.SetValue($context, [Drawing.Size]::Empty)
$rawGeometryVideoSizeGeneration.SetValue($context, 0)
$rawGeometryIsAmbiguous.SetValue($context, $false)
$earlyDeviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_GEOMETRY width0=998 height0=2160 source=998x2160 aux=1421x0 encoded=998x2160")) |
    Out-Null
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
        "AEROMIRROR_VIDEO_GEOMETRY width0=3840 height0=2160 source=3840x2160 aux=0x0 encoded=3840x2160")) |
    Out-Null
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_SIZE source=3840x2160 encoded=3840x2160")) |
    Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    $portraitFrame -and
    [Drawing.Size]$pendingVideoSize.GetValue($context) -eq
        $presentationCanvas -and
    [bool]$pendingVideoSizeIsAmbiguous.GetValue($context)) `
    "the later Photos canvas keeps both the early device frame and its ambiguous classification"
$pendingVideoSizeDueUtc.SetValue(
    $context, [DateTime]::UtcNow.AddMilliseconds(-1))
$stableArguments = [object[]]@(0, $false)
$recordedStableCanvas = [Drawing.Size]$getStableVideoSize.Invoke(
    $context, $stableArguments)
$recordedPhotosResult = Resolve-AutomaticVideoSize `
    $recordedStableCanvas ([bool]$stableArguments[1])
Assert-True ($recordedStableCanvas -eq $presentationCanvas -and
    [bool]$stableArguments[1] -and
    -not $recordedPhotosResult.OrientationAuthoritative -and
    $recordedPhotosResult.Size -eq $portraitFrame -and
    $recordedPhotosResult.SuppressionChanged) `
    "the recorded direct-in-Photos sequence keeps the portrait window baseline"

$pendingVideoSize.SetValue($context, [Drawing.Size]::Empty)
$pendingVideoSizeDueUtc.SetValue($context, [DateTime]::MinValue)
$pendingVideoSizeIsAmbiguous.SetValue($context, $false)
$currentVideoSize.SetValue($context, [Drawing.Size]::Empty)
$currentVideoSizeIsAmbiguous.SetValue($context, $false)
$rawGeometryVideoSize.SetValue($context, [Drawing.Size]::Empty)
$rawGeometryVideoSizeGeneration.SetValue($context, 0)
$rawGeometryIsAmbiguous.SetValue($context, $false)
$earlyDeviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$deviceFrameVideoSize.SetValue($context, [Drawing.Size]::Empty)
$lastSuppressedVideoSize.SetValue($context, [Drawing.Size]::Empty)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_GEOMETRY width0=3840 height0=2160 source=3840x2160 aux=0x0 encoded=3840x2160")) |
    Out-Null
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_SIZE source=3840x2160 encoded=3840x2160")) |
    Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [bool]$pendingVideoSizeIsAmbiguous.GetValue($context)) `
    "a first raw Photos canvas is classified without becoming an iPhone candidate"
$pendingVideoSizeDueUtc.SetValue(
    $context, [DateTime]::UtcNow.AddMilliseconds(-1))
$directCanvasArguments = [object[]]@(0, $false)
$directCanvas = [Drawing.Size]$getStableVideoSize.Invoke(
    $context, $directCanvasArguments)
$directCanvasResult = Resolve-AutomaticVideoSize `
    $directCanvas ([bool]$directCanvasArguments[1])
Assert-True ($directCanvas -eq $presentationCanvas -and
    [bool]$directCanvasArguments[1] -and
    $directCanvasResult.Size.IsEmpty -and
    -not $directCanvasResult.OrientationAuthoritative) `
    "the observed Photos-first canvas remains unresolved instead of forcing landscape"
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_GEOMETRY width0=998 height0=2160 source=998x2160 aux=1421x0 encoded=998x2160")) |
    Out-Null
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_VIDEO_SIZE source=998x2160 encoded=998x2160")) |
    Out-Null
$latePortraitResult = Resolve-AutomaticVideoSize `
    $directCanvas ([bool]$directCanvasArguments[1])
Assert-True (-not $latePortraitResult.OrientationAuthoritative -and
    $latePortraitResult.Size -eq $portraitFrame) `
    "the later early phone marker repairs orientation before its debounce completes"
$pendingVideoSizeDueUtc.SetValue(
    $context, [DateTime]::UtcNow.AddMilliseconds(-1))
$latePortraitArguments = [object[]]@(0, $false)
$latePortraitStable = [Drawing.Size]$getStableVideoSize.Invoke(
    $context, $latePortraitArguments)
$latePortraitStableResult = Resolve-AutomaticVideoSize `
    $latePortraitStable ([bool]$latePortraitArguments[1])
Assert-True ($latePortraitStable -eq $portraitFrame -and
    -not [bool]$latePortraitArguments[1] -and
    $latePortraitStableResult.OrientationAuthoritative -and
    $latePortraitStableResult.Size -eq $portraitFrame) `
    "the completed Photos-first replay establishes portrait as the saved device baseline"
$pendingVideoSize.SetValue($context, [Drawing.Size]::Empty)
$pendingVideoSizeDueUtc.SetValue($context, [DateTime]::MinValue)
$pendingVideoSizeIsAmbiguous.SetValue($context, $false)

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
$calculateFeedbackPlaceholderDue = $contextType.GetMethod(
    "CalculateFeedbackGapPlaceholderDueTicks", $staticFlags)
$shouldShowFeedbackPlaceholder = $contextType.GetMethod(
    "ShouldShowFeedbackGapPlaceholder", $staticFlags)
$handleFeedbackPlaceholderTimer = $contextType.GetMethod(
    "HandleFeedbackGapPlaceholderTimer", $instanceFlags)
$consumeLostRecovery = $contextType.GetMethod(
    "ConsumeDueLostConnectionRecoveryLocked", $instanceFlags)
Assert-True ($null -ne $calculateFeedbackPlaceholderDue -and
    $null -ne $shouldShowFeedbackPlaceholder -and
    $null -ne $handleFeedbackPlaceholderTimer) `
    "feedback-gap continuity exposes deterministic deadline transitions"
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
$feedbackDeadlineBase = [DateTime]::UtcNow.Ticks
$feedbackDeadline = [long]$calculateFeedbackPlaceholderDue.Invoke(
    $null, [object[]]@(3, [long]$feedbackDeadlineBase))
Assert-True ($feedbackDeadline -eq
        $feedbackDeadlineBase + [TimeSpan]::FromSeconds(1).Ticks) `
    "the first three-second warning deterministically schedules continuity at four seconds"
Assert-True (-not [bool]$shouldShowFeedbackPlaceholder.Invoke(
        $null,
        [object[]]@(
            [long]$feedbackDeadline,
            [long]($feedbackDeadline - 1),
            $true, $true, $true, $false))) `
    "continuity remains hidden before the local four-second deadline"
Assert-True ([bool]$shouldShowFeedbackPlaceholder.Invoke(
        $null,
        [object[]]@(
            [long]$feedbackDeadline,
            [long]$feedbackDeadline,
            $true, $true, $true, $false))) `
    "continuity becomes eligible exactly at the local deadline"
Assert-True (-not [bool]$shouldShowFeedbackPlaceholder.Invoke(
        $null,
        [object[]]@(
            [long]$feedbackDeadline,
            [long]$feedbackDeadline,
            $true, $true, $true, $true))) `
    "a fatal recovery episode owns continuity instead of the feedback timer"

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
$rendererHandoffPending.SetValue($context, 0)
$lostStatePending.SetValue($context, 0)
$recoveredStatePending.SetValue($context, 0)
$feedbackPlaceholderDue.SetValue($context, [long]0)
$restartPending.SetValue($context, $false)
$mirrorActive.SetValue($context, 1)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "*** ERROR:   5 seconds since last client feedback request (expected every two seconds); client may be offline")) |
    Out-Null
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 0) `
    "a legacy core without recovered markers cannot open a pre-fatal placeholder that it cannot dismiss"
Assert-True ([long]$feedbackPlaceholderDue.GetValue($context) -eq 0) `
    "a legacy core without recovered markers does not arm the local continuity timer"
$feedbackEpisodeActive.SetValue($context, 0)
$feedbackEpisodeCount.SetValue($context, 0)
$feedbackLongest.SetValue($context, 0)
$observe.Invoke(
    $context,
    [object[]]@(42, "AEROMIRROR_FEEDBACK_HEALTH_READY")) | Out-Null
Assert-True ([int]$feedbackMarkersReady.GetValue($context) -eq 1) `
    "the patched native feedback-health capability is detected"
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
Assert-True ([int]$feedbackEpisodeActive.GetValue($context) -eq 1 -and
    [int]$feedbackEpisodeCount.GetValue($context) -eq 1 -and
    [int]$feedbackLongest.GetValue($context) -eq 3) `
    "a short feedback gap is counted without disrupting the active stream"
$scheduledFeedbackDue = [long]$feedbackPlaceholderDue.GetValue($context)
Assert-True ($scheduledFeedbackDue -gt [DateTime]::UtcNow.Ticks -and
    $scheduledFeedbackDue -le [DateTime]::UtcNow.AddSeconds(2).Ticks) `
    "the first warning arms a bounded local deadline instead of waiting for another native warning"

$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_CLIENT_FEEDBACK_RECOVERED gap_seconds=3")) |
    Out-Null
Assert-True ([long]$feedbackPlaceholderDue.GetValue($context) -eq 0 -and
    [int]$placeholderShowPending.GetValue($context) -eq 0 -and
    [int]$rendererHandoffPending.GetValue($context) -eq 0) `
    "feedback recovery before four seconds cancels the queued placeholder"

$observe.Invoke(
    $context,
    [object[]]@(42,
        "*** ERROR:   3 seconds since last client feedback request (expected every two seconds); client may be offline")) |
    Out-Null
$feedbackPlaceholderDue.SetValue(
    $context, [DateTime]::UtcNow.AddMilliseconds(-1).Ticks)
$handleFeedbackPlaceholderTimer.Invoke($context, @()) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0 -and
    -not [bool]$restartPending.GetValue($context)) `
    "the local four-second deadline still does not arm destructive recovery"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$feedbackPlaceholderActive.GetValue($context) -eq 1 -and
    [int]$feedbackEpisodeCount.GetValue($context) -eq 2 -and
    [int]$feedbackLongest.GetValue($context) -eq 3 -and
    [long]$feedbackPlaceholderDue.GetValue($context) -eq 0) `
    "the local deadline queues continuity without requiring another native warning"

$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_CLIENT_FEEDBACK_RECOVERED gap_seconds=4")) |
    Out-Null
Assert-True ([int]$feedbackEpisodeActive.GetValue($context) -eq 0 -and
    [int]$feedbackPlaceholderActive.GetValue($context) -eq 0 -and
    [int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$placeholderClosePending.GetValue($context) -eq 0 -and
    [int]$rendererHandoffPending.GetValue($context) -eq 1 -and
    [int]$recoveredStatePending.GetValue($context) -eq 1 -and
    [long]$feedbackPlaceholderDue.GetValue($context) -eq 0) `
    "a native feedback-recovered marker shows recovery state and queues a smooth renderer handoff"

$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror->running is no longer true")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "a clean mirror shutdown does not arm abnormal-loss recovery"
Assert-True (-not [bool]$restartPending.GetValue($context)) `
    "a clean mirror shutdown does not schedule a receiver restart"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 0) `
    "a clean mirror shutdown does not show a lost-frame placeholder"

$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_READY stage=initial port=53999")) | Out-Null
$mirrorActive.SetValue($context, 1)

$before = [DateTime]::UtcNow.Ticks
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror error in recv: 10054")) | Out-Null
$armedDue = [long]$recoveryDue.GetValue($context)
Assert-True ([int]$recoveryPending.GetValue($context) -eq 1) `
    "fatal mirror recv error arms recovery"
Assert-True ([int]$socketsReady.GetValue($context) -eq 0 -and
    [int]$httpResetStatus.GetValue($context) -eq 0 -and
    [int]$httpResetPort.GetValue($context) -eq 0) `
    "fatal loss clears listener readiness until the native reset is explicitly confirmed"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$rendererHandoffPending.GetValue($context) -eq 0 -and
    [int]$lostStatePending.GetValue($context) -eq 1 -and
    [int]$recoveredStatePending.GetValue($context) -eq 0 -and
    [long]$feedbackPlaceholderDue.GetValue($context) -eq 0) `
    "fatal mirror recv error queues continuity and cancels any smooth handoff"
Assert-True ($armedDue -ge $before + [TimeSpan]::FromSeconds(2).Ticks) `
    "recovery grace is not shorter than two seconds"
Assert-True ($armedDue -le [DateTime]::UtcNow.AddSeconds(4).Ticks) `
    "recovery grace is bounded"

$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_CLIENT_FEEDBACK_RECOVERED gap_seconds=6")) |
    Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 1 -and
    [int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$rendererHandoffPending.GetValue($context) -eq 0) `
    "a late recovered marker cannot dismiss an already-fatal loss episode"

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
    [object[]]@(42,
        "AEROMIRROR_HTTP_READY stage=reset port=53999")) | Out-Null
Assert-True ([int]$httpResetStatus.GetValue($context) -eq 1 -and
    [int]$httpResetPort.GetValue($context) -eq 53999 -and
    [int]$socketsReady.GetValue($context) -eq 1) `
    "matching native reset readiness is retained through abnormal mirror cleanup"
$observe.Invoke(
    $context,
    [object[]]@(42, "connection request from reconnecting iPhone")) | Out-Null
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0) `
    "a reconnect request cancels abnormal-loss discovery renewal"
Assert-True ([int]$recoveryPid.GetValue($context) -eq 0) `
    "a reconnect request clears the abnormal-loss owner"
Assert-True ([long]$recoveryDue.GetValue($context) -eq 0) `
    "a reconnect request clears the abnormal-loss deadline"
Assert-True ([int]$httpResetStatus.GetValue($context) -eq 0 -and
    [int]$httpResetPort.GetValue($context) -eq 0) `
    "a reconnect request clears one-shot HTTP reset evidence"
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$placeholderClosePending.GetValue($context) -eq 0) `
    "a reconnect handshake keeps the placeholder until mirroring really starts"

$clientGraceDue.SetValue($context, [long]0)
$mirrorActive.SetValue($context, 0)
$httpMarkersReady.SetValue($context, 1)
$httpPort.SetValue($context, 53999)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 0)
$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$missingConfirmationAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($missingConfirmationAction -eq "RestartStalledSession") `
    "a marker-capable core cannot preserve same-process recovery without matching reset readiness"

$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$observe.Invoke(
    $context,
    [object[]]@(42,
        "AEROMIRROR_HTTP_READY stage=reset port=53999")) | Out-Null
$preserveAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($preserveAction -eq "PreserveNativeRecovery") `
    "an ended abnormal session preserves only an explicitly confirmed same-port native reset"
Assert-True ([int]$recoveryPending.GetValue($context) -eq 0 -and
    [int]$recoveryPid.GetValue($context) -eq 0 -and
    [long]$recoveryDue.GetValue($context) -eq 0 -and
    [int]$httpResetStatus.GetValue($context) -eq 0 -and
    [int]$httpResetPort.GetValue($context) -eq 0) `
    "consuming discovery renewal clears all one-shot recovery state"
$secondRenewAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($secondRenewAction -eq "None") `
    "the same abnormal loss cannot renew discovery twice"

$httpMarkersReady.SetValue($context, 0)
$httpPort.SetValue($context, 0)
$httpResetStatus.SetValue($context, 0)
$httpResetPort.SetValue($context, 0)
$socketsReady.SetValue($context, 0)
$recoveryPending.SetValue($context, 1)
$recoveryPid.SetValue($context, 42)
$recoveryDue.SetValue($context, [DateTime]::UtcNow.AddSeconds(-1).Ticks)
$observeSocketReady.Invoke($context, [object[]]@(42)) | Out-Null
$legacyPreserveAction = $consumeLostRecovery.Invoke(
    $context, [object[]]@([DateTime]::UtcNow, $true, $false)).ToString()
Assert-True ($legacyPreserveAction -eq "PreserveLegacyRecovery") `
    "a legacy core keeps a bounded generic listener fallback without claiming port identity"

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
$pendingVideoSizeIsAmbiguous.SetValue($context, $true)
$currentVideoSizeIsAmbiguous.SetValue($context, $true)
$rawGeometryVideoSize.SetValue($context, $presentationCanvas)
$rawGeometryVideoSizeGeneration.SetValue($context, 7)
$rawGeometryIsAmbiguous.SetValue($context, $true)
$earlyDeviceFrameVideoSize.SetValue($context, $portraitFrame)
$deviceFrameVideoSize.SetValue($context, $landscapeFrame)
$lastSuppressedVideoSize.SetValue($context, $presentationCanvas)
$observe.Invoke(
    $context,
    [object[]]@(42, "raop_rtp_mirror starting mirroring")) | Out-Null
Assert-True ([int]$placeholderShowPending.GetValue($context) -eq 1 -and
    [int]$placeholderClosePending.GetValue($context) -eq 0 -and
    [int]$rendererHandoffPending.GetValue($context) -eq 1) `
    "a new mirroring start keeps continuity until the renderer actually exists"
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$deviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$lastSuppressedVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    -not [bool]$pendingVideoSizeIsAmbiguous.GetValue($context) -and
    -not [bool]$currentVideoSizeIsAmbiguous.GetValue($context) -and
    [Drawing.Size]$rawGeometryVideoSize.GetValue($context) -eq
        [Drawing.Size]::Empty -and
    -not [bool]$rawGeometryIsAmbiguous.GetValue($context)) `
    "a new mirroring session forgets the previous device aspect and media-canvas classification"
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
$pendingVideoSizeIsAmbiguous.SetValue($context, $true)
$currentVideoSizeIsAmbiguous.SetValue($context, $true)
$rawGeometryVideoSize.SetValue($context, $presentationCanvas)
$rawGeometryVideoSizeGeneration.SetValue($context, 7)
$rawGeometryIsAmbiguous.SetValue($context, $true)
$earlyDeviceFrameVideoSize.SetValue($context, $portraitFrame)
$deviceFrameVideoSize.SetValue($context, $landscapeFrame)
$lastSuppressedVideoSize.SetValue($context, $presentationCanvas)
$httpMarkersReady.SetValue($context, 1)
$httpPort.SetValue($context, 53999)
$httpResetStatus.SetValue($context, 1)
$httpResetPort.SetValue($context, 53999)
$resetCoreSession.Invoke($context, [object[]]@($false)) | Out-Null
Assert-True ([Drawing.Size]$earlyDeviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$deviceFrameVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    [Drawing.Size]$lastSuppressedVideoSize.GetValue($context) -eq
    [Drawing.Size]::Empty -and
    -not [bool]$pendingVideoSizeIsAmbiguous.GetValue($context) -and
    -not [bool]$currentVideoSizeIsAmbiguous.GetValue($context) -and
    [Drawing.Size]$rawGeometryVideoSize.GetValue($context) -eq
        [Drawing.Size]::Empty -and
    -not [bool]$rawGeometryIsAmbiguous.GetValue($context) -and
    [int]$httpMarkersReady.GetValue($context) -eq 0 -and
    [int]$httpPort.GetValue($context) -eq 0 -and
    [int]$httpResetStatus.GetValue($context) -eq 0 -and
    [int]$httpResetPort.GetValue($context) -eq 0) `
    "core reset clears learned device orientation, media-canvas, and native HTTP lifecycle state"

Write-Host "Receiver resilience checks passed."
