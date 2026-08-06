param(
    [string]$Destination = ".\vendor"
)

$ErrorActionPreference = "Stop"
$releaseTag = "2.0.0.1736"
$assetName = "uxplay-windows.zip"
$expectedSha256 = "9D3A51C15FC9DB857351195E7EB7BBB21700D9AE25D936A54BCF8536B62CCA18"
$url = "https://github.com/leapbtw/uxplay-windows/releases/download/$releaseTag/$assetName"

$destinationRoot = [System.IO.Path]::GetFullPath($Destination)
$archive = Join-Path $destinationRoot $assetName
$extracted = Join-Path $destinationRoot "uxplay-windows-$releaseTag"

function Assert-ChildPath([string]$Parent, [string]$Child) {
    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childFull = [System.IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe output path: $childFull is outside $parentFull"
    }
}

New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null
Invoke-WebRequest -Uri $url -OutFile $archive

$actualSha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
if ($actualSha256 -ne $expectedSha256) {
    throw "SHA-256 mismatch. Expected $expectedSha256, got $actualSha256."
}

Assert-ChildPath -Parent $destinationRoot -Child $extracted
if (Test-Path $extracted) {
    Remove-Item -LiteralPath $extracted -Recurse -Force
}
Expand-Archive -LiteralPath $archive -DestinationPath $extracted

Write-Host "Verified and extracted: $extracted"
Write-Host "Create the portable package with:"
Write-Host ".\package.ps1 -UxPlayPortablePath `"$extracted`""
