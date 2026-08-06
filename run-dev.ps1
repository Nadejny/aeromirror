$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $projectRoot "build.ps1")
& (Join-Path $projectRoot "artifacts\Release\AeroMirror.exe") --show
