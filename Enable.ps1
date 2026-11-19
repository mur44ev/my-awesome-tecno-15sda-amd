$ErrorActionPreference = 'Stop'
$helperDir = Join-Path $env:LOCALAPPDATA 'TecnoBacklightKeepAlive'
$config = Get-Content -LiteralPath (Join-Path $helperDir 'install.json') -Raw | ConvertFrom-Json
$flag = Join-Path $helperDir 'disabled.flag'
if (Test-Path -LiteralPath $flag) { Remove-Item -LiteralPath $flag }
Start-Process -FilePath $config.pythonw -ArgumentList ('"' + (Join-Path $helperDir 'backlight.py') + '"') -WorkingDirectory $helperDir -WindowStyle Hidden
Write-Output 'Helper enabled.'
