$ErrorActionPreference = 'Stop'
$helperDir = Join-Path $env:LOCALAPPDATA 'TecnoBacklightKeepAlive'
if (!(Test-Path -LiteralPath $helperDir)) { throw 'Helper is not installed.' }
Set-Content -LiteralPath (Join-Path $helperDir 'disabled.flag') -Value 'disabled'
Write-Output 'Helper disabled. It will stop within four seconds and remain disabled after sign-in.'
